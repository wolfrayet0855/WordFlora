import SwiftUI

/// The sky header on the resting card (night: lavender asleep under a moon) and the break card (day: a sunflower
/// under the sun). Decorative only, so it is hidden from VoiceOver. Fixed height; it does not grow with text size.
/// Loops (breathing plant, twinkling stars, floating z's) play for `playSeconds`, then hold; under the system or the
/// app's own Reduce Motion they never start.
struct RestScene: View {
    enum Kind { case night, day }
    var kind: Kind

    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(AppModel.self) private var app
    @Environment(\.self) private var environment

    static let height: CGFloat = 176
    /// The loops play for a few breaths as the card opens, then the scene holds one frame (as the Home weather art
    /// does). A card can sit open for a long time; a scene redrawn 30 times a second for as long as it is open keeps
    /// the app from ever going idle, and the accessibility audit, which grows the text and waits for the card to
    /// settle, then measured the card mid-layout ("Dynamic Type partially unsupported" on its texts, under load).
    static let playSeconds = 10.0
    @State private var settled = false
    private var reduceMotion: Bool { systemReduceMotion || app.settings.reduceMotionOverride }

    /// Star centres as fractions of a 345pt-wide card (the mockup's layout), with their sizes. None sit in the
    /// top-right corner, where the moon is.
    private static let stars: [(x: CGFloat, y: CGFloat, size: CGFloat, delay: Double)] = [
        (34, 26, 6, 0), (78, 70, 4, 0.7), (120, 22, 6, 1.4), (64, 118, 4, 2.1), (268, 104, 6, 2.8),
    ]

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30, paused: reduceMotion || settled)) { timeline in
            let t = reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate
            GeometryReader { geo in
                ZStack(alignment: .topLeading) {
                    background
                    if kind == .night {
                        ForEach(Self.stars.indices, id: \.self) { i in star(i, width: geo.size.width, t: t) }
                        moon.position(x: geo.size.width - 42 - 20, y: 18 + 20)
                    } else {
                        Circle().fill(Color.appAccent).frame(width: 40, height: 40)
                            .position(x: geo.size.width - 44 - 20, y: 20 + 20)
                    }
                    plant(t: t).frame(width: geo.size.width, height: geo.size.height, alignment: .bottom)
                    if kind == .night {
                        zee(size: 16, x: geo.size.width / 2 + 52, top: 64, delay: 0, t: t)
                        zee(size: 12, x: geo.size.width / 2 + 64, top: 46, delay: 1.2, t: t)
                    }
                }
            }
        }
        .frame(height: Self.height)
        .clipped()
        .accessibilityHidden(true)
        .task {
            try? await Task.sleep(for: .seconds(Self.playSeconds))
            settled = true
        }
    }

    // MARK: Pieces

    private var background: some View {
        let stops: [Gradient.Stop]
        switch kind {
        case .night:
            stops = [.init(color: .tileLevelsFill, location: 0), .init(color: .tileVisitorsFill, location: 0.52),
                     .init(color: .bloomFill, location: 0.78), .init(color: halfBloom, location: 0.92),
                     .init(color: .appBackground, location: 1)]
        case .day:
            stops = [.init(color: .tileLevelsFill, location: 0), .init(color: .appBackground, location: 1)]
        }
        return LinearGradient(stops: stops, startPoint: .top, endPoint: .bottom)
    }

    /// bloomFill at 50% over appBackground, resolved for the current light or dark appearance.
    private var halfBloom: Color {
        let a = Color.bloomFill.resolve(in: environment), b = Color.appBackground.resolve(in: environment)
        return Color(Color.Resolved(red: (a.red + b.red) / 2, green: (a.green + b.green) / 2, blue: (a.blue + b.blue) / 2))
    }

    /// A crescent: the moon disc with a second disc cut away, tilted a little.
    private var moon: some View {
        ZStack {
            Circle().fill(Color.appAccent).offset(x: -9, y: 3)
            Circle().fill(Color.black).blendMode(.destinationOut)
        }
        .frame(width: 40, height: 40)
        .compositingGroup()
        .rotationEffect(.degrees(-20))
    }

    private func star(_ i: Int, width: CGFloat, t: Double) -> some View {
        let s = Self.stars[i]
        let twinkle = reduceMotion ? 1 : 0.35 + 0.65 * wave(t + s.delay, period: 3.4)
        return Circle().fill(starColor).frame(width: s.size, height: s.size)
            .opacity(twinkle)
            .position(x: s.x / 345 * width + s.size / 2, y: s.y + s.size / 2)
    }

    @Environment(\.colorScheme) private var colorScheme
    private var starColor: Color { colorScheme == .dark ? Color.appAccent.opacity(0.6) : Color.tileVisitorsIcon.opacity(0.4) }

    private func plant(t: Double) -> some View {
        let breathe = reduceMotion ? 0 : wave(t, period: 4.8)
        return Image(kind == .night ? "plant_lavender" : "plant_sunflower")
            .resizable().scaledToFit()
            .frame(width: kind == .night ? 136 : 112)
            .scaleEffect(1 + 0.025 * breathe, anchor: .bottom)
            .offset(y: -breathe)
            .padding(.bottom, 4)
    }

    /// A "z" that rises 18pt and fades, then starts again.
    private func zee(size: CGFloat, x: CGFloat, top: CGFloat, delay: Double, t: Double) -> some View {
        var dx: CGFloat = 0, dy: CGFloat = 0, opacity = 0.8
        if !reduceMotion {
            let p = (t - delay).truncatingRemainder(dividingBy: 3.6) / 3.6
            let phase = p < 0 ? p + 1 : p
            let eased = 1 - (1 - phase) * (1 - phase)                 // ease out
            dx = 8 * eased; dy = 6 - 24 * eased                       // from +6 to -18
            opacity = phase < 0.3 ? 0.8 * phase / 0.3 : 0.8 * (1 - (phase - 0.3) / 0.7)
        }
        // Drawn as a shape, not text: it is decoration, so it has no text for VoiceOver or the audit to find.
        return ZeeShape()
            .stroke(Color.tileVisitorsIcon, style: StrokeStyle(lineWidth: size * 0.16, lineCap: .round, lineJoin: .round))
            .frame(width: size * 0.5, height: size * 0.5)
            .padding(size * 0.25)
            .opacity(opacity)
            .offset(x: x + dx, y: top + dy)
    }

    /// 0 -> 1 -> 0 over one period, eased at both ends.
    private func wave(_ t: Double, period: Double) -> Double { 0.5 - 0.5 * cos(2 * .pi * t / period) }
}

/// A small lowercase "z" for the sleeping plant: top bar, diagonal, bottom bar.
private struct ZeeShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.minY))
        p.addLine(to: CGPoint(x: r.minX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        return p
    }
}
