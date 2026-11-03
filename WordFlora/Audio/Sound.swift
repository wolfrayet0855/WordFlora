import Foundation
import AVFoundation

/// One small sound layer for the whole app (spec sections 5b, 19; docs/research/audio-feedback.md).
/// Sounds are optional, respect the silent switch (ambient session), mix with the player's own audio, and every
/// event has exactly one sound. The candidates are the audio designer's recommended set; swapping a pick is a
/// one-line change below plus the file in Resources/Sounds.
enum SoundEvent: CaseIterable {
    case key, correct, wrong, word, earned, levelUp, rest, wake, water, soil, sun, snip, butterfly
    case badgeBronze, badgeSilver, badgeGold, button, ambient

    static func badge(tier: Int) -> SoundEvent {
        switch tier { case 2: return .badgeSilver; case 3...: return .badgeGold; default: return .badgeBronze }
    }
}

struct SoundSpec {
    var file: String
    var ext: String
    /// Correction toward about -20 LUFS, measured by the audio designer. Players can only attenuate, so boosts are capped.
    var gainDb: Float
}

enum SoundCatalog {
    static let specs: [SoundEvent: SoundSpec] = [
        .key: SoundSpec(file: "wf-key", ext: "m4a", gainDb: -5.8),
        .correct: SoundSpec(file: "wf-correct", ext: "m4a", gainDb: -4.7),
        .wrong: SoundSpec(file: "wf-wrong", ext: "m4a", gainDb: -1.7),
        .word: SoundSpec(file: "wf-word", ext: "m4a", gainDb: -3.4),
        .earned: SoundSpec(file: "wf-earned", ext: "m4a", gainDb: -4.5),
        .levelUp: SoundSpec(file: "wf-levelUp", ext: "m4a", gainDb: -3.8),
        .rest: SoundSpec(file: "wf-rest", ext: "m4a", gainDb: -4.7),
        .wake: SoundSpec(file: "wf-wake", ext: "m4a", gainDb: -4.1),
        .water: SoundSpec(file: "wf-water", ext: "m4a", gainDb: -5.6),
        .soil: SoundSpec(file: "wf-soil", ext: "m4a", gainDb: -3.3),
        .sun: SoundSpec(file: "wf-sun", ext: "m4a", gainDb: -4.4),
        .snip: SoundSpec(file: "wf-snip", ext: "m4a", gainDb: 0.9),
        .butterfly: SoundSpec(file: "wf-butterfly", ext: "m4a", gainDb: -5.9),
        .badgeBronze: SoundSpec(file: "wf-badgeBronze", ext: "m4a", gainDb: -2.5),
        .badgeSilver: SoundSpec(file: "wf-badgeSilver", ext: "m4a", gainDb: -3.5),
        .badgeGold: SoundSpec(file: "wf-badgeGold", ext: "m4a", gainDb: -3.8),
        .button: SoundSpec(file: "wf-button", ext: "m4a", gainDb: -5.9),
        .ambient: SoundSpec(file: "wf-ambient", ext: "caf", gainDb: -0.6),
    ]

    static let ambientVolume: Float = 0.25

    static func url(for event: SoundEvent, bundle: Bundle = .main) -> URL? {
        guard let s = specs[event] else { return nil }
        return bundle.url(forResource: s.file, withExtension: s.ext)
    }

    static func volume(for event: SoundEvent, master: Float) -> Float {
        let gain = specs[event]?.gainDb ?? 0
        return min(1.0, max(0, master * Float(pow(10.0, Double(gain) / 20.0))))
    }
}

@MainActor
protocol SoundPlaying: AnyObject {
    var enabled: Bool { get set }
    func play(_ event: SoundEvent)
}

@MainActor
final class SoundPlayer: SoundPlaying {
    static let shared = SoundPlayer()

    var enabled = true { didSet { if !enabled { stopAmbient() } } }
    var master: Float = 0.8
    private(set) var playCount = 0
    private var players: [SoundEvent: AVAudioPlayer] = [:]
    private var ambient: AVAudioPlayer?

    struct Jitter { var volumeScale: Float; var rate: Float }

    /// Tiny per-play variation (volume ±5%, pitch ±3%) so repeated sounds don't tire the ear.
    static func jitter(seed: UInt64) -> Jitter {
        var rng = SplitMix64(seed: seed)
        let a = Double(rng.next() % 1000) / 1000, b = Double(rng.next() % 1000) / 1000
        return Jitter(volumeScale: Float(0.95 + a * 0.10), rate: Float(0.97 + b * 0.06))
    }

    /// Ambient: obeys the silent switch and mixes with the player's own music or podcast.
    static func configureSession() {
        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [])
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    func play(_ event: SoundEvent) {
        guard enabled else { return }
        playCount += 1
        guard event != .ambient, let url = SoundCatalog.url(for: event) else { return }
        let player: AVAudioPlayer
        if let cached = players[event] { player = cached } else {
            guard let p = try? AVAudioPlayer(contentsOf: url) else { return }
            p.enableRate = true; p.prepareToPlay(); players[event] = p; player = p
        }
        let j = Self.jitter(seed: UInt64(truncatingIfNeeded: playCount))
        player.volume = min(1, SoundCatalog.volume(for: event, master: master) * j.volumeScale)
        player.rate = j.rate
        player.currentTime = 0
        player.play()
    }

    func startAmbient() {
        guard enabled, ambient?.isPlaying != true, let url = SoundCatalog.url(for: .ambient), let p = try? AVAudioPlayer(contentsOf: url) else { return }
        p.numberOfLoops = -1
        p.volume = SoundCatalog.ambientVolume
        p.play()
        ambient = p
    }

    func stopAmbient() { ambient?.stop(); ambient = nil }

    /// Lowers the garden bed while a clue is read aloud, then brings it back.
    func duckAmbient(_ on: Bool) {
        ambient?.setVolume(on ? 0.08 : SoundCatalog.ambientVolume, fadeDuration: on ? 0.25 : 0.6)
    }
}
