import XCTest
@testable import WordFlora

/// The petal sound toy on the plant page: five petals, five pentatonic notes, gentle and gated by the comfort settings.
final class PetalNotesTests: XCTestCase {
    func testFivePetalsPlayTheMajorPentatonicGoingUp() {
        let f = (0..<5).map { PetalNotes.frequency(petal: $0) }
        XCTAssertEqual(f.count, 5)
        XCTAssertEqual(f, f.sorted(), "left to right goes up")
        // C D E G A: no fourth and no seventh, so any order of taps sounds kind.
        let semitones = f.map { Int((12 * log2($0 / f[0])).rounded()) }
        XCTAssertEqual(semitones, [0, 2, 4, 7, 9])
        XCTAssertEqual(f[0], 523.25, accuracy: 0.01)
    }

    func testOutOfRangePetalsClamp() {
        XCTAssertEqual(PetalNotes.frequency(petal: -3), PetalNotes.frequency(petal: 0))
        XCTAssertEqual(PetalNotes.frequency(petal: 99), PetalNotes.frequency(petal: 4))
    }

    func testTheLoveFlowerPlaysTheWholeRow() {
        XCTAssertEqual(PetalNotes.notes(forTap: nil), [0, 1, 2, 3, 4])
        XCTAssertEqual(PetalNotes.notes(forTap: 2), [2])
    }

    func testVolumeFollowsSoundAndCalm() {
        XCTAssertEqual(PetalNotes.volume(soundOn: false, calm: false), 0)
        XCTAssertEqual(PetalNotes.volume(soundOn: false, calm: true), 0)
        let normal = PetalNotes.volume(soundOn: true, calm: false), calm = PetalNotes.volume(soundOn: true, calm: true)
        XCTAssertGreaterThan(normal, 0)
        XCTAssertGreaterThan(calm, 0)
        XCTAssertLessThan(calm, normal, "Calm is softer")
        XCTAssertLessThanOrEqual(normal, 0.6, "always gentle")
    }

    func testHapticsFollowTheSwitch() {
        XCTAssertTrue(PetalNotes.haptic(hapticsOn: true))
        XCTAssertFalse(PetalNotes.haptic(hapticsOn: false))
    }

    func testTapPositionPicksThePetal() {
        let w: CGFloat = 13, lead: CGFloat = 8
        XCTAssertNil(PetalNotes.petalIndex(x: 10, pipWidth: w, leading: lead), "the love flower")
        // Each pip's centre maps to its own index.
        for i in 0..<5 {
            let centre = lead + 1.6 * w + 0.3 * w + CGFloat(i) * 1.3 * w + w / 2
            XCTAssertEqual(PetalNotes.petalIndex(x: centre, pipWidth: w, leading: lead), i)
        }
        XCTAssertEqual(PetalNotes.petalIndex(x: 500, pipWidth: w, leading: lead), 4, "past the end is the last petal")
    }

    func testThePluckIsShortQuietAndFadesOut() {
        let s = PetalNotes.samples(frequency: 523.25, sampleRate: 44_100, volume: 0.5)
        XCTAssertEqual(s.count, Int(44_100 * PetalNotes.duration))
        let peak = s.map { abs($0) }.max() ?? 0
        XCTAssertGreaterThan(peak, 0.1)
        XCTAssertLessThanOrEqual(peak, 0.5 + 1e-4, "never louder than asked")
        XCTAssertLessThan(abs(s.first ?? 1), 0.05, "a soft start, no click")
        let tail = s.suffix(200).map { abs($0) }.max() ?? 1
        XCTAssertLessThan(tail, 0.01, "fades to nothing, no click")
        XCTAssertTrue(PetalNotes.samples(frequency: 523.25, sampleRate: 44_100, volume: 0).allSatisfy { $0 == 0 })
    }
}
