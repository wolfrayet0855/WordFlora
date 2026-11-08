import Foundation

/// The weekly garden note (docs/pm/engagement-quick-wins.md, task A): on the first Home visit of a new week, a calm card
/// sums up the past Monday-to-Sunday in the player's garden. Positives only, no comparisons, no streaks, no card when
/// nothing happened. Computed from what is already stored (no model field); the week seen lives in device UserDefaults.
enum WeeklyNote {
    /// Monday-start Gregorian weeks in the device time zone.
    static func calendar(timeZone: TimeZone = .current) -> Calendar {
        var c = Calendar(identifier: .gregorian)
        c.firstWeekday = 2
        c.minimumDaysInFirstWeek = 1
        c.timeZone = timeZone
        return c
    }

    /// The local midnight of the Monday that starts the week holding `now`.
    static func weekStart(_ now: Date, calendar: Calendar) -> Date {
        calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? calendar.startOfDay(for: now)
    }

    /// The week key: the day number (days since 1 Jan 1970) of that Monday's local date. Built from the local year,
    /// month and day, so it is the same across daylight saving and in every time zone.
    static func weekKey(_ now: Date, calendar: Calendar) -> Int {
        let d = calendar.dateComponents([.year, .month, .day], from: weekStart(now, calendar: calendar))
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(identifier: "UTC")!
        guard let day = utc.date(from: DateComponents(year: d.year, month: d.month, day: d.day)) else { return 0 }
        return Int((day.timeIntervalSince1970 / 86_400).rounded())
    }

    /// The past week: `[weekStart - 7 days, weekStart)`, counted in calendar days so a daylight saving week is whole.
    static func pastWeek(_ now: Date, calendar: Calendar) -> Range<Date> {
        let end = weekStart(now, calendar: calendar)
        let start = calendar.date(byAdding: .day, value: -7, to: end) ?? end.addingTimeInterval(-7 * 86_400)
        return start..<end
    }

    /// One won or played round, as stored in `GameRecord`.
    struct Round: Equatable {
        var date: Date
        var won: Bool
        var isDaily: Bool
        var plantEarned: String?
    }

    struct Summary: Equatable {
        var words = 0
        var dailyBlooms = 0
        /// Species names (never typed names), in arrival order.
        var newPlants: [String] = []
        var friends = 0
        var weekKey = 0

        var hasAnything: Bool { words > 0 || dailyBlooms > 0 || !newPlants.isEmpty || friends > 0 }
    }

    /// The past week's summary.
    /// - `rounds`: every stored round (a plant counts as new in the week its first ever arrival falls in).
    /// - `friendsSeenAt`: the album's latest meeting per visitor id (weather stickers are not friends).
    /// Known limit: `seenAt` is the latest meeting, so a friend met again this week moves out of the past week.
    static func summary(rounds: [Round], friendsSeenAt: [String: Date], now: Date, calendar: Calendar) -> Summary {
        let week = pastWeek(now, calendar: calendar)
        var s = Summary(weekKey: weekKey(now, calendar: calendar))
        let wins = rounds.filter { $0.won && week.contains($0.date) }
        s.words = wins.count
        s.dailyBlooms = wins.filter(\.isDaily).count
        var firstArrival: [String: Date] = [:]
        for r in rounds where r.won {
            guard let name = r.plantEarned, !name.isEmpty else { continue }
            firstArrival[name] = min(firstArrival[name] ?? r.date, r.date)
        }
        s.newPlants = firstArrival.filter { week.contains($0.value) }
            .sorted { ($0.value, $0.key) < ($1.value, $1.key) }.map(\.key)
        s.friends = friendsSeenAt.filter { !WeatherSticker.isWeather($0.key) && week.contains($0.value) }.count
        return s
    }

    struct Context {
        var now: Date
        var calendar: Calendar
        /// The guide was seen or the first session finished.
        var onboarded: Bool
        /// `PlayerProfile.createdAt`.
        var gardenCreatedAt: Date
        /// `AppSettings.weeklyNoteSeenWeek` (0 = never).
        var seenWeek: Int
        /// A weather card, weather banner or welcome card is on Home: the note waits for a later visit this week.
        var otherCardShowing = false
        /// The Play nudge card is up.
        var nudgeShowing = false
        var quietGarden = false
    }

    /// Garden age in whole calendar days.
    static func gardenAgeDays(created: Date, now: Date, calendar: Calendar) -> Int {
        calendar.dateComponents([.day], from: calendar.startOfDay(for: created), to: calendar.startOfDay(for: now)).day ?? 0
    }

    /// The cheap checks, before any fetch: onboarding done, garden at least 7 days old, a week not seen, no other card.
    static func mayShow(_ c: Context) -> Bool {
        c.onboarded && !c.nudgeShowing && !c.otherCardShowing
            && gardenAgeDays(created: c.gardenCreatedAt, now: c.now, calendar: c.calendar) >= 7
            && weekKey(c.now, calendar: c.calendar) != c.seenWeek
    }

    /// The whole rule: the cheap checks, then something to say (Quiet Garden needs a new plant, as it shows no numbers).
    static func shouldShow(_ c: Context, summary: Summary) -> Bool {
        guard mayShow(c) else { return false }
        return c.quietGarden ? !summary.newPlants.isEmpty : summary.hasAnything
    }

    /// "Share my week": 13 and up only (ShareGate), and never in Quiet Garden (no numbers to show).
    static func shareAllowed(ageBand: AgeBand?, quietGarden: Bool) -> Bool {
        ShareGate.isAllowed(ageBand: ageBand) && !quietGarden
    }
}

/// Every word on the weekly note and its share card (swept by CopySafety in WeeklyNoteTests).
enum WeeklyNoteCopy {
    static let title = "Your week in the garden"
    static let celebrate = "Celebrate"
    static let celebrateHint = "Shows a moment of flowers for your week."
    static let celebrateTitle = "What a week!"
    static let celebrateLine = "Your garden grew with you."
    static let celebrateDone = "Done"
    static let share = "Share my week"
    static let shareHint = "Shares a picture of your week. No names or dates."
    static let caption = "My week in my WordFlora garden."
    static let shareHeader = "WordFlora"
    static let tagline = "Guess words. Grow a garden."
    static let closings = ["Your garden is glad you came by.", "Every word helps your garden grow.",
                           "Thank you for all the care this week."]

    static func words(_ n: Int) -> String { "You grew \(n) \(n == 1 ? "word" : "words")." }
    static func daily(_ n: Int) -> String { "You solved \(n) \(n == 1 ? "Daily Bloom" : "Daily Blooms")." }
    static func friends(_ n: Int) -> String { "You said hello to \(n) \(n == 1 ? "friend" : "friends")." }
    static func plants(_ names: [String]) -> String {
        "\(names.count == 1 ? "New plant" : "New plants"): \(list(names))."
    }
    /// Quiet Garden: names only, no numbers.
    static func quietPlants(_ names: [String]) -> String { "New in your garden: \(list(names))." }

    /// "Daisy", "Daisy and Clover", "Daisy, Clover and Fern", "Daisy, Clover, Fern and 2 more".
    static func list(_ names: [String]) -> String {
        switch names.count {
        case 0: return ""
        case 1: return names[0]
        case 2, 3: return names.dropLast().joined(separator: ", ") + " and " + names[names.count - 1]
        default: return names.prefix(3).joined(separator: ", ") + " and \(names.count - 3) more"
        }
    }

    /// The closing line, picked by week (the same all week, a different one the next).
    static func closing(weekKey: Int) -> String {
        let i = ((weekKey / 7) % closings.count + closings.count) % closings.count
        return closings[i]
    }

    /// The rows in order; a row with 0 is hidden. Quiet Garden: the plant names only.
    static func rows(_ s: WeeklyNote.Summary, quiet: Bool) -> [String] {
        if quiet { return s.newPlants.isEmpty ? [] : [quietPlants(s.newPlants)] }
        var r = [String]()
        if s.words > 0 { r.append(words(s.words)) }
        if s.dailyBlooms > 0 { r.append(daily(s.dailyBlooms)) }
        if !s.newPlants.isEmpty { r.append(plants(s.newPlants)) }
        if s.friends > 0 { r.append(friends(s.friends)) }
        return r
    }

    /// One hero tile on the card: a big number (nil in Quiet Garden) over a small label, and the sentence VoiceOver reads.
    struct Tile: Equatable {
        enum Kind: Equatable { case words, plants, friends }
        var kind: Kind
        var number: String?
        var label: String
        var spoken: String
    }

    static func wordsLabel(_ n: Int) -> String { n == 1 ? "word grown" : "words grown" }
    static func plantsLabel(_ n: Int) -> String { n == 1 ? "new plant" : "new plants" }
    static func friendsLabel(_ n: Int) -> String { n == 1 ? "friend said hello" : "friends said hello" }
    static let quietPlantsLabel = "New in your garden"

    /// The card's tiles in order: words grown, new plants, friends said hello; a tile with 0 is hidden. Daily Blooms are
    /// counted in the words. Quiet Garden: one plants tile with the names and no number.
    static func tiles(_ s: WeeklyNote.Summary, quiet: Bool) -> [Tile] {
        if quiet {
            return s.newPlants.isEmpty ? [] : [Tile(kind: .plants, number: nil, label: quietPlantsLabel + ": " + list(s.newPlants),
                                                    spoken: quietPlants(s.newPlants))]
        }
        var t = [Tile]()
        if s.words > 0 { t.append(Tile(kind: .words, number: "\(s.words)", label: wordsLabel(s.words), spoken: words(s.words))) }
        if !s.newPlants.isEmpty {
            t.append(Tile(kind: .plants, number: "\(s.newPlants.count)", label: plantsLabel(s.newPlants.count), spoken: plants(s.newPlants)))
        }
        if s.friends > 0 { t.append(Tile(kind: .friends, number: "\(s.friends)", label: friendsLabel(s.friends), spoken: friends(s.friends))) }
        return t
    }

    /// VoiceOver reads the card as one element: the title, then each tile's sentence in order, then the closing line.
    static func accessibilityLabel(_ s: WeeklyNote.Summary, quiet: Bool) -> String {
        ([title + "."] + tiles(s, quiet: quiet).map(\.spoken) + [closing(weekKey: s.weekKey)]).joined(separator: " ")
    }
}
