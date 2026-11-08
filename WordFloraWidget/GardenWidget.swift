import WidgetKit
import SwiftUI
import SwiftData
import AppIntents

// MARK: Intent (runs in the widget process; same rules as the app via WidgetActions)

struct WaterPlantIntent: AppIntent {
    // Titles stay literals (App Intents metadata); WidgetCopy.titles repeats them for the copy test.
    static var title: LocalizedStringResource = "Water a plant"
    static var isDiscoverable: Bool { false }

    @Parameter(title: "Plant") var plantId: String

    init() { plantId = "" }
    init(plantId: String) { self.plantId = plantId }

    @MainActor
    func perform() async throws -> some IntentResult {
        if let container = try? SharedContainer.make(role: .appExtension) {
            WidgetActions.water(plantId: plantId, context: container.mainContext, now: .now, calendar: .current, quiet: SharedDefaults.quietGarden)
        }
        // WidgetKit reloads only the tapped widget; this also moves the Lock Screen gauge and any second widget.
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

/// The medium widget's Say hello button: the same hello as a tap on the plant in the app (love, so it keeps its petals
/// and the daily quest's "say hello" counts it). Allowed in Quiet Garden and Calm, like the tap hello.
struct HelloPlantIntent: AppIntent {
    static var title: LocalizedStringResource = "Say hello to a plant"
    static var isDiscoverable: Bool { false }

    @Parameter(title: "Plant") var plantId: String

    init() { plantId = "" }
    init(plantId: String) { self.plantId = plantId }

    @MainActor
    func perform() async throws -> some IntentResult {
        if let container = try? SharedContainer.make(role: .appExtension) {
            WidgetActions.hello(plantId: plantId, context: container.mainContext, now: .now,
                                exempt: SharedDefaults.loveExempt(in: SharedDefaults.store))
        }
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

// MARK: Timeline

struct GardenEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetActions.GardenSnapshot
    let quiet: Bool
    var unavailable = false
    /// Tomorrow's garden weather in plain words (GardenWeather.widgetLine), or nil. Never in Calm or Quiet Garden.
    var weatherLine: String? = nil
    var weatherChip: String? = nil
}

struct GardenProvider: TimelineProvider {
    func placeholder(in context: Context) -> GardenEntry {
        GardenEntry(date: .now, snapshot: WidgetActions.sample, quiet: false)
    }

    func getSnapshot(in context: Context, completion: @escaping (GardenEntry) -> Void) {
        let preview = context.isPreview
        Task { @MainActor in
            let entry = load()
            // The widget gallery shows a plant, not the empty state, on a phone with no plant yet.
            completion(WidgetActions.galleryShowsSample(isPreview: preview, snapshot: entry.snapshot)
                       ? GardenEntry(date: .now, snapshot: WidgetActions.sample, quiet: entry.quiet) : entry)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<GardenEntry>) -> Void) {
        Task { @MainActor in
            // The thirsty look is never shown in a widget, so a slow refresh is enough (spec section 4).
            let now = Date()
            let entry = load(at: now)
            guard !entry.unavailable else {
                completion(Timeline(entries: [entry], policy: .after(now.addingTimeInterval(15 * 60)))); return
            }
            // Refresh when the next free drop arrives (a minute late, so it is surely in), else in six hours, so the
            // water button is not hidden while a drop is in the can.
            var refresh = now.addingTimeInterval(6 * 3600)
            if let drop = entry.snapshot.nextTrickle?.addingTimeInterval(60), drop > now, drop < refresh { refresh = drop }
            // Midnight too: the weather line, "Watered today" and "Said hello" follow the day.
            let midnight = Calendar.current.startOfDay(for: now).addingTimeInterval(86_400 + 60)
            let later = [midnight, refresh].filter { $0 > now && $0 <= refresh }.sorted().map { load(at: $0) }
            completion(Timeline(entries: [entry] + later, policy: .after(refresh)))
        }
    }

    @MainActor private func load(at date: Date = .now) -> GardenEntry {
        let calm = true /* never the thirsty look in a widget */, quiet = SharedDefaults.quietGarden
        guard let container = try? SharedContainer.make(role: .appExtension) else {
            return GardenEntry(date: date, snapshot: .init(hero: nil, others: [], water: 0), quiet: quiet, unavailable: true)
        }
        let context = container.mainContext
        let d = SharedDefaults.store
        var entry = GardenEntry(date: date, snapshot: WidgetActions.snapshot(context: context, now: date, calm: calm, calendar: .current,
                                                                             exempt: SharedDefaults.loveExempt(in: d)), quiet: quiet)
        if let p = (try? context.fetch(FetchDescriptor<PlayerProfile>()))?.first {
            let c = GardenWeather.widgetContext(profile: p, today: WeatherDay.key(date), quietGarden: quiet,
                                                calmMode: SharedDefaults.calmMode(in: d), weatherOn: SharedDefaults.gardenWeather(in: d))
            entry.weatherLine = GardenWeather.widgetLine(c)
            entry.weatherChip = GardenWeather.widgetChip(c)
        }
        return entry
    }
}

// MARK: Views

struct GardenWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "GardenWidget", provider: GardenProvider()) { entry in
            GardenWidgetView(entry: entry)
                .containerBackground(Color("appBackground"), for: .widget)
        }
        .configurationDisplayName(WidgetCopy.displayName)
        .description(WidgetCopy.description)
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

struct GardenWidgetView: View {
    let entry: GardenEntry
    /// Only for rendering checks outside WidgetKit (the family environment value cannot be set there).
    var familyOverride: WidgetFamily?
    @Environment(\.widgetFamily) private var family
    @Environment(\.dynamicTypeSize) private var typeSize

    init(entry: GardenEntry, familyOverride: WidgetFamily? = nil) {
        self.entry = entry
        self.familyOverride = familyOverride
    }

    var body: some View {
        switch familyOverride ?? family {
        case .accessoryCircular: circular
        case .accessoryRectangular: rectangular
        case .accessoryInline: inline
        case .systemMedium: medium
        default: small
        }
    }

    private var hero: WidgetActions.PlantSnapshot? { entry.snapshot.hero }
    private let primary = Color("appPrimaryText")

    /// The plant gives way first: `ideal` is what the layout check counts, and the art grows up to `max` when there is room.
    private func plantImage(_ s: WidgetActions.PlantSnapshot, ideal: CGFloat, max: CGFloat) -> some View {
        Image(s.imageName).resizable().scaledToFit()
            .frame(idealHeight: ideal, maxHeight: max)
            .accessibilityHidden(true)
    }

    private func name(_ s: WidgetActions.PlantSnapshot) -> some View {
        Text(s.name).font(.system(.subheadline, design: .rounded, weight: .bold)).foregroundStyle(primary)
            .lineLimit(2).minimumScaleFactor(0.8).multilineTextAlignment(.center)
    }

    private func capsule<V: View>(_ content: V, ink: Color, fill: Color, inset: CGFloat = 12) -> some View {
        content
            .font(.system(.footnote, design: .rounded, weight: .bold)).foregroundStyle(ink)
            .minimumScaleFactor(0.8).multilineTextAlignment(.center)
            .padding(.horizontal, inset).padding(.vertical, 6).background(fill, in: Capsule())
    }

    /// Water: the drop count while it can drink; "Watered today" (not a button) after both drinks; "Play a word" when dry.
    @ViewBuilder private func waterButton(_ s: WidgetActions.PlantSnapshot) -> some View {
        if s.waterDone {
            capsule(Label(WidgetCopy.wateredToday, systemImage: "checkmark"), ink: primary, fill: Color("appSurface"))
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(WidgetCopy.wateredLabel(name: s.name))
        } else if entry.snapshot.water > 0 || entry.quiet {
            Button(intent: WaterPlantIntent(plantId: s.plantId)) {
                capsule(Label(entry.quiet ? WidgetCopy.water : "\(entry.snapshot.water)", systemImage: "drop.fill").invalidatableContent(),
                        ink: Color("ink"), fill: Color("appAccent"))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(WidgetCopy.waterLabel(name: s.name, water: entry.snapshot.water, quiet: entry.quiet))
        } else {
            Link(destination: URL(string: "wordflora://play")!) {
                capsule(Text(WidgetCopy.playWord), ink: primary, fill: Color("appSurface"))
            }
            .accessibilityLabel(WidgetCopy.playWordLabel)
        }
    }

    /// Hello: "Say hello", then "Said hello" for the day (still a button; a second hello is harmless). A seed is woken in
    /// the app, so it becomes a "Visit" link to the plant's page.
    @ViewBuilder private func helloButton(_ s: WidgetActions.PlantSnapshot) -> some View {
        if s.isSeed {
            Link(destination: WidgetCopy.plantURL(s.plantId)) {
                capsule(Label(WidgetCopy.visit, systemImage: "leaf.fill"), ink: primary, fill: Color("appSurface"), inset: 10)
            }
            .accessibilityLabel(WidgetCopy.visitLabel(name: s.name))
        } else {
            Button(intent: HelloPlantIntent(plantId: s.plantId)) {
                capsule(Label(s.saidHelloToday ? WidgetCopy.saidHello : WidgetCopy.sayHello,
                              systemImage: s.saidHelloToday ? "heart.fill" : "heart"),
                        ink: primary, fill: Color("appSurface"), inset: 10)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(s.saidHelloToday ? WidgetCopy.saidHelloLabel(name: s.name) : WidgetCopy.helloLabel(name: s.name))
        }
    }

    private var chip: some View {
        Text(entry.weatherChip ?? WidgetCopy.growing).font(.system(.caption2, design: .rounded))
            .foregroundStyle(primary.opacity(0.7)).multilineTextAlignment(.center)
    }

    private var small: some View {
        Group {
            if let s = hero {
                // The first layout whose words all fit: drop the chip, then the name; the plant art shrinks before any word.
                ViewThatFits(in: .vertical) {
                    VStack(spacing: 4) { plantImage(s, ideal: 36, max: 74); name(s); chip; waterButton(s) }
                    VStack(spacing: 4) { plantImage(s, ideal: 36, max: 74); name(s); waterButton(s) }
                    VStack(spacing: 4) { plantImage(s, ideal: 28, max: 74); waterButton(s) }
                }
                .widgetURL(WidgetCopy.plantURL(s.plantId))
            } else { empty }
        }
    }

    private func growthBar(_ s: WidgetActions.PlantSnapshot) -> some View {
        ProgressView(value: s.growthFraction).tint(Color("appSuccess")).padding(.horizontal, 12)
            .accessibilityLabel(WidgetCopy.growingLabel)
            .accessibilityValue(WidgetCopy.percent(s.growthFraction))
    }

    /// Stacked in the medium widget at every text size (a row of two would not fit the column).
    private func buttons(_ s: WidgetActions.PlantSnapshot) -> some View {
        VStack(spacing: 4) { waterButton(s); helloButton(s) }
    }

    private var line: some View {
        Text(hero.map { WidgetActions.line(for: $0, weather: entry.weatherLine) } ?? WidgetCopy.defaultLine)
            .font(.system(.caption, design: .rounded)).foregroundStyle(primary.opacity(0.75)).multilineTextAlignment(.center)
    }

    private var medium: some View {
        Group {
            if let s = hero {
                HStack(spacing: 12) {
                    VStack(spacing: 4) {
                        plantImage(s, ideal: 44, max: 84)
                        name(s)
                        growthBar(s)
                    }.frame(maxWidth: .infinity)
                    ViewThatFits(in: .vertical) {
                        VStack(spacing: 6) {
                            if !entry.snapshot.others.isEmpty {
                                HStack(spacing: 6) { ForEach(entry.snapshot.others, id: \.plantId) { o in
                                    Image(o.imageName).resizable().scaledToFit().frame(height: 32).accessibilityHidden(true) } }
                            }
                            line
                            buttons(s)
                        }
                        VStack(spacing: 6) { line; buttons(s) }
                        buttons(s)
                    }.frame(maxWidth: .infinity)
                }
                .widgetURL(WidgetCopy.plantURL(s.plantId))
            } else { empty }
        }
    }

    private var circular: some View {
        Group {
            if let s = hero {
                // The gauge is growth toward full bloom, so a leaf, not a drop.
                Gauge(value: s.growthFraction) { Image(systemName: "leaf.fill") }
                    .gaugeStyle(.accessoryCircularCapacity)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(WidgetCopy.circularLabel(name: s.name))
                    .accessibilityValue(WidgetCopy.percent(s.growthFraction))
            } else { Image(systemName: "leaf.fill").accessibilityLabel(WidgetCopy.appName) }
        }
    }

    private var rectangular: some View {
        Group {
            if let s = hero {
                VStack(alignment: .leading, spacing: 2) {
                    // At the accessibility sizes the name takes the room the chip had (layout chosen by size, not measured).
                    Text(s.name).font(.headline).lineLimit(typeSize.isAccessibilitySize ? 2 : 1).minimumScaleFactor(0.8)
                    if !typeSize.isAccessibilitySize { Text(entry.weatherChip ?? WidgetCopy.growing).font(.caption) }
                    Gauge(value: s.growthFraction) { EmptyView() }.gaugeStyle(.accessoryLinearCapacity).accessibilityHidden(true)
                }
            } else { Text(WidgetCopy.emptyLine(unavailable: entry.unavailable)).font(.caption).minimumScaleFactor(0.8) }
        }
    }

    private var inline: some View {
        Label(WidgetCopy.inline(name: hero?.name, chip: entry.weatherChip), systemImage: "leaf.fill")
    }

    private var empty: some View {
        VStack(spacing: 6) {
            // The leaf steps aside at the accessibility sizes so every word of the line has the room.
            if !typeSize.isAccessibilitySize {
                Image(systemName: "leaf.fill").font(.title).foregroundStyle(Color("appSuccess")).accessibilityHidden(true)
            }
            Text(WidgetCopy.emptyLine(unavailable: entry.unavailable)).font(.system(.caption, design: .rounded))
                .multilineTextAlignment(.center).minimumScaleFactor(0.8).foregroundStyle(primary)
        }
        .widgetURL(WidgetCopy.emptyURL(unavailable: entry.unavailable))
    }
}
