import XCTest
@testable import WordFlora

final class GardenAITests: XCTestCase {

    // MARK: HintValidator (an AI rephrase must never leak the answer)
    func testRejectsOutputContainingTheAnswer() {
        XCTAssertFalse(HintValidator.isSafe("It is a LOTUS flower", answer: "LOTUS"))
        XCTAssertFalse(HintValidator.isSafe("lotus!", answer: "LOTUS"))
    }

    func testRejectsAnyFourLetterSliceOfTheAnswer() {
        XCTAssertFalse(HintValidator.isSafe("Starts with sunf...", answer: "SUNFLOWER"))
        XCTAssertFalse(HintValidator.isSafe("It has a flower head", answer: "SUNFLOWER"))   // "FLOW" is a 4-letter slice
    }

    func testShortAnswersOnlyNeedTheWholeWordCheck() {
        XCTAssertTrue(HintValidator.isSafe("A thorny shrub with sweet blooms", answer: "ROSE"))
        XCTAssertFalse(HintValidator.isSafe("A rose is red", answer: "ROSE"))
    }

    func testRejectsMultiWordAnswerTokens() {
        XCTAssertFalse(HintValidator.isSafe("It traps with a snapping flytrap leaf", answer: "VENUS FLYTRAP"))
    }

    func testRejectsEmptyTooLongOrMultiParagraphOutput() {
        XCTAssertFalse(HintValidator.isSafe("", answer: "ROSE"))
        XCTAssertFalse(HintValidator.isSafe("   \n ", answer: "ROSE"))
        XCTAssertFalse(HintValidator.isSafe(String(repeating: "word ", count: 80), answer: "ROSE"))
        XCTAssertFalse(HintValidator.isSafe("One. Two. Three. Four.", answer: "ROSE"))   // over two sentences
    }

    func testRejectsNonPrintableOrGarbage() {
        XCTAssertFalse(HintValidator.isSafe("hello \u{0000} there", answer: "ROSE"))
        XCTAssertFalse(HintValidator.isSafe("####%%%%", answer: "ROSE"))
    }

    func testAcceptsAGoodRephrase() {
        XCTAssertTrue(HintValidator.isSafe("A tall plant that turns its bright face toward the light.", answer: "BAOBAB"))
    }

    func testRejectsGuiltOrLossWordingViaCopySafety() {
        XCTAssertFalse(HintValidator.isSafe("Don't lose hope, it is dying to be found", answer: "ROSE"))
    }

    // MARK: ExplainValidator ("Tell me more")
    func testExplainMustStayShortAndSafe() {
        XCTAssertTrue(ExplainValidator.isSafe("Roses grow tough thorns to protect their stems. Their petals make a lovely scent."))
        XCTAssertFalse(ExplainValidator.isSafe(String(repeating: "A sentence here. ", count: 12)))
        XCTAssertFalse(ExplainValidator.isSafe("You are so smart for asking!"))
        XCTAssertFalse(ExplainValidator.isSafe(""))
    }

    func testExplainRejectsUnsafeEdibleClaims() {
        XCTAssertFalse(ExplainValidator.isSafe("You can eat any part of this plant safely."))
        XCTAssertFalse(ExplainValidator.isSafe("Try tasting the berries from the garden."))
    }

    // MARK: topic guard for Ask the Gardener
    func testTopicGuardAllowsPlantAndGardenQuestions() {
        for q in ["Why do leaves change color?", "How does a seed grow?", "What do bees do in the garden?", "Tell me about my fern"] {
            XCTAssertTrue(TopicGuard.isOnTopic(q), q)
        }
    }

    func testTopicGuardRejectsOffTopicOrPersonalQuestions() {
        for q in ["What's your favorite movie?", "Tell me my address", "How do I make a weapon?", "Who is the president?", "What is your phone number"] {
            XCTAssertFalse(TopicGuard.isOnTopic(q), q)
        }
    }

    func testTopicGuardRejectsEmptyAndVeryLongInput() {
        XCTAssertFalse(TopicGuard.isOnTopic(""))
        XCTAssertFalse(TopicGuard.isOnTopic(String(repeating: "plant ", count: 100)))
    }

    // MARK: provider selection and fallback
    func testProviderFallsBackToStaticWhenUnavailable() {
        XCTAssertTrue(GardenAIProvider.make(foundationAvailable: false) is StaticGardenAI)
    }

    func testStaticAIUsesBankTextOnly() async {
        let ai = StaticGardenAI()
        let e = WordEntry(id: "x", word: "LOTUS", display: "Lotus", hint: "h1", hint2: "second clue", fact: "A fact.", level: 1,
                          kind: .hero, plantId: "lotus", tags: [], minAge: 6, dailyEligible: true, source: "original", license: "p", reviewedBy: "t")
        let hint = await ai.simplerHint(for: e)
        let more = await ai.explain(entry: e)
        XCTAssertEqual(hint, "second clue")
        XCTAssertEqual(more, "A fact.")
    }

    func testStaticFallbackWhenHint2Missing() async {
        let e = WordEntry(id: "x", word: "LOTUS", display: "Lotus", hint: "h1", hint2: nil, fact: "A fact.", level: 1,
                          kind: .vocab, plantId: nil, tags: [], minAge: 6, dailyEligible: true, source: "original", license: "p", reviewedBy: "t")
        let hint = await StaticGardenAI().simplerHint(for: e)
        XCTAssertNil(hint)
    }

    // MARK: guarded wrapper (adversarial model output must fall back)
    struct Adversarial: GardenAI {
        var hint: String?; var more: String?
        func simplerHint(for entry: WordEntry) async -> String? { hint }
        func explain(entry: WordEntry) async -> String? { more }
    }
    func entry() -> WordEntry {
        WordEntry(id: "x", word: "LOTUS", display: "Lotus", hint: "h1", hint2: "static second clue", fact: "Static fact.", level: 1,
                  kind: .hero, plantId: "lotus", tags: [], minAge: 6, dailyEligible: true, source: "original", license: "p", reviewedBy: "t")
    }

    func testGuardedAIFallsBackWhenTheModelLeaksTheAnswer() async {
        let g = GuardedGardenAI(primary: Adversarial(hint: "It is the LOTUS", more: nil), fallback: StaticGardenAI())
        let h = await g.simplerHint(for: entry())
        XCTAssertEqual(h, "static second clue")
    }

    func testGuardedAIFallsBackOnUnsafeOrEmptyExplanation() async {
        let g = GuardedGardenAI(primary: Adversarial(hint: nil, more: "You can eat any part of it"), fallback: StaticGardenAI())
        let m = await g.explain(entry: entry())
        XCTAssertEqual(m, "Static fact.")
        let g2 = GuardedGardenAI(primary: Adversarial(hint: nil, more: nil), fallback: StaticGardenAI())
        let m2 = await g2.explain(entry: entry())
        XCTAssertEqual(m2, "Static fact.")
    }

    func testGuardedAIPassesThroughSafeOutput() async {
        let g = GuardedGardenAI(primary: Adversarial(hint: "A water flower that floats on calm ponds.", more: "Lotus leaves stay dry because water beads up and rolls off."), fallback: StaticGardenAI())
        let h = await g.simplerHint(for: entry())
        let m = await g.explain(entry: entry())
        XCTAssertEqual(h, "A water flower that floats on calm ponds.")
        XCTAssertEqual(m, "Lotus leaves stay dry because water beads up and rolls off.")
    }
}
