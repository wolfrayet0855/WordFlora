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

    func testThunderRollsWellAfterTheFlashAndTheFirstFlashWaitsForTheChildToSettle() {
        for r in [-1.0, 0.0, 0.5, 1.0, 2.0] {
            XCTAssertTrue((1.5...3.0).contains(ThunderGate.soundDelay(unit: r)), "\(r)")          // distant: sound follows light
            XCTAssertTrue((4.0...6.0).contains(ThunderGate.firstFlashDelay(unit: r)), "\(r)")
        }
        XCTAssertEqual(ThunderGate.soundDelay(unit: 0), 1.5, accuracy: 0.001)
        XCTAssertEqual(ThunderGate.soundDelay(unit: 1), 3.0, accuracy: 0.001)
        XCTAssertGreaterThan(ThunderGate.soundDelay(unit: 0), ThunderGate.hapticDelay(unit: 1))
    }

    func testThunderRollsOncePerVisitAndAtMostEveryThreeMinutesAppWide() {
        let t0 = Date(timeIntervalSinceReferenceDate: 1_000_000)
        XCTAssertEqual(ThunderGate.rollCooldown, 180)
        XCTAssertTrue(ThunderGate.shouldSound(playedThisVisit: false, lastRoll: nil, now: t0))
        XCTAssertFalse(ThunderGate.shouldSound(playedThisVisit: true, lastRoll: nil, now: t0))
        XCTAssertFalse(ThunderGate.shouldSound(playedThisVisit: false, lastRoll: t0, now: t0.addingTimeInterval(179)))   // hopping plants
        XCTAssertTrue(ThunderGate.shouldSound(playedThisVisit: false, lastRoll: t0, now: t0.addingTimeInterval(180)))
        XCTAssertFalse(ThunderGate.shouldSound(playedThisVisit: true, lastRoll: t0, now: t0.addingTimeInterval(600)))
    }

    func testAVisitIsOnlyMarkedPlayedOnceTheRollHasRun() {
        let t0 = Date(timeIntervalSinceReferenceDate: 1_000_000)
        var visit = ThunderGate.Visit()
        XCTAssertTrue(visit.wantsRoll(lastRoll: nil, now: t0))
        XCTAssertTrue(visit.wantsRoll(lastRoll: nil, now: t0))         // asking does not use it up (the roll may be cancelled)
        visit.markPlayed()
        XCTAssertFalse(visit.wantsRoll(lastRoll: nil, now: t0.addingTimeInterval(600)))   // later flashes stay silent
        visit = ThunderGate.Visit()                                     // the page appears again: a new visit
        XCTAssertTrue(visit.wantsRoll(lastRoll: nil, now: t0))
        XCTAssertFalse(visit.wantsRoll(lastRoll: t0, now: t0.addingTimeInterval(60)))     // but the app-wide cooldown still holds
    }

    func testTheAmbientBedComesBackOnlyWhenNothingIsDuckingIt() {
        var d = DuckState()
        XCTAssertFalse(d.ducked)
        XCTAssertEqual(d.set(.readAloud, true), true)                   // changed: duck now
        XCTAssertNil(d.set(.thunder, true))                             // already ducked: nothing to do
        XCTAssertNil(d.set(.thunder, false))                            // reading aloud still: stay ducked
        XCTAssertTrue(d.ducked)
        XCTAssertNil(d.set(.thunder, true))
        XCTAssertNil(d.set(.readAloud, false))                          // the roll still plays: stay ducked
        XCTAssertEqual(d.set(.thunder, false), false)                   // both done: bring the bed back
        XCTAssertFalse(d.ducked)
        XCTAssertNil(d.set(.thunder, false))
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

    /// One sound for the win: level up, else a plant arriving (the very first word brings one), else the word.
    func testWinningPlaysOneWinSound() throws {
        let s = RecordingSound(); let vm = try makeVM(s); vm.start(entry: entry())
        guess(vm, "LOTUS")
        XCTAssertNotNil(vm.earnedPlantName)
        XCTAssertEqual(s.played.last, vm.leveledUp ? .levelUp : .earned); XCTAssertFalse(s.played.contains(.rest))
        XCTAssertEqual(s.played.filter { [.word, .earned, .levelUp].contains($0) }.count, 1)
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
