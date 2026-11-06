import XCTest
@testable import WordFlora

/// The Family Sharing line: grown-ups without Plus only, never kids, never Quiet Garden.
final class FamilyShareNudgeTests: XCTestCase {
    func testShownToTeensAndAdultsWithoutPlus() {
        XCTAssertTrue(FamilyShareNudge.isShown(ageBand: .eighteenPlus, hasPlus: false, quietGarden: false))
        XCTAssertTrue(FamilyShareNudge.isShown(ageBand: .thirteenPlus, hasPlus: false, quietGarden: false))
    }

    func testKidsAndUnknownAgeNeverSeeIt() {
        XCTAssertFalse(FamilyShareNudge.isShown(ageBand: .under13, hasPlus: false, quietGarden: false))
        XCTAssertFalse(FamilyShareNudge.isShown(ageBand: nil, hasPlus: false, quietGarden: false))
    }

    func testPlusOwnersAndQuietGardenDoNotSeeIt() {
        XCTAssertFalse(FamilyShareNudge.isShown(ageBand: .eighteenPlus, hasPlus: true, quietGarden: false))
        XCTAssertFalse(FamilyShareNudge.isShown(ageBand: .eighteenPlus, hasPlus: false, quietGarden: true))
    }

    func testCopyIsCalm() {
        for line in FamilyShareNudge.Copy.all { XCTAssertEqual(CopySafety.check(line), [], line) }
        XCTAssertEqual(FamilyShareNudge.Copy.line + " " + FamilyShareNudge.Copy.button + ".",
                       "Already have Plus on a family phone? Restore purchases.")
    }
}
