import SwiftUI

/// The weather sounds' one door into the app's settings (Sound, Calm, Quiet Garden, Reduce Motion, Low Power).
extension AppModel {
    func weatherSoundContext(onScreen: Bool = true, appActive: Bool = true, systemReduceMotion: Bool) -> WeatherSoundContext {
        WeatherSoundContext(soundOn: settings.soundOn, calm: settings.calmMode, quietGarden: settings.quietGarden,
                            onScreen: onScreen, appActive: appActive,
                            reduceMotion: systemReduceMotion || settings.reduceMotionOverride,
                            lowPower: ProcessInfo.processInfo.isLowPowerModeEnabled)
    }

    /// A weather one-shot: the relief chime (`stopsBed` as the day ends), the flourish, a termite tap. Gated and spaced.
    func playWeather(_ sound: WeatherSound, systemReduceMotion: Bool, stopsBed: Bool = false) {
        WeatherSoundPlayer.shared.master = SoundPlayer.shared.master
        WeatherSoundPlayer.shared.play(sound, context: weatherSoundContext(systemReduceMotion: systemReduceMotion), stopsBed: stopsBed)
    }
}

/// Mount on a page that shows a weather day: while `active`, on screen and the app is active, it plays the kind's bed
/// (ramped in, never restarted) and its arrival one-shot once per visit; it stops when the page goes or a gate closes.
/// Nothing ever autoplays elsewhere.
struct WeatherSoundscape: ViewModifier {
    let kind: WeatherKind?
    let active: Bool
    @Environment(AppModel.self) private var app
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var onScreen = false
    @State private var arrivalPlayed = false

    private struct Key: Equatable { var kind: WeatherKind?; var context: WeatherSoundContext }

    func body(content: Content) -> some View {
        let ctx = app.weatherSoundContext(onScreen: onScreen && active, appActive: scenePhase == .active, systemReduceMotion: reduceMotion)
        content
            .onAppear { onScreen = true; arrivalPlayed = false }
            .onDisappear { onScreen = false; WeatherSoundPlayer.shared.stopBed() }
            .onChange(of: Key(kind: active ? kind : nil, context: ctx), initial: true) { _, key in update(key.kind, key.context) }
    }

    private func update(_ kind: WeatherKind?, _ ctx: WeatherSoundContext) {
        let player = WeatherSoundPlayer.shared
        player.master = SoundPlayer.shared.master
        guard let kind, ctx.onScreen else { player.stopBed(); return }
        if let bed = WeatherSound.bed(for: kind) { player.startBed(bed, context: ctx) } else { player.stopBed() }
        if !arrivalPlayed, let shot = WeatherSound.arrival(for: kind), WeatherSoundGate.allows(shot, ctx) {
            arrivalPlayed = true
            player.play(shot, context: ctx)
        }
    }
}

extension View {
    /// The weather day's sound for this page (see `WeatherSoundscape`).
    func weatherSoundscape(_ kind: WeatherKind?, active: Bool = true) -> some View {
        modifier(WeatherSoundscape(kind: kind, active: active))
    }
}
