import XCTest
@testable import WordFlora

/// Living Touch (light): a finger stroking the plant makes it lean with the finger; every third stroke is one hello.
final class LivingTouchTests: XCTestCase {
    let t0 = Date(timeIntervalSince1970: 1_780_000_000)

    func testThePlantLeansWithTheFingerAndNeverTooFar() {
        let w: CGFloat = 220
        XCTAssertEqual(LivingTouch.lean(translationX: 0, width: w, motion: .full), 0)
        XCTAssertGreaterThan(LivingTouch.lean(translationX: 40, width: w, motion: .full), 0, "right finger, right lean")
        XCTAssertLessThan(LivingTouch.lean(translationX: -40, width: w, motion: .full), 0)
        XCTAssertLessThan(LivingTouch.lean(translationX: 20, width: w, motion: .full), LivingTouch.lean(translationX: 60, width: w, motion: .full),
                          "scaled by how far the finger moved")
        XCTAssertEqual(LivingTouch.lean(translationX: 5_000, width: w, motion: .full), LivingTouch.maxLean, accuracy: 0.001)
        XCTAssertEqual(LivingTouch.lean(translationX: -5_000, width: w, motion: .full), -LivingTouch.maxLean, accuracy: 0.001)
        XCTAssertEqual(LivingTouch.lean(translationX: 40, width: 0, motion: .full), 0, "no size, no lean")
    }

    func testReduceMotionHoldsThePlantStillAndCalmLeansSoftly() {
        XCTAssertEqual(LivingTouch.motion(reduceMotion: true, appReduceMotion: false, calm: false), .still)
        XCTAssertEqual(LivingTouch.motion(reduceMotion: false, appReduceMotion: true, calm: true), .still)
        XCTAssertEqual(LivingTouch.motion(reduceMotion: false, appReduceMotion: false, calm: true), .soft)
        XCTAssertEqual(LivingTouch.motion(reduceMotion: false, appReduceMotion: false, calm: false), .full)
        XCTAssertEqual(LivingTouch.lean(translationX: 80, width: 220, motion: .still), 0)
        let full = LivingTouch.lean(translationX: 80, width: 220, motion: .full)
        XCTAssertEqual(LivingTouch.lean(translationX: 80, width: 220, motion: .soft), full / 2, accuracy: 0.001)
    }

    func testTheHapticTapsAtMostOnceEveryThreeTenthsOfASecond() {
        XCTAssertTrue(LivingTouch.mayTap(last: nil, now: t0))
        XCTAssertFalse(LivingTouch.mayTap(last: t0, now: t0.addingTimeInterval(0.1)))
        XCTAssertFalse(LivingTouch.mayTap(last: t0, now: t0.addingTimeInterval(0.29)))
        XCTAssertTrue(LivingTouch.mayTap(last: t0, now: t0.addingTimeInterval(0.3)))
        XCTAssertEqual(LivingTouch.hapticGap, 0.3)
    }

    func testOnlyASidewaysMoveIsAStroke() {
        XCTAssertTrue(LivingTouch.isStroke(dx: 40, dy: 5))
        XCTAssertTrue(LivingTouch.isStroke(dx: -40, dy: 10))
        XCTAssertFalse(LivingTouch.isStroke(dx: 8, dy: 0), "too short")
        XCTAssertFalse(LivingTouch.isStroke(dx: 30, dy: 60), "a scroll, not a stroke")
    }

    func testTheThirdStrokeIsOneHello() {
        var s = LivingTouch.Strokes()
        XCTAssertFalse(s.stroke(at: t0))
        XCTAssertFalse(s.stroke(at: t0.addingTimeInterval(0.5)))
        XCTAssertTrue(s.stroke(at: t0.addingTimeInterval(1)), "the third stroke says hello")
        XCTAssertFalse(s.stroke(at: t0.addingTimeInterval(1.5)), "then it counts again from one")
        XCTAssertFalse(s.stroke(at: t0.addingTimeInterval(2)))
        XCTAssertTrue(s.stroke(at: t0.addingTimeInterval(2.5)))
    }

    func testStrokesFarApartStartOver() {
        var s = LivingTouch.Strokes()
        XCTAssertFalse(s.stroke(at: t0))
        XCTAssertFalse(s.stroke(at: t0.addingTimeInterval(1)))
        XCTAssertFalse(s.stroke(at: t0.addingTimeInterval(1 + LivingTouch.strokeWindow + 1)), "a long pause starts over")
        XCTAssertFalse(s.stroke(at: t0.addingTimeInterval(1 + LivingTouch.strokeWindow + 2)))
        XCTAssertTrue(s.stroke(at: t0.addingTimeInterval(1 + LivingTouch.strokeWindow + 3)))
    }
}
