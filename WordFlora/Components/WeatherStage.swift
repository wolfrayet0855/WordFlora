import SwiftUI

/// Shows the weather on the plant itself: lean and sway with the wind, droop on dry and hot days, a frosty rim on cold
/// nights, a little paler while weathered. Reduce Motion (`still`) holds the lean; nothing about the plant moves.
struct WeatherPoseModifier: ViewModifier {
    let spec: WeatherArt.Spec?
    var still = false
    var paused = false
    /// The plant's base in its box (the app's plant box: soil at 188 of 220).
    var anchor = UnitPoint(x: 0.5, y: 188.0 / 220)

    func body(content: Content) -> some View {
        if let spec, !still, spec.pose.sway > 0 {
            TimelineView(.animation(minimumInterval: 1.0 / 30, paused: paused)) { tl in
                posed(content, WeatherArt.pose(spec, time: tl.date.timeIntervalSinceReferenceDate, still: false))
            }
        } else {
            posed(content, spec?.pose ?? WeatherArt.Pose())
        }
    }

    private func posed(_ content: Content, _ p: WeatherArt.Pose) -> some View {
        GeometryReader { geo in
            let h = geo.size.height, base = h * anchor.y
            content
                .saturation(p.saturation)
                .brightness(p.brightness)
                .shadow(color: .white.opacity(p.glow ? 0.95 : 0), radius: 1.5)
                .shadow(color: .white.opacity(p.glow ? 0.8 : 0), radius: 3)
                .scaleEffect(x: 1, y: p.squash, anchor: anchor)
                // Shear about the base so the stem stays planted in the soil.
                .transformEffect(CGAffineTransform(a: 1, b: 0, c: tan(p.skew * .pi / 180), d: 1, tx: -tan(p.skew * .pi / 180) * base, ty: 0))
                .rotationEffect(.degrees(p.lean), anchor: anchor)
                .offset(y: p.drop * h)
        }
    }
}

extension View {
    /// Poses a plant for the weather (nil: standing tall). Pair it with `WeatherOverlay` layers around the plant.
    func weatherPose(_ spec: WeatherArt.Spec?, still: Bool = false, paused: Bool = false,
                     anchor: UnitPoint = UnitPoint(x: 0.5, y: 188.0 / 220)) -> some View {
        modifier(WeatherPoseModifier(spec: spec, still: still, paused: paused, anchor: anchor))
    }
}

/// A whole weather picture in a rounded card: sky, back art, the pot, the plant (posed), front art, and the shelf.
/// For cards that stand alone (forecast, banner, Shed, previews); the plant page mounts the layers itself. `plant` is
/// the plant alone in its `plantSize` box (the pot is drawn here, unposed). `label` (optional) makes the card one
/// VoiceOver image; without it the card is decorative.
struct WeatherStage<Plant: View>: View {
    let kind: WeatherKind
    var look: WeatherEffect = .full
    var plantSize: CGFloat = 220
    var pot: Pot? = PotCatalog.plainBlue
    var still = false
    var paused = false
    var label: String?
    @ViewBuilder var plant: () -> Plant
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let r = WeatherOverlay.sceneRect(plantSize: plantSize)
        let k = plantSize / 220, potRect = TendAnimationView.potRect
        let spec = WeatherArt.spec(kind, look: look)
        let shelf = Color(hex: scheme == .dark ? 0x3A503A : 0xE3D9C0)
        ZStack(alignment: .topLeading) {
            WeatherSky(kind: kind, look: look)
            shelf.frame(height: (WeatherOverlay.sceneHeight - WeatherOverlay.floorY) * r.height / WeatherOverlay.sceneHeight)
                .frame(maxHeight: .infinity, alignment: .bottom)
            Group {
                WeatherOverlay(kind: kind, look: look, layer: .back, size: plantSize, still: still, paused: paused)
                if let pot {
                    PotArtView(pot: pot, width: potRect.width * k, soil: true)
                        .offset(x: potRect.minX * k, y: potRect.minY * k)
                        .frame(width: plantSize, height: plantSize, alignment: .topLeading)
                }
                plant().frame(width: plantSize, height: plantSize).weatherPose(spec, still: still, paused: paused)
                WeatherOverlay(kind: kind, look: look, layer: .front, size: plantSize, still: still, paused: paused)
            }
            .offset(x: -r.minX, y: -r.minY)
        }
        .frame(width: r.width, height: r.height)
        .clipShape(RoundedRectangle(cornerRadius: 30 * r.width / 361, style: .continuous))
        .artLabel(label)
    }
}

/// One VoiceOver image with this label, or hidden when nil (decorative art).
struct ArtLabel: ViewModifier {
    let label: String?
    func body(content: Content) -> some View {
        if let label {
            content.accessibilityElement(children: .ignore).accessibilityLabel(label).accessibilityAddTraits(.isImage)
        } else {
            content.accessibilityHidden(true)
        }
    }
}

extension View {
    func artLabel(_ label: String?) -> some View { modifier(ArtLabel(label: label)) }
}

/// A catalog plant's art filling its box, as the plant page draws it (for previews and snapshot tests).
struct WeatherPreviewPlant: View {
    let imageName: String
    var size: CGFloat = 220

    var body: some View {
        Image(imageName).resizable().scaledToFit().frame(width: size, height: size)
    }
}

#Preview("Weather stages") {
    ScrollView {
        VStack(spacing: 16) {
            ForEach(WeatherKind.allCases, id: \.self) { k in
                WeatherStage(kind: k) { WeatherPreviewPlant(imageName: "plant_sunflower") }
            }
            WeatherStage(kind: .bigWind, look: .snug) { WeatherPreviewPlant(imageName: "plant_rose") }
        }
        .padding()
    }
    .background(Color.appBackground)
}
