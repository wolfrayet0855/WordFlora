import SwiftUI
import SwiftData

/// Garden Path: the five levels as stops on a winding dirt path (design-preview/level-map/README.md).
/// Two tracks per level (spec section 19, P-01): plants found (Word) and plants in full bloom (Garden).
/// No padlocks anywhere: levels not open yet are "Coming soon in your garden". No prices, ads or Plus here.
struct LevelMapView: View {
    @Environment(AppModel.self) private var app
    @Environment(GameRouter.self) private var router
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query private var plants: [PlantCollectible]

    private var oneColumn: Bool { typeSize.isAccessibilitySize }

    var body: some View {
        let current = app.profile?.currentLevel ?? 1
        let stops = LevelMapCopy.stops(plants: plants.map { PlantProgress(level: $0.level, earned: $0.earnedCount > 0, stage: $0.stage) },
                                       currentLevel: current, mending: app.levelMending())
        let totalFound = plants.filter { $0.earnedCount > 0 }.count
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header(totalFound: totalFound)
                    MapKeyCard(oneColumn: oneColumn)
                        .padding(.horizontal, Space.gutter).padding(.top, Space.card)
                    trail(stops)
                        .padding(.horizontal, Space.gutter).padding(.top, Space.section)
                    end
                        .padding(.top, Space.section).padding(.bottom, 120)
                }
            }
            .onAppear {
                let target = stops.first(where: \.isCurrent)?.level ?? 1
                DispatchQueue.main.async {
                    withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.5)) { proxy.scrollTo(target, anchor: .center) }
                }
            }
        }
        .background(Color.appBackground.ignoresSafeArea())
        // Our own bar, so the "Home" back button shows its word and grows with Dynamic Type (the system bar caps its text).
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .top, spacing: 0) { navBar }
    }

    private var navBar: some View {
        // Decorative: the "Garden Path" header below is the screen's title for VoiceOver. Fixed size, not scaled.
        let wordmark = Image("Wordmark").resizable().scaledToFit().frame(height: 24).accessibilityHidden(true)
        let back = Button { dismiss() } label: {
            HStack(spacing: 3) {
                Image(systemName: "chevron.left").font(Theme.font(.body, weight: .bold))
                Text(LevelMapCopy.back).font(Theme.font(.body, weight: .bold))
            }
            .foregroundStyle(Color.accentText)
            .padding(.horizontal, 4)
            .tapTarget()
        }
        .accessibilityLabel(LevelMapCopy.back)
        return Group {
            if oneColumn {
                // Large text: side by side, so the big "Home" never runs into the wordmark.
                HStack(spacing: 8) { back; Spacer(minLength: 0); wordmark }
            } else {
                ZStack {
                    wordmark
                    HStack { back; Spacer(minLength: 0) }
                }
            }
        }
        .padding(.horizontal, Space.gutter - 4).padding(.vertical, 2)
        .frame(maxWidth: .infinity)
        .background(Color.appBackground.ignoresSafeArea(edges: .top))   // opaque, so scrolled text never shows through
    }

    // MARK: header

    private func header(totalFound: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(LevelMapCopy.title)
                .font(Theme.font(.largeTitle, weight: .black))
                .foregroundStyle(Color.appPrimaryText)
                .accessibilityAddTraits(.isHeader)
            Text(LevelMapCopy.subLine(totalFound: totalFound))
                .font(Theme.font(.body))
                .foregroundStyle(Color.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, Space.gutter).padding(.top, Space.s)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: trail

    private func trail(_ stops: [LevelStop]) -> some View {
        VStack(spacing: 26) {
            ForEach(stops, id: \.level) { stop in
                MapStopView(stop: stop, heroImage: heroImage(for: stop), medalLeading: stop.level % 2 == 1, oneColumn: oneColumn) {
                    router.go(.game(daily: false, level: stop.level))
                }
                .id(stop.level)
            }
        }
        .backgroundPreferenceValue(MapMedalCentreKey.self) { anchors in
            GeometryReader { geo in
                let points = anchors.sorted { $0.key < $1.key }.map { geo[$0.value] }
                ZStack {
                    MapTrailShape(points: points).stroke(Color.pathEdge, style: StrokeStyle(lineWidth: 26, lineCap: .round))
                    MapTrailShape(points: points).stroke(Color.path, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                    MapTrailShape(points: points).stroke(Color.pathEdge, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, dash: [1, 14]))
                    let waveLevels = BloomWave.levels(stops)
                    if !waveLevels.isEmpty { MapBloomWave(levels: waveLevels, medals: points) }
                }
            }
            .accessibilityHidden(true)
        }
    }

    /// The level's hero plant, or the first plant in the level when that art is not in the catalog.
    private func heroImage(for stop: LevelStop) -> String {
        if plants.isEmpty || plants.contains(where: { $0.imageName == stop.heroImage }) { return stop.heroImage }
        return plants.filter { $0.level == stop.level }.min { $0.plantId < $1.plantId }?.imageName ?? stop.heroImage
    }

    private var end: some View {
        VStack(spacing: 8) {
            MapBenchShape()
                .fill(Color.soil)
                .frame(width: 48, height: 22)
                .accessibilityHidden(true)
            Text(LevelMapCopy.end)
                .font(Theme.font(.subheadline, weight: .bold))
                .foregroundStyle(Color.secondaryText)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, Space.gutter)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Medal centres for the path

private struct MapMedalCentreKey: PreferenceKey {
    static let defaultValue: [Int: Anchor<CGPoint>] = [:]
    static func reduce(value: inout [Int: Anchor<CGPoint>], nextValue: () -> [Int: Anchor<CGPoint>]) {
        value.merge(nextValue()) { $1 }
    }
}

/// Cubic curves through the medal centres, control points at the vertical midpoint (straight when the centres line up).
private struct MapTrailShape: Shape {
    var points: [CGPoint]
    func path(in rect: CGRect) -> Path {
        var p = Path()
        guard let first = points.first else { return p }
        p.move(to: first)
        for (a, c) in zip(points, points.dropFirst()) {
            let midY = (a.y + c.y) / 2
            p.addCurve(to: c, control1: CGPoint(x: a.x, y: midY), control2: CGPoint(x: c.x, y: midY))
        }
        return p
    }
}

// MARK: - Bloom wave (G-3)

/// Small blooms open one after another along a full-bloom level's stretch of path, then rest there as a still garland.
/// Decorative (the path is hidden from VoiceOver; the card already says "Full bloom garden!"). Plays once per session;
/// Reduce Motion (system or the app's switch) shows the still garland; Calm, Quiet Garden and Low Power open it slowly.
private struct MapBloomWave: View {
    let levels: [Int]
    let medals: [CGPoint]
    @Environment(AppModel.self) private var app
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @State private var start: Date?
    @State private var waving: Set<Int> = []
    /// Levels whose wave has played this session (computed rule, nothing stored).
    @MainActor private static var played: Set<Int> = []

    private var calm: Bool { app.settings.calmMode || app.settings.quietGarden || ProcessInfo.processInfo.isLowPowerModeEnabled }

    var body: some View {
        Group {
            if let start, !waving.isEmpty {
                TimelineView(.animation(minimumInterval: 1 / 30)) { tl in garland(t: tl.date.timeIntervalSince(start)) }
            } else {
                garland(t: .infinity)
            }
        }
        .allowsHitTesting(false)
        .onAppear(perform: begin)
    }

    private func begin() {
        let reduceMotion = systemReduceMotion || app.settings.reduceMotionOverride
        let fresh = Set(levels.filter { BloomWave.mode(level: $0, played: Self.played, reduceMotion: reduceMotion) == .wave })
        Self.played.formUnion(levels)
        guard !fresh.isEmpty else { return }
        waving = fresh
        start = Date().addingTimeInterval(0.6)          // after the map has scrolled to the current level
        let end = 0.6 + BloomWave.duration(of: 2 * BloomWave.perHalf, calm: calm) + 0.2
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(end))
            waving = []                                 // then one still frame, no timeline left running
        }
    }

    private func garland(t: Double) -> some View {
        Canvas { g, _ in
            for level in levels {
                let spots = BloomWave.points(level: level, medals: medals)
                for (i, p) in spots.enumerated() {
                    let s = waving.contains(level) ? BloomWave.scale(index: i, of: spots.count, t: t, calm: calm) : 1
                    if s > 0.01 { bloom(g, at: p, scale: s, tilt: Double(i * 37 % 72)) }
                }
            }
        }
    }

    /// A five-petal bloom in the map's petal colour with a gold middle (the key's "petal" and "gold ring").
    private func bloom(_ g: GraphicsContext, at p: CGPoint, scale s: Double, tilt: Double) {
        var c = g
        c.translateBy(x: p.x, y: p.y)
        c.rotate(by: .degrees(tilt + (1 - min(1, s)) * 40))
        c.scaleBy(x: s, y: s)
        for k in 0..<5 {
            var petal = c
            petal.rotate(by: .degrees(Double(k) * 72))
            let shape = Path(ellipseIn: CGRect(x: -3.6, y: -10, width: 7.2, height: 9.5))
            petal.fill(shape, with: .color(.petal))
            petal.stroke(shape, with: .color(Color.appPrimaryText.opacity(0.22)), lineWidth: 0.8)
        }
        let middle = Path(ellipseIn: CGRect(x: -3.2, y: -3.2, width: 6.4, height: 6.4))
        c.fill(middle, with: .color(.appAccent))
        c.stroke(middle, with: .color(Color.appPrimaryText.opacity(0.25)), lineWidth: 0.6)
    }
}

// MARK: - Key card

private struct MapKeyCard: View {
    let oneColumn: Bool
    @ScaledMetric(relativeTo: .footnote) private var icon: CGFloat = 13

    var body: some View {
        let layout = oneColumn ? AnyLayout(VStackLayout(alignment: .leading, spacing: 10)) : AnyLayout(HStackLayout(spacing: 16))
        layout {
            item(LevelMapCopy.keyPetal) { MapPetalGlyph(size: icon) }
            item(LevelMapCopy.keyRing) {
                Circle().strokeBorder(Color.appAccent, lineWidth: max(2.5, icon * 0.22)).frame(width: icon, height: icon)
            }
        }
        .padding(.vertical, Space.m).padding(.horizontal, Space.card)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.appSurface.opacity(0.6), in: RoundedRectangle(cornerRadius: 16))
        .background(Color.appBackground, in: RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(LevelMapCopy.keyAccessibility)
    }

    private func item<G: View>(_ text: String, @ViewBuilder glyph: () -> G) -> some View {
        HStack(spacing: 6) {
            glyph()
            Text(text)
                .font(Theme.font(.footnote, weight: .bold))
                .foregroundStyle(Color.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// The small petal used in the key and the card rows.
private struct MapPetalGlyph: View {
    var size: CGFloat
    var body: some View {
        MapPetalShape().fill(Color.petal).frame(width: size * 0.7, height: size)
    }
}

/// A pointed petal (two arcs meeting top and bottom), drawn upright in its rect.
private struct MapPetalShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.midX, y: r.minY))
        p.addQuadCurve(to: CGPoint(x: r.midX, y: r.maxY), control: CGPoint(x: r.maxX + r.width * 0.25, y: r.midY + r.height * 0.1))
        p.addQuadCurve(to: CGPoint(x: r.midX, y: r.minY), control: CGPoint(x: r.minX - r.width * 0.25, y: r.midY + r.height * 0.1))
        return p
    }
}

/// A park bench: backrest, seat and two legs.
private struct MapBenchShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let w = r.width, h = r.height
        p.addRoundedRect(in: CGRect(x: r.minX, y: r.minY, width: w, height: h * 0.18), cornerSize: CGSize(width: 1.5, height: 1.5))
        p.addRoundedRect(in: CGRect(x: r.minX, y: r.minY + h * 0.36, width: w, height: h * 0.18), cornerSize: CGSize(width: 1.5, height: 1.5))
        p.addRect(CGRect(x: r.minX + w * 0.1, y: r.minY + h * 0.18, width: w * 0.07, height: h * 0.82))
        p.addRect(CGRect(x: r.maxX - w * 0.17, y: r.minY + h * 0.18, width: w * 0.07, height: h * 0.82))
        return p
    }
}

// MARK: - Stop (medal + card)

private struct MapStopView: View {
    let stop: LevelStop
    let heroImage: String
    let medalLeading: Bool
    let oneColumn: Bool
    let play: () -> Void

    var body: some View {
        if oneColumn {
            VStack(spacing: 12) {
                medal(size: 96)
                MapStopCard(stop: stop, play: play)
            }
        } else {
            HStack(alignment: .center, spacing: 12) {
                if medalLeading { medal(size: 128) }
                MapStopCard(stop: stop, play: play)
                if !medalLeading { medal(size: 128) }
            }
        }
    }

    private func medal(size: CGFloat) -> some View {
        LevelMedal(stop: stop, heroImage: heroImage, size: size)
            .anchorPreference(key: MapMedalCentreKey.self, value: .center) { [stop.level: $0] }
    }
}

/// The round medal for a level: tinted disc, hero plant, a petal per plant found and a gold arc per plant in full bloom.
/// Decorative (hidden from VoiceOver); the card's label says the same in words.
private struct LevelMedal: View {
    let stop: LevelStop
    let heroImage: String
    let size: CGFloat
    @Environment(\.colorScheme) private var scheme

    private static let tints: [Color] = [.levelTint1, .levelTint2, .levelTint3, .levelTint4, .levelTint5]

    var body: some View {
        ZStack {
            Canvas { ctx, _ in draw(&ctx) }
            if stop.isSoon {
                sprout
            } else {
                Image(heroImage)
                    .resizable().scaledToFit()
                    .frame(width: 68, height: 68)
                    .offset(y: -4)
            }
            badge.offset(x: 42, y: -46)
        }
        .frame(width: 128, height: 128)
        .scaleEffect(size / 128)
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    private func draw(_ ctx: inout GraphicsContext) {
        let c = CGPoint(x: 64, y: 64)
        let tint = Self.tints[(stop.level - 1) % Self.tints.count]
        let off = Color.appPrimaryText.opacity(scheme == .dark ? 0.18 : 0.13)
        let disc = Path(ellipseIn: CGRect(x: c.x - 40, y: c.y - 40, width: 80, height: 80))
        ctx.fill(disc, with: .color(tint))
        ctx.stroke(disc, with: .color(Color.appPrimaryText.opacity(0.14)), lineWidth: 1)
        guard stop.isOpen else { return }   // soon levels: no rings, so no blank slots

        if stop.isCurrent {
            ctx.stroke(Path(ellipseIn: CGRect(x: c.x - 43, y: c.y - 43, width: 86, height: 86)), with: .color(.appAccent), lineWidth: 3)
        }
        // Petal ring: one petal per plant, filled when found.
        for i in 0..<LevelMapCopy.perLevel {
            let angle = Angle.degrees(Double(i) * 36)
            let t = CGAffineTransform(translationX: c.x, y: c.y).rotated(by: angle.radians).translatedBy(x: 0, y: -50)
            let petal = Path(ellipseIn: CGRect(x: -4.6, y: -7.2, width: 9.2, height: 14.4)).applying(t)
            if i < stop.found { ctx.fill(petal, with: .color(.petal)) } else { ctx.stroke(petal, with: .color(off), lineWidth: 1.6) }
        }
        // Bloom ring: one arc per plant in full bloom; a solid ring when the whole level is in full bloom.
        if stop.fullBloom && stop.mending == 0 {
            ctx.stroke(Path(ellipseIn: CGRect(x: c.x - 60, y: c.y - 60, width: 120, height: 120)), with: .color(.appAccent), lineWidth: 5)
        } else {
            for i in 0..<LevelMapCopy.perLevel {
                let start = Double(i) * 36 - 90 + 1.5
                var arc = Path()
                arc.addArc(center: c, radius: 60, startAngle: .degrees(start), endAngle: .degrees(start + 33), clockwise: false)
                if i >= stop.bloom - stop.mending && i < stop.bloom {
                    // Wild Weather: a plant resting after the weather. Dashed gold, never grey or red; it mends by care or time.
                    ctx.stroke(arc, with: .color(.appAccent), style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [4, 5]))
                } else if i < stop.bloom {
                    ctx.stroke(arc, with: .color(.appAccent), lineWidth: 4.5)
                } else {
                    ctx.stroke(arc, with: .color(off), lineWidth: 2)
                }
            }
        }
    }

    /// Soon levels: a soil mound with a two-leaf sprout.
    private var sprout: some View {
        ZStack {
            Ellipse().fill(Color.soil.opacity(0.85)).frame(width: 44, height: 16).offset(y: 14)
            Capsule().fill(Color.successText).frame(width: 3, height: 20).offset(y: 0)
            MapLeafShape().fill(Color.successText).frame(width: 14, height: 8).rotationEffect(.degrees(-25)).offset(x: -7, y: -9)
            MapLeafShape().fill(Color.successText).frame(width: 14, height: 8).rotationEffect(.degrees(25)).scaleEffect(x: -1).offset(x: 7, y: -9)
        }
        .offset(y: 4)
    }

    @ViewBuilder private var badge: some View {
        if stop.isOpen && stop.fullBloom {
            Circle().fill(Color.appAccent).frame(width: 26, height: 26)
                .overlay(Image(systemName: "sun.max.fill").font(.system(size: 14, weight: .bold)).foregroundStyle(Color.ink))
        } else if stop.isOpen && stop.allFound {
            Circle().fill(Color.successText).frame(width: 26, height: 26)
                .overlay(Image(systemName: "checkmark").font(.system(size: 13, weight: .heavy)).foregroundStyle(.white))
        }
    }
}

/// A simple leaf: pointed at the left tip, round at the stem end.
private struct MapLeafShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.maxX, y: r.midY))
        p.addQuadCurve(to: CGPoint(x: r.minX, y: r.midY), control: CGPoint(x: r.midX, y: r.minY - r.height * 0.4))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.midY), control: CGPoint(x: r.midX, y: r.maxY + r.height * 0.4))
        return p
    }
}

// MARK: - Card

private struct MapStopCard: View {
    let stop: LevelStop
    let play: () -> Void
    @ScaledMetric(relativeTo: .subheadline) private var rowIcon: CGFloat = 14

    private let shape = RoundedRectangle(cornerRadius: 18)

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            info
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(stop.accessibilityLabel)
                .accessibilityAddTraits(stop.isCurrent ? .isSelected : [])
            if stop.isOpen { playButton }
        }
        .padding(Space.card)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background { cardFill }
        .overlay { cardBorder }
        .accessibilityElement(children: .contain)
    }

    private var info: some View {
        VStack(alignment: .leading, spacing: 3) {
            if stop.isCurrent {
                HStack(spacing: 4) {
                    Image(systemName: "mappin").font(Theme.font(.caption2, weight: .bold)).foregroundStyle(Color.accentText)
                    Text(LevelMapCopy.chip).font(Theme.font(.footnote, weight: .bold)).foregroundStyle(Color.appPrimaryText)
                }
                .padding(.horizontal, 9).padding(.vertical, 3)
                .background(Color.appAccent.opacity(0.24), in: Capsule())
                .padding(.bottom, 4)
            }
            Text(LevelMapCopy.eyebrow(stop.level).uppercased())
                .font(Theme.font(.footnote, weight: .heavy))
                .tracking(0.8)
                .foregroundStyle(Color.secondaryText)
            Text(stop.name)
                .font(Theme.font(.title3, weight: .black))
                .foregroundStyle(stop.isSoon ? Color.secondaryText : Color.appPrimaryText)
            Text(stop.theme)
                .font(Theme.font(.subheadline))
                .foregroundStyle(Color.secondaryText)
            VStack(alignment: .leading, spacing: 4) {
                if stop.isSoon {
                    line(LevelMapCopy.soonTag, weight: .heavy, color: .successText)
                    line(LevelMapCopy.soonLine(level: stop.level), weight: .regular, color: .secondaryText)
                } else {
                    if stop.found == 0 {
                        line(LevelMapCopy.firstPlant, weight: .bold, color: .appPrimaryText).frame(minHeight: 24)
                    } else {
                        row(LevelMapCopy.foundRow(stop.found)) { MapPetalGlyph(size: rowIcon) }
                        row(LevelMapCopy.bloomRow(stop.bloom)) {
                            Circle().strokeBorder(Color.appAccent, lineWidth: 2.5).frame(width: rowIcon, height: rowIcon)
                        }
                    }
                    if let mend = stop.mendingLine {
                        line(mend, weight: .regular, color: .secondaryText).accessibilityIdentifier("levelMap.mending.\(stop.level)")
                    }
                    if let all = stop.allFoundLine { line(all, weight: .heavy, color: .successText) }
                    if let bloom = stop.fullBloomLine {
                        HStack(spacing: 4) {
                            Image(systemName: "sun.max.fill").font(.system(size: rowIcon * 0.9, weight: .bold))
                            Text(bloom).font(Theme.font(.subheadline, weight: .heavy))
                        }
                        .foregroundStyle(Color.accentText)
                    }
                    if let next = stop.nextStep { line(next, weight: .regular, color: .secondaryText) }
                }
            }
            .padding(.top, 6)
        }
    }

    private func line(_ text: String, weight: Font.Weight, color: Color) -> some View {
        Text(text).font(Theme.font(.subheadline, weight: weight)).foregroundStyle(color)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func row<G: View>(_ text: String, @ViewBuilder glyph: () -> G) -> some View {
        HStack(spacing: 6) {
            glyph().frame(width: rowIcon + 2)
            Text(text).font(Theme.font(.subheadline, weight: .bold)).foregroundStyle(Color.appPrimaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(minHeight: 24)
    }

    private var playButton: some View {
        let button = RoundedRectangle(cornerRadius: 14)
        return Button(action: play) {
            HStack(spacing: 8) {
                Image(systemName: "play.fill").font(Theme.font(.subheadline, weight: .heavy))
                Text(LevelMapCopy.play(stop.level)).font(Theme.font(.body, weight: .heavy))
            }
            .foregroundStyle(stop.isCurrent ? Color.ink : Color.appPrimaryText)
            .frame(maxWidth: .infinity, minHeight: 48)
            .background(stop.isCurrent ? Color.appAccent : Color.appSurface, in: button)
            .overlay { if !stop.isCurrent { button.strokeBorder(Color.appPrimaryText.opacity(0.14), lineWidth: 1.5) } }
            .contentShape(button)
        }
        .buttonStyle(MapPressStyle())
        .accessibilityLabel(LevelMapCopy.play(stop.level))
    }

    @ViewBuilder private var cardFill: some View {
        if stop.isSoon {
            ZStack { Color.appBackground; Color.appSurface.opacity(0.55) }.clipShape(shape)
        } else {
            shape.fill(Color.appSurface)
                .shadow(color: .black.opacity(0.08), radius: 6, y: 2)
                .background {
                    if stop.isCurrent { shape.fill(Color.appAccent.opacity(0.18)).padding(-5) }
                }
        }
    }

    @ViewBuilder private var cardBorder: some View {
        if stop.isSoon {
            shape.strokeBorder(Color.appPrimaryText.opacity(0.22), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
        } else if stop.isCurrent {
            shape.strokeBorder(Color.appAccent, lineWidth: 2)
        } else {
            shape.strokeBorder(Color.appPrimaryText.opacity(0.14), lineWidth: 1)
        }
    }
}

/// A gentle press for the Play buttons (no motion under Reduce Motion).
private struct MapPressStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1)
    }
}
