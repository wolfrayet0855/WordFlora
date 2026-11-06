import Foundation

/// The weather-day and Grand Garden sounds (docs/pm/endgame-events-audio-plan.md). All original, rendered by
/// tools/make_weather_sounds.py and encoded with afconvert (AAC, 64 kb/s mono, gapless info kept so beds loop cleanly).
enum WeatherSound: String, CaseIterable {
    case windBed, stormBed, droughtBed
    case termiteTick, reliefChime, grandFlourish, frostTwinkle, hailPatter

    var file: String {
        switch self {
        case .windBed: return "wf-wind-loop"
        case .stormBed: return "wf-storm-loop"
        case .droughtBed: return "wf-drought-loop"
        case .termiteTick: return "wf-termite-tick"
        case .reliefChime: return "wf-relief-chime"
        case .grandFlourish: return "wf-grand-flourish"
        case .frostTwinkle: return "wf-frost-twinkle"
        case .hailPatter: return "wf-hail-patter"
        }
    }

    func url(bundle: Bundle = .main) -> URL? { bundle.url(forResource: file, withExtension: "m4a") }

    /// Beds loop quietly under the page; everything else plays once.
    var isBed: Bool { self == .windBed || self == .stormBed || self == .droughtBed }

    /// One-shots tied to moving pictures: Reduce Motion skips them along with the motion.
    var followsMotion: Bool { self == .termiteTick || self == .frostTwinkle || self == .hailPatter }

    /// Share of the player's level. Beds are already quiet in the file (about -30 LUFS); one-shots sit at 0.35 to 0.5,
    /// and the frost twinkle (the hottest file) is trimmed 3 dB.
    var level: Float {
        switch self {
        case .windBed, .stormBed, .droughtBed: return 1
        case .termiteTick, .hailPatter: return 0.45
        case .reliefChime, .grandFlourish: return 0.5
        case .frostTwinkle: return 0.5 * 0.708
        }
    }

    /// The length of the file, for spacing one-shots without loading them.
    var seconds: TimeInterval {
        switch self {
        case .windBed, .stormBed: return 8
        case .droughtBed: return 6
        case .termiteTick: return 1.2
        case .reliefChime: return 1.8
        case .grandFlourish: return 3
        case .frostTwinkle: return 1.4
        case .hailPatter: return 1.6
        }
    }

    /// The bed under a weather day's plant page (none for frost, bugs and hail: they have a one-shot instead).
    static func bed(for kind: WeatherKind) -> WeatherSound? {
        switch kind {
        case .bigWind: return .windBed
        case .bigPuddles: return .stormBed
        case .drySpell, .hotDay: return .droughtBed
        case .busyBugs, .frostyNight, .hailShower: return nil
        }
    }

    /// The soft one-shot when a weather day first shows on the page (once per visit).
    static func arrival(for kind: WeatherKind) -> WeatherSound? {
        switch kind {
        case .busyBugs: return .termiteTick
        case .frostyNight: return .frostTwinkle
        case .hailShower: return .hailPatter
        default: return nil
        }
    }
}

/// Everything a weather sound must check, gathered by the caller (the app model and the page).
struct WeatherSoundContext: Equatable {
    var soundOn: Bool
    var calm: Bool
    var quietGarden: Bool
    var onScreen: Bool
    var appActive: Bool
    var reduceMotion: Bool
    var lowPower: Bool
}

/// The rules every weather sound follows. A sound that fails a gate is skipped silently: the picture still tells it.
enum WeatherSoundGate {
    static func allows(_ s: WeatherSound, _ c: WeatherSoundContext) -> Bool {
        guard c.soundOn, !c.calm, !c.quietGarden, c.onScreen, c.appActive else { return false }
        if s.isBed && c.lowPower { return false }              // no continuous decode in Low Power Mode
        if s.followsMotion && c.reduceMotion { return false }
        return true
    }

    /// The gate's share of the level: 0 when closed, the wind bed 3 dB down under Reduce Motion.
    static func volume(_ s: WeatherSound, _ c: WeatherSoundContext) -> Float {
        guard allows(s, c) else { return 0 }
        return s == .windBed && c.reduceMotion ? db(-3) : 1
    }

    static let readAloudDuck = db(-12)
    static let oneShotDip = db(-4)
    static let bedFadeIn: TimeInterval = 0.6
    static let bedFadeOut: TimeInterval = 0.6
    static let crossFade: TimeInterval = 0.8
    /// Termite taps in the puzzle: at most one every 400 ms. Flourish replays: at most one every 10 s.
    static let termiteGap: TimeInterval = 0.4
    static let flourishGap: TimeInterval = 10

    static func db(_ d: Float) -> Float { Float(pow(10, Double(d) / 20)) }
}

/// Keeps one-shots from stacking: the same sound never overlaps itself (termite taps are spaced 400 ms), the relief
/// chime and flourish cancel any other one-shot, and while the flourish rings nothing else starts.
struct WeatherShotLimiter: Equatable {
    enum Decision: Equatable { case skip, play(cancelling: [WeatherSound]) }

    private var started: [WeatherSound: Date] = [:]

    private func ringing(_ s: WeatherSound, at now: Date) -> Bool {
        guard let t = started[s] else { return false }
        return now.timeIntervalSince(t) < s.seconds
    }

    private func minGap(_ s: WeatherSound) -> TimeInterval {
        switch s {
        case .termiteTick: return WeatherSoundGate.termiteGap
        case .grandFlourish: return WeatherSoundGate.flourishGap
        default: return s.seconds
        }
    }

    mutating func admit(_ s: WeatherSound, now: Date) -> Decision {
        if s != .grandFlourish && ringing(.grandFlourish, at: now) { return .skip }
        if let t = started[s], now.timeIntervalSince(t) < minGap(s) { return .skip }
        var cancel: [WeatherSound] = []
        if s == .reliefChime || s == .grandFlourish {
            cancel = WeatherSound.allCases.filter { !$0.isBed && $0 != s && ringing($0, at: now) }
            for c in cancel { started[c] = nil }
        }
        started[s] = now
        return .play(cancelling: cancel)
    }
}
