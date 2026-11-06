import WidgetKit
import SwiftUI
import SwiftData
import AppIntents

// MARK: Intent (runs in the widget process; same rules as the app via WidgetActions)

struct WaterPlantIntent: AppIntent {
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
        GardenEntry(date: .now, snapshot: .init(hero: .init(plantId: "rose", name: "Rose", imageName: "plant_rose", stage: 2, thirsty: false, growthFraction: 0.4), others: [], water: 3), quiet: false)
    }

    func getSnapshot(in context: Context, completion: @escaping (GardenEntry) -> Void) {
        Task { @MainActor in completion(load()) }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<GardenEntry>) -> Void) {
        Task { @MainActor in
            // One entry; the thirsty look is computed when the widget draws, so a slow refresh is enough (spec section 4).
            let entry = load()
            // A second entry at midnight, so the weather line follows the day (the forecast is a pure function of it).
            var entries = [entry]
            let midnight = Calendar.current.startOfDay(for: Date()).addingTimeInterval(86_400 + 60)
            if !entry.unavailable && midnight < Date().addingTimeInterval(6 * 3600) { entries.append(load(at: midnight)) }
            completion(Timeline(entries: entries, policy: .after(Date().addingTimeInterval(entry.unavailable ? 15 * 60 : 6 * 3600))))
        }
    }

    @MainActor private func load(at date: Date = .now) -> GardenEntry {
        let calm = true /* never the thirsty look in a widget */, quiet = SharedDefaults.quietGarden
        guard let container = try? SharedContainer.make(role: .appExtension) else {
            return GardenEntry(date: date, snapshot: .init(hero: nil, others: [], water: 0), quiet: quiet, unavailable: true)
        }
        let context = container.mainContext
        var entry = GardenEntry(date: date, snapshot: WidgetActions.snapshot(context: context, now: date, calm: calm), quiet: quiet)
        if let p = (try? context.fetch(FetchDescriptor<PlayerProfile>()))?.first {
            let d = SharedDefaults.store
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
        .configurationDisplayName("Your garden")
        .description("See a plant from your garden and give it a drink.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular])
    }
}

struct GardenWidgetView: View {
    let entry: GardenEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .accessoryCircular: circular
        case .accessoryRectangular: rectangular
        case .systemMedium: medium
        default: small
        }
    }

    private var hero: WidgetActions.PlantSnapshot? { entry.snapshot.hero }

    private func plantImage(_ s: WidgetActions.PlantSnapshot, height: CGFloat) -> some View {
        Image(s.imageName).resizable().scaledToFit().frame(height: height)
            
    }

    private func waterButton(_ s: WidgetActions.PlantSnapshot) -> some View {
        Group {
            if entry.snapshot.water > 0 || entry.quiet {
                Button(intent: WaterPlantIntent(plantId: s.plantId)) {
                    Label(entry.quiet ? "Water" : "\(entry.snapshot.water)", systemImage: "drop.fill")
                        .font(.system(.footnote, design: .rounded, weight: .bold)).foregroundStyle(Color("ink"))
                        .padding(.horizontal, 12).padding(.vertical, 6).background(Color("appAccent"), in: Capsule())
                }
                .buttonStyle(.plain)
            } else {
                Link(destination: URL(string: "wordflora://play")!) {
                    Text("Play a word").font(.system(.footnote, design: .rounded, weight: .bold)).foregroundStyle(Color("appPrimaryText"))
                        .padding(.horizontal, 12).padding(.vertical, 6).background(Color("appSurface"), in: Capsule())
                }
            }
        }
    }

    private var small: some View {
        Group {
            if let s = hero {
                VStack(spacing: 4) {
                    plantImage(s, height: 74)
                    Text(s.name).font(.system(.subheadline, design: .rounded, weight: .bold)).foregroundStyle(Color("appPrimaryText")).lineLimit(1)
                    Text(entry.weatherChip ?? "Growing nicely").font(.system(.caption2, design: .rounded)).foregroundStyle(Color("appPrimaryText").opacity(0.7))
                    waterButton(s)
                }
                .widgetURL(URL(string: "wordflora://plant/\(s.plantId)"))
            } else { empty }
        }
    }

    private var medium: some View {
        Group {
            if let s = hero {
                HStack(spacing: 12) {
                    VStack(spacing: 4) {
                        plantImage(s, height: 84)
                        Text(s.name).font(.system(.subheadline, design: .rounded, weight: .bold)).foregroundStyle(Color("appPrimaryText")).lineLimit(1)
                    }.frame(maxWidth: .infinity)
                    VStack(spacing: 8) {
                        HStack(spacing: 6) { ForEach(entry.snapshot.others, id: \.plantId) { o in plantImage(o, height: 44) } }
                        Text(entry.weatherLine ?? "Your garden says hello").font(.system(.caption, design: .rounded)).foregroundStyle(Color("appPrimaryText").opacity(0.75)).multilineTextAlignment(.center)
                        waterButton(s)
                    }.frame(maxWidth: .infinity)
                }
                .widgetURL(URL(string: "wordflora://plant/\(s.plantId)"))
            } else { empty }
        }
    }

    private var circular: some View {
        Group {
            if let s = hero {
                Gauge(value: s.growthFraction) { Image(systemName: "drop.fill") }
                    .gaugeStyle(.accessoryCircularCapacity)
            } else { Image(systemName: "leaf.fill") }
        }
    }

    private var rectangular: some View {
        Group {
            if let s = hero {
                VStack(alignment: .leading, spacing: 2) {
                    Text(s.name).font(.headline).lineLimit(1)
                    Text(entry.weatherChip ?? "Growing nicely").font(.caption)
                    Gauge(value: s.growthFraction) { EmptyView() }.gaugeStyle(.accessoryLinearCapacity)
                }
            } else { Text(entry.unavailable ? GardenFallback.widgetLine : "Play a word to find your first plant").font(.caption) }
        }
    }

    private var empty: some View {
        VStack(spacing: 6) {
            Image(systemName: "leaf.fill").font(.title).foregroundStyle(Color("appSuccess"))
            Text("Play a word to find your first plant").font(.system(.caption, design: .rounded)).multilineTextAlignment(.center).foregroundStyle(Color("appPrimaryText"))
        }
        .widgetURL(URL(string: "wordflora://play"))
    }
}
