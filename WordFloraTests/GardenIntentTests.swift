import XCTest
import SwiftData
@testable import WordFlora

@MainActor
final class GardenIntentTests: XCTestCase {
    var container: ModelContainer!
    var ctx: ModelContext { container.mainContext }
    let t0 = Date(timeIntervalSince1970: 1_780_000_000)
    var cal: Calendar { var c = Calendar(identifier: .gregorian); c.timeZone = TimeZone(identifier: "UTC")!; return c }

    override func setUp() async throws {
        container = try SharedContainer.make(inMemory: true)
        try PlantCatalog.seedIfNeeded(context: ctx)
        let p = PlayerProfile(); p.water = 2; p.lastTrickleAt = t0; ctx.insert(p); try ctx.save()
    }
    func own(_ id: String) { try! ctx.fetch(FetchDescriptor<PlantCollectible>()).first { $0.plantId == id }!.earnedCount = 1 }
    var profile: PlayerProfile { try! ctx.fetch(FetchDescriptor<PlayerProfile>()).first! }

    func testSiriWateringSpendsARealDropFromTheSameStoreAsTheWidget() {
        own("rose")
        let line = WidgetActions.waterGarden(context: ctx, now: t0, calendar: cal, quiet: false)
        XCTAssertEqual(profile.water, 1)
        XCTAssertTrue(line.contains("Rose"))
    }

    func testNoPlantsYetPointsToPlayingAWord() {
        let line = WidgetActions.waterGarden(context: ctx, now: t0, calendar: cal, quiet: false)
        XCTAssertTrue(line.lowercased().contains("word"))
        XCTAssertEqual(profile.water, 2)
    }

    func testOutOfDropsIsPhrasedKindly() {
        own("rose"); profile.water = 0
        let line = WidgetActions.waterGarden(context: ctx, now: t0, calendar: cal, quiet: false)
        XCTAssertTrue(line.lowercased().contains("word"))
    }

    func testEveryLineIsCopySafe() {
        own("rose")
        var lines = [WidgetActions.waterGarden(context: ctx, now: t0, calendar: cal, quiet: false)]
        lines.append(WidgetActions.waterGarden(context: ctx, now: t0, calendar: cal, quiet: false))
        lines.append(WidgetActions.waterGarden(context: ctx, now: t0, calendar: cal, quiet: false))     // out of drops
        for _ in 0..<12 { lines.append(WidgetActions.waterGarden(context: ctx, now: t0, calendar: cal, quiet: true)) }   // daily cap
        for l in lines { XCTAssertEqual(CopySafety.check(l), [], l) }
    }
}
