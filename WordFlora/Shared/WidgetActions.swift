import Foundation
import SwiftData

/// Logic shared by the app and the home-screen widget, so both run exactly the same rules (spec section 4).
enum WidgetActions {
    /// Spec section 18 (P15): the thirsty look never appears in widgets or notifications.
    static let widgetShowsThirstyLook = false

    struct PlantSnapshot: Equatable {
        var plantId: String
        var name: String
        var imageName: String
        var stage: Int
        var thirsty: Bool
        var growthFraction: Double
        // Computed from the stored plant when the snapshot is taken (never stored): what the buttons and the line show.
        /// Both of today's drinks are in (the water button would be refused).
        var waterDone = false
        /// At least one drink today (the plant's water line).
        var wateredToday = false
        var saidHelloToday = false
        /// Petals all gone (13+ only; never under 13, Calm or Quiet Garden): the widget cannot wake it, so it links to the plant.
        var isSeed = false
        /// The app's own seed for the plant's lines today (`AppModel.helloLine`), so the widget says what the app said.
        var voiceSeed = 0
        /// The species name ("Rose"), shown instead of a typed name while the phone is locked.
        var speciesName = ""
        /// `name` is a name the player typed (a nickname), so the Lock Screen hides it while locked.
        var hasTypedName: Bool { !speciesName.isEmpty && speciesName != name }
        /// The name to show: the species name when `hideTyped` (Lock Screen while locked), else `name`.
        func shownName(hideTyped: Bool) -> String { hideTyped && hasTypedName ? speciesName : name }
    }

    /// A typed plant name is never shown for under 13, on any widget family (the species name is used instead).
    static func showsTypedNames(in d: UserDefaults) -> Bool { d.string(forKey: "ageBand") != "under13" }

    /// The widget's midnight refresh: the next local midnight by the calendar (safe across daylight saving and the
    /// new year; a day is not always 24 hours). On a day with no midnight, the first moment after it.
    static func nextMidnight(after now: Date, calendar: Calendar) -> Date {
        calendar.nextDate(after: now, matching: DateComponents(hour: 0, minute: 0, second: 0), matchingPolicy: .nextTime)
            ?? calendar.startOfDay(for: now).addingTimeInterval(86_400)
    }

    struct GardenSnapshot: Equatable {
        var hero: PlantSnapshot?
        var others: [PlantSnapshot]
        var water: Int
        /// When the next free drop arrives (the timeline refreshes then), or nil when the can is full.
        var nextTrickle: Date? = nil
    }

    /// What the widget gallery and the placeholder show: a rose, never the empty state.
    static let sample = GardenSnapshot(hero: PlantSnapshot(plantId: "rose", name: "Rose", imageName: "plant_rose", stage: 2,
                                                           thirsty: false, growthFraction: 0.4), others: [], water: 3)

    /// The gallery (a preview) shows the sample when this phone has no plant to show yet.
    static func galleryShowsSample(isPreview: Bool, snapshot: GardenSnapshot) -> Bool { isPreview && snapshot.hero == nil }

    @MainActor
    static func snapshot(context: ModelContext, now: Date, calm: Bool, calendar: Calendar = .current, exempt: Bool = false,
                         typedNames: Bool = true) -> GardenSnapshot {
        let profile = (try? context.fetch(FetchDescriptor<PlayerProfile>()))?.first
        let earned = ((try? context.fetch(FetchDescriptor<PlantCollectible>(sortBy: [SortDescriptor(\.level), SortDescriptor(\.name)]))) ?? [])
            .filter { $0.earnedCount > 0 && !$0.plantId.hasPrefix("glasshouse_") }     // ladder plants (GlasshouseCatalog.idPrefix)
        // The count the can holds once the free drops that are due arrive (a tap credits them first), and the next one's time.
        var water = 0, next: Date?
        if let profile {
            let trickle = ToolEngine.trickleEconomy(.default, inventory: ToolInventory(json: profile.toolsJSON))
            water = TendingEngine.projectedWater(profile, now: now, economy: trickle)
            next = TendingEngine.nextTrickle(profile, now: now, economy: trickle)
        }
        guard !earned.isEmpty else { return GardenSnapshot(hero: nil, others: [], water: water, nextTrickle: next) }

        let hero: PlantCollectible
        if let pin = profile?.widgetPlantID, let pinned = earned.first(where: { $0.plantId == pin }) {
            hero = pinned
        } else {
            // The plant that has waited longest for a drink (never-tended plants count as freshly watered).
            hero = earned.min { ($0.lastTendedAt ?? .distantFuture) < ($1.lastTendedAt ?? .distantFuture) } ?? earned[0]
        }
        func snap(_ p: PlantCollectible) -> PlantSnapshot {
            let eco = Economy.default
            let cost = eco.levelBaseCost * eco.levelCostMultipliers[max(0, min(4, p.level - 1))]
            return PlantSnapshot(plantId: p.plantId, name: !typedNames || p.nickname.isEmpty ? p.name : p.nickname,
                                 imageName: p.imageName, stage: p.stage,
                                 thirsty: TendingEngine.isThirsty(p, now: now, calm: calm), growthFraction: min(1, Double(p.growthPoints) / cost),
                                 waterDone: TendingEngine.isDone(.water, plant: p, now: now, calendar: calendar, economy: eco),
                                 wateredToday: TendingEngine.waterings(p, now: now, calendar: calendar) > 0,
                                 saidHelloToday: TendingEngine.isToday(p.lastLovedAt, now: now, calendar: calendar),
                                 isSeed: LoveEngine.state(lastLoved: p.lastLovedAt, now: now, exempt: exempt).isSeed,
                                 voiceSeed: Int(now.timeIntervalSince1970 / 86_400) &+ p.earnedCount, speciesName: p.name)
        }
        let others = earned.filter { $0.plantId != hero.plantId }.prefix(2).map(snap)
        return GardenSnapshot(hero: snap(hero), others: Array(others), water: water, nextTrickle: next)
    }

    /// The medium widget's line, in order: tomorrow's weather when there is one; the plant's hello answer after a hello
    /// today; its water line after a drink today; else the calm default. Same `PlantVoice` pools and seed as the app.
    static func line(for s: PlantSnapshot, weather: String?) -> String {
        if let weather { return weather }
        if s.saidHelloToday { return PlantVoice.helloLine(plantId: s.plantId, daySeed: s.voiceSeed, tap: 0) }
        if s.wateredToday { return PlantVoice.line(plantId: s.plantId, event: .water, daySeed: s.voiceSeed) }
        return WidgetCopy.defaultLine
    }

    /// The widget's water button. Free drops are credited first, then one drop is spent. Safe to call repeatedly.
    @MainActor
    @discardableResult
    static func water(plantId: String, context: ModelContext, now: Date, calendar: Calendar, quiet: Bool) -> TendResult {
        guard let profile = (try? context.fetch(FetchDescriptor<PlayerProfile>()))?.first,
              let plant = (try? context.fetch(FetchDescriptor<PlantCollectible>()))?.first(where: { $0.plantId == plantId && $0.earnedCount > 0 })
        else { return .blocked(.noWater) }
        let eco = Economy.default
        ToolEngine.applyTrickle(profile, inventory: ToolInventory(json: profile.toolsJSON), now: now, economy: eco)
        let result = TendingEngine.water(plant, profile: profile, now: now, calendar: calendar, economy: eco, quiet: quiet)
        try? context.save()
        return result
    }

    /// One calm sentence for Siri and Control Center: waters the garden's hero plant using the very same rules as the widget.
    @MainActor
    static func waterGarden(context: ModelContext, now: Date, calendar: Calendar, quiet: Bool) -> String {
        guard let hero = snapshot(context: context, now: now, calm: true).hero else {
            return WidgetCopy.siriNoPlant
        }
        let result = water(plantId: hero.plantId, context: context, now: now, calendar: calendar, quiet: quiet)
        if result.applied { return "\(hero.name) had a drink and is growing nicely." }
        switch result.reason {
        case .noWater: return TendCopy.canDry
        case .doneForToday: return TendCopy.done(.water, name: hero.name)
        default: return "Your garden is ready when you are."
        }
    }

    /// The widget's Say hello button: the same love as a tap hello in the app (sets `lastLovedAt`, so the daily quest's
    /// "say hello" counts it when the app comes back). A seed is woken in the app, never from the widget. Safe to repeat.
    @MainActor
    @discardableResult
    static func hello(plantId: String, context: ModelContext, now: Date, exempt: Bool) -> Bool {
        guard let plant = (try? context.fetch(FetchDescriptor<PlantCollectible>()))?.first(where: { $0.plantId == plantId && $0.earnedCount > 0 }),
              !LoveEngine.state(lastLoved: plant.lastLovedAt, now: now, exempt: exempt).isSeed
        else { return false }
        plant.lastLovedAt = now
        try? context.save()
        return true
    }
}

/// Every word the widget, its Lock Screen families and the Control Center button show (checked by `CopySafety` in tests).
/// Intent and control titles must stay string literals in their own files; `titles` repeats them so the test sees them.
enum WidgetCopy {
    static let displayName = "Your garden"
    static let description = "See a plant from your garden and give it a drink."
    static let growing = "Growing nicely"
    static let growingInline = "growing nicely"
    static let growingLabel = "Growing"
    static let defaultLine = "Your garden says hello"
    static let firstPlant = "Play a word to find your first plant"
    static let playWord = "Play a word"
    static let playWordLabel = "Play a word to fill your can"
    static let water = "Water"
    static let wateredToday = "Watered today"
    static let sayHello = "Say hello"
    static let saidHello = "Said hello"
    static let visit = "Visit"
    static let appName = "WordFlora"
    static let watering = "Watering"
    static let controlLabel = "Water garden"
    static let titles = ["Water a plant", "Say hello to a plant", "Plant", "Water my garden",
                         "Give your garden a drink.", "Gives your garden a drink."]
    static let siriNoPlant = "Play a word to find your first plant, then come back to water it."

    /// The empty small and medium widget: the calm fallback when the store cannot be read yet, else the first-plant invitation.
    static func emptyLine(unavailable: Bool) -> String { unavailable ? GardenFallback.widgetLine : firstPlant }
    /// Where the empty widget goes: the app itself when the store is not ready (the player may have plants), else a round.
    static func emptyURL(unavailable: Bool) -> URL { URL(string: unavailable ? "wordflora://" : "wordflora://play")! }
    static func plantURL(_ plantId: String) -> URL { URL(string: "wordflora://plant/\(plantId)") ?? emptyURL(unavailable: false) }

    static func drops(_ n: Int) -> String { n == 1 ? "1 drop" : "\(n) drops" }
    static func waterLabel(name: String, water: Int, quiet: Bool) -> String {
        quiet ? "Water \(name)" : "Water \(name). \(drops(water)) in your can"
    }
    static func wateredLabel(name: String) -> String { "\(name) watered today" }
    static func helloLabel(name: String) -> String { "Say hello to \(name)" }
    static func saidHelloLabel(name: String) -> String { "You said hello to \(name) today" }
    static func visitLabel(name: String) -> String { "Visit \(name)" }
    static func circularLabel(name: String) -> String { "\(name), growing" }
    static func percent(_ fraction: Double) -> String { "\(Int((min(1, max(0, fraction)) * 100).rounded(.down))) percent" }
    /// The Lock Screen inline line: "Daisy: growing nicely" or "Daisy: Tomorrow: windy". The system truncates it itself.
    static func inline(name: String?, chip: String?) -> String {
        guard let name else { return appName }
        return "\(name): \(chip ?? growingInline)"
    }

    /// Every fixed string plus each template filled with a sample name, for the copy test.
    static func all(sampleName n: String = "Daisy") -> [String] {
        [displayName, description, growing, growingInline, growingLabel, defaultLine, firstPlant, playWord, playWordLabel, water,
         wateredToday, sayHello, saidHello, visit, appName, watering, controlLabel, siriNoPlant, emptyLine(unavailable: true), emptyLine(unavailable: false),
         waterLabel(name: n, water: 3, quiet: false), waterLabel(name: n, water: 1, quiet: false), waterLabel(name: n, water: 0, quiet: true),
         wateredLabel(name: n), helloLabel(name: n), saidHelloLabel(name: n), visitLabel(name: n), circularLabel(name: n),
         percent(0.4), inline(name: n, chip: nil), inline(name: nil, chip: nil)] + titles
    }
}
