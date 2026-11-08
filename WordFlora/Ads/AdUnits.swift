import Foundation

/// The nine AdMob unit keys (Info.plist, filled from Config/Ads.xcconfig; real ids only in the git-ignored local file
/// for Release). Pure, so the fallback chain is unit-tested without the SDK (docs/pm/admob-ad-ids-review.md 1.2).
enum AdUnit: String, CaseIterable {
    case banner = "AdMobBannerUnitID"
    case bannerGarden = "AdMobBannerGardenUnitID"
    case bannerGardenCollapsible = "AdMobBannerGardenCollapsibleUnitID"
    case interstitial = "AdMobInterstitialUnitID"
    case rewarded = "AdMobRewardedUnitID"
    case rewardedHint = "AdMobRewardedHintUnitID"
    case rewardedWake = "AdMobRewardedWakeUnitID"
    case appOpen = "AdMobAppOpenUnitID"
    case native = "AdMobNativeUnitID"

    /// The app id key (tilde form), read by the SDK itself.
    static let appIDKey = "GADApplicationIdentifier"

    /// Same-format fallback only (an ad unit only ever fills its own format):
    /// Garden -> Home banner; collapsible -> Garden -> Home; hint and wake -> water rewarded;
    /// app open and native have none, so an empty id switches that format off.
    var fallback: AdUnit? {
        switch self {
        case .bannerGarden: .banner
        case .bannerGardenCollapsible: .bannerGarden
        case .rewardedHint, .rewardedWake: .rewarded
        case .banner, .interstitial, .rewarded, .appOpen, .native: nil
        }
    }

    /// The unit for a rewarded perk (R1 water, R2 hint, R3 wake).
    static func rewarded(_ perk: RewardedPerk) -> AdUnit {
        switch perk {
        case .water: .rewarded
        case .hint: .rewardedHint
        case .wake: .rewardedWake
        }
    }

    /// The id for a unit from an Info dictionary, following the fallback chain past missing, empty or unresolved
    /// (`$(...)`) values. Returns "" when nothing in the chain is set.
    static func id(_ unit: AdUnit, info: [String: Any]) -> String {
        var next: AdUnit? = unit
        while let u = next {
            if let s = (info[u.rawValue] as? String)?.trimmingCharacters(in: .whitespaces), !s.isEmpty, !s.hasPrefix("$(") {
                return s
            }
            next = u.fallback
        }
        return ""
    }

    /// Google's published test publisher number. Debug builds carry only test ids; a Release build that carries one
    /// fails its build phase (`tools/ads/check-ad-ids.sh`).
    static let googleTestPublisher = "3940256099942544"
}
