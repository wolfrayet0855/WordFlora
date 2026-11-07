import XCTest
import SwiftData
@testable import WordFlora

/// Petal celebrations: the pure PetalKit timelines, the landing intro, the one resolver for Reduce Motion / Calm /
/// Quiet Garden / Low Power, one sound per win, and badge moments fed by every unlock site.
@MainActor
final class CelebrationTests: XCTestCase {
    let phone = CGSize(width: 393, height: 852)
    let sizes = [CGSize(width: 393, height: 852), CGSize(width: 375, height: 667), CGSize(width: 440, height: 956)]
    let confettiLevels: [CelebrationLevel] = [.small, .smallCalm, .medium, .large, .badge, .calm, .reduceMotion]

    private func parts(_ level: CelebrationLevel, size: CGSize? = nil, seed: UInt64 = 7) -> [PetalKit.Particle] {
        PetalKit.particles(level: level, origin: .fromTop(260), in: size ?? phone, seed: seed)
    }

    // MARK: PetalKit

    func testNoLevelEverDrawsMoreThan120Particles() {
        for size in sizes {
            for level in confettiLevels {
                let p = parts(level, size: size)
                XCTAssertLessThanOrEqual(p.count, PetalKit.maxParticles, "\(level)")
                XCTAssertEqual(p.count, level.particleCount, "\(level)")
            }
            // A level up over a new plant: layered, still capped, and the level-up burst is kept whole.
            let both = PetalKit.particles([.init(level: .medium, origin: .fromTop(100)), .init(level: .large, origin: .fromTop(100))],
                                          in: size, seed: 7)
            XCTAssertEqual(both.count, PetalKit.maxParticles)
            XCTAssertEqual(Array(both.prefix(40)), PetalKit.particles(level: .medium, origin: .fromTop(100), in: size, seed: 7))
            let many = PetalKit.particles(Array(repeating: .init(level: .large, origin: .fromTop(100)), count: 4), in: size, seed: 1)
            XCTAssertLessThanOrEqual(many.count, PetalKit.maxParticles)
        }
        XCTAssertEqual(CelebrationLevel.small.particleCount, 14)
        XCTAssertEqual(CelebrationLevel.medium.particleCount, 40)
        XCTAssertEqual(CelebrationLevel.large.particleCount, 96)
        XCTAssertEqual(CelebrationLevel.badge.particleCount, 28)
        XCTAssertEqual(CelebrationLevel.calm.particleCount, 24)
        XCTAssertEqual(CelebrationLevel.reduceMotion.particleCount, 12)
        XCTAssertLessThanOrEqual(CelebrationLevel.intro.particleCount, PetalKit.maxParticles)
    }

    func testTheSameSeedGivesTheSameCelebrationAndAnotherSeedADifferentOne() {
        for level in confettiLevels {
            XCTAssertEqual(parts(level, seed: 42), parts(level, seed: 42), "\(level)")
            let a = parts(level, seed: 42), b = parts(level, seed: 43)
            for t in [0.1, 0.5, 1.0] {
                XCTAssertEqual(a.map { PetalKit.pose($0, at: t) }, a.map { PetalKit.pose($0, at: t) })
            }
            if level != .reduceMotion { XCTAssertNotEqual(a, b, "\(level)") }    // the still arc is the same picture every time
        }
        XCTAssertEqual(IntroTimeline(size: phone, seed: 5).fallers, IntroTimeline(size: phone, seed: 5).fallers)
        XCTAssertNotEqual(IntroTimeline(size: phone, seed: 5).fallers, IntroTimeline(size: phone, seed: 6).fallers)
    }

    func testEveryParticleFadesToNothingByTheEndOfItsLifeAndTheLevelsDuration() {
        for level in confettiLevels {
            for p in parts(level) {
                let end = p.t0 + p.life
                XCTAssertLessThanOrEqual(end, level.duration + 1e-9, "\(level) runs past its duration")
                XCTAssertEqual(PetalKit.pose(p, at: end)?.alpha ?? 0, 0, accuracy: 1e-9, "\(level)")
                XCTAssertNil(PetalKit.pose(p, at: end + 0.01), "\(level)")
                XCTAssertNil(PetalKit.pose(p, at: p.t0 - 0.01), "\(level)")
                for t in stride(from: p.t0, through: end, by: 0.05) {
                    let pose = PetalKit.pose(p, at: t)!
                    XCTAssertTrue((0...1).contains(pose.alpha), "\(level)")
                    XCTAssertGreaterThanOrEqual(pose.scaleX, 0.35, "a petal seen edge-on never becomes a sliver")
                }
            }
        }
    }

    func testReduceMotionPetalsNeverMoveOnlyFade() {
        for p in parts(.reduceMotion) {
            let a = PetalKit.pose(p, at: 0.1)!, b = PetalKit.pose(p, at: 1.0)!
            XCTAssertEqual(a.x, b.x); XCTAssertEqual(a.y, b.y); XCTAssertEqual(a.angle, b.angle)
            XCTAssertEqual(PetalKit.pose(p, at: 0.3)!.alpha, 1, accuracy: 1e-9)       // in by 0.3 s
            XCTAssertEqual(PetalKit.pose(p, at: 0.9)!.alpha, 1, accuracy: 1e-9)       // out from 0.9 s to 1.4 s
            XCTAssertGreaterThan(b.y, 0, "the arc stays on the canvas")
        }
        XCTAssertEqual(PetalKit.tileScale(at: 0.14, level: .reduceMotion), 1)
        XCTAssertEqual(PetalKit.tileScale(at: 0.14, level: .small), 1.1, accuracy: 1e-9)
        XCTAssertEqual(PetalKit.tileWash(at: 0.85), 0)
    }

    func testThePaletteIsTheAppsPetalsAndNeverWhite() {
        for c in PetalKit.allColours {
            XCTAssertNotEqual(c, 0xFFFFFF)
            let r = (c >> 16) & 0xFF, g = (c >> 8) & 0xFF, b = c & 0xFF
            XCTAssertLessThan(min(r, g, b), 0xE0, String(c, radix: 16))              // nothing that vanishes on cream
        }
        let fills = Set(PetalKit.palette.map(\.fill))
        for brand: UInt32 in [0xF2788A, 0xE9A36C, 0xC7A9B0, 0x8EA6C4, 0xE27D8A, 0xC9506C, 0xF5C858] { XCTAssertTrue(fills.contains(brand), String(brand, radix: 16)) }
        XCTAssertTrue(PetalKit.allColours.contains(0xE0962A))
        XCTAssertTrue(PetalKit.allColours.contains(0xC95F6E))
    }

    // MARK: Landing intro

    func testTheIntroIsOverBy3Point5SecondsWith41PetalsAndSevenFlowers() {
        for size in sizes {
            let intro = IntroTimeline(size: size)
            XCTAssertEqual(intro.fallers.count, 41)
            XCTAssertEqual(intro.clusters.count, 7)
            XCTAssertLessThanOrEqual(intro.lastMotion, IntroTimeline.finish)
            let end = intro.items(at: IntroTimeline.finish)
            XCTAssertEqual(end.filter { if case .blossom = $0 { return true } else { return false } }.count, 7)
            XCTAssertEqual(end.filter { if case .petal = $0 { return true } else { return false } }.count, 0, "loose petals have soaked away")
        }
        XCTAssertEqual(IntroTimeline.handoff, 0.4)
        XCTAssertEqual(IntroTimeline.reduceMotionHandoff, 2.0)
    }

    /// docs/pm/logo-decision.md item 3: the petals wait for the wordmark to settle, are the logo's rose family and
    /// gold (deep rose #C9506C included, never white), and stay faint behind the wordmark and tagline.
    func testIntroPetalsWaitForTheWordmarkAndUseTheLogoRoseAndGold() {
        let settled = IntroTimeline.wordmark(at: IntroTimeline.wordmarkSettled, reduceMotion: false)
        XCTAssertEqual(settled.opacity, IntroTimeline.wordmark(at: IntroTimeline.finish, reduceMotion: false).opacity, accuracy: 0.05)
        XCTAssertEqual(settled.dy, -18, accuracy: 1e-9)
        XCTAssertEqual(IntroTimeline.wordmark(at: 2.0, reduceMotion: false), IntroTimeline.wordmark(at: IntroTimeline.finish, reduceMotion: false))
        let roseAndGold: Set<UInt32> = [0xF2788A, 0xF5C858, 0xE27D8A, 0xC9506C]
        XCTAssertTrue(IntroTimeline.introTints.map { PetalKit.palette[$0].fill }.contains(0xC9506C))
        for size in sizes {
            let intro = IntroTimeline(size: size)
            for p in intro.fallers {
                XCTAssertGreaterThanOrEqual(p.ts, IntroTimeline.wordmarkSettled, "no petal falls before the wordmark settles")
                XCTAssertTrue(roseAndGold.contains(PetalKit.palette[p.tint].fill), "petal tint \(p.tint)")
            }
            for c in intro.clusters { XCTAssertTrue(roseAndGold.contains(PetalKit.palette[c.tint].fill), "flower tint \(c.tint)") }
            XCTAssertTrue(intro.items(at: IntroTimeline.wordmarkSettled - 0.01).isEmpty, "nothing is drawn while the wordmark arrives")
        }
        XCTAssertLessThanOrEqual(IntroTimeline.fallingAlpha(back: false, y: 100, band: 50...150), IntroTimeline.inBandAlpha)
        XCTAssertLessThan(IntroTimeline.inBandAlpha, 0.5)
    }

    func testEveryHeapHasLandedBeforeItsStemGrows() {
        let intro = IntroTimeline(size: phone)
        for (i, c) in intro.clusters.enumerated() {
            let heap = intro.fallers.filter { $0.cluster == i }
            XCTAssertEqual(heap.count, 5)
            for p in heap { XCTAssertLessThan(p.lands, c.bloomStart, "heap \(i)") }
            XCTAssertEqual(intro.stemTop(c, at: c.bloomStart - 0.001).growth, 0, "heap \(i)")
            XCTAssertGreaterThan(intro.stemTop(c, at: c.bloomStart + 0.25).growth, 0, "heap \(i)")
        }
    }

    func testTheFlowerRowStaysInTheLowerThirdAndFallingPetalsPassBehindTheText() {
        for size in sizes {
            let intro = IntroTimeline(size: size)
            let lowerThird = Double(size.height) * 2 / 3
            let band = Double(size.height) * 0.4 - 60 ... Double(size.height) * 0.4 + 60
            for t in stride(from: 0.0, through: IntroTimeline.finish, by: 0.05) {
                for item in intro.items(at: t, textBand: band) {
                    switch item {
                    case let .petal(layer, _, y, _, _, _, alpha, _, _):
                        if layer == .front { XCTAssertGreaterThanOrEqual(y, lowerThird, "t \(t)") }
                        if layer == .behindText && band.contains(y) { XCTAssertLessThanOrEqual(alpha, IntroTimeline.inBandAlpha + 1e-9, "t \(t)") }
                    case let .blossom(_, y, _, _, _, _, _, _): XCTAssertGreaterThanOrEqual(y, lowerThird, "t \(t)")
                    case let .stem(_, _, _, topY, _, _, _): XCTAssertGreaterThanOrEqual(topY, lowerThird, "t \(t)")
                    case .leaf: break
                    }
                }
            }
        }
    }

    func testTheWordmarkAndTaglineFadeInOnTheMockupsTimings() {
        XCTAssertEqual(IntroTimeline.wordmark(at: 0, reduceMotion: false).opacity, 0)
        XCTAssertEqual(IntroTimeline.wordmark(at: 0, reduceMotion: false).scale, 0.94, accuracy: 1e-9)
        XCTAssertEqual(IntroTimeline.wordmark(at: 0, reduceMotion: false).dy, 14, accuracy: 1e-9)
        XCTAssertEqual(IntroTimeline.wordmark(at: 0.8, reduceMotion: false).opacity, 1, accuracy: 1e-9)
        XCTAssertEqual(IntroTimeline.wordmark(at: 0.8, reduceMotion: false).scale, 1, accuracy: 1e-9)
        XCTAssertEqual(IntroTimeline.wordmark(at: 3.5, reduceMotion: false).dy, -18, accuracy: 1e-9)
        XCTAssertEqual(IntroTimeline.tagline(at: 0.6, reduceMotion: false).opacity, 0)
        XCTAssertEqual(IntroTimeline.tagline(at: 1.2, reduceMotion: false).opacity, 1, accuracy: 1e-9)
        // Reduce Motion: opacity only, all together over 0.6 s
        for t in [0.0, 0.3, 0.6] {
            let w = IntroTimeline.wordmark(at: t, reduceMotion: true), g = IntroTimeline.tagline(at: t, reduceMotion: true)
            XCTAssertEqual(w.opacity, g.opacity, accuracy: 1e-9); XCTAssertEqual(w.scale, 1); XCTAssertEqual(w.dy, -18)
        }
        XCTAssertEqual(IntroTimeline.wordmark(at: 0.6, reduceMotion: true).opacity, 1, accuracy: 1e-9)
    }

    // MARK: CelebrationStyle

    func testTheResolverTable() {
        typealias L = CelebrationLevel
        func r(_ l: L, rm: Bool = false, calm: Bool = false) -> L { CelebrationStyle.resolve(requested: l, reduceMotion: rm, calm: calm) }
        for l in L.allCases { XCTAssertEqual(r(l, rm: true), .reduceMotion, "Reduce Motion is the still arc for \(l)") }
        for l in L.allCases { XCTAssertEqual(r(l, rm: true, calm: true), .reduceMotion, "\(l)") }
        XCTAssertEqual(r(.large), .large); XCTAssertEqual(r(.medium), .medium); XCTAssertEqual(r(.small), .small); XCTAssertEqual(r(.badge), .badge)
        XCTAssertEqual(r(.intro), .intro)
        XCTAssertEqual(r(.large, calm: true), .calm, "calm is gentle, never nothing")
        XCTAssertEqual(r(.medium, calm: true), .calm)
        XCTAssertEqual(r(.small, calm: true), .smallCalm)
        XCTAssertLessThan(CelebrationLevel.smallCalm.duration, CelebrationLevel.small.duration)
        XCTAssertEqual(r(.badge, calm: true), .reduceMotion, "a calm badge pops with the still arc")
    }

    func testTheResolverReadsEverySetting() {
        func settings(_ change: (AppSettings) -> Void = { _ in }) -> AppSettings {
            let s = AppSettings(defaults: UserDefaults(suiteName: "wf-celebrate-\(UUID().uuidString)")!); change(s); return s
        }
        func r(_ s: AppSettings, system: Bool = false, low: Bool = false, _ l: CelebrationLevel = .large) -> CelebrationLevel {
            CelebrationStyle.resolve(requested: l, settings: s, systemReduceMotion: system, lowPower: low)
        }
        XCTAssertEqual(r(settings()), .large)
        XCTAssertEqual(r(settings(), system: true), .reduceMotion)
        XCTAssertEqual(r(settings { $0.reduceMotionOverride = true }), .reduceMotion)
        XCTAssertEqual(r(settings { $0.calmMode = true }), .calm)
        XCTAssertEqual(r(settings { $0.quietGarden = true }), .calm)
        XCTAssertEqual(r(settings(), low: true), .calm)
        XCTAssertEqual(r(settings { $0.calmMode = true; $0.reduceMotionOverride = true }), .reduceMotion)
        XCTAssertEqual(r(settings { $0.quietGarden = true }, low: true, .small), .smallCalm)
        XCTAssertEqual(r(settings(), system: true, low: true, .badge), .reduceMotion)
        XCTAssertEqual(r(settings(), system: true, .intro), .reduceMotion, "the intro honours Reduce Motion too")
        XCTAssertEqual(r(settings { $0.reduceMotionOverride = true }, .intro), .reduceMotion)
        // An under-13 player starts in Calm mode and still gets petals on the very first win.
        let young = settings { $0.applyAgeDefaults(.under13) }
        XCTAssertTrue(young.calmMode)
        XCTAssertEqual(r(young), .calm)
        XCTAssertGreaterThan(CelebrationLevel.calm.particleCount, 0)
        XCTAssertTrue(CelebrationStyle.badgePops(settings: settings { $0.calmMode = true }, systemReduceMotion: false))
        XCTAssertFalse(CelebrationStyle.badgePops(settings: settings { $0.reduceMotionOverride = true }, systemReduceMotion: false))
        XCTAssertFalse(CelebrationStyle.badgePops(settings: settings(), systemReduceMotion: true))
    }

    // MARK: One sound per win

    func testAWinPlaysExactlyOneSoundTheBiggestThing() {
        XCTAssertEqual(CelebrationStyle.winSound(leveledUp: true, plantArrived: true), .levelUp)
        XCTAssertEqual(CelebrationStyle.winSound(leveledUp: true, plantArrived: false), .levelUp)
        XCTAssertEqual(CelebrationStyle.winSound(leveledUp: false, plantArrived: true), .earned)
        XCTAssertEqual(CelebrationStyle.winSound(leveledUp: false, plantArrived: false), .word)
    }

    var container: ModelContainer!

    func testTheRoundPlaysOneWinSoundForAPlantAndForAWordTowardOne() throws {
        let sound = SoundTests.RecordingSound()
        container = try SharedContainer.make(inMemory: true)
        let bank = WordBank(schemaVersion: 1, bankVersion: "t", entries: [], daily: DailyConfig(epoch: "2026-01-01", seed: 1))
        let vm = GameViewModel(modelContext: container.mainContext, bank: bank, sounds: sound)
        vm.seedPlantsIfNeeded()
        let wins: Set<SoundEvent> = [.word, .earned, .levelUp]
        for n in 1...3 {
            sound.played = []
            vm.start(entry: WordEntry(id: "x\(n)", word: "LOTUS", display: "Lotus", hint: "h", hint2: nil, fact: "f", level: 1, kind: .vocab,
                                      plantId: nil, tags: [], minAge: 6, dailyEligible: true, source: "t", license: "t", reviewedBy: "t"))
            for c in "LOTUS" { vm.guessInput = String(c); vm.submitGuess() }
            XCTAssertEqual(vm.phase, .won)
            XCTAssertEqual(sound.played.filter { wins.contains($0) }.count, 1, "word \(n): \(sound.played)")
            XCTAssertEqual(sound.played.last, CelebrationStyle.winSound(leveledUp: vm.leveledUp, plantArrived: vm.earnedPlantName != nil))
        }
    }

    // MARK: Badge moments

    func makeApp(quiet: Bool = false, now: @escaping () -> Date = { .now }) throws -> AppModel {
        let container = try SharedContainer.make(inMemory: true)
        let settings = AppSettings(defaults: UserDefaults(suiteName: "wf-celebrate-\(UUID().uuidString)")!)
        settings.quietGarden = quiet
        let bank = WordBank(schemaVersion: 1, bankVersion: "t", entries: [], daily: DailyConfig(epoch: "2026-01-01", seed: 1))
        return AppModel(container: container, settings: settings, bank: bank, now: now, notifications: ReminderTests.FakeCenter())
    }

    private func lotus() -> WordEntry {
        WordEntry(id: "x", word: "LOTUS", display: "Lotus", hint: "h", hint2: nil, fact: "f", level: 1, kind: .vocab, plantId: nil,
                  tags: [], minAge: 6, dailyEligible: true, source: "t", license: "t", reviewedBy: "t")
    }

    func testARoundsBadgeWaitsForItsCardThenShowsOnce() throws {
        let app = try makeApp()
        XCTAssertNil(app.pendingBadge)
        app.game.start(entry: lotus())
        app.pauseBadgeMoments(.round, true)                     // GameView holds them while the earned card is up
        for ch in "LOTUS" { app.game.guessInput = String(ch); app.game.submitGuess() }
        app.roundFinished()
        XCTAssertEqual(app.pendingBadge?.badgeId, "perfect_bloom")
        XCTAssertNil(app.presentNextBadge(), "held while the round's card is up")
        app.pauseBadgeMoments(.round, false)                    // Continue: it shows at once, in the same update
        XCTAssertEqual(app.shownBadge?.badgeId, "perfect_bloom")
        XCTAssertNil(app.presentNextBadge(), "one at a time")
        app.dismissBadgeMoment()
        XCTAssertNil(app.shownBadge)
        XCTAssertNil(app.pendingBadge)
        app.roundFinished()
        XCTAssertNil(app.pendingBadge, "asking again never re-awards")
    }

    func testTendingFeedsTheBadgeMoment() throws {
        let app = try makeApp()
        let plant = app.plants().first!; plant.earnedCount = 1; app.profile?.water = 3
        app.profile?.badgesJSON = #"{"progress":{"waterings":24},"unlocked":{}}"#
        app.reconcileSyncedData()
        XCTAssertEqual(app.badges.progress(of: .waterings), 24)
        XCTAssertTrue(app.tend(.water, plant: plant).applied)
        XCTAssertEqual(app.pendingBadge, BadgeUnlock(badgeId: "green_thumb", tier: 1, at: app.pendingBadge?.at ?? .now))
        XCTAssertEqual(app.badgeMomentDelay, 1.0, "after the pour")
    }

    func testAReviveFeedsTheBadgeMoment() throws {
        let app = try makeApp(); app.profile?.roseOfJerichoCount = 1
        app.game.start(entry: lotus())
        for ch in "ZXQJKVWY" { app.game.guessInput = String(ch); app.game.submitGuess() }
        app.wakeFlower()
        XCTAssertEqual(app.pendingBadge?.badgeId, "resurrected")
    }

    func testAButterflyGameFeedsTheBadgeMomentForEachNewBadge() throws {
        let app = try makeApp()
        var g = app.startButterflyGame(seed: 5)
        g.visitors = [ButterflyGameModel.Visitor(id: 90, speciesId: "monarch", x: 0.5, y: 0.5, vx: 0, vy: 0, born: 0, resting: false)]
        g.catchAt(x: 0.5, y: 0.5)
        app.finishButterflyGame(g)
        XCTAssertEqual(app.pendingBadges.map(\.badgeId), ["visitor_friend", "first_butterfly"], "Gentle Net now counts gentle hellos, not plays")
        XCTAssertEqual(app.badgeMomentDelay, 1.9, "after the summary's petals")
    }

    func testAWakeGameFeedsTheBadgeMomentButItWaitsForTheSheet() throws {
        let app = try makeApp()
        app.pauseBadgeMoments(.sheet, true)
        var g = app.startButterflyGame(seed: 5, wake: true)
        g.visitors = [ButterflyGameModel.Visitor(id: 90, speciesId: "monarch", x: 0.5, y: 0.5, vx: 0, vy: 0, born: 0, resting: false)]
        g.catchAt(x: 0.5, y: 0.5)
        app.finishButterflyGame(g, wake: true)
        XCTAssertNotNil(app.pendingBadge)
        XCTAssertNil(app.presentNextBadge())
        app.pauseBadgeMoments(.sheet, false)
        XCTAssertNotNil(app.presentNextBadge())
    }

    func testQuietGardenNeverShowsABadgeMoment() throws {
        let app = try makeApp(quiet: true)
        var g = app.startButterflyGame(seed: 5)
        g.visitors = [ButterflyGameModel.Visitor(id: 90, speciesId: "monarch", x: 0.5, y: 0.5, vx: 0, vy: 0, born: 0, resting: false)]
        g.catchAt(x: 0.5, y: 0.5)
        app.finishButterflyGame(g)
        app.game.start(entry: lotus())
        for ch in "LOTUS" { app.game.guessInput = String(ch); app.game.submitGuess() }
        app.roundFinished()
        XCTAssertNil(app.pendingBadge)
    }

    func testOneMomentPerBadgeAtItsHighestNewTier() throws {
        let app = try makeApp()
        let t = Date(timeIntervalSince1970: 0)
        app.enqueueBadgeMoments([BadgeUnlock(badgeId: "feeder", tier: 1, at: t), BadgeUnlock(badgeId: "feeder", tier: 2, at: t),
                                 BadgeUnlock(badgeId: "streak", tier: 1, at: t)])
        XCTAssertEqual(app.pendingBadges.map { "\($0.badgeId)#\($0.tier)" }, ["feeder#2", "streak#1"])
    }

    // MARK: Copy

    func testNewWordsAreGentle() throws {
        var lines = [BadgeMomentCopy.earned, IntroBloomView.tagline] + BadgeMomentCopy.tiers
        let defs = try BadgeCatalog.load()
        for d in defs { for tier in 1...3 { lines.append(BadgeMomentCopy.title(BadgeUnlock(badgeId: d.id, tier: tier, at: .now), defs: defs)) } }
        for line in lines { XCTAssertEqual(CopySafety.check(line), [], line) }
        XCTAssertEqual(BadgeMomentCopy.title(BadgeUnlock(badgeId: "daily_bloom", tier: 3, at: .now), defs: defs), "Gold Daily Bloomer")
    }
}
