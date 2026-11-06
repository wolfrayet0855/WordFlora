import XCTest
import SwiftData
@testable import WordFlora

/// The daily tiny quest: one a day, count-up only, no streak, no loss, no timers.
final class DailyQuestTests: XCTestCase {
    private let all = DailyQuest.Availability(plantsFound: 10, sunOpen: true, visitorsOpen: true)

    // MARK: Picking the quest

    func testTheQuestIsTheSameForTheSameSeedAndDay() {
        for day in 0..<60 {
            XCTAssertEqual(DailyQuest.quest(day: day, seed: 42, availability: all), DailyQuest.quest(day: day, seed: 42, availability: all))
        }
    }

    func testSeedsAndDaysGiveVariety() {
        let kinds = Set((0..<60).compactMap { DailyQuest.quest(day: $0, seed: 7, availability: all)?.kind })
        XCTAssertEqual(kinds, Set(QuestKind.allCases), "every kind turns up over two months")
        let a = (0..<30).compactMap { DailyQuest.quest(day: $0, seed: 1, availability: all)?.kind }
        let b = (0..<30).compactMap { DailyQuest.quest(day: $0, seed: 2, availability: all)?.kind }
        XCTAssertNotEqual(a, b, "two players get different runs")
    }

    func testTheSameKindNeverComesTwoDaysInARow() {
        for seed: Int64 in [0, 1, 99, -5, .max] {
            let run = (0..<200).compactMap { DailyQuest.quest(day: $0, seed: seed, availability: all)?.kind }
            for (x, y) in zip(run, run.dropFirst()) { XCTAssertNotEqual(x, y, "seed \(seed)") }
        }
    }

    func testNoQuestBeforeTheFirstPlant() {
        XCTAssertNil(DailyQuest.quest(day: 3, seed: 1, availability: .init(plantsFound: 0, sunOpen: false, visitorsOpen: false)))
    }

    func testOnlyQuestsThePlayerCanDoArePicked() {
        let one = DailyQuest.Availability(plantsFound: 1, sunOpen: false, visitorsOpen: false)
        XCTAssertEqual(Set(DailyQuest.pool(one)), [.findWords, .longWord])
        let two = DailyQuest.Availability(plantsFound: 2, sunOpen: false, visitorsOpen: false)
        XCTAssertEqual(Set(DailyQuest.pool(two)), [.findWords, .longWord, .waterPlants])
        XCTAssertEqual(Set(DailyQuest.pool(all)), Set(QuestKind.allCases))
        for day in 0..<100 {
            let q = DailyQuest.quest(day: day, seed: 3, availability: one)
            XCTAssertTrue([QuestKind.findWords, .longWord].contains(q!.kind))
        }
    }

    func testTargetsAreSmall() {
        for k in QuestKind.allCases { XCTAssertTrue((1...3).contains(DailyQuest.target(k)), "\(k)") }
        XCTAssertEqual(DailyQuest.target(.waterPlants), 2)
        XCTAssertEqual(DailyQuest.target(.helloPlants), 3)
        XCTAssertEqual(DailyQuest.target(.longWord), 1)
        XCTAssertEqual(DailyQuest.target(.visitVisitors), 1)
    }

    // MARK: Progress

    private func q(_ k: QuestKind) -> DailyQuest.Quest { DailyQuest.Quest(kind: k, target: DailyQuest.target(k)) }

    func testCountsUpAndCapsAtTheTarget() {
        var s = QuestState()
        s = DailyQuest.step(.wordFound(letters: 3), quest: q(.findWords), state: s, today: 10)
        XCTAssertEqual(s, QuestState(day: 10, progress: 1, done: false))
        s = DailyQuest.step(.wordFound(letters: 4), quest: q(.findWords), state: s, today: 10)
        XCTAssertEqual(s, QuestState(day: 10, progress: 2, done: true))
        s = DailyQuest.step(.wordFound(letters: 4), quest: q(.findWords), state: s, today: 10)
        XCTAssertEqual(s, QuestState(day: 10, progress: 2, done: true), "never above the target")
    }

    func testOnlyMatchingEventsCount() {
        let s0 = QuestState()
        XCTAssertEqual(DailyQuest.step(.wordFound(letters: 4), quest: q(.longWord), state: s0, today: 1).progress, 0)
        XCTAssertEqual(DailyQuest.step(.wordFound(letters: 5), quest: q(.longWord), state: s0, today: 1).progress, 1)
        XCTAssertEqual(DailyQuest.step(.wordFound(letters: 9), quest: q(.longWord), state: s0, today: 1).progress, 1)
        XCTAssertEqual(DailyQuest.step(.sunned, quest: q(.findWords), state: s0, today: 1).progress, 0)
        XCTAssertEqual(DailyQuest.step(.sunned, quest: q(.sunPlant), state: s0, today: 1).progress, 1)
        XCTAssertEqual(DailyQuest.step(.visitedVisitors, quest: q(.visitVisitors), state: s0, today: 1).progress, 1)
        XCTAssertEqual(DailyQuest.step(.visitedVisitors, quest: q(.waterPlants), state: s0, today: 1).progress, 0)
    }

    func testPlantCountsTakeTheDaysCountOfPlantsNotTaps() {
        var s = QuestState()
        s = DailyQuest.step(.watered(plantsToday: 1), quest: q(.waterPlants), state: s, today: 5)
        s = DailyQuest.step(.watered(plantsToday: 1), quest: q(.waterPlants), state: s, today: 5)
        XCTAssertEqual(s.progress, 1, "the same plant twice is still one plant")
        s = DailyQuest.step(.watered(plantsToday: 2), quest: q(.waterPlants), state: s, today: 5)
        XCTAssertTrue(s.done)
        var h = QuestState()
        h = DailyQuest.step(.greeted(plantsToday: 2), quest: q(.helloPlants), state: h, today: 5)
        h = DailyQuest.step(.greeted(plantsToday: 1), quest: q(.helloPlants), state: h, today: 5)
        XCTAssertEqual(h.progress, 2, "never counts down")
    }

    func testANewDayStartsFreshAndNothingIsLost() {
        let yesterday = QuestState(day: 4, progress: 1, done: false)
        XCTAssertEqual(DailyQuest.current(yesterday, today: 5), QuestState(day: 5, progress: 0, done: false))
        XCTAssertEqual(DailyQuest.current(yesterday, today: 4), yesterday)
        let s = DailyQuest.step(.wordFound(letters: 3), quest: q(.findWords), state: yesterday, today: 5)
        XCTAssertEqual(s, QuestState(day: 5, progress: 1, done: false))
    }

    func testAClockThatWentBackChangesNothing() {
        let s = QuestState(day: 9, progress: 1, done: false)
        XCTAssertEqual(DailyQuest.step(.wordFound(letters: 3), quest: q(.findWords), state: s, today: 8), s)
    }

    // MARK: Reward

    func testOnePointOnceWhenItFinishes() {
        let before = QuestState(day: 3, progress: 1, done: false)
        let after = QuestState(day: 3, progress: 2, done: true)
        XCTAssertEqual(DailyQuest.reward(before: before, after: after, quietGarden: false), 1)
        XCTAssertEqual(DailyQuest.reward(before: after, after: after, quietGarden: false), 0, "never twice")
        XCTAssertEqual(DailyQuest.reward(before: before, after: before, quietGarden: false), 0)
        XCTAssertEqual(DailyQuest.reward(before: before, after: after, quietGarden: true), 0, "Quiet Garden has no points")
        XCTAssertEqual(DailyQuest.pointsPerQuest, 1)
    }

    func testHiddenInQuietGarden() {
        XCTAssertFalse(DailyQuest.isShown(quietGarden: true, onboardingDone: true))
        XCTAssertFalse(DailyQuest.isShown(quietGarden: false, onboardingDone: false))
        XCTAssertTrue(DailyQuest.isShown(quietGarden: false, onboardingDone: true))
    }

    // MARK: Merge (sync and backups)

    func testMergeLaterDayWinsSameDayMaxProgress() {
        let a = QuestState(day: 5, progress: 2, done: true), b = QuestState(day: 6, progress: 0, done: false)
        XCTAssertEqual(DailyQuest.merged(a, b), b)
        XCTAssertEqual(DailyQuest.merged(b, a), b)
        let c = QuestState(day: 6, progress: 1, done: false), d = QuestState(day: 6, progress: 3, done: true)
        XCTAssertEqual(DailyQuest.merged(c, d), d)
        XCTAssertEqual(DailyQuest.merged(d, c), d)
        XCTAssertEqual(DailyQuest.merged(d, d), d)
        // Done on one device with a different count on another (the quest's kind moved mid-day): done stays.
        XCTAssertEqual(DailyQuest.merged(QuestState(day: 6, progress: 1, done: true), QuestState(day: 6, progress: 2, done: false)),
                       QuestState(day: 6, progress: 2, done: true))
    }

    // MARK: Copy

    func testCopyIsKind() {
        for line in DailyQuestCopy.all() {
            XCTAssertEqual(CopySafety.check(line), [], line)
            for word in ["streak", "hurry", "today only", "lose", "fail", "timer", "left"] {
                XCTAssertFalse(line.lowercased().contains(word), "\(line) says \(word)")
            }
        }
        XCTAssertEqual(DailyQuestCopy.title(q(.waterPlants)), "Water 2 plants")
        XCTAssertEqual(DailyQuestCopy.title(q(.helloPlants)), "Say hello to 3 plants")
        XCTAssertEqual(DailyQuestCopy.title(q(.visitVisitors)), "Visit the Visitors page")
        XCTAssertEqual(DailyQuestCopy.progress(1, of: 2), "1 of 2")
    }

    // MARK: Storage

    func testOlderBackupsReadWithoutQuestFields() throws {
        let json = """
        {"schemaVersion":1,"kind":"WordFlora garden backup","exportedAt":"2026-11-01T10:00:00Z","gamesRecorded":0,"plants":[],
         "profile":{"currentLevel":1,"plantsEarnedThisLevel":0,"roseOfJerichoCount":0,"gamesPlayed":0,"water":0,"soil":0,"streak":0,
         "bestStreak":0,"streakFreezes":0,"seenIds":[],"roseSeedProgress":0,"gardenDays":0,"shedPoints":0,"glowLanterns":0,
         "toolsJSON":"","badgesJSON":"","albumJSON":""}}
        """
        guard case .success(let b) = GardenBackup.decode(Data(json.utf8)) else { return XCTFail("old backup should read") }
        XCTAssertNil(b.profile.questDay)
        XCTAssertNil(b.profile.questProgress)
        XCTAssertNil(b.profile.questDone)
    }

    @MainActor
    func testBackupCarriesTheQuestAndRestoreMergesBestOfDay() throws {
        let container = try SharedContainer.make(inMemory: true)
        let ctx = container.mainContext
        let p = PlayerProfile(); ctx.insert(p)
        p.questDay = 20; p.questProgress = 1; p.questDone = false
        try ctx.save()
        let data = try GardenBackup.make(context: ctx, now: .now).encoded()
        guard case .success(let backup) = GardenBackup.decode(data) else { return XCTFail() }
        XCTAssertEqual(backup.profile.questDay, 20)
        XCTAssertEqual(backup.profile.questProgress, 1)
        XCTAssertEqual(backup.profile.questDone, false)

        // The garden moved on to a later day: an older backup does not pull it back.
        p.questDay = 21; p.questProgress = 0; p.questDone = false
        backup.merge(into: ctx, badgeDefs: [])
        XCTAssertEqual(p.questDay, 21); XCTAssertEqual(p.questProgress, 0)

        // Same day: the bigger count wins, done stays done.
        p.questDay = 20; p.questProgress = 0
        backup.merge(into: ctx, badgeDefs: [])
        XCTAssertEqual(p.questDay, 20); XCTAssertEqual(p.questProgress, 1); XCTAssertFalse(p.questDone)
    }

    @MainActor
    func testReconcilerMergesTheQuest() throws {
        let a = PlayerProfile(), b = PlayerProfile()
        a.questDay = 8; a.questProgress = 1; a.questDone = false
        b.questDay = 8; b.questProgress = 2; b.questDone = true
        DataReconciler.merge(b, into: a, defs: [])
        XCTAssertEqual(a.questDay, 8); XCTAssertEqual(a.questProgress, 2); XCTAssertTrue(a.questDone)
        let c = PlayerProfile(); c.questDay = 9
        DataReconciler.merge(c, into: a, defs: [])
        XCTAssertEqual(a.questDay, 9); XCTAssertEqual(a.questProgress, 0); XCTAssertFalse(a.questDone)
    }

    // MARK: The app

    @MainActor
    private func makeApp(quiet: Bool = false) throws -> AppModel {
        let app = try AppModelTendingTests().makeApp(quiet: quiet)
        app.settings.onboardingComplete = true
        for p in app.plants().prefix(3) { p.earnedCount = 1 }
        app.profile?.water = 10
        return app
    }

    @MainActor
    func testWateringTwoPlantsFinishesTheQuestAndGivesOnePoint() throws {
        let app = try makeApp()
        app.questTestOverride = .waterPlants
        let plants = app.plants().filter { $0.earnedCount > 0 }
        let before = app.profile?.shedPoints ?? 0
        XCTAssertTrue(app.tend(.water, plant: plants[0]).applied)
        XCTAssertTrue(app.tend(.water, plant: plants[0]).applied)
        XCTAssertEqual(app.questState.progress, 1, "one plant so far")
        XCTAssertFalse(app.questState.done)
        XCTAssertTrue(app.tend(.water, plant: plants[1]).applied)
        XCTAssertTrue(app.questState.done)
        XCTAssertEqual(app.profile?.shedPoints, before + 1)
        app.recordQuest(.watered(plantsToday: 3))
        XCTAssertEqual(app.profile?.shedPoints, before + 1, "one point a day at most")
    }

    /// A hello or a drink from the widget (another process) is counted when the app comes back to the front.
    @MainActor
    func testWidgetHellosAndDrinksCountWhenTheAppComesBack() throws {
        let app = try makeApp()
        app.questTestOverride = .helloPlants
        let plants = app.plants().filter { $0.earnedCount > 0 }
        for p in plants { XCTAssertTrue(WidgetActions.hello(plantId: p.plantId, context: app.context, now: app.nowDate, exempt: false)) }
        XCTAssertEqual(app.questState.progress, 0)
        app.refreshQuestFromGarden()
        XCTAssertTrue(app.questState.done)

        let other = try makeApp()
        other.questTestOverride = .waterPlants
        other.profile?.water = 9
        for p in other.plants().filter({ $0.earnedCount > 0 }).prefix(2) {
            XCTAssertTrue(WidgetActions.water(plantId: p.plantId, context: other.context, now: other.nowDate, calendar: .current, quiet: false).applied)
        }
        other.refreshQuestFromGarden()
        XCTAssertTrue(other.questState.done)
    }

    @MainActor
    func testHellosCountPlantsGreetedToday() throws {
        let app = try makeApp()
        app.questTestOverride = .helloPlants
        let plants = app.plants().filter { $0.earnedCount > 0 }
        app.love(plants[0]); app.love(plants[0])
        XCTAssertEqual(app.questState.progress, 1)
        app.love(plants[1]); app.love(plants[2])
        XCTAssertTrue(app.questState.done)
    }

    @MainActor
    func testQuietGardenHidesTheQuestAndGivesNothing() throws {
        let app = try makeApp(quiet: true)
        app.questTestOverride = .visitVisitors
        XCTAssertNil(app.todaysQuest)
        let before = app.profile?.shedPoints ?? 0
        app.recordQuest(.visitedVisitors)
        XCTAssertEqual(app.profile?.shedPoints, before)
        XCTAssertFalse(app.questState.done)
    }

    @MainActor
    func testVisitorsQuestFinishesOnAVisit() throws {
        let app = try makeApp()
        app.questTestOverride = .visitVisitors
        XCTAssertEqual(app.todaysQuest?.kind, .visitVisitors)
        app.recordQuest(.visitedVisitors)
        XCTAssertTrue(app.questState.done)
    }
}
