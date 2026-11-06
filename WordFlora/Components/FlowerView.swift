import SwiftUI

/// The 8-petal flower, ported from the approved flower_*.svg (200x240 design space).
/// Petals fall in a symmetric order; lost petals stay as dashed ghosts so the player sees what they lost.
struct FlowerView: View {
    var petals: Int                      // 0...8
    var resting = false                  // folded bud (round ended without a solve)
    var sway = true

    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @State private var falling: [Int: FallingPetal] = [:]
    @State private var swayPhase = false

    static let lossOrder = [0, 4, 2, 6, 1, 5, 3, 7]
    private var present: Set<Int> { Set(Self.lossOrder.suffix(max(0, min(8, petals)))) }
    private var palette: Palette { Palette.for(petals: petals) }

    var body: some View {
        GeometryReader { geo in
            let scale = min(geo.size.width / 200, geo.size.height / 240)
            ZStack {
                stem
                ForEach(0..<8, id: \.self) { i in petal(i) }
                ForEach(falling.keys.sorted(), id: \.self) { i in fallingPetal(i) }
                if resting { bud }
                center
            }
            .frame(width: 200, height: 240)
            .scaleEffect(scale)
            .frame(width: geo.size.width, height: geo.size.height)
            .rotationEffect(.degrees(sway && !systemReduceMotion && !resting ? (swayPhase ? 1.6 : -1.6) : 0), anchor: .bottom)
        }
        .aspectRatio(200.0 / 240.0, contentMode: .fit)
        .onAppear(perform: startSway)
        // `sway` can turn off for a while (behind the game's resting and break cards) and back on.
        .onChange(of: sway) { _, on in
            if on { startSway() } else { var t = Transaction(); t.disablesAnimations = true; withTransaction(t) { swayPhase = false } }
        }
        .onChange(of: petals) { old, new in
            guard new < old else { return }
            let lost = Set(Self.lossOrder.suffix(old)).subtracting(Set(Self.lossOrder.suffix(new)))
            for i in lost {
                falling[i] = FallingPetal(palette: Palette.for(petals: old), dx: CGFloat.random(in: -70...70), started: false)
                DispatchQueue.main.async {
                    withAnimation(.easeIn(duration: systemReduceMotion ? 0.3 : 0.9)) { falling[i]?.started = true }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) { falling[i] = nil }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(resting ? "Flower resting" : Self.petalsLabel(petals))
    }

    private func startSway() {
        guard sway, !systemReduceMotion else { return }
        swayPhase = false
        withAnimation(.easeInOut(duration: 3.2).repeatForever(autoreverses: true)) { swayPhase = true }
    }

    /// VoiceOver's count of the petals still on the flower (never "left": CopySafety).
    static func petalsLabel(_ petals: Int) -> String { "\(petals) of 8 petals on the flower" }

    // MARK: Parts

    private var stem: some View {
        ZStack {
            Ellipse().fill(Color(hex: 0x2C3E2C).opacity(0.14)).frame(width: 80, height: 10).position(x: 100, y: 236)
            Path { p in
                p.move(to: CGPoint(x: 100, y: 236))
                p.addCurve(to: CGPoint(x: 100, y: 100), control1: CGPoint(x: 100, y: 190), control2: CGPoint(x: 100, y: 150))
            }.stroke(Color(hex: 0x4E9A55), style: StrokeStyle(lineWidth: 7, lineCap: .round))
            Path { p in
                p.move(to: CGPoint(x: 100, y: 208))
                p.addCurve(to: CGPoint(x: 50, y: 168), control1: CGPoint(x: 74, y: 208), control2: CGPoint(x: 54, y: 190))
                p.addCurve(to: CGPoint(x: 100, y: 208), control1: CGPoint(x: 78, y: 168), control2: CGPoint(x: 98, y: 184))
            }.fill(Color(hex: 0x5FA860))
            Path { p in
                p.move(to: CGPoint(x: 100, y: 196))
                p.addCurve(to: CGPoint(x: 150, y: 156), control1: CGPoint(x: 124, y: 196), control2: CGPoint(x: 144, y: 178))
                p.addCurve(to: CGPoint(x: 100, y: 196), control1: CGPoint(x: 122, y: 156), control2: CGPoint(x: 102, y: 172))
            }.fill(Color(hex: 0x3F8A4A))
        }
    }

    @ViewBuilder
    private func petal(_ i: Int) -> some View {
        let isPresent = present.contains(i) && !resting
        let angle = Double(i) * 45
        ZStack {
            if isPresent {
                PetalShape().fill(palette.fill)
                PetalShape().stroke(palette.stroke, lineWidth: 2)
            } else if !resting {
                PetalShape().stroke(Color(hex: 0x7C867C).opacity(0.55), style: StrokeStyle(lineWidth: 1.6, dash: [4, 3]))
            }
        }
        .frame(width: 200, height: 240)
        .rotationEffect(.degrees(angle), anchor: UnitPoint(x: 0.5, y: 88.0 / 240))
        .opacity(1)
        .animation(.spring(response: 0.45, dampingFraction: 0.7), value: isPresent)
    }

    private var bud: some View {
        ZStack {
            ForEach([-14.0, 0.0, 14.0], id: \.self) { a in
                PetalShape().fill(Color(hex: 0xC7A9B0)).overlay(PetalShape().stroke(Color(hex: 0xA98791), lineWidth: 2))
                    .scaleEffect(0.62, anchor: UnitPoint(x: 0.5, y: 88.0 / 240))
                    .rotationEffect(.degrees(a), anchor: UnitPoint(x: 0.5, y: 88.0 / 240))
            }
        }
        .frame(width: 200, height: 240)
    }

    private var center: some View {
        ZStack {
            Circle().fill(petals > 0 || resting ? Color(hex: 0xE8A838) : Color(hex: 0x8E968E)).frame(width: 40, height: 40)
            Circle().fill(petals > 0 || resting ? Color(hex: 0xF5C858) : Color(hex: 0xA9B0A9)).frame(width: 24, height: 24)
            Circle().fill(.white.opacity(0.8)).frame(width: 4.4, height: 4.4).offset(x: -4, y: -4)
        }
        .position(x: 100, y: 88)
        .frame(width: 200, height: 240)
    }

    struct FallingPetal { var palette: Palette; var dx: CGFloat; var started: Bool }

    @ViewBuilder
    private func fallingPetal(_ i: Int) -> some View {
        if let f = falling[i] {
            ZStack {
                PetalShape().fill(f.palette.fill)
                PetalShape().stroke(f.palette.stroke, lineWidth: 2)
            }
            .frame(width: 200, height: 240)
            .rotationEffect(.degrees(Double(i) * 45 + (f.started && !systemReduceMotion ? 50 : 0)), anchor: UnitPoint(x: 0.5, y: 88.0 / 240))
            .offset(x: f.started && !systemReduceMotion ? f.dx : 0, y: f.started && !systemReduceMotion ? 150 : 0)
            .opacity(f.started ? 0 : 1)
            .allowsHitTesting(false)
        }
    }

    struct Palette {
        let fill: Color, stroke: Color
        static func `for`(petals n: Int) -> Palette {
            switch n {
            case 7...8: return Palette(fill: Color(hex: 0xF2788A), stroke: Color(hex: 0xD9566C))
            case 5...6: return Palette(fill: Color(hex: 0xE9A36C), stroke: Color(hex: 0xCF8247))
            case 3...4: return Palette(fill: Color(hex: 0xC7A9B0), stroke: Color(hex: 0xA98791))
            default: return Palette(fill: Color(hex: 0x8EA6C4), stroke: Color(hex: 0x6E87A8))
            }
        }
    }
}

/// One petal in the 200x240 design space, centred on the flower hub at (100, 88).
struct PetalShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let o = CGPoint(x: 100, y: 88)
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: o.x + x, y: o.y + y) }
        p.move(to: pt(0, -14))
        p.addCurve(to: pt(0, -68), control1: pt(-19, -26), control2: pt(-17, -58))
        p.addCurve(to: pt(0, -14), control1: pt(17, -58), control2: pt(19, -26))
        p.closeSubpath()
        return p
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255, blue: Double(hex & 0xFF) / 255)
    }
}

#Preview("Petals") {
    HStack { FlowerView(petals: 8); FlowerView(petals: 4); FlowerView(petals: 0, resting: true) }
        .padding().background(Color.appBackground)
}
