import SwiftUI

// The Grand Garden endgame (G-2 to G-5; design-preview/endgame direction A, Revision 1). No Plus, ads, prices or
// offers appear anywhere in these screens, and the visit that shows a ceremony stays free of them (`markQuietVisit`).

private let crownGold = Color(red: 0.96, green: 0.78, blue: 0.30)

private extension Color {
    /// A colour with its own dark-mode value (art colours not in the asset catalog).
    init(light: UIColor, dark: UIColor) {
        self.init(uiColor: UIColor { $0.userInterfaceStyle == .dark ? dark : light })
    }
}

extension EndgamePolicy.Ceremony: Identifiable { var id: String { rawValue } }

// MARK: The Gardener's Crown

/// A flower crown, not a royal one: a ring of leaves with seven small flowers. Drawn into one Canvas so VoiceOver and
/// the audit see one image with its label.
struct GardenerCrownView: View {
    var gold = false

    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let band = Path { p in
                p.move(to: CGPoint(x: w * 0.1, y: h * 0.62))
                p.addQuadCurve(to: CGPoint(x: w * 0.9, y: h * 0.62), control: CGPoint(x: w * 0.5, y: h * -0.05))
            }
            ctx.stroke(band, with: .color(Color(red: 0.55, green: 0.70, blue: 0.48)), style: StrokeStyle(lineWidth: max(2, h * 0.06), lineCap: .round))
            for (x, flip) in [(0.06, false), (0.94, true)] {
                var leaf = Path(ellipseIn: CGRect(x: -h * 0.16, y: -h * 0.08, width: h * 0.32, height: h * 0.16))
                leaf = leaf.applying(CGAffineTransform(rotationAngle: flip ? -0.5 : 0.5))
                    .applying(CGAffineTransform(translationX: w * x, y: h * 0.56))
                ctx.fill(leaf, with: .color(Color(red: 0.31, green: 0.55, blue: 0.33)))
            }
            let petals: [Color] = gold
                ? [crownGold, Color(red: 0.93, green: 0.66, blue: 0.20), crownGold, Color(red: 1, green: 0.88, blue: 0.5),
                   crownGold, Color(red: 0.93, green: 0.66, blue: 0.20), crownGold]
                : [Color(red: 0.89, green: 0.42, blue: 0.48), Color(red: 0.89, green: 0.65, blue: 0.26), Color(red: 0.69, green: 0.58, blue: 0.86),
                   .white, Color(red: 0.89, green: 0.65, blue: 0.26), Color(red: 0.69, green: 0.58, blue: 0.86), Color(red: 0.89, green: 0.42, blue: 0.48)]
            let r = min(w / 16, h * 0.2)
            for i in 0..<7 {
                let t = Double(i) / 6
                let cx = w * (0.2 + 0.6 * t), cy = h * (0.66 - 0.06 * sin(t * .pi))
                let big = i == 3 ? 1.25 : 1.0
                for k in 0..<5 {
                    let a = Double(k) / 5 * 2 * .pi - .pi / 2
                    let pr = r * 0.62 * big
                    let c = CGPoint(x: cx + cos(a) * pr, y: cy + sin(a) * pr)
                    let petal = Path(ellipseIn: CGRect(x: c.x - pr * 0.8, y: c.y - pr * 0.8, width: pr * 1.6, height: pr * 1.6))
                    ctx.fill(petal, with: .color(petals[i]))
                    ctx.stroke(petal, with: .color(.black.opacity(0.12)), lineWidth: 0.6)
                }
                let core = Path(ellipseIn: CGRect(x: cx - r * 0.38 * big, y: cy - r * 0.38 * big, width: r * 0.76 * big, height: r * 0.76 * big))
                ctx.fill(core, with: .color(gold ? Color(red: 0.75, green: 0.45, blue: 0.10) : Color(red: 0.95, green: 0.78, blue: 0.30)))
            }
        }
        .aspectRatio(3.2, contentMode: .fit)
        .accessibilityElement()
        .accessibilityLabel(gold ? EndgameCopy.goldCrownPicture : EndgameCopy.crownPicture)
        .accessibilityAddTraits(.isImage)
    }
}

extension View {
    /// The crown resting on the Home wordmark once every plant is found (gold once the whole garden is in full bloom).
    func crowned(_ crown: EndgamePolicy.Crown) -> some View { modifier(CrownedWordmark(crown: crown)) }
    /// Plays the Grand Garden or the gold crown once, the first time Home appears after it is earned.
    func grandGardenCeremony() -> some View { modifier(GrandGardenCeremony()) }
    /// The golden look of a plant with 7 golden days: a warm gold tint and a soft glow.
    func goldenBloom(_ golden: Bool) -> some View { modifier(GoldenBloom(golden: golden)) }
}

private struct CrownedWordmark: ViewModifier {
    let crown: EndgamePolicy.Crown
    func body(content: Content) -> some View {
        content
            .overlay(alignment: .topLeading) {
                if crown != .none {
                    GardenerCrownView(gold: crown == .gold)
                        .frame(width: 64)
                        .offset(x: -6, y: -20)
                        .accessibilityLabel(crown == .gold ? EndgameCopy.goldCrownOnWordmark : EndgameCopy.crownOnWordmark)
                        .accessibilityIdentifier("home.crown")
                }
            }
            .padding(.top, crown == .none ? 0 : 14)
    }
}

private struct GoldenBloom: ViewModifier {
    let golden: Bool
    func body(content: Content) -> some View {
        if golden {
            content
                .compositingGroup()
                .colorMultiply(Color(red: 1, green: 0.88, blue: 0.55))
                .shadow(color: crownGold.opacity(0.75), radius: 14)
        } else {
            content
        }
    }
}

private struct GrandGardenCeremony: ViewModifier {
    @Environment(AppModel.self) private var app
    @Environment(GameRouter.self) private var router
    @State private var showing: EndgamePolicy.Ceremony?

    func body(content: Content) -> some View {
        content
            .onAppear {
                guard showing == nil, let c = app.pendingCeremony else { return }
                app.markCeremonySeen(c)
                app.pauseBadgeMoments(.sheet, true)
                showing = c
            }
            .fullScreenCover(item: $showing, onDismiss: { app.pauseBadgeMoments(.sheet, false) }) { c in
                EndgameCeremonyView(ceremony: c) { walk in
                    showing = nil
                    if walk { router.go(.garden) }
                }
                .environment(app).environment(router)
            }
    }
}

// MARK: The ceremony screens

/// The Grand Garden (with "What grows next" after it) or the gold crown moment.
struct EndgameCeremonyView: View {
    let ceremony: EndgamePolicy.Ceremony
    var replay = false
    /// Called to close; `true` when the player chose "Walk my garden".
    let close: (Bool) -> Void

    @Environment(AppModel.self) private var app
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @State private var page = 0
    @AccessibilityFocusState private var titleFocus: Bool

    private var reduceMotion: Bool { systemReduceMotion || app.settings.reduceMotionOverride }

    var body: some View {
        ZStack {
            switch (ceremony, page) {
            case (.grandGarden, 0): GrandGardenPage(reduceMotion: reduceMotion, titleFocus: $titleFocus,
                                                   next: { go(1) }, walk: { close(true) }).transition(.opacity)
            case (.grandGarden, _): WhatGrowsNextPage(titleFocus: $titleFocus, done: { close(false) }).transition(.opacity)
            case (.goldCrown, _): GoldCrownPage(reduceMotion: reduceMotion, titleFocus: $titleFocus, done: { close(false) })
            }
        }
        .animation(.easeInOut(duration: reduceMotion ? 0.3 : 0.5), value: page)
        .onAppear { app.markQuietVisit() }
    }

    private func go(_ p: Int) {
        page = p
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { titleFocus = true }
    }
}

private struct SkyBackground: View {
    var body: some View {
        LinearGradient(colors: [Color(light: UIColor(red: 0.88, green: 0.92, blue: 0.97, alpha: 1), dark: UIColor(red: 0.10, green: 0.13, blue: 0.24, alpha: 1)),
                                Color(light: UIColor(red: 0.93, green: 0.91, blue: 0.96, alpha: 1), dark: UIColor(red: 0.16, green: 0.15, blue: 0.27, alpha: 1)),
                                Color.appBackground],
                       startPoint: .top, endPoint: .bottom)
        .ignoresSafeArea()
    }
}

private struct GrandGardenPage: View {
    let reduceMotion: Bool
    var titleFocus: AccessibilityFocusState<Bool>.Binding
    let next: () -> Void
    let walk: () -> Void
    @Environment(AppModel.self) private var app
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        ZStack(alignment: .top) {
            SkyBackground()
            if !reduceMotion {
                PetalConfettiView(level: app.celebrationLevel(.medium, systemReduceMotion: reduceMotion), origin: .fromTop(120), seed: 50)
                    .ignoresSafeArea().allowsHitTesting(false).accessibilityHidden(true)
            }
            ScrollView {
                VStack(spacing: 14) {
                    GardenerCrownView().frame(maxWidth: 260).padding(.top, 18)
                        .background(Circle().fill(crownGold.opacity(0.22)).blur(radius: 30).accessibilityHidden(true))
                    Label(EndgameCopy.crownEarned, systemImage: "sparkles")
                        .font(Theme.font(.subheadline, weight: .bold)).foregroundStyle(Color.appPrimaryText)
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(Color.appSurface, in: Capsule())
                        .overlay(Capsule().stroke(crownGold, lineWidth: 2))
                    // A soft card under the words, so falling petals never pass behind the text.
                    VStack(spacing: 8) {
                        Text(EndgameCopy.everyPlantFound)
                            .font(Theme.font(.largeTitle, weight: .heavy)).foregroundStyle(Color.appPrimaryText)
                            .multilineTextAlignment(.center).accessibilityAddTraits(.isHeader)
                            .accessibilityFocused(titleFocus)
                            .accessibilityIdentifier("grandGarden.title")
                        Text(EndgameCopy.everyPlantLine)
                            .font(Theme.font(.body)).foregroundStyle(Color.appPrimaryText).multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 12).padding(.vertical, 8)
                    .background(Color.appBackground, in: RoundedRectangle(cornerRadius: 18))
                    GardenHills(plants: app.plants(), compact: typeSize.isAccessibilitySize)
                        .padding(.horizontal, -20)
                    legend
                    Button(EndgameCopy.seeWhatsNext, action: next).buttonStyle(PrimaryButtonStyle())
                        .accessibilityIdentifier("grandGarden.next")
                    Button(EndgameCopy.walkGarden, action: walk).buttonStyle(SecondaryButtonStyle())
                        .accessibilityIdentifier("grandGarden.walk")
                }
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 20).padding(.bottom, 24)
            }
        }
    }

    private var legend: some View {
        let layout = typeSize.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8)) : AnyLayout(HStackLayout(spacing: 24))
        return layout { legendItem(EndgameCopy.stillGrowing, small: true); legendItem(EndgameCopy.fullBloom, small: false) }
    }

    private func legendItem(_ text: String, small: Bool) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "camera.macro").font(small ? .caption : .body).foregroundStyle(Color.successText).accessibilityHidden(true)
            Text(text).font(Theme.font(.subheadline, weight: .semibold)).foregroundStyle(Color.appPrimaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// Every plant on five terraced hills, rarest at the back, each drawn at its earned stage. One label for the picture.
struct GardenHills: View {
    let plants: [PlantCollectible]
    var compact = false

    var body: some View {
        let sorted = plants.sorted { ($0.level, $0.name) < ($1.level, $1.name) }
        let rows = EndgamePolicy.hills(sorted)
        let height: CGFloat = compact ? 300 : 380
        GeometryReader { geo in
            let w = geo.size.width
            ZStack(alignment: .top) {
                ForEach(Array(rows.enumerated()), id: \.offset) { i, row in
                    let top = height * (0.06 + 0.19 * CGFloat(i))
                    Ellipse()
                        .fill(Color(light: UIColor(red: 0.80 - 0.04 * CGFloat(i), green: 0.88 - 0.02 * CGFloat(i), blue: 0.74 - 0.04 * CGFloat(i), alpha: 1),
                                    dark: UIColor(red: 0.17 + 0.02 * CGFloat(i), green: 0.27 + 0.02 * CGFloat(i), blue: 0.20, alpha: 1)))
                        .frame(width: w * 1.5, height: height * 0.5)
                        .offset(y: top + 22)
                    let size = min(w / CGFloat(max(row.count, 1)) * 0.95, 36 + 7 * CGFloat(i))
                    HStack(alignment: .bottom, spacing: 0) {
                        ForEach(row, id: \.plantId) { p in
                            Image(p.imageName).resizable().scaledToFit()
                                .frame(width: size * EndgamePolicy.hillScale(stage: p.stage), height: size * EndgamePolicy.hillScale(stage: p.stage))
                                .goldenBloom(EndgamePolicy.isGolden(days: p.goldenDays))
                                .frame(maxWidth: .infinity, minHeight: size, alignment: .bottom)
                        }
                    }
                    .frame(width: w * 0.94)
                    .offset(y: top)
                }
            }
            .frame(width: w, height: height, alignment: .top)
            .clipped()
        }
        .frame(height: height)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(EndgameCopy.gardenPicture)
        .accessibilityAddTraits(.isImage)
        .accessibilityIdentifier("grandGarden.hills")
    }
}

private struct WhatGrowsNextPage: View {
    var titleFocus: AccessibilityFocusState<Bool>.Binding
    let done: () -> Void
    @Environment(AppModel.self) private var app

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                GardenerCrownView(gold: app.crown == .gold).frame(maxWidth: 160).padding(.top, 20)
                Text(EndgameCopy.whatGrowsNext).font(Theme.font(.largeTitle, weight: .heavy)).foregroundStyle(Color.appPrimaryText)
                    .multilineTextAlignment(.center).accessibilityAddTraits(.isHeader).accessibilityFocused(titleFocus)
                    .accessibilityIdentifier("whatsNext.title")
                Text(EndgameCopy.keepsGrowing).font(Theme.font(.body)).foregroundStyle(Color.secondaryText).multilineTextAlignment(.center)
                NextCard(symbol: "sun.max.fill", tint: crownGold, title: EndgameCopy.goldenTitle, blurb: EndgameCopy.goldenBlurb) {
                    if let f = app.featuredGolden {
                        GoldenPips(days: f.days, label: EndgameCopy.goldenProgress(name: f.name, days: f.days, of: Economy.default.goldenDaysNeeded))
                    }
                }
                NextCard(symbol: "camera.macro", tint: .petalRose, title: EndgameCopy.rankTitle, blurb: EndgameCopy.ranksBlurb) {
                    RankChips(rank: app.bloomRank)
                }
                NextCard(symbol: "book.fill", tint: .tileVisitorsIcon, title: EndgameCopy.visitorsBook, blurb: EndgameCopy.bookBlurb) { EmptyView() }
                if !app.settings.quietGarden {
                    NextCard(symbol: "wind", tint: .tileLevelsIcon, title: EndgameCopy.weatherTitle, blurb: EndgameCopy.weatherBlurb) { EmptyView() }
                }
                Label(EndgameCopy.staysWithYou, systemImage: "leaf.fill")
                    .font(Theme.font(.subheadline, weight: .semibold)).foregroundStyle(Color.appPrimaryText)
                Button(EndgameCopy.backToGarden, action: done).buttonStyle(PrimaryButtonStyle())
                    .accessibilityIdentifier("whatsNext.done")
            }
            .padding(.horizontal, 20).padding(.bottom, 24)
        }
        .background(Color.appBackground.ignoresSafeArea())
    }
}

private struct NextCard<Extra: View>: View {
    let symbol: String
    let tint: Color
    let title: String
    let blurb: String
    @ViewBuilder let extra: () -> Extra
    @Environment(\.dynamicTypeSize) private var typeSize
    @ScaledMetric(relativeTo: .title) private var art: CGFloat = 64

    var body: some View {
        let layout = typeSize.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: 10)) : AnyLayout(HStackLayout(alignment: .top, spacing: 14))
        layout {
            Image(systemName: symbol).font(.system(size: art * 0.45)).foregroundStyle(tint)
                .frame(width: art, height: art).background(tint.opacity(0.15), in: RoundedRectangle(cornerRadius: 14))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 6) {
                Text(title).font(Theme.font(.title3, weight: .bold)).foregroundStyle(Color.appPrimaryText).accessibilityAddTraits(.isHeader)
                Text(blurb).font(Theme.font(.body)).foregroundStyle(Color.secondaryText).fixedSize(horizontal: false, vertical: true)
                extra()
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.appSurface, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
        .overlay(RoundedRectangle(cornerRadius: Theme.cardRadius).stroke(Color.appPrimaryText.opacity(0.08)))
    }
}

/// Seven pips for golden days plus the words (VoiceOver reads the words only).
struct GoldenPips: View {
    let days: Int
    let label: String
    @ScaledMetric(relativeTo: .body) private var pip: CGFloat = 16
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        let goal = Economy.default.goldenDaysNeeded
        let layout = typeSize >= .xxLarge ? AnyLayout(VStackLayout(alignment: .leading, spacing: 6)) : AnyLayout(HStackLayout(spacing: 10))
        layout { pips(goal); if !label.isEmpty { words } }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(EndgameCopy.goldenPips(days: min(days, goal), of: goal))
    }

    private var words: some View {
        Text(label).font(Theme.font(.subheadline, weight: .bold)).foregroundStyle(Color.appPrimaryText).fixedSize(horizontal: false, vertical: true)
    }

    private func pips(_ goal: Int) -> some View {
        HStack(spacing: 5) {
            ForEach(0..<goal, id: \.self) { i in
                Circle().fill(i < days ? crownGold : Color.clear)
                    .overlay(Circle().stroke(i < days ? crownGold : Color.appPrimaryText.opacity(0.45), lineWidth: 1.5))
                    .frame(width: pip, height: pip)
            }
        }
    }
}

/// The six ranks as chips; the current one has a tick and is said in words.
struct RankChips: View {
    let rank: BloomRank

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            FlowChips(items: BloomRank.allCases.dropFirst().map { $0 }) { r in
                HStack(spacing: 4) {
                    if r == rank { Image(systemName: "checkmark").font(.caption.weight(.bold)).accessibilityHidden(true) }
                    Text(r.name).font(Theme.font(.footnote, weight: .bold))
                }
                .foregroundStyle(r == rank ? Color.ink : Color.appPrimaryText)
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(r == rank ? Color.appAccent : Color.appBackground, in: Capsule())
                .overlay(Capsule().stroke(Color.appPrimaryText.opacity(0.12)))
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(BloomRank.allCases.dropFirst().map(\.name).joined(separator: ", "))
            Text(EndgameCopy.youAre(rank)).font(Theme.font(.subheadline, weight: .bold)).foregroundStyle(Color.appPrimaryText)
                .accessibilityIdentifier("bloomRank.line")
        }
    }
}

/// A simple wrapping row of chips.
private struct FlowChips<Item: Hashable, Chip: View>: View {
    let items: [Item]
    @ViewBuilder let chip: (Item) -> Chip
    var body: some View {
        FlowLayout(spacing: 6, lineSpacing: 6) { ForEach(items, id: \.self) { chip($0) } }
    }
}

private struct GoldCrownPage: View {
    let reduceMotion: Bool
    var titleFocus: AccessibilityFocusState<Bool>.Binding
    let done: () -> Void
    @Environment(AppModel.self) private var app

    var body: some View {
        ZStack {
            SkyBackground()
            if !reduceMotion {
                PetalConfettiView(level: app.celebrationLevel(.medium, systemReduceMotion: reduceMotion), origin: .fromTop(140), seed: 51)
                    .ignoresSafeArea().allowsHitTesting(false).accessibilityHidden(true)
            }
            ScrollView {
                VStack(spacing: 16) {
                    GardenerCrownView(gold: true).frame(maxWidth: 280).padding(.top, 40)
                        .background(Circle().fill(crownGold.opacity(0.3)).blur(radius: 30).accessibilityHidden(true))
                    VStack(spacing: 10) {
                        Text(EndgameCopy.goldCrownTitle).font(Theme.font(.largeTitle, weight: .heavy)).foregroundStyle(Color.appPrimaryText)
                            .multilineTextAlignment(.center).accessibilityAddTraits(.isHeader).accessibilityFocused(titleFocus)
                            .accessibilityIdentifier("goldCrown.title")
                        Text(EndgameCopy.goldCrownLine).font(Theme.font(.title3, weight: .semibold)).foregroundStyle(Color.appPrimaryText)
                            .multilineTextAlignment(.center)
                        Text(EndgameCopy.goldCrownTurns).font(Theme.font(.body)).foregroundStyle(Color.appPrimaryText).multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 12).padding(.vertical, 8)
                    .background(Color.appBackground, in: RoundedRectangle(cornerRadius: 18))
                    GardenHills(plants: app.plants(), compact: true).padding(.horizontal, -20)
                    Button(EndgameCopy.lovely, action: done).buttonStyle(PrimaryButtonStyle()).accessibilityIdentifier("goldCrown.done")
                }
                .padding(.horizontal, 20).padding(.bottom, 24)
            }
        }
    }
}

// MARK: Home, plant page and Badges pieces

/// Home's golden line once every plant is found: the plant nearest to golden today, or "Every plant is golden."
struct EndgameHomeCard: View {
    @Environment(AppModel.self) private var app
    @Environment(GameRouter.self) private var router

    var body: some View {
        if app.crown != .none && !app.settings.quietGarden {
            if let f = app.featuredGolden {
                Button { router.go(.plant(f.id)) } label: { card(EndgameCopy.daysFromGolden(name: f.name, days: EndgamePolicy.daysToGolden(days: f.days)), days: f.days) }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("home.golden")
            } else if app.everyPlantGolden {
                card(EndgameCopy.allGolden, days: nil).accessibilityIdentifier("home.golden")
            }
        }
    }

    private func card(_ line: String, days: Int?) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(EndgameCopy.goldenTitle, systemImage: "sun.max.fill")
                .font(Theme.font(.caption, weight: .bold)).foregroundStyle(Color.appPrimaryText)
            Text(line).font(Theme.font(.body, weight: .semibold)).foregroundStyle(Color.appPrimaryText).fixedSize(horizontal: false, vertical: true)
            if let days { GoldenPips(days: days, label: "").accessibilityHidden(true) }
        }
        .padding(14).frame(maxWidth: .infinity, alignment: .leading)
        .background(crownGold.opacity(0.18), in: RoundedRectangle(cornerRadius: Theme.cardRadius))
        .overlay(RoundedRectangle(cornerRadius: Theme.cardRadius).stroke(crownGold.opacity(0.6)))
        .accessibilityElement(children: .combine)
    }
}

/// The plant page's golden progress, once every plant is found and this plant is in full bloom.
struct GoldenProgressCard: View {
    let plant: PlantCollectible
    @Environment(AppModel.self) private var app

    var body: some View {
        if app.allPlantsFoundNow && plant.stage >= 4 {
            let name = plant.nickname.isEmpty ? plant.name : plant.nickname
            let golden = app.isGolden(plant)
            VStack(alignment: .leading, spacing: 8) {
                Text(EndgameCopy.goldenTitle).font(Theme.font(.headline, weight: .bold)).foregroundStyle(Color.appPrimaryText)
                    .accessibilityAddTraits(.isHeader)
                Text(golden ? EndgameCopy.goldenLine(name: name) : EndgameCopy.daysFromGolden(name: name, days: EndgamePolicy.daysToGolden(days: plant.goldenDays)))
                    .font(Theme.font(.body)).foregroundStyle(Color.appPrimaryText).fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("plant.golden")
                if !golden {
                    GoldenPips(days: plant.goldenDays, label: "")
                    Text(EndgameCopy.goldenNote).font(Theme.font(.footnote)).foregroundStyle(Color.secondaryText).fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(16).frame(maxWidth: .infinity, alignment: .leading)
            .background(crownGold.opacity(0.14), in: RoundedRectangle(cornerRadius: Theme.cardRadius))
            .overlay(RoundedRectangle(cornerRadius: Theme.cardRadius).stroke(crownGold.opacity(0.5)))
        }
    }
}

/// The top of the Badges page: the bloom rank, and once earned a card to watch the Grand Garden again.
struct EndgameBadgesHeader: View {
    @Environment(AppModel.self) private var app
    @State private var replay = false

    var body: some View {
        VStack(spacing: 12) {
            if app.crown != .none {
                HStack(spacing: 12) {
                    GardenerCrownView(gold: app.crown == .gold).frame(width: 84)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(EndgameCopy.grandGardenTitle).font(Theme.font(.headline, weight: .bold)).foregroundStyle(Color.appPrimaryText)
                            .accessibilityAddTraits(.isHeader)
                        Button(EndgameCopy.replay) { replay = true }
                            .font(Theme.font(.subheadline, weight: .bold)).foregroundStyle(Color.accentText).tapTarget()
                            .accessibilityIdentifier("badges.replayGrandGarden")
                    }
                    Spacer(minLength: 0)
                }
                .padding(14)
                .background(Color.appSurface, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
            }
            if !app.settings.quietGarden {
                VStack(alignment: .leading, spacing: 8) {
                    Text(EndgameCopy.rankTitleShort).font(Theme.font(.headline, weight: .bold)).foregroundStyle(Color.appPrimaryText)
                        .accessibilityAddTraits(.isHeader)
                    RankChips(rank: app.bloomRank)
                    if let n = app.bloomsToNextRank, app.bloomRank != .unranked {
                        Text(EndgameCopy.rankNext(n)).font(Theme.font(.footnote)).foregroundStyle(Color.secondaryText)
                    } else if app.bloomRank == .evergreen {
                        Text(EndgameCopy.topRank).font(Theme.font(.footnote)).foregroundStyle(Color.secondaryText)
                    }
                }
                .padding(14).frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.appSurface, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
                .accessibilityIdentifier("badges.bloomRank")
            }
        }
        .fullScreenCover(isPresented: $replay) {
            EndgameCeremonyView(ceremony: .grandGarden, replay: true) { _ in replay = false }.environment(app)
        }
    }
}
