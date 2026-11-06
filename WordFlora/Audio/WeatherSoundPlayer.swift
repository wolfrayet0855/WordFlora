import Foundation
import AVFoundation

/// One playing sound. AVAudioPlayer in the app, a fake in tests.
@MainActor
protocol WeatherVoice: AnyObject {
    var volume: Float { get }
    var loops: Int { get set }
    var duration: TimeInterval { get }
    func play()
    func stop()
    func setVolume(_ v: Float, fade: TimeInterval)
}

/// Plays the weather beds and one-shots on the app's `.ambient` session (silent switch respected, mixes with the
/// child's own music, never starts the session itself). One bed at a time, cross-faded; every bed ramps in from
/// silence; read-aloud ducks the bed 12 dB; a one-shot dips it 4 dB; while a bed plays the garden bed is ducked.
@MainActor
final class WeatherSoundPlayer {
    static let shared = WeatherSoundPlayer(master: 0.8, make: WeatherSoundPlayer.avVoice,
                                           duckAmbient: { SoundPlayer.shared.duckForWeather($0) })

    var master: Float
    private let make: (WeatherSound) -> WeatherVoice?
    private let duckAmbient: (Bool) -> Void
    private(set) var currentBed: WeatherSound?
    private var bed: WeatherVoice?
    private var bedLevel: Float = 0
    private var shots: [WeatherSound: WeatherVoice] = [:]
    private var limiter = WeatherShotLimiter()
    private var readAloud = false
    private var dipped = false
    private var undip: DispatchWorkItem?

    init(master: Float, make: @escaping (WeatherSound) -> WeatherVoice?, duckAmbient: @escaping (Bool) -> Void) {
        self.master = master
        self.make = make
        self.duckAmbient = duckAmbient
    }

    /// Starts (or keeps) the bed for this page. A different bed cross-fades over 800 ms; a closed gate fades it away.
    func startBed(_ s: WeatherSound, context c: WeatherSoundContext) {
        guard s.isBed, WeatherSoundGate.allows(s, c) else { stopBed(); return }
        if currentBed == s { return }                          // never restarts on a state change
        let fade = bed == nil ? WeatherSoundGate.bedFadeIn : WeatherSoundGate.crossFade
        if bed != nil { fadeOutBed(over: fade) }
        guard let v = make(s) else { return }
        v.loops = -1
        v.setVolume(0, fade: 0)
        v.play()
        bed = v; currentBed = s
        bedLevel = master * s.level * WeatherSoundGate.volume(s, c)
        v.setVolume(bedTarget, fade: fade)
        duckAmbient(true)
    }

    func stopBed(fade: TimeInterval = WeatherSoundGate.bedFadeOut) {
        guard bed != nil else { return }
        fadeOutBed(over: fade)
        duckAmbient(false)
    }

    /// One-shots: gated, spaced by `WeatherShotLimiter`. `stopsBed` ends the weather bed (the relief chime as a day ends).
    func play(_ s: WeatherSound, context c: WeatherSoundContext, now: Date = .now, stopsBed: Bool = false) {
        guard !s.isBed, WeatherSoundGate.allows(s, c) else { return }
        guard case .play(let cancelling) = limiter.admit(s, now: now) else { return }
        for x in cancelling { shots[x]?.stop() }
        if stopsBed { stopBed() }
        guard let v = shots[s] ?? make(s) else { return }
        shots[s] = v
        v.stop()
        v.setVolume(master * s.level * WeatherSoundGate.volume(s, c), fade: 0)
        v.play()
        if bed != nil { dip(for: v.duration) }
    }

    func setReadAloud(_ on: Bool) {
        readAloud = on
        bed?.setVolume(bedTarget, fade: on ? 0.25 : 0.6)
    }

    /// Sound turned off, the app went to the background: everything stops at once.
    func stopAll() {
        bed?.stop(); bed = nil; currentBed = nil
        for v in shots.values { v.stop() }
        undip?.cancel(); undip = nil; dipped = false
        duckAmbient(false)
    }

    /// Brings the bed back up after a one-shot (scheduled automatically; public for tests).
    func endDip() {
        undip?.cancel(); undip = nil
        dipped = false
        bed?.setVolume(bedTarget, fade: 0.4)
    }

    private var bedTarget: Float {
        bedLevel * (readAloud ? WeatherSoundGate.readAloudDuck : 1) * (dipped ? WeatherSoundGate.oneShotDip : 1)
    }

    private func dip(for seconds: TimeInterval) {
        dipped = true
        bed?.setVolume(bedTarget, fade: 0.15)
        undip?.cancel()
        let item = DispatchWorkItem { [weak self] in self?.endDip() }
        undip = item
        DispatchQueue.main.asyncAfter(deadline: .now() + max(0.3, seconds), execute: item)
    }

    private func fadeOutBed(over fade: TimeInterval) {
        guard let old = bed else { return }
        old.setVolume(0, fade: fade)
        DispatchQueue.main.asyncAfter(deadline: .now() + fade + 0.05) { old.stop() }
        bed = nil; currentBed = nil
    }

    private static func avVoice(_ s: WeatherSound) -> WeatherVoice? {
        guard let url = s.url(), let p = try? AVAudioPlayer(contentsOf: url) else { return nil }
        p.prepareToPlay()
        return AVWeatherVoice(p)
    }
}

@MainActor
private final class AVWeatherVoice: WeatherVoice {
    private let p: AVAudioPlayer
    init(_ p: AVAudioPlayer) { self.p = p }
    var volume: Float { p.volume }
    var loops: Int { get { p.numberOfLoops } set { p.numberOfLoops = newValue } }
    var duration: TimeInterval { p.duration }
    func play() { p.play() }
    func stop() { p.stop(); p.currentTime = 0 }
    func setVolume(_ v: Float, fade: TimeInterval) { p.setVolume(min(max(v, 0), 1), fadeDuration: fade) }
}
