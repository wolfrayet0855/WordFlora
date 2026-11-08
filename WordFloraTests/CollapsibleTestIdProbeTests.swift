import XCTest
import UIKit
@testable import WordFlora

/// One-off live probe (g4a brief 3.1 [verify]): does Google's collapsible banner test id return a collapsible test ad?
/// Skipped unless `WF_LIVE_ADS=1` (network, Debug test ids only; never part of the normal suite).
@MainActor
final class CollapsibleTestIdProbeTests: XCTestCase {
    func testTheCollapsibleTestIdServesACollapsibleAd() async throws {
        try XCTSkipUnless(ProcessInfo.processInfo.environment["WF_LIVE_ADS"] == "1", "live ad probe: set WF_LIVE_ADS=1")
        let window = UIWindow(frame: UIScreen.main.bounds)
        let root = UIViewController(); window.rootViewController = root; window.makeKeyAndVisible()
        let r = await AdsService.debugProbeCollapsibleTestID(in: root)
        let result = try XCTUnwrap(r, "no answer in 30 s, or not a test id")
        print("collapsible probe: loaded \(result.loaded) collapsible \(result.collapsible)")
        XCTAssertTrue(result.loaded)
        XCTAssertTrue(result.collapsible, "a test ad came back but not collapsible")
    }
}
