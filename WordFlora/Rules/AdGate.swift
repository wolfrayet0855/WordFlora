import Foundation

/// Interstitial and consent rules (spec sections 12, 16, 18, 19). Pure so it can be tested exhaustively.
enum AdGate {
    /// `playSoonAfterEnough`: the player tapped Play on Home within `returnWindowSeconds` of "That's enough for now".
    enum Choice { case oneMore, thatsEnough, playSoonAfterEnough }

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
        /// 9 pm to 8 am local (`isNight`). A return soon after "That's enough" never plays an ad at night.
        var isNight = false
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
        // Only on the player's own tap: "One more", or Play again soon after "That's enough" (never the exit itself).
        guard c.choice == .oneMore || c.choice == .playSoonAfterEnough else { return false }
        if c.choice == .playSoonAfterEnough, c.isNight { return false }
        guard !c.midRound, !c.aroundDailyBloom, !c.lastRoundWasLoss else { return false }
        guard c.roundsSinceAd >= c.frequency else { return false }
        guard c.completedSessions >= 1 else { return false }                              // never in the first session
        guard c.completedSessions >= 3 || c.wordLevelUps >= 1 else { return false }   // grace period
        if let last = c.lastAdAt, c.now.timeIntervalSince(last) < c.minGapSeconds { return false }
        guard c.adsToday < c.maxPerDay else { return false }
        if let peak = c.lastPeakAt, c.now.timeIntervalSince(peak) < c.peakWindowSeconds { return false }
        return true
    }

    // MARK: Coming back soon after "That's enough for now" (docs/pm/ad-gate-return-nudge.md)

    /// Play tapped this soon after "That's enough for now" counts as coming straight back.
    static let returnWindowSeconds = 180.0

    /// What Play on Home does: an ordinary start, an ad that may play first on the player's tap (the button says so),
    /// or the gentle nudge card ("Your garden would love a visit") that never blocks play.
    enum ReturnVisit: Equatable { case free, adMayPlay, nudge }

    struct ReturnContext {
        var now: Date
        /// When the player last tapped "That's enough for now" (nil: not this sitting, or already answered).
        var enoughAt: Date?
        var calmMode = false
        var quietGarden = false
        /// The ad service is switched on (false: switched off, or known not to be able to play one).
        var adsAvailable = true
        /// The ordinary interstitial rules for this tap; `choice` is set to `playSoonAfterEnough` when judged.
        var ad: Context
    }

    static func isInReturnWindow(enoughAt: Date?, now: Date) -> Bool {
        guard let enoughAt else { return false }
        let elapsed = now.timeIntervalSince(enoughAt)
        return elapsed >= 0 && elapsed < returnWindowSeconds
    }

    /// Calm mode and Quiet Garden never get an ad here; anyone an ad cannot or may not reach gets the nudge instead.
    static func returnVisit(_ r: ReturnContext) -> ReturnVisit {
        guard isInReturnWindow(enoughAt: r.enoughAt, now: r.now) else { return .free }
        if r.calmMode || r.quietGarden || !r.adsAvailable { return .nudge }
        var ad = r.ad
        ad.choice = .playSoonAfterEnough
        return shouldShowInterstitial(ad) ? .adMayPlay : .nudge
    }

    /// The reminders' quiet hours (`ReminderPolicy.quietStartHour` to `quietEndHour`), local time.
    static func isNight(_ date: Date, calendar: Calendar = .current) -> Bool {
        let hour = calendar.component(.hour, from: date)
        return hour >= ReminderPolicy.quietStartHour || hour < ReminderPolicy.quietEndHour
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
