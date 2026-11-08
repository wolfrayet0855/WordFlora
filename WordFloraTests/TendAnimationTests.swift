import XCTest
import SwiftData
@testable import WordFlora

/// Tend effects (timing, one play at a time, plant pose), the action button looks, and the seed rule.
@MainActor
final class TendAnimationTests: XCTestCase {

    // MARK: Effects

    func testEveryEffectIsUnderTwoSecondsAndReduceMotionIsShorter() {
        for e in TendEffect.allCases {
            XCTAssertLessThan(e.duration, 2, e.rawValue)
            XCTAssertLessThan(e.duration(calm: true), e.duration(calm: false), e.rawValue)
            XCTAssertLessThan(TendMotion.lifetime(e, calm: false, hold: false), 2)
        }
    }

    func testActionsMapToTheirEffectAndSound() {
        XCTAssertEqual(TendEffect(.water), .water)
        XCTAssertEqual(TendEffect(.feed), .soil)
        XCTAssertEqual(TendEffect(.sun), .sun)
        XCTAssertEqual(TendEffect(.repot(.loam)), .repot)
        XCTAssertNil(TendEffect(.prune))
        XCTAssertEqual(TendEffect.water.sound, .water)
        XCTAssertEqual(TendEffect.soil.sound, .soil)
        XCTAssertEqual(TendEffect.sun.sound, .sun)
        XCTAssertEqual(TendEffect.repot.sound, .soil)
        XCTAssertEqual(TendEffect.water.identifier, "tend-anim-water")
    }

    func testANewTapReplacesThePlayInsteadOfStacking() {
        var seq = TendSequencer()
        let t0 = Date(timeIntervalSince1970: 1_000)
        let first = seq.start(.water, at: t0)
        let second = seq.start(.sun, at: t0.addingTimeInterval(0.5))
        XCTAssertNotEqual(first.id, second.id)
        XCTAssertEqual(seq.current, second, "one play at a time")
        seq.finish(id: first.id)
        XCTAssertEqual(seq.current, second, "an old play finishing never clears the new one")
        XCTAssertEqual(seq.active(at: t0.addingTimeInterval(1), calm: false, hold: false), second)
        XCTAssertNil(seq.active(at: t0.addingTimeInterval(0.5 + 1.81), calm: false, hold: false), "plays once, no loop")
        seq.finish(id: second.id)
        XCTAssertNil(seq.current)
    }

    func testUITestHoldFreezesTheMiddleFrameThenFinishes() {
        let mid = TendMotion.midpoint(.water, calm: false)
        XCTAssertEqual(TendMotion.localTime(elapsed: 0.2, effect: .water, calm: false, hold: true), 0.2)
        XCTAssertEqual(TendMotion.localTime(elapsed: mid + 2, effect: .water, calm: false, hold: true), mid)
        XCTAssertEqual(TendMotion.localTime(elapsed: mid + TendMotion.holdSeconds + 0.3, effect: .water, calm: false, hold: true), mid + 0.3, accuracy: 1e-9)
        XCTAssertEqual(TendMotion.localTime(elapsed: 1.2, effect: .water, calm: false, hold: false), 1.2)
    }

    func testThePlantRestsAtTheStartAndEndOfEveryPlay() {
        for e in TendEffect.allCases {
            XCTAssertEqual(TendMotion.plantPose(e, t: 0, calm: false), .rest, e.rawValue)
            XCTAssertEqual(TendMotion.plantPose(e, t: e.duration, calm: false), .rest, e.rawValue)
            for t in stride(from: 0.0, through: e.duration, by: 0.1) {
                XCTAssertEqual(TendMotion.plantPose(e, t: t, calm: true), .rest, "Reduce Motion never moves the plant")
            }
        }
    }

    func testWaterGivesASoftDrinkAfterTheDropsLand() {
        XCTAssertEqual(TendMotion.plantPose(.water, t: 0.9, calm: false), .rest, "no drink before the drops land")
        let peak = stride(from: 1.05, through: 1.55, by: 0.01).map { TendMotion.plantPose(.water, t: $0, calm: false).scaleX }.max()!
        XCTAssertEqual(peak, 1.04, accuracy: 0.005)
    }

    func testSunFluttersFromTheFirstGlintAndRepotLiftsFirst() {
        XCTAssertNotEqual(TendMotion.plantPose(.sun, t: 0.35, calm: false).rotation, 0)
        XCTAssertLessThan(TendMotion.plantPose(.repot, t: 0.34, calm: false).lift, -50, "the plant is up before the old pot slides out at 0.3 s")
        XCTAssertLessThan(TendMotion.plantPose(.repot, t: 0.9, calm: false).lift, -50, "and stays up while the new pot slides in")
        XCTAssertGreaterThan(TendMotion.plantPose(.repot, t: 1.25, calm: false).lift, -5, "then lowers into it")
    }

    func testTrackInterpolatesBetweenKeys() {
        let keys: [(Double, [Double])] = [(0, [0]), (0.5, [10]), (1, [0])]
        XCTAssertEqual(TendMotion.track(keys, 0.5, ease: TendMotion.linear)[0], 10)
        XCTAssertEqual(TendMotion.track(keys, 0.25, ease: TendMotion.linear)[0], 5)
        XCTAssertEqual(TendMotion.track(keys, -1)[0], 0)
        XCTAssertEqual(TendMotion.track(keys, 2)[0], 0)
    }

    // MARK: Button looks

    private func state(_ s: AppModel.ActionState.Status, _ label: String, _ line: String? = nil) -> AppModel.ActionState {
        AppModel.ActionState(status: s, label: label, line: line)
    }

    func testReadyButtonsAreLitAndSayWhatTheyDo() {
        let w = TendButtonLook(kind: .water, state: state(.ready, "Water"))
        XCTAssertTrue(w.lit); XCTAssertEqual(w.badge, .none)
        XCTAssertEqual(w.title, "Water"); XCTAssertEqual(w.caption, "Give a drink")
        XCTAssertEqual(TendButtonLook(kind: .feed, state: state(.ready, "Feed")).caption, "Add soil")
        XCTAssertEqual(TendButtonLook(kind: .sun, state: state(.ready, "Sun")).caption, "Let it shine")
    }

    func testDoneButtonsAreSoftlyCheckedWithTheirDoneWords() {
        let f = TendButtonLook(kind: .feed, state: state(.done, "Fed today", "Pip is well fed today. More soil tomorrow."))
        XCTAssertFalse(f.lit); XCTAssertEqual(f.badge, .check)
        XCTAssertEqual(f.title, "Fed today"); XCTAssertEqual(f.caption, "More tomorrow")
        XCTAssertEqual(f.hint, "Pip is well fed today. More soil tomorrow.")
        XCTAssertEqual(TendButtonLook(kind: .prune, state: state(.done, "Prune", "x")).title, "Trim")
    }

    func testNeedsASupplyShowsTheReasonAndTheTapSaysTheNextStep() {
        let w = TendButtonLook(kind: .water, state: state(.needsSupply, "Water", TendCopy.canDry))
        XCTAssertEqual(w.badge, .supply); XCTAssertFalse(w.lit)
        XCTAssertEqual(w.title, "Water"); XCTAssertEqual(w.caption, "Can is dry")
        XCTAssertEqual(w.hint, TendCopy.canDry)
        XCTAssertEqual(TendButtonLook(kind: .feed, state: state(.needsSupply, "Feed")).caption, "Need scoops")
        XCTAssertEqual(TendButtonLook(kind: .prune, state: state(.needsSupply, "Prune")).caption, "Need shears")
    }

    func testASeedsButtonsSayWakeFirst() {
        for kind in TendKind.allCases {
            let look = TendButtonLook(kind: kind, state: state(.seed, "Wake first", "Pip is tucked in as a seed. Wake it with a challenge."))
            XCTAssertEqual(look.title, "Wake first"); XCTAssertEqual(look.badge, .rest); XCTAssertFalse(look.lit)
        }
    }

    func testTheButtonAndTheRuleUseTheSameWakeWords() {
        XCTAssertEqual(TendKind.wakeFirst, AppModel.wakeFirstLabel)
    }

    func testButtonsKeepTheirActionNameForVoiceOver() {
        for kind in TendKind.allCases {
            for s in [AppModel.ActionState.Status.ready, .done, .needsSupply, .seed] {
                XCTAssertEqual(TendButtonLook(kind: kind, state: state(s, "x")).accessibilityLabel, kind.title)
            }
        }
    }

    // MARK: Copy

    private let banned = ["miss", "only", "last", "waiting", "lost", "dead", "empty", "left", "beat", "forget"]

    func testEveryNewStringIsKind() {
        var lines = TendEffect.allCases.map(\.spokenLabel) + TendPot.allCases.map(\.name) + [TendKind.wakeFirst, TendKind.wakeCaption, TendKind.moreTomorrow, TendKind.trimLater, TendKind.trimmed]
        for kind in TendKind.allCases {
            lines += [kind.title, kind.readyCaption, kind.supplyCaption]
            for s in [AppModel.ActionState.Status.ready, .done, .needsSupply, .seed] {
                let look = TendButtonLook(kind: kind, state: state(s, kind.title))
                lines += [look.title, look.caption, look.accessibilityValue, look.hint]
            }
        }
        lines += AppModel.ruleLines(name: "Pip") + PlantDetailCopy.all
        for line in lines {
            XCTAssertEqual(CopySafety.check(line), [], line)
            for word in banned {
                XCTAssertNil(line.range(of: "\\b\(word)\\b", options: [.regularExpression, .caseInsensitive]), "\(word) in \(line)")
            }
        }
    }

    // MARK: Seed rule: the buttons and tend agree

    private func makeApp(now: @escaping () -> Date) throws -> AppModel {
        let container = try SharedContainer.make(inMemory: true)
        let settings = AppSettings(defaults: UserDefaults(suiteName: "wf-tend-\(UUID().uuidString)")!)
        let bank = WordBank(schemaVersion: 1, bankVersion: "t", entries: [], daily: DailyConfig(epoch: "2026-01-01", seed: 1))
        return AppModel(container: container, settings: settings, bank: bank, now: now, notifications: ReminderTests.FakeCenter())
    }

    func testASeedRefusesEveryActionAndItsButtonsSaySoFirst() throws {
        let t = Date(timeIntervalSince1970: 1_780_000_000)
        let app = try makeApp(now: { t })
        let plant = app.plants().first!; plant.earnedCount = 1; plant.nickname = "Pip"
        plant.lastLovedAt = t.addingTimeInterval(-6 * 86_400)
        app.profile?.water = 9; app.profile?.soil = 3
        app.inventory = { var i = app.inventory; i.unlock(.shears); return i }()
        XCTAssertTrue(app.showsWakeCard(plant))
        for action in [AppModel.TendAction.water, .feed, .sun, .prune, .repot(.loam)] {
            let s = app.actionState(action, plant: plant)
            XCTAssertEqual(s.status, .seed, "\(action)")
            XCTAssertFalse(s.isReady)
            XCTAssertEqual(s.label, "Wake first")
            let outcome = app.tend(action, plant: plant)
            XCTAssertFalse(outcome.applied, "\(action)")
            XCTAssertEqual(outcome.message, s.line, "the tap says what the button said")
        }
        XCTAssertEqual(app.profile?.water, 9, "nothing was spent")
        app.wake(plant)
        XCTAssertEqual(app.actionState(.water, plant: plant).status, .ready, "awake again, the buttons work")
    }
}
