import XCTest
@testable import WordFlora

final class WordProviderTests: XCTestCase {

    // MARK: fixtures
    private func entry(_ id: String, _ word: String, level: Int, kind: WordEntry.Kind = .vocab,
                       plantId: String? = nil, hint: String = "a hint", daily: Bool = true) -> WordEntry {
        WordEntry(id: id, word: word, display: word.capitalized, hint: hint, hint2: nil, fact: "fact",
                  level: level, kind: kind, plantId: plantId, tags: [], minAge: 6,
                  dailyEligible: daily, source: "original", license: "proprietary", reviewedBy: "t")
    }
    private func bank(_ entries: [WordEntry]) -> WordBank {
        WordBank(schemaVersion: 1, bankVersion: "t", entries: entries,
                 daily: DailyConfig(epoch: "2026-01-01", seed: 42))
    }

    // MARK: SplitMix64
    func testSplitMix64GoldenVectorForSeedZero() {
        var g = SplitMix64(seed: 0)
        XCTAssertEqual(g.next(), 0xE220A8397B1DCDAF)
        XCTAssertEqual(g.next(), 0x6E789E6AA1B965F4)
    }

    // MARK: shipped bank
    func testShippedBankDecodes() throws {
        let b = try WordBank.load()
        XCTAssertFalse(b.entries.isEmpty)
    }

    func testShippedBankPassesValidation() throws {
        let issues = WordBankValidator.validate(try WordBank.load(), knownPlantIds: Set(try PlantCatalog.load().map(\.plantId)))
        XCTAssertEqual(issues, [])
    }

    func testShippedBankCoversAllFiveLevels() throws {
        let levels = Set(try WordBank.load().entries.map(\.level))
        XCTAssertEqual(levels, [1, 2, 3, 4, 5])
    }

    // MARK: validator
    func testValidatorRejectsDigitsAndSymbols() {
        let issues = WordBankValidator.validate(bank([entry("a", "H2O", level: 1), entry("b", "212F", level: 1)]), knownPlantIds: [])
        XCTAssertEqual(issues.count, 2)
    }

    func testValidatorRejectsSpacesInVocab() {
        XCTAssertFalse(WordBankValidator.validate(bank([entry("a", "TWO WORDS", level: 3)]), knownPlantIds: []).isEmpty)
    }

    func testValidatorAllowsSpacesInHero() {
        let e = entry("a", "VENUS FLYTRAP", level: 3, kind: .hero, plantId: "venus_flytrap")
        XCTAssertEqual(WordBankValidator.validate(bank([e]), knownPlantIds: ["venus_flytrap"]), [])
    }

    func testValidatorRejectsHintContainingAnswer() {
        let e = entry("a", "ROSE", level: 1, hint: "The rose is a flower")
        XCTAssertFalse(WordBankValidator.validate(bank([e]), knownPlantIds: []).isEmpty)
    }

    func testValidatorRejectsDuplicateIdsAndBadLevel() {
        let issues = WordBankValidator.validate(bank([entry("a", "SEED", level: 1), entry("a", "LEAF", level: 9)]), knownPlantIds: [])
        XCTAssertTrue(issues.count >= 2)
    }

    func testValidatorRejectsHeroWithUnknownPlant() {
        let e = entry("a", "ROSE", level: 1, kind: .hero, plantId: "nope")
        XCTAssertFalse(WordBankValidator.validate(bank([e]), knownPlantIds: ["rose"]).isEmpty)
    }

    func testValidatorEnforcesVocabLengthBandsPerLevel() {
        // level 1 vocab must be 3-5 letters
        XCTAssertFalse(WordBankValidator.validate(bank([entry("a", "PHOTOSYNTHESIS", level: 1)]), knownPlantIds: []).isEmpty)
    }

    // MARK: provider
    func testPrefersUnseenAtLevel() {
        let b = bank([entry("a", "SEED", level: 1), entry("b", "LEAF", level: 1), entry("c", "ROOT", level: 1)])
        var rng = SplitMix64(seed: 1)
        for _ in 0..<20 {
            let pick = WordProvider(bank: b).next(level: 1, seen: ["a", "b"], excluding: nil, using: &rng)
            XCTAssertEqual(pick?.id, "c")
        }
    }

    func testExhaustedPoolResetsButSkipsLastTenSeen() {
        let ids = (0..<14).map { "id\($0)" }
        let words = ["SEED","LEAF","ROOT","STEM","BUD","BARK","MOSS","PINE","OAK","ELM","FIR","ASH","YEW","BEE"]
        let b = bank(zip(ids, words).map { entry($0, $1, level: 1) })
        let seen = ids   // everything seen, order = oldest first
        let recent = Set(seen.suffix(10))
        var rng = SplitMix64(seed: 7)
        for _ in 0..<50 {
            let pick = WordProvider(bank: b).next(level: 1, seen: seen, excluding: nil, using: &rng)
            XCTAssertNotNil(pick)
            XCTAssertFalse(recent.contains(pick!.id))
        }
    }

    func testNeverReturnsExcludedId() {
        let b = bank([entry("a", "SEED", level: 1), entry("b", "LEAF", level: 1)])
        var rng = SplitMix64(seed: 3)
        for _ in 0..<30 {
            XCTAssertEqual(WordProvider(bank: b).next(level: 1, seen: [], excluding: "a", using: &rng)?.id, "b")
        }
    }

    func testFallsBackToLowerLevelWhenLevelEmpty() {
        let b = bank([entry("a", "SEED", level: 1)])
        var rng = SplitMix64(seed: 3)
        XCTAssertEqual(WordProvider(bank: b).next(level: 4, seen: [], excluding: nil, using: &rng)?.id, "a")
    }

    func testReturnsNilForEmptyBank() {
        var rng = SplitMix64(seed: 3)
        XCTAssertNil(WordProvider(bank: bank([])).next(level: 1, seen: [], excluding: nil, using: &rng))
    }

    // MARK: Daily Bloom
    private var utc: Calendar { var c = Calendar(identifier: .gregorian); c.timeZone = TimeZone(identifier: "UTC")!; return c }
    private func date(_ s: String, tz: String = "UTC") -> Date {
        let f = DateFormatter(); f.calendar = Calendar(identifier: .gregorian)
        f.timeZone = TimeZone(identifier: tz)!; f.dateFormat = "yyyy-MM-dd HH:mm"
        return f.date(from: s)!
    }
    private var dailyBank: WordBank {
        bank((0..<7).map { entry("d\($0)", ["SEED","LEAF","ROOT","STEM","BUD","BARK","MOSS"][$0], level: 1) })
    }

    func testDailyIsDeterministicAcrossInstances() {
        let d = date("2026-03-10 09:00")
        XCTAssertEqual(DailyBloom(bank: dailyBank, calendar: utc).wordId(for: d),
                       DailyBloom(bank: dailyBank, calendar: utc).wordId(for: d))
    }

    func testDailySameForWholeLocalDay() {
        let a = DailyBloom(bank: dailyBank, calendar: utc)
        XCTAssertEqual(a.wordId(for: date("2026-03-10 00:00")), a.wordId(for: date("2026-03-10 23:59")))
    }

    func testDailyCoversEveryEligibleIdOncePerCycle() {
        let a = DailyBloom(bank: dailyBank, calendar: utc)
        let start = date("2026-02-01 12:00")
        let ids = (0..<7).map { a.wordId(for: utc.date(byAdding: .day, value: $0, to: start)!) }
        XCTAssertEqual(Set(ids).count, 7)
        // next cycle repeats the same order
        XCTAssertEqual(a.wordId(for: utc.date(byAdding: .day, value: 7, to: start)!), ids[0])
    }

    func testDailyIgnoresIneligibleEntries() {
        let b = bank([entry("a", "SEED", level: 1), entry("b", "LEAF", level: 1, daily: false)])
        let a = DailyBloom(bank: b, calendar: utc)
        for i in 0..<5 { XCTAssertEqual(a.wordId(for: utc.date(byAdding: .day, value: i, to: date("2026-05-01 10:00"))!), "a") }
    }

    func testDailyRespectsLocalCalendarDayAcrossTimeZones() {
        var tokyo = Calendar(identifier: .gregorian); tokyo.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        let a = DailyBloom(bank: dailyBank, calendar: tokyo)
        // 23:30 and 00:30 local next day must differ in day index
        let late = date("2026-03-10 23:30", tz: "Asia/Tokyo"), early = date("2026-03-11 00:30", tz: "Asia/Tokyo")
        XCTAssertEqual(a.dayIndex(for: early) - a.dayIndex(for: late), 1)
    }

    func testDailyDayIndexStableAcrossDSTChange() {
        var ny = Calendar(identifier: .gregorian); ny.timeZone = TimeZone(identifier: "America/New_York")!
        let a = DailyBloom(bank: dailyBank, calendar: ny)
        // US spring-forward is 2026-03-08; consecutive local days still differ by exactly 1
        let d1 = date("2026-03-07 12:00", tz: "America/New_York"), d2 = date("2026-03-08 12:00", tz: "America/New_York"),
            d3 = date("2026-03-09 12:00", tz: "America/New_York")
        XCTAssertEqual(a.dayIndex(for: d2) - a.dayIndex(for: d1), 1)
        XCTAssertEqual(a.dayIndex(for: d3) - a.dayIndex(for: d2), 1)
    }

    func testDailyOverrideWins() {
        var b = dailyBank
        b = WordBank(schemaVersion: 1, bankVersion: "t", entries: b.entries, daily: b.daily)
        let a = DailyBloom(bank: b, calendar: utc, overrides: ["2026-03-10": "d3"])
        XCTAssertEqual(a.wordId(for: date("2026-03-10 12:00")), "d3")
    }

    func testDailyBeforeEpochStillResolves() {
        let a = DailyBloom(bank: dailyBank, calendar: utc)
        XCTAssertNotNil(a.wordId(for: date("2025-12-01 12:00")))
    }
}
