import Foundation

/// What the weather art draws for a kind and a look (design-preview/events, Revision 1). Pure, so it is tested; the
/// views (`WeatherSky`, `WeatherOverlay`, `.weatherPose`) only paint it. Gentle by design: one hue per kind, no dark
/// storms, nothing flashes, a plant leans at most 15 degrees, and Reduce Motion gets the same picture held still.
enum WeatherArt {
    enum Layer { case back, front }

    enum Element: Hashable {
        case sun, clouds, greyClouds
        case windStreaks, blownLeaves
        case dryCracks, heatShimmer
        case termites, crumbs
        case frostRim, snowflakes
        case hailPellets, hailOnSoil
        case rain, puddle
        /// White sparkles round a plant that shrugs the weather off.
        case cheer
        /// The Shed helper set out over a snug garden.
        case shelter
    }

    enum Helper: String, CaseIterable { case shadeCloth, bugCover, windNet, frostCloth, umbrella, raisedBed }

    /// How the plant itself shows the weather. Degrees and shares; the identity pose is "standing tall".
    struct Pose: Equatable {
        var lean = 0.0          // degrees, + leans right (with the wind)
        var skew = 0.0          // degrees of horizontal shear
        var squash = 1.0        // vertical scale (droop)
        var drop = 0.0          // share of the plant box it sinks
        var saturation = 1.0
        var brightness = 0.0
        var glow = false        // frost rim
        var sway = 0.0          // degrees either side of `lean`, over `swayPeriod`
    }

    struct Spec: Equatable {
        var kind: WeatherKind
        var look: WeatherEffect
        var elements: [Element]
        var pose: Pose
        var particles: Int
        var helper: Helper?
    }

    static let swayPeriod = 5.0
    /// The frame Reduce Motion holds (the art is laid out to read well at this moment).
    static let stillTime = 1.3

    static func helper(_ k: WeatherKind) -> Helper {
        switch k {
        case .drySpell, .hotDay: return .shadeCloth
        case .busyBugs: return .bugCover
        case .bigWind: return .windNet
        case .frostyNight: return .frostCloth
        case .hailShower: return .umbrella
        case .bigPuddles: return .raisedBed
        }
    }

    static func layer(_ e: Element) -> Layer {
        switch e {
        case .sun, .clouds, .greyClouds: return .back
        default: return .front
        }
    }

    /// The kind's one hue (mockup `--ev`), for the sky, pills and chips.
    static func tint(_ k: WeatherKind) -> UInt32 {
        switch k {
        case .drySpell: return 0xE3A23C
        case .busyBugs: return 0x8FB052
        case .bigWind: return 0x7FA0BD
        case .frostyNight: return 0x8CCBEA
        case .hotDay: return 0xF08A3C
        case .hailShower: return 0x9DB0C2
        case .bigPuddles: return 0x4F93CF
        }
    }

    /// An SF Symbol for chips and pills.
    static func symbol(_ k: WeatherKind) -> String {
        switch k {
        case .drySpell: return "sun.max"
        case .busyBugs: return "ant"
        case .bigWind: return "wind"
        case .frostyNight: return "snowflake"
        case .hotDay: return "sun.haze"
        case .hailShower: return "cloud.hail"
        case .bigPuddles: return "drop"
        }
    }

    // MARK: The spec

    static func spec(_ k: WeatherKind, look: WeatherEffect) -> Spec {
        let full = fullSpec(k)
        switch look {
        case .full:
            return full
        case .light:
            var s = full
            s.look = .light
            s.particles = max(1, full.particles / 2)
            s.pose = soften(full.pose)
            return s
        case .snug:
            // The weather still shows round the helper; the plants stay upright and bright.
            let outside = full.elements.filter { ![.dryCracks, .termites, .crumbs, .frostRim, .hailOnSoil].contains($0) }
            return Spec(kind: k, look: .snug, elements: outside + [.shelter], pose: Pose(), particles: max(1, full.particles / 2),
                        helper: helper(k))
        case .shrugs:
            let sky = full.elements.filter { layer($0) == .back }
            return Spec(kind: k, look: .shrugs, elements: sky + [.cheer], pose: Pose(), particles: 3, helper: nil)
        }
    }

    private static func fullSpec(_ k: WeatherKind) -> Spec {
        switch k {
        case .drySpell:
            return Spec(kind: k, look: .full, elements: [.sun, .dryCracks], pose: Pose(lean: -5, skew: 4, squash: 0.88, saturation: 0.55,
                                                                                    brightness: 0.04), particles: 5)
        case .busyBugs:
            return Spec(kind: k, look: .full, elements: [.termites, .crumbs], pose: Pose(), particles: 6)
        case .bigWind:
            return Spec(kind: k, look: .full, elements: [.clouds, .windStreaks, .blownLeaves], pose: Pose(lean: 15, skew: -6, sway: 2),
                        particles: 3)
        case .frostyNight:
            return Spec(kind: k, look: .full, elements: [.frostRim, .snowflakes], pose: Pose(saturation: 0.8, brightness: 0.08, glow: true),
                        particles: 8)
        case .hotDay:
            return Spec(kind: k, look: .full, elements: [.sun, .heatShimmer], pose: Pose(lean: -5, squash: 0.88, drop: 0.045, saturation: 0.82,
                                                                                       brightness: 0.03), particles: 3)
        case .hailShower:
            return Spec(kind: k, look: .full, elements: [.greyClouds, .hailPellets, .hailOnSoil], pose: Pose(lean: -1.5), particles: 14)
        case .bigPuddles:
            return Spec(kind: k, look: .full, elements: [.clouds, .rain, .puddle], pose: Pose(), particles: 10)
        }
    }

    private static func soften(_ p: Pose) -> Pose {
        Pose(lean: p.lean * 0.55, skew: p.skew * 0.5, squash: 1 - (1 - p.squash) * 0.5, drop: p.drop * 0.5,
             saturation: 1 - (1 - p.saturation) * 0.5, brightness: p.brightness * 0.5, glow: p.glow, sway: p.sway * 0.75)
    }

    /// The pose at a moment: the lean breathes `sway` either side over `swayPeriod`; Reduce Motion holds the lean.
    static func pose(_ s: Spec, time: Double, still: Bool) -> Pose {
        guard !still, s.pose.sway > 0 else { return s.pose }
        var p = s.pose
        p.lean += s.pose.sway * sin(2 * .pi * time / swayPeriod)
        return p
    }

    // MARK: Words

    /// One sentence for a picture that stands alone (a card with no caption). Pages that already say it in words hide the
    /// art from VoiceOver instead.
    static func accessibilityLabel(_ k: WeatherKind, look: WeatherEffect, name: String) -> String {
        switch look {
        case .shrugs: return WeatherCopy.shrugLine(name: name, k)
        case .snug: return WeatherCopy.snugLine(name: name, k)
        case .light, .full:
            switch k {
            case .drySpell: return "\(name) is thirsty on a dry day."
            case .busyBugs: return "Busy bugs are visiting \(name)."
            case .bigWind: return "A big wind is bending \(name)."
            case .frostyNight: return "A frosty night. \(name) is chilly."
            case .hotDay: return "A hot day. \(name) feels very warm."
            case .hailShower: return "Hail is bouncing off \(name)."
            case .bigPuddles: return "Big puddles. \(name) has wet feet."
            }
        }
    }
}
