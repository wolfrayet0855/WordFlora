import SwiftUI

/// The landing intro (design-preview/celebrate/intro.html): petals fall into little heaps along the bottom, each heap
/// grows a stem and blooms into a five-petal flower, while the real wordmark and tagline fade in above. Falling petals
/// pass behind the text, never over it; the row stays in the lower third. A tap skips to the final frame and hands off.
/// Reduce Motion: wordmark, tagline and the bloomed row fade in together (opacity only) and it hands off at 2 s.
struct IntroBloomView: View {
    var onFinish: () -> Void

    @Environment(AppModel.self) private var app
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.colorScheme) private var colorScheme
    @State private var start = Date.now
    @State private var skipped = false
    @State private var handedOff = false
    @State private var textBand: ClosedRange<Double>?
    @State private var cache = TimelineCache()

    static let tagline = "Guess words. Grow a garden."
    /// UI tests (`-uitest-intro-hold`) keep the intro up until it is tapped, to prove the tap skips it.
    private static let uiTestHold = ProcessInfo.processInfo.arguments.contains("-uitest-intro-hold")
    /// UI tests (`-uitest-intro-t=1.2`) freeze the intro at one moment, for screenshots of the frames.
    private static let uiTestFrame: Double? = ProcessInfo.processInfo.arguments
        .first { $0.hasPrefix("-uitest-intro-t=") }.flatMap { Double($0.dropFirst("-uitest-intro-t=".count)) }

    private var reduceMotion: Bool {
        CelebrationStyle.resolve(requested: .intro, settings: app.settings, systemReduceMotion: systemReduceMotion, lowPower: false) == .reduceMotion
    }

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let timeline = cache.timeline(for: size)
            TimelineView(.animation(minimumInterval: nil, paused: skipped || handedOff || Self.uiTestFrame != nil)) { tl in
                let t = skipped ? IntroTimeline.finish : (Self.uiTestFrame ?? tl.date.timeIntervalSince(start))
                ZStack {
                    Canvas { ctx, _ in draw(timeline, t: t, layer: .behindText, in: ctx) }
                    text(t)
                        .position(x: size.width / 2, y: size.height * 0.40)
                    Canvas { ctx, _ in draw(timeline, t: t, layer: .front, in: ctx) }
                }
            }
        }
        .ignoresSafeArea()
        .coordinateSpace(name: "intro")
        .contentShape(Rectangle())
        .onTapGesture { skip() }
        // Once handed off the intro only fades out: it must not take the player's first tap on the age question under it.
        .allowsHitTesting(!handedOff)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("WordFlora")
        .accessibilityValue(Self.tagline)
        .accessibilityAddTraits(.isHeader)
        .accessibilityAction { skip() }
        .accessibilityIdentifier("intro")
        .task {
            guard !Self.uiTestHold, Self.uiTestFrame == nil else { return }
            let wait = reduceMotion ? IntroTimeline.reduceMotionHandoff : IntroTimeline.finish
            try? await Task.sleep(for: .seconds(wait))
            guard !Task.isCancelled else { return }
            handOff()
        }
    }

    // MARK: Text

    private func text(_ t: Double) -> some View {
        let mark = IntroTimeline.wordmark(at: t, reduceMotion: reduceMotion)
        let tag = IntroTimeline.tagline(at: t, reduceMotion: reduceMotion)
        return VStack(spacing: 10) {
            WordmarkView(style: .largeTitle)
            Text(Self.tagline).font(Theme.font(.callout, weight: .medium)).foregroundStyle(Color.secondaryText)
                .multilineTextAlignment(.center)
                .opacity(tag.opacity)
                .offset(y: tag.dy)
        }
        .padding(.horizontal, 24)
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .named("intro")) } action: { f in
            // The band the falling petals pass behind (offsets below never move the layout frame).
            textBand = Double(f.minY - 24)...Double(f.maxY + 24)
        }
        .scaleEffect(mark.scale)
        .opacity(mark.opacity)
        .offset(y: mark.dy)
    }

    // MARK: Drawing

    private func draw(_ timeline: IntroTimeline, t: Double, layer: IntroTimeline.Layer, in ctx: GraphicsContext) {
        var ctx = ctx
        let items: [IntroTimeline.Item]
        if reduceMotion {
            guard layer == .front else { return }
            ctx.opacity = Ease.outCubic(Ease.seg(t, 0, IntroTimeline.reduceMotionFade))
            items = timeline.bloomedRow()
        } else {
            items = timeline.items(at: t, textBand: textBand)
        }
        let dark = colorScheme == .dark
        for item in items {
            switch item {
            case let .petal(l, x, y, angle, len, tint, alpha, flip, pivot):
                guard l == layer else { continue }
                PetalArt.drawPetal(ctx, x: x, y: y, angle: angle, len: len, tint: PetalKit.palette[tint % PetalKit.palette.count],
                                   alpha: alpha, flip: flip, midPivot: pivot == .mid)
            case let .stem(baseX, ground, topX, topY, lean, height, growth):
                guard layer == .front else { continue }
                var shadow = ctx
                shadow.opacity = ctx.opacity * (dark ? 0.28 : 0.12)
                let rx = 6 + 10 * growth
                shadow.fill(Path(ellipseIn: CGRect(x: baseX - rx, y: ground + 4 - 2.6, width: rx * 2, height: 5.2)),
                            with: .color(dark ? .black : Color(hex: 0x2C3E2C)))
                var stem = Path()
                stem.move(to: CGPoint(x: baseX, y: ground + 2))
                stem.addQuadCurve(to: CGPoint(x: topX, y: topY), control: CGPoint(x: baseX - lean * 30, y: ground - height * 0.5))
                ctx.stroke(stem, with: .color(Color(hex: PetalKit.stem)), style: StrokeStyle(lineWidth: 3, lineCap: .round))
            case let .leaf(x, y, len, angle, colour):
                guard layer == .front else { continue }
                PetalArt.drawLeaf(ctx, x: x, y: y, len: len, angle: angle, colour: colour)
            case let .blossom(x, y, r, tint, open, rotation, centre, alpha):
                guard layer == .front else { continue }
                PetalArt.drawBlossom(ctx, x: x, y: y, r: r, tint: PetalKit.palette[tint % PetalKit.palette.count], alpha: alpha,
                                     open: open, rotation: rotation, centre: centre)
            }
        }
    }

    // MARK: Flow

    /// A tap jumps to the final frame, then the 0.4 s hand-off.
    private func skip() {
        guard !handedOff else { return }
        skipped = true
        handOff()
    }

    private func handOff() {
        guard !handedOff else { return }
        handedOff = true
        onFinish()
    }

    final class TimelineCache {
        private var size: CGSize?
        private var value: IntroTimeline?
        func timeline(for size: CGSize) -> IntroTimeline {
            if let value, self.size == size { return value }
            let t = IntroTimeline(size: size)
            self.size = size; value = t
            return t
        }
    }
}

#Preview("Intro") {
    IntroBloomView(onFinish: {})
        .environment(AppModel(container: try! SharedContainer.make(inMemory: true)))
        .background(Color.appBackground)
}
