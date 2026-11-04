import SwiftUI

/// Loads the petal thinning manifest once for the plant page.
enum PlantArt {
    static let manifest: PlantThinningManifest? = try? PlantThinningManifest.load()
    static func thinning(for imageName: String) -> PlantThinning? { manifest?.plants[imageName] }
}

/// A plant drawn from its PlantLayers art at a love petal count (PlantThinning): ground, back, the petals still
/// showing, front. Droop plants tilt, squash and soften instead. When the count drops, the lost petals let go,
/// drift down once (3.4 s) and rest on the ground; when it rises, petals spring out one pip group at a time,
/// 0.3 s apart. Reduce Motion turns both into fades. Plants not in the manifest draw their whole art.
struct LayeredPlantView: View {
    let imageName: String
    /// Love petals now (0...5).
    let pips: Int
    /// The count this plant last showed (persisted), so each change animates once.
    let shownPips: Int
    let size: CGFloat
    /// Called when the shown count settles, to persist it.
    var onShown: (Int) -> Void = { _ in }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var display: Int?
    @State private var falling: [Falling] = []
    @State private var fallT: Double = 0
    @State private var fading: Set<PetalRef> = []
    @State private var fadeOut = false
    @State private var pending: Set<PetalRef> = []
    /// The count the last change came from: curled petals cross-fade from their look there (the `fading` pattern),
    /// and leaving petals keep it.
    @State private var changedFrom: Int?
    @State private var generation = 0

    struct Falling: Identifiable, Equatable {
        let ref: PetalRef
        let index: Int
        let rest: CGPoint
        /// The count the petal last showed at, so a curled petal falls as it looked.
        let look: Int
        var id: PetalRef { ref }
    }

    private static let fallDuration = 3.4, fallDelay = 0.6, stagger = 0.26

    var body: some View {
        Group {
            if let t = PlantArt.thinning(for: imageName) {
                layered(t)
            } else {
                Image(imageName).resizable().scaledToFit()
            }
        }
        .frame(width: size, height: size)
        .onAppear { start(PetalMotion.next(shown: shownPips, now: pips)) }
        .onChange(of: pips) { _, new in start(PetalMotion.next(shown: display ?? shownPips, now: new)) }
        .onDisappear { if display != pips || !falling.isEmpty { onShown(pips) } }
    }

    // MARK: Drawing

    private var k: CGFloat { size / 200 }

    @ViewBuilder private func layered(_ t: PlantThinning) -> some View {
        let shown = display ?? min(max(shownPips, pips), 5)
        let visible = Set(t.visiblePetals(pips: shown)).union(fading)
        let pose = t.droopPose(pips: shown)
        let pivot = t.droop.map { UnitPoint(x: $0.pivot[0] / 200, y: $0.pivot[1] / 200) } ?? .bottom
        ZStack(alignment: .topLeading) {
            ForEach(Array(t.layers.enumerated()), id: \.offset) { _, layer in
                if layer.kind == .ground { layerImage(layer) }
            }
            ZStack(alignment: .topLeading) {
                ForEach(Array(t.layers.enumerated()), id: \.offset) { _, layer in
                    switch layer.kind {
                    case .ground: EmptyView()
                    case .static: layerImage(layer, rule: t.rule, pips: shown)
                    case .petals:
                        ForEach(layer.petalRefs.filter { visible.contains($0) }, id: \.self) { ref in
                            let leaving = fading.contains(ref)
                            petal(t, ref, pips: leaving ? (changedFrom ?? shown) : shown, from: leaving ? nil : changedFrom)
                                .offset(settle(t, ref, pips: shown))
                                .opacity(fading.contains(ref) && fadeOut ? 0 : 1)
                                .scaleEffect(pending.contains(ref) ? (reduceMotion ? 1 : 0.05) : 1, anchor: headAnchor(t, ref))
                                .opacity(pending.contains(ref) ? 0 : 1)
                        }
                    }
                }
            }
            .scaleEffect(x: pose.scaleX, y: pose.scaleY, anchor: pivot)
            .rotationEffect(.degrees(pose.tiltDegrees), anchor: pivot)
            .saturation(pose.saturation)
            .brightness(pose.brightness - 1)
            .animation(.easeInOut(duration: reduceMotion ? 0.3 : 1.4), value: shown)

            ForEach(falling) { f in
                // a drooped petal starts its fall at its angle + droop
                petal(t, f.ref, pips: f.look)
                    .modifier(FallEffect(t: localT(f.index), reduceMotion: reduceMotion, start: centre(t, f.ref), rest: f.rest,
                                         angle: angle(t, f.ref) + (t.curl(for: f.ref, pips: f.look)?.rotate ?? 0), k: k))
            }
        }
        .frame(width: size, height: size, alignment: .topLeading)
    }

    private func layerImage(_ layer: PlantThinning.Layer, rule: PlantThinning.Rule? = nil, pips: Int = 5) -> some View {
        let splay = layer.role == "sepal" && pips <= (rule?.splayAt ?? -1) ? (layer.splayDegrees ?? 0) : 0
        let o = layer.origin ?? [100, 100]
        return Image(layer.image ?? "").resizable().frame(width: size, height: size)
            .rotationEffect(.degrees(splay), anchor: UnitPoint(x: o[0] / 200, y: o[1] / 200))
    }

    /// A petal as it looks at `pips`. With a curl rule (the rose) a petal that stays swaps to its curled sprite and
    /// droops about its base; when the count changed from `from`, the two sprites cross-fade with `fadeOut` and the
    /// droop eases with the head's state animation (0.3 s under Reduce Motion).
    @ViewBuilder private func petal(_ t: PlantThinning, _ ref: PetalRef, pips: Int, from: Int? = nil) -> some View {
        let ring = t.rings[ref.ring], p = ring.petals[ref.petal]
        let fresh = ring.sprites[min(p.sprite, ring.sprites.count - 1)].image
        if t.rule?.curl == nil {
            sprite(fresh, p)
        } else {
            let entry = t.curl(for: ref, pips: pips)
            let now = entry?.image ?? fresh
            let was = from.flatMap { f in ring.visiblePetals(pips: f).contains(ref.petal) ? (t.curl(for: ref, pips: f)?.image ?? fresh) : nil }
            let images = was.map { $0 == now ? [now] : [$0, now] } ?? [now]
            let pivot = (entry ?? from.flatMap { t.curl(for: ref, pips: $0) })?.pivot ?? [100, 100]
            ZStack(alignment: .topLeading) {
                // keyed by image so a sprite that stays keeps its opacity across the change
                ForEach(images, id: \.self) { name in
                    sprite(name, name == fresh ? p : nil)
                        .opacity(images.count == 1 || (name == now) == fadeOut ? 1 : 0)
                }
            }
            .rotationEffect(.degrees(entry?.rotate ?? 0), anchor: UnitPoint(x: pivot[0] / 200, y: pivot[1] / 200))
        }
    }

    /// A ring sprite moved onto its petal, or (no petal) a curled sprite already drawn in place.
    private func sprite(_ image: String, _ p: PlantThinning.Ring.Petal?) -> some View {
        let m = p.flatMap { $0.transform.count == 6 ? $0.transform : nil } ?? [1, 0, 0, 1, 0, 0]
        return Image(image).resizable().frame(width: size, height: size)
            .transformEffect(CGAffineTransform(a: m[0], b: m[1], c: m[2], d: m[3], tx: m[4] * k, ty: m[5] * k))
    }

    private func centre(_ t: PlantThinning, _ ref: PetalRef) -> CGPoint {
        let c = t.rings[ref.ring].petals[ref.petal].centre
        return CGPoint(x: c.first ?? 100, y: c.count > 1 ? c[1] : 100)
    }
    private func angle(_ t: PlantThinning, _ ref: PetalRef) -> Double { t.rings[ref.ring].petals[ref.petal].angle }
    private func headAnchor(_ t: PlantThinning, _ ref: PetalRef) -> UnitPoint {
        let p = t.rings[ref.ring].pivot
        return UnitPoint(x: (p.first ?? 100) / 200, y: (p.count > 1 ? p[1] : 100) / 200)
    }

    /// The rose bud sinks into its sepals at low counts (rule `settle`).
    private func settle(_ t: PlantThinning, _ ref: PetalRef, pips: Int) -> CGSize {
        guard let settle = t.rule?.settle else { return .zero }
        let match = settle.compactMap { key, s -> (Int, PlantThinning.Rule.Settle)? in
            guard let n = Int(key), n >= pips, s.petals.contains([ref.ring, ref.petal]) else { return nil }
            return (n, s)
        }.min { $0.0 < $1.0 }
        guard let s = match?.1 else { return .zero }
        return CGSize(width: s.dx * k, height: s.dy * k)
    }

    private func localT(_ i: Int) -> Double {
        let n = Double(max(falling.count, 1)), total = Self.fallDuration + Self.stagger * (n - 1)
        return min(max((fallT * total - Self.stagger * Double(i)) / Self.fallDuration, 0), 1)
    }

    // MARK: Motion

    private func start(_ motion: PetalMotion) {
        guard let t = PlantArt.thinning(for: imageName) else { display = pips; if shownPips != pips { onShown(pips) }; return }
        generation += 1
        let gen = generation
        switch motion {
        case .still:
            display = pips
            changedFrom = nil
        case let .fall(from, to):
            var lost: [PetalRef] = []
            for p in stride(from: to + 1, through: from, by: 1) { lost += t.fallOrder(fromPips: p) }
            let drift = Array(lost.prefix(max(1, t.maxFallPerPip)))
            fading = Set(lost.dropFirst(drift.count)); fadeOut = false
            falling = drift.enumerated().map { i, ref in Falling(ref: ref, index: i, rest: restSpot(i), look: from) }
            pending = []
            changedFrom = t.rule?.curl == nil ? nil : from
            fallT = 0
            display = to
            let n = Double(drift.count), total = Self.fallDuration + Self.stagger * max(0, n - 1)
            DispatchQueue.main.async {          // after the reset above has been drawn
                guard gen == generation else { return }
                if reduceMotion {
                    withAnimation(.easeIn(duration: 0.6)) { fallT = 1 }
                    withAnimation(.easeOut(duration: 0.5)) { fadeOut = true }
                } else {
                    withAnimation(.linear(duration: total).delay(Self.fallDelay)) { fallT = 1 }
                    withAnimation(.easeOut(duration: 0.8).delay(Self.fallDelay + 0.4)) { fadeOut = true }
                }
            }
            let settleAfter = (reduceMotion ? 0.7 : Self.fallDelay + total) + (to == 0 ? Double(t.rule?.seedAfterMs ?? 1200) / 1000 : 0)
            DispatchQueue.main.asyncAfter(deadline: .now() + settleAfter) {
                guard gen == generation else { return }
                fading = []
                onShown(to)
            }
        case let .regrow(from, to):
            falling = []; fading = []; fallT = 0
            var groups: [Set<PetalRef>] = []
            for p in stride(from: from + 1, through: to, by: 1) {
                groups.append(Set(t.visiblePetals(pips: p)).subtracting(t.visiblePetals(pips: p - 1)))
            }
            pending = groups.reduce(into: Set<PetalRef>()) { $0.formUnion($1) }
            display = to
            onShown(to)
            if t.rule?.curl != nil {            // curled petals cross-fade back to their fresher look
                changedFrom = from; fadeOut = false
                DispatchQueue.main.async {
                    guard gen == generation else { return }
                    withAnimation(reduceMotion ? .easeIn(duration: 0.25) : .easeInOut(duration: 0.6)) { fadeOut = true }
                }
            }
            for (i, g) in groups.enumerated() {
                let delay = reduceMotion ? 0.05 : 0.3 + 0.3 * Double(i)
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    guard gen == generation else { return }
                    withAnimation(reduceMotion ? .easeIn(duration: 0.25) : .spring(response: 0.65, dampingFraction: 0.55)) {
                        pending.subtract(g)
                    }
                }
            }
        }
    }

    /// Fallen petals lie on the ground shadow, alternating sides of the stem.
    private func restSpot(_ i: Int) -> CGPoint {
        let side: CGFloat = i % 2 == 0 ? 1 : -1
        return CGPoint(x: 100 + side * (30 + 12 * CGFloat(i / 2)), y: 171)
    }
}

/// One falling petal: lifts off the head, drifts down in a gentle sway and rests flat on the ground (box units, scaled by k).
private struct FallEffect: ViewModifier, Animatable {
    var t: Double
    let reduceMotion: Bool
    let start: CGPoint
    let rest: CGPoint
    let angle: Double
    let k: CGFloat

    var animatableData: Double { get { t } set { t = newValue } }

    func body(content: Content) -> some View {
        let dx = (rest.x - start.x), dy = (rest.y - start.y)
        let a = angle * .pi / 180, r = 90 - angle.truncatingRemainder(dividingBy: 180)
        let ox = 4 * sin(a), oy = -4 * cos(a)
        // keyframes from lifestats.html: lift, drift right, drift left, rest
        let keys: [(Double, Double, Double, Double, Double)] = [   // time, x, y, rotation, scale
            (0, 0, 0, 0, 1), (0.10, ox, oy, 6, 1), (0.38, dx * 0.45 + 14, dy * 0.32, r * 0.6 + 20, 0.95),
            (0.68, dx * 0.5 - 8, dy * 0.7, r * 0.3 - 10, 0.88), (1, dx, dy, r, 0.78),
        ]
        let e = reduceMotion ? 1 : ease(t)
        var v = keys.last!
        for j in 1..<keys.count where e <= keys[j].0 {
            let a0 = keys[j - 1], a1 = keys[j], f = (e - a0.0) / max(0.0001, a1.0 - a0.0)
            v = (e, a0.1 + (a1.1 - a0.1) * f, a0.2 + (a1.2 - a0.2) * f, a0.3 + (a1.3 - a0.3) * f, a0.4 + (a1.4 - a0.4) * f)
            break
        }
        let anchor = UnitPoint(x: start.x / 200, y: start.y / 200)
        return content
            .scaleEffect(v.4, anchor: anchor)
            .rotationEffect(.degrees(v.3), anchor: anchor)
            .offset(x: v.1 * k, y: v.2 * k)
            .opacity(reduceMotion ? t : 1)
    }

    /// cubic-bezier(.45, .05, .55, .95), close enough for a drift.
    private func ease(_ x: Double) -> Double { x < 0.5 ? 4 * x * x * x : 1 - pow(-2 * x + 2, 3) / 2 }
}
