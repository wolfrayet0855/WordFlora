import XCTest
@testable import WordFlora

/// Ad unit ids (docs/pm/admob-ad-ids-review.md 3.4): the same-format fallback chain, no cross-format fallback, and a
/// format switched off when its id is empty. Pure, no SDK. Real ids are never printed: failures name the key only.
final class AdUnitIDTests: XCTestCase {
    private let home = "ca-app-pub-1111111111111111/1111111111"
    private let garden = "ca-app-pub-1111111111111111/2222222222"
    private let collapsible = "ca-app-pub-1111111111111111/3333333333"
    private let water = "ca-app-pub-1111111111111111/4444444444"
    private let hint = "ca-app-pub-1111111111111111/5555555555"
    private let wake = "ca-app-pub-1111111111111111/6666666666"
    private let interstitial = "ca-app-pub-1111111111111111/7777777777"
    private let appOpen = "ca-app-pub-1111111111111111/8888888888"
    private let native = "ca-app-pub-1111111111111111/9999999999"

    private var full: [String: Any] {
        [AdUnit.banner.rawValue: home, AdUnit.bannerGarden.rawValue: garden, AdUnit.bannerGardenCollapsible.rawValue: collapsible,
         AdUnit.rewarded.rawValue: water, AdUnit.rewardedHint.rawValue: hint, AdUnit.rewardedWake.rawValue: wake,
         AdUnit.interstitial.rawValue: interstitial, AdUnit.appOpen.rawValue: appOpen, AdUnit.native.rawValue: native]
    }

    // 1. Fallback chain, for a missing key and for an empty one (and an unresolved build setting).
    func testTheFallbackChainForMissingEmptyAndUnresolvedKeys() {
        XCTAssertEqual(AdUnit.allCases.count, 9)
        for unit in AdUnit.allCases { XCTAssertEqual(AdUnit.id(unit, info: full), (full[unit.rawValue] as! String), "\(unit)") }
        for blank in [nil, "", "  ", "$(ADMOB_X_ID)"] as [String?] {
            func info(_ drop: AdUnit...) -> [String: Any] {
                var d = full
                for u in drop { if let blank { d[u.rawValue] = blank } else { d.removeValue(forKey: u.rawValue) } }
                return d
            }
            let label = blank ?? "missing"
            XCTAssertEqual(AdUnit.id(.bannerGarden, info: info(.bannerGarden)), home, "Garden -> Home (\(label))")
            XCTAssertEqual(AdUnit.id(.bannerGardenCollapsible, info: info(.bannerGardenCollapsible)), garden, "collapsible -> Garden (\(label))")
            XCTAssertEqual(AdUnit.id(.bannerGardenCollapsible, info: info(.bannerGardenCollapsible, .bannerGarden)), home, "collapsible -> Home (\(label))")
            XCTAssertEqual(AdUnit.id(.rewardedHint, info: info(.rewardedHint)), water, "hint -> water (\(label))")
            XCTAssertEqual(AdUnit.id(.rewardedWake, info: info(.rewardedWake)), water, "wake -> water (\(label))")
            XCTAssertEqual(AdUnit.id(.appOpen, info: info(.appOpen)), "", "app open off (\(label))")
            XCTAssertEqual(AdUnit.id(.native, info: info(.native)), "", "native off (\(label))")
        }
        XCTAssertEqual(AdUnit.rewarded(.water), .rewarded)
        XCTAssertEqual(AdUnit.rewarded(.hint), .rewardedHint)
        XCTAssertEqual(AdUnit.rewarded(.wake), .rewardedWake)
    }

    // 2. App open and native never borrow another format's id, for any combination of missing keys.
    func testNoCrossFormatFallback() {
        let others = AdUnit.allCases.filter { $0 != .appOpen && $0 != .native }
        for mask in 0..<(1 << AdUnit.allCases.count) {
            var d = full
            for (k, u) in AdUnit.allCases.enumerated() where mask & (1 << k) != 0 { d.removeValue(forKey: u.rawValue) }
            for unit in [AdUnit.appOpen, .native] {
                let id = AdUnit.id(unit, info: d)
                XCTAssertTrue(id == "" || id == (full[unit.rawValue] as! String), "\(unit) mask \(mask)")
                for o in others { XCTAssertNotEqual(id, full[o.rawValue] as! String, "\(unit) took \(o)'s id") }
            }
        }
    }

    // 5. A format with no id is switched off by the policy (G4b's callers read this; G4b extends the service spy).
    func testAFormatWithAnEmptyIdIsSwitchedOff() {
        for band in [AgeBand.thirteenPlus, .eighteenPlus] {
            var i = AdPolicyTests.permissive(band)
            XCTAssertTrue(AdPolicy.decide(.appOpen, i, caps: AdCaps()).isYes)
            XCTAssertTrue(AdPolicy.decide(.native, i, caps: AdCaps()).isYes)
            i.appOpenUnitSet = false; i.nativeUnitSet = false
            XCTAssertEqual(AdPolicy.decide(.appOpen, i, caps: AdCaps()), .no(.notApplicable))
            XCTAssertEqual(AdPolicy.decide(.native, i, caps: AdCaps()), .no(.notApplicable))
        }
    }
}

/// What the built app actually carries (3 and 4). Runs in the hosted unit-test bundle, so `Bundle.main` is the app.
final class AdUnitIDBundleTests: XCTestCase {
    private var info: [String: Any] { Bundle.main.infoDictionary ?? [:] }

    // 3. Shape: every unit key present and resolved, the app id in tilde form.
    func testEveryIdInTheBuiltAppHasTheRightShape() throws {
        let unit = try NSRegularExpression(pattern: #"^ca-app-pub-\d{16}/\d{10}$"#)
        let app = try NSRegularExpression(pattern: #"^ca-app-pub-\d{16}~\d{10}$"#)
        func matches(_ r: NSRegularExpression, _ s: String) -> Bool { r.firstMatch(in: s, range: NSRange(s.startIndex..., in: s)) != nil }
        for u in AdUnit.allCases {
            let s = info[u.rawValue] as? String ?? ""
            XCTAssertTrue(matches(unit, s), "\(u.rawValue) is missing, empty, unresolved or the wrong shape")
        }
        XCTAssertTrue(matches(app, info[AdUnit.appIDKey] as? String ?? ""), "\(AdUnit.appIDKey) must be the tilde app id")
    }

    // 4. Debug carries only Google's test ids; Release none, with Garden equal to Home (the reuse decision).
    func testDebugCarriesOnlyTestIdsAndReleaseNone() {
        let keys = AdUnit.allCases.map(\.rawValue) + [AdUnit.appIDKey]
        #if DEBUG
        for k in keys { XCTAssertTrue((info[k] as? String ?? "").contains(AdUnit.googleTestPublisher), "\(k) is not a test id in Debug") }
        #else
        for k in keys { XCTAssertFalse((info[k] as? String ?? "").contains(AdUnit.googleTestPublisher), "\(k) is a test id in Release") }
        XCTAssertEqual(info[AdUnit.bannerGarden.rawValue] as? String, info[AdUnit.banner.rawValue] as? String, "Garden reuses Home")
        #endif
    }
}
