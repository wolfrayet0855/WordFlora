import XCTest
import AVFoundation
@testable import WordFlora

/// E-9: the eight weather and Grand Garden sounds (docs/pm/endgame-events-audio-plan.md).
@MainActor
final class WeatherSoundTests: XCTestCase {

    // MARK: catalog

    func testEverySoundIsBundledSmallAndTheRightLength() throws {
        let lengths: [WeatherSound: ClosedRange<Double>] = [
            .windBed: 7.9...8.1, .stormBed: 7.9...8.1, .droughtBed: 5.9...6.1, .termiteTick: 1.1...1.3,
            .reliefChime: 1.7...1.9, .grandFlourish: 2.9...3.1, .frostTwinkle: 1.3...1.5, .hailPatter: 1.5...1.7,
        ]
        var total = 0
        for s in WeatherSound.allCases {
            let url = try XCTUnwrap(s.url(), "missing \(s.file).m4a")
            XCTAssertEqual(url.pathExtension, "m4a")
            let size = try XCTUnwrap(try url.resourceValues(forKeys: [.fileSizeKey]).fileSize)
            XCTAssertLessThan(size, (s.isBed ? 120 : 60) * 1024, "\(s) over its size budget")
            total += size
            // A gapless loop needs the encoder padding trimmed: the length must match the WAV, not the padded frames.
            let player = try AVAudioPlayer(contentsOf: url)
            XCTAssertTrue(try XCTUnwrap(lengths[s]).contains(player.duration), "\(s) is \(player.duration) s")
        }
        XCTAssertLessThan(total, 400 * 1024, "the weather sounds stay well inside the audio budget")
    }

    func testBedsAndOneShotsAreSortedAsThePlanSays() {
        XCTAssertEqual(WeatherSound.allCases.filter(\.isBed), [.windBed, .stormBed, .droughtBed])
        XCTAssertEqual(Set(WeatherSound.allCases.filter(\.followsMotion)), [.termiteTick, .frostTwinkle, .hailPatter])
    }

    func testEachKindHasItsBedAndArrivalSound() {
        XCTAssertEqual(WeatherSound.bed(for: .bigWind), .windBed)
        XCTAssertEqual(WeatherSound.bed(for: .bigPuddles), .stormBed)
        XCTAssertEqual(WeatherSound.bed(for: .drySpell), .droughtBed)
        XCTAssertEqual(WeatherSound.bed(for: .hotDay), .droughtBed)
        XCTAssertNil(WeatherSound.bed(for: .frostyNight))
        XCTAssertNil(WeatherSound.bed(for: .busyBugs))
        XCTAssertNil(WeatherSound.bed(for: .hailShower))
        XCTAssertEqual(WeatherSound.arrival(for: .busyBugs), .termiteTick)
        XCTAssertEqual(WeatherSound.arrival(for: .frostyNight), .frostTwinkle)
        XCTAssertEqual(WeatherSound.arrival(for: .hailShower), .hailPatter)
        XCTAssertNil(WeatherSound.arrival(for: .bigWind))
    }

    func testLevelsKeepOneShotsSoftAndFrostTrimmed() {
        for s in WeatherSound.allCases where !s.isBed {
            XCTAssertTrue((0.25...0.5).contains(s.level), "\(s) at \(s.level)")
        }
        XCTAssertLessThan(WeatherSound.frostTwinkle.level, WeatherSound.reliefChime.level)   // the hottest file is trimmed 3 dB
        for s in WeatherSound.allCases where s.isBed { XCTAssertEqual(s.level, 1) }
    }

    // MARK: gates

    private func ctx(sound: Bool = true, calm: Bool = false, quiet: Bool = false, onScreen: Bool = true, active: Bool = true,
                     rm: Bool = false, lowPower: Bool = false) -> WeatherSoundContext {
        WeatherSoundContext(soundOn: sound, calm: calm, quietGarden: quiet, onScreen: onScreen, appActive: active,
                            reduceMotion: rm, lowPower: lowPower)
    }

    func testEveryStandardGateSilencesEverySound() {
        let closed = [ctx(sound: false), ctx(calm: true), ctx(quiet: true), ctx(onScreen: false), ctx(active: false)]
        for s in WeatherSound.allCases {
            XCTAssertTrue(WeatherSoundGate.allows(s, ctx()), "\(s)")
            for c in closed { XCTAssertFalse(WeatherSoundGate.allows(s, c), "\(s) in \(c)") }
        }
    }

    func testReduceMotionSkipsTheMotionOneShotsButKeepsBedsAndRewards() {
        let rm = ctx(rm: true)
        for s in [WeatherSound.termiteTick, .frostTwinkle, .hailPatter] { XCTAssertFalse(WeatherSoundGate.allows(s, rm)) }
        for s in [WeatherSound.windBed, .stormBed, .droughtBed, .reliefChime, .grandFlourish] { XCTAssertTrue(WeatherSoundGate.allows(s, rm)) }
    }

    func testLowPowerTurnsBedsOffButKeepsOneShots() {
        let lp = ctx(lowPower: true)
        for s in WeatherSound.allCases { XCTAssertEqual(WeatherSoundGate.allows(s, lp), !s.isBed, "\(s)") }
    }

    func testReduceMotionLowersTheWindBedThreeDecibels() {
        XCTAssertEqual(WeatherSoundGate.volume(.windBed, ctx()), 1, accuracy: 0.001)
        XCTAssertEqual(WeatherSoundGate.volume(.windBed, ctx(rm: true)), Float(pow(10, -3.0 / 20)), accuracy: 0.001)
        XCTAssertEqual(WeatherSoundGate.volume(.stormBed, ctx(rm: true)), 1, accuracy: 0.001)
        XCTAssertEqual(WeatherSoundGate.volume(.windBed, ctx(sound: false)), 0)
    }

    func testDuckAmountsAreTheAgreedDecibels() {
        XCTAssertEqual(WeatherSoundGate.readAloudDuck, Float(pow(10, -12.0 / 20)), accuracy: 0.0001)
        XCTAssertEqual(WeatherSoundGate.oneShotDip, Float(pow(10, -4.0 / 20)), accuracy: 0.0001)
        XCTAssertGreaterThanOrEqual(WeatherSoundGate.bedFadeIn, 0.4)
        XCTAssertGreaterThanOrEqual(WeatherSoundGate.bedFadeOut, 0.6)
        XCTAssertEqual(WeatherSoundGate.crossFade, 0.8, accuracy: 0.001)
    }

    // MARK: one-shot spacing

    func testTermiteTapsAreSpacedAndFlourishReplaysWaitTenSeconds() {
        var lim = WeatherShotLimiter()
        let t0 = Date(timeIntervalSinceReferenceDate: 1000)
        XCTAssertEqual(lim.admit(.termiteTick, now: t0), .play(cancelling: []))
        XCTAssertEqual(lim.admit(.termiteTick, now: t0.addingTimeInterval(0.3)), .skip)
        XCTAssertEqual(lim.admit(.termiteTick, now: t0.addingTimeInterval(1.3)), .play(cancelling: []))
        XCTAssertEqual(lim.admit(.grandFlourish, now: t0.addingTimeInterval(20)), .play(cancelling: []))
        XCTAssertEqual(lim.admit(.grandFlourish, now: t0.addingTimeInterval(29)), .skip)
        XCTAssertEqual(lim.admit(.grandFlourish, now: t0.addingTimeInterval(30.5)), .play(cancelling: []))
    }

    func testTheSameOneShotNeverOverlapsItself() {
        var lim = WeatherShotLimiter()
        let t0 = Date(timeIntervalSinceReferenceDate: 0)
        XCTAssertEqual(lim.admit(.hailPatter, now: t0), .play(cancelling: []))
        XCTAssertEqual(lim.admit(.hailPatter, now: t0.addingTimeInterval(1.0)), .skip)      // still ringing (1.6 s)
        XCTAssertEqual(lim.admit(.hailPatter, now: t0.addingTimeInterval(1.7)), .play(cancelling: []))
    }

    func testReliefAndFlourishCancelOtherShotsAndTheFlourishWins() {
        var lim = WeatherShotLimiter()
        let t0 = Date(timeIntervalSinceReferenceDate: 0)
        _ = lim.admit(.frostTwinkle, now: t0)
        XCTAssertEqual(lim.admit(.reliefChime, now: t0.addingTimeInterval(0.2)), .play(cancelling: [.frostTwinkle]))
        XCTAssertEqual(lim.admit(.grandFlourish, now: t0.addingTimeInterval(0.4)), .play(cancelling: [.reliefChime]))
        XCTAssertEqual(lim.admit(.reliefChime, now: t0.addingTimeInterval(2.5)), .skip)      // the flourish is still ringing
        XCTAssertEqual(lim.admit(.hailPatter, now: t0.addingTimeInterval(2.6)), .skip)       // nothing talks over it
        XCTAssertEqual(lim.admit(.hailPatter, now: t0.addingTimeInterval(3.5)), .play(cancelling: []))
    }

    // MARK: player (fake voices)

    @MainActor final class FakeVoice: WeatherVoice {
        let sound: WeatherSound
        var volume: Float = 1
        var loops = 0
        var playing = false
        var stopped = false
        var fades: [(Float, TimeInterval)] = []
        var duration: TimeInterval { 1 }
        init(_ s: WeatherSound) { sound = s }
        func play() { playing = true }
        func stop() { playing = false; stopped = true }
        func setVolume(_ v: Float, fade: TimeInterval) { volume = v; fades.append((v, fade)) }
    }

    @MainActor final class Rig {
        var voices: [FakeVoice] = []
        var ambientDucks: [Bool] = []
        lazy var player = WeatherSoundPlayer(master: 0.8, make: { [unowned self] s in let v = FakeVoice(s); voices.append(v); return v },
                                             duckAmbient: { [unowned self] in ambientDucks.append($0) })
    }

    private let open = WeatherSoundContext(soundOn: true, calm: false, quietGarden: false, onScreen: true, appActive: true,
                                           reduceMotion: false, lowPower: false)

    func testABedLoopsAndRampsInFromSilenceAndDucksTheGardenBed() throws {
        let rig = Rig()
        rig.player.startBed(.windBed, context: open)
        let v = try XCTUnwrap(rig.voices.first)
        XCTAssertEqual(v.loops, -1)
        XCTAssertTrue(v.playing)
        XCTAssertEqual(v.fades.first?.0, 0)                                  // starts silent...
        XCTAssertEqual(v.fades.last?.1 ?? 0, WeatherSoundGate.bedFadeIn, accuracy: 0.001)   // ...then ramps in
        XCTAssertEqual(v.volume, 0.8, accuracy: 0.001)
        XCTAssertEqual(rig.ambientDucks, [true])
        rig.player.startBed(.windBed, context: open)                          // never restarts the same bed
        XCTAssertEqual(rig.voices.count, 1)
    }

    func testANewBedCrossFadesOverTheOldOneAndStopUnducks() {
        let rig = Rig()
        rig.player.startBed(.windBed, context: open)
        rig.player.startBed(.stormBed, context: open)
        XCTAssertEqual(rig.voices.count, 2)
        XCTAssertEqual(rig.voices[0].fades.last?.0, 0)
        XCTAssertEqual(rig.voices[0].fades.last?.1 ?? 0, WeatherSoundGate.crossFade, accuracy: 0.001)
        XCTAssertEqual(rig.voices[1].fades.last?.1 ?? 0, WeatherSoundGate.crossFade, accuracy: 0.001)
        XCTAssertEqual(rig.player.currentBed, .stormBed)
        rig.player.stopBed()
        XCTAssertNil(rig.player.currentBed)
        XCTAssertEqual(rig.voices[1].fades.last?.0, 0)
        XCTAssertEqual(rig.ambientDucks.last, false)
    }

    func testAClosedGateStartsNothingAndStopsARunningBed() {
        let rig = Rig()
        var quiet = open; quiet.lowPower = true
        rig.player.startBed(.stormBed, context: quiet)
        XCTAssertTrue(rig.voices.isEmpty)
        rig.player.startBed(.stormBed, context: open)
        rig.player.startBed(.stormBed, context: quiet)                       // Low Power came on: the bed fades away
        XCTAssertNil(rig.player.currentBed)
        XCTAssertEqual(rig.voices[0].fades.last?.0, 0)
        var off = open; off.soundOn = false
        rig.player.play(.reliefChime, context: off)
        XCTAssertEqual(rig.voices.count, 1)
    }

    func testReadAloudDucksTheBedTwelveDecibelsAndBringsItBack() {
        let rig = Rig()
        rig.player.startBed(.droughtBed, context: open)
        rig.player.setReadAloud(true)
        XCTAssertEqual(rig.voices[0].volume, 0.8 * WeatherSoundGate.readAloudDuck, accuracy: 0.001)
        rig.player.setReadAloud(false)
        XCTAssertEqual(rig.voices[0].volume, 0.8, accuracy: 0.001)
    }

    func testAOneShotDipsTheBedAndPlaysSoftly() {
        let rig = Rig()
        rig.player.startBed(.windBed, context: open)
        rig.player.play(.reliefChime, context: open, now: Date(timeIntervalSinceReferenceDate: 0))
        XCTAssertEqual(rig.voices.count, 2)
        XCTAssertEqual(rig.voices[1].volume, 0.8 * WeatherSound.reliefChime.level, accuracy: 0.001)
        XCTAssertTrue(rig.voices[1].playing)
        XCTAssertEqual(rig.voices[0].volume, 0.8 * WeatherSoundGate.oneShotDip, accuracy: 0.001)
        rig.player.endDip()
        XCTAssertEqual(rig.voices[0].volume, 0.8, accuracy: 0.001)
    }

    func testTheRewardChimeStopsTheWeatherBed() {
        let rig = Rig()
        rig.player.startBed(.windBed, context: open)
        rig.player.play(.reliefChime, context: open, stopsBed: true)
        XCTAssertNil(rig.player.currentBed)
        XCTAssertEqual(rig.voices[0].fades.last?.0, 0)
        XCTAssertEqual(rig.voices[0].fades.last?.1 ?? 0, WeatherSoundGate.bedFadeOut, accuracy: 0.001)
    }

    func testSoundOffStopsEverything() {
        let rig = Rig()
        rig.player.startBed(.windBed, context: open)
        rig.player.play(.reliefChime, context: open)
        rig.player.stopAll()
        XCTAssertNil(rig.player.currentBed)
        XCTAssertTrue(rig.voices[1].stopped)
        XCTAssertEqual(rig.ambientDucks.last, false)
    }

    func testTheGardenBedDuckKeepsItsOtherReasons() {
        var d = DuckState()
        XCTAssertEqual(d.set(.weather, true), true)
        XCTAssertNil(d.set(.readAloud, true))
        XCTAssertNil(d.set(.weather, false))
        XCTAssertEqual(d.set(.readAloud, false), false)
    }
}
