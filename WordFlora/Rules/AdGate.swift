import Foundation

/// Interstitial and consent rules (spec sections 12, 16, 18, 19). Pure so it can be tested exhaustively.
enum AdGate {
    enum Choice { case oneMore, thatsEnough }

    struct Context {
        var now: Date
        var roundsSinceAd = 0
        var choice: Choice?
        var isUnderThirteen = false
        var hasRemoveAds = false
        var midRound = false
        var aroundDailyBloom = false
        var lastRoundWasLoss = false
        var completedSessions = 0
        var wordLevelUps = 0
        var lastAdAt: Date?
        var adsToday = 0
        var lastPeakAt: Date?
        // remote-config tunables
        var frequency = 3
        var minGapSeconds = 180.0
        var maxPerDay = 6
        /// Measured from when a celebration is dismissed. The real protection is structural: an ad can only follow
        /// the player's own "One more" tap, never a celebration itself (ruling, spec section 20).
        var peakWindowSeconds = 5.0

        init(now: Date) { self.now = now }
    }

    static func shouldShowInterstitial(_ c: Context) -> Bool {
        guard mayLoadAnyAd(isUnderThirteen: c.isUnderThirteen, hasRemoveAds: c.hasRemoveAds) else { return false }
        guard c.choice == .oneMore else { return false }                    // only after the player picks "One more"
        guard !c.midRound, !c.aroundDailyBloom, !c.lastRoundWasLoss else { return false }
        guard c.roundsSinceAd >= c.frequency else { return false }
        guard c.completedSessions >= 3 || c.wordLevelUps >= 1 else { return false }   // grace period
        if let last = c.lastAdAt, c.now.timeIntervalSince(last) < c.minGapSeconds { return false }
        guard c.adsToday < c.maxPerDay else { return false }
        if let peak = c.lastPeakAt, c.now.timeIntervalSince(peak) < c.peakWindowSeconds { return false }
        return true
    }

    /// Under-13 profiles and subscribers never load any ad.
    static func mayLoadAnyAd(isUnderThirteen: Bool, hasRemoveAds: Bool) -> Bool {
        !isUnderThirteen && !hasRemoveAds
    }

    /// UMP / ATT prompts appear only immediately before an ad request that is actually allowed.
    static func mayAskConsent(adRequestImminent: Bool, isUnderThirteen: Bool, hasRemoveAds: Bool) -> Bool {
        adRequestImminent && mayLoadAnyAd(isUnderThirteen: isUnderThirteen, hasRemoveAds: hasRemoveAds)
    }
}
