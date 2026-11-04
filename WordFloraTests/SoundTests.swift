import XCTest
import AVFoundation
import SwiftData
@testable import WordFlora

@MainActor
final class SoundTests: XCTestCase {

    final class RecordingSound: SoundPlaying {
        var enabled = true
        var played: [SoundEvent] = []
        var volumes: [Float] = []
        func play(_ event: SoundEvent, volume: Float) { if enabled { played.append(event); volumes.append(volume) } }
    }

    // MARK: catalog
    func testEveryEventHasABundledFile() {
        for e in SoundEvent.allCases {
            XCTAssertNotNil(SoundCatalog.url(for: e), "missing sound file for \(e)")
        }
    }

    func testVolumesAreSafeAndNeverAboveFull() {
        for e in SoundEvent.allCases {
            let v = SoundCatalog.volume(for: e, master: 0.8)
            XCTAssertGreaterThan(v, 0.05, "\(e)"); XCTAssertLessThanOrEqual(v, 1.0, "\(e)")
        }
        XCTAssertEqual(SoundCatalog.volume(for: .snip, master: 1.0), 1.0)              // a boosted clip is capped, never clipped
    }

    func testTheAmbientBedIsQuieterThanActionSounds() {
        XCTAssertLessThan(SoundCatalog.ambientVolume, SoundCatalog.volume(for: .correct, master: 0.8))
    }

    func testBadgeTiersMapToTheThreeBadgeSounds() {
        XCTAssertEqual(SoundEvent.badge(tier: 1), .badgeBronze)
        XCTAssertEqual(SoundEvent.badge(tier: 2), .badgeSilver)
        XCTAssertEqual(SoundEvent.badge(tier: 3), .badgeGold)
        XCTAssertEqual(SoundEvent.badge(tier: 9), .badgeGold)
        XCTAssertEqual(SoundEvent.badge(tier: 0), .badgeBronze)
    }

    // MARK: thunder
    func testThunderAssetIsBundledSmallAndAboutFourSecondsLong() throws {
        let url = try XCTUnwrap(SoundCatalog.url(for: .thunder))
        XCTAssertEqual(url.lastPathComponent, "wf-thunder.m4a")
        let size = try XCTUnwrap(try url.resourceValues(forKeys: [.fileSizeKey]).fileSize)
        XCTAssertLessThan(size, 300 * 1024)
        let player = try AVAudioPlayer(contentsOf: url)
        XCTAssertTrue((2.5...6.0).contains(player.duration), "duration \(player.duration)")
    }

    func testThunderPlaysSoftlyAndDucksTheAmbientBed() {
        XCTAssertEqual(ThunderGate.soundVolume, 0.35, accuracy: 0.001)
        XCTAssertLessThan(SoundCatalog.volume(for: .thunder, master: 0.8) * ThunderGate.soundVolume, SoundCatalog.volume(for: .water, master: 0.8))
        XCTAssertTrue(SoundCatalog.specs[.thunder]?.ducksAmbient == true)
        XCTAssertFalse(SoundCatalog.specs[.water]?.ducksAmbient == true)
    }

    func testThunderRollsAfterTheFirstFlashOnlyOncePerVisit() {
        for r in [-1.0, 0.0, 0.5, 1.0, 2.0] { XCTAssertTrue((0.6...1.2).contains(ThunderGate.soundDelay(unit: r)), "\(r)") }
        XCTAssertLessThan(ThunderGate.soundDelay(unit: 0), ThunderGate.soundDelay(unit: 1))   // sound follows light, never with it
        XCTAssertTrue(ThunderGate.shouldSound(playedThisVisit: false))
        XCTAssertFalse(ThunderGate.shouldSound(playedThisVisit: true))
        var visit = ThunderGate.Visit()
        XCTAssertTrue(visit.flash())                    // first flash of the visit rolls
        XCTAssertFalse(visit.flash())                   // later flashes stay silent
        XCTAssertFalse(visit.flash())
        visit = ThunderGate.Visit()                     // a new visit (the page appears again) may roll once more
        XCTAssertTrue(visit.flash())
    }

    func testPlayingAtAVolumePassesItThroughAndThePlainCallIsFullVolume() {
        let s = RecordingSound()
        s.play(.correct); s.play(.thunder, volume: 0.35)
        XCTAssertEqual(s.played, [.correct, .thunder]); XCTAssertEqual(s.volumes, [1, 0.35])
        s.enabled = false; s.play(.thunder, volume: 0.35)
        XCTAssertEqual(s.played.count, 2)               // sound off: no thunder
    }

    func testDisabledPlayerPlaysNoThunder() {
        let p = SoundPlayer(); p.enabled = false
        p.play(.thunder, volume: ThunderGate.soundVolume)
        XCTAssertEqual(p.playCount, 0)
    }

    // MARK: jitter (fatigue control)
    func testJitterStaysWithinFivePercentVolumeAndThreePercentPitch() {
        for seed in 0..<200 as Range<UInt64> {
            let j = SoundPlayer.jitter(seed: seed)
            XCTAssertTrue((0.95...1.05).contains(j.volumeScale)); XCTAssertTrue((0.97...1.03).contains(j.rate))
        }
        XCTAssertNotEqual(SoundPlayer.jitter(seed: 1).rate, SoundPlayer.jitter(seed: 2).rate)
    }

    // MARK: player
    func testSessionIsAmbientSoSilentSwitchAndOtherAudioAreRespected() throws {
        SoundPlayer.configureSession()
        XCTAssertEqual(AVAudioSession.sharedInstance().category, .ambient)
    }

    func testDisabledPlayerPlaysNothing() {
        let p = SoundPlayer(); p.enabled = false
        p.play(.correct)
        XCTAssertEqual(p.playCount, 0)
        p.enabled = true; p.play(.correct)
        XCTAssertEqual(p.playCount, 1)
    }

    // MARK: the game plays one sound per action
    var container: ModelContainer!                 // must outlive the view model that fetches from it

    func makeVM(_ sound: RecordingSound) throws -> GameViewModel {
        container = try SharedContainer.make(inMemory: true)
        let bank = WordBank(schemaVersion: 1, bankVersion: "t", entries: [], daily: DailyConfig(epoch: "2026-01-01", seed: 1))
        let vm = GameViewModel(modelContext: container.mainContext, bank: bank, sounds: sound)
        vm.seedPlantsIfNeeded()
        return vm
    }
    func entry() -> WordEntry {
        WordEntry(id: "x", word: "LOTUS", display: "Lotus", hint: "h", hint2: nil, fact: "f", level: 1, kind: .vocab, plantId: nil, tags: [],
                  minAge: 6, dailyEligible: true, source: "t", license: "t", reviewedBy: "t")
    }
    func guess(_ vm: GameViewModel, _ s: String) { for c in s { vm.guessInput = String(c); vm.submitGuess() } }

    func testCorrectAndWrongGuessesEachPlayOneDistinctSound() throws {
        let s = RecordingSound(); let vm = try makeVM(s); vm.start(entry: entry())
        guess(vm, "L"); XCTAssertEqual(s.played, [.correct])
        guess(vm, "Z"); XCTAssertEqual(s.played, [.correct, .wrong])
        guess(vm, "Z"); XCTAssertEqual(s.played.count, 2)                  // a repeated letter is ignored: no sound
    }

    func testWinningPlaysTheWordSound() throws {
        let s = RecordingSound(); let vm = try makeVM(s); vm.start(entry: entry())
        guess(vm, "LOTUS")
        XCTAssertEqual(s.played.last, .word); XCTAssertFalse(s.played.contains(.rest))
    }

    func testLosingPlaysTheGentleRestSoundNotAnErrorSound() throws {
        let s = RecordingSound(); let vm = try makeVM(s); vm.start(entry: entry())
        guess(vm, "ZXQJKVWY")
        XCTAssertEqual(s.played.last, .rest); XCTAssertFalse(s.played.contains(.word))
    }

    func testWrongGuessesNeverUseAnErrorLikeSound() throws {
        let s = RecordingSound(); let vm = try makeVM(s); vm.start(entry: entry())
        guess(vm, "ZXQ")
        XCTAssertEqual(Set(s.played), [.wrong])                            // the soft whoosh, one per miss
    }

    func testMutingSilencesTheGame() throws {
        let s = RecordingSound(); let vm = try makeVM(s); vm.start(entry: entry())
        vm.soundEnabled = false
        guess(vm, "LZ")
        XCTAssertTrue(s.played.isEmpty)
    }
}
