import Foundation

// One pure entry point for every ad format (docs/pm/admob-full-spec.md sections 0.1, 1.0, 1.1, 2 and the Review rulings).
// The age-and-Plus treatment is checked first, before any other input is read, so the under-13 rule is structural:
// under 13, an unknown age and every Plus owner get `.none` for every format, and `.none` means no SDK start, no
// consent form, no tracking prompt and no ad. 13 to 17 get `.teen` (non-personalised, G rated, never a tracking
// prompt); 18 and over get `.adult` (personalised only with consent and tracking allowed).

enum AdTreatment: Equatable { case none, teen, adult }

enum BannerSlot: Equatable, CaseIterable { case home, garden }

/// R1, R2, R3 (spec section 2).
enum RewardedPerk: String, Codable, CaseIterable { case water, hint, wake }

enum AdFormat: Equatable {
    case banner(BannerSlot), collapsible, interstitial(AdGate.Choice), appOpen, native, rewarded(RewardedPerk)

    /// Full-screen: interstitial, app open, rewarded.
    var isFullScreen: Bool {
        switch self {
        case .interstitial, .appOpen, .rewarded: true
        case .banner, .collapsible, .native: false
        }
    }

    /// Pushed: the app picks the moment (interstitial, app open). Rewarded is the player's own tap.
    var isPushed: Bool {
        switch self {
        case .interstitial, .appOpen: true
        default: false
        }
    }
}

/// In-memory counters for one ad visit (a cold launch, or coming back after `AdCaps.sessionBreak` in the background).
struct AdSessionState: Equatable {
    var startedAt = Date(timeIntervalSince1970: 0)
    var fullScreenShown = 0            // interstitial + app open + rewarded this visit
    var pushedShown = 0                // interstitial + app open this visit
    var rewardedShown = 0
    var collapsibleShown = 0
    var lastBackgroundAt: Date?        // for app open
    var roundWasInProgressAtBackground = false
    var launchedFromLink = false       // URL, widget, notification, App Shortcut, Siri
    var quietVisit = false             // an ending ceremony or the weather puzzle this visit
    var consentResolved = false        // consent obtained or not required
    var attResolved = false            // adults: tracking answer known; teens: always true (never asked)
    /// A rewarded ad failed to load this visit: rewarded rows hide until the next visit (never a dead button).
    var rewardedLoadFailed = false
}

/// The synced profile counters (meaning widened, no new field): `lastAdAt` is any full-screen ad, `adsToday` pushed
/// ads today, `rewardedToday` rewarded ads today. Already rolled to today by whoever builds the inputs.
struct SyncedAdCounters: Equatable {
    var lastAdAt: Date?
    var adsToday = 0
    var rewardedToday = 0
}

/// What the rewarded rows need to know (spec section 2).
struct PerkContext: Equatable {
    var water = 1
    var whisperBanked = false
    var wakeDreamsInARow = 0
    /// The resting card says "A short ad may play first." (R2 never stacks a second ad prompt under it).
    var shortAdNoteShowing = false
}

struct AdInputs: Equatable {
    var ageBand: AgeBand?
    var hasPlus = false
    var entitlementsLoaded = true
    var quietGarden = false
    var calm = false
    var onboardingComplete = true
    var completedSessions = 0
    var now: Date
    var isNight = false
    var roundInProgress = false        // game.phase == .playing
    var aroundDailyBloom = false
    var lastRoundWasLoss = false
    var pendingCeremony = false
    var reduceMotion = false
    var voiceOverOrSwitchControl = false
    var accessibilityTextSize = false
    /// The Plus page or the Seasons page is the current screen: no ad of any kind there.
    var onPaywall = false
    /// A sheet that is not our own ad is up (StoreKit purchase, consent form, tracking prompt, offer code, manage
    /// subscriptions, the grown-up question): no full-screen ad.
    var sheetUp = false
    /// An empty unit id switches that format off (app open and native have no fallback to another format).
    var appOpenUnitSet = true
    var nativeUnitSet = true
    var session = AdSessionState()
    var ledger = AdLedger()
    var synced = SyncedAdCounters()
    var interstitial: AdGate.Context
    var perk = PerkContext()

    init(ageBand: AgeBand?, now: Date) {
        self.ageBand = ageBand
        self.now = now
        self.interstitial = AdGate.Context(now: now)
    }
}

enum AdDecision: Equatable {
    case no(AdBlock), yes(AdTreatment)
    var isYes: Bool {
        if case .yes = self { return true }
        return false
    }
}

enum AdBlock: Equatable {
    case ageOrPlus, notLoaded, onboarding, grace, puzzle, quiet, calm, night, daily, loss, ceremony,
         consentPending, firstSession, background, link, gap, dayCap, sessionCap, formatCap, accessibility, notApplicable,
         paywall, sheetUp, noFill
}

/// How a rewarded perk is offered: not at all, free (no video), or with a video.
enum PerkPath: Equatable { case hidden, free, ad(AdTreatment) }

enum AdPolicy {
    // MARK: Who sees ads (spec 0.1)

    /// The whole safety claim in one function. `AdGate.mayLoadAnyAd` and the ad service read it too.
    static func treatment(ageBand: AgeBand?, hasPlus: Bool) -> AdTreatment {
        guard !hasPlus else { return .none }
        switch ageBand {
        case .eighteenPlus: return .adult
        case .thirteenPlus: return .teen
        case .under13, nil: return .none
        }
    }

    /// Under 13 and an unknown age (the grown-up question's rule, `ParentalGate.isRequired`).
    static func isYoungOrUnknown(_ ageBand: AgeBand?) -> Bool { ageBand == nil || ageBand == .under13 }

    /// The tracking prompt: adults without Plus only. Teens never see it.
    static func mayAskTracking(ageBand: AgeBand?, hasPlus: Bool) -> Bool { treatment(ageBand: ageBand, hasPlus: hasPlus) == .adult }

    // MARK: Decide

    static func decide(_ format: AdFormat, _ i: AdInputs, caps: AdCaps = .current) -> AdDecision {
        let t = treatment(ageBand: i.ageBand, hasPlus: i.hasPlus)
        guard t != .none else { return .no(.ageOrPlus) }            // first, before any other input is read
        if let block = commonBlock(format, i) { return .no(block) }
        if let block = formatBlock(format, i, caps: caps) { return .no(block) }
        return .yes(t)
    }

    /// The calm guarantees every format obeys (spec 0.3), after the treatment.
    private static func commonBlock(_ f: AdFormat, _ i: AdInputs) -> AdBlock? {
        if !i.entitlementsLoaded { return .notLoaded }
        if !i.onboardingComplete { return .onboarding }
        if i.onPaywall { return .paywall }
        if i.roundInProgress { return .puzzle }
        if i.session.quietVisit { return .quiet }
        if i.pendingCeremony { return .ceremony }
        if f.isFullScreen && i.sheetUp { return .sheetUp }
        return nil
    }

    private static func formatBlock(_ f: AdFormat, _ i: AdInputs, caps: AdCaps) -> AdBlock? {
        switch f {
        case .banner:
            return i.completedSessions >= 1 ? nil : .firstSession
        case .collapsible:
            if i.completedSessions < 1 { return .firstSession }
            if i.completedSessions < caps.collapsibleMinSessions { return .grace }
            if i.calm { return .calm }
            if i.quietGarden { return .quiet }
            if i.voiceOverOrSwitchControl || i.accessibilityTextSize { return .accessibility }
            if i.session.collapsibleShown >= caps.collapsiblePerSession { return .sessionCap }
            if i.ledger.collapsible >= caps.collapsiblePerDay { return .formatCap }
            return nil
        case .interstitial(let choice):
            var c = i.interstitial
            c.choice = choice
            if !AdGate.shouldShowInterstitial(c) { return interstitialReason(c) }
            return fullScreenBudgetBlock(f, i, caps: caps)
        case .appOpen:
            if !i.appOpenUnitSet { return .notApplicable }
            if i.completedSessions < caps.appOpenMinSessions { return .grace }
            if i.calm { return .calm }
            if i.quietGarden { return .quiet }
            if i.isNight { return .night }
            if !i.session.consentResolved || !i.session.attResolved { return .consentPending }
            if i.session.launchedFromLink { return .link }
            if i.session.roundWasInProgressAtBackground { return .puzzle }
            let away = i.session.lastBackgroundAt ?? i.ledger.lastBackgroundAt
            guard let away, i.now.timeIntervalSince(away) >= caps.appOpenMinBackground else { return .background }
            if i.ledger.appOpen >= caps.appOpenPerDay { return .formatCap }
            if !gapMet(since: lastFullScreen(i), now: i.now, gap: caps.gapToAppOpen) { return .gap }
            return fullScreenBudgetBlock(f, i, caps: caps)
        case .native:
            if !i.nativeUnitSet { return .notApplicable }
            if i.completedSessions < caps.nativeMinSessions { return .grace }
            if !i.session.consentResolved { return .consentPending }
            if i.ledger.nativeLoads >= caps.nativeLoadsPerDay { return .formatCap }
            if !gapMet(since: i.ledger.lastNativeLoadAt, now: i.now, gap: caps.nativeLoadGap) { return .gap }
            return nil
        case .rewarded(let perk):
            if i.completedSessions < 1 { return .firstSession }
            if i.quietGarden { return .quiet }                          // no rewarded ad prompts in Quiet Garden
            if !perkApplies(perk, i) { return .notApplicable }
            if i.session.rewardedLoadFailed { return .noFill }
            if perkUsedToday(perk, i.ledger) >= caps.perPerkPerDay(perk) { return .formatCap }
            if i.synced.rewardedToday >= caps.rewardedPerDay { return .dayCap }
            if i.session.rewardedShown >= caps.rewardedPerSession { return .sessionCap }
            if !gapMet(since: lastFullScreen(i), now: i.now, gap: caps.gapToRewarded) { return .gap }
            return fullScreenBudgetBlock(f, i, caps: caps)
        }
    }

    /// The shared budgets (spec 1.1, ruled numbers): pushed per day and per visit, full-screen per day and per visit,
    /// and the gap from any full-screen ad to the next pushed one.
    private static func fullScreenBudgetBlock(_ f: AdFormat, _ i: AdInputs, caps: AdCaps) -> AdBlock? {
        if f.isPushed {
            if i.synced.adsToday >= caps.pushedPerDay { return .dayCap }
            if i.session.pushedShown >= caps.pushedPerSession { return .sessionCap }
            if !gapMet(since: lastFullScreen(i), now: i.now, gap: caps.gapToPushed) { return .gap }
        }
        if fullScreenToday(i) >= caps.fullScreenPerDay { return .dayCap }
        if i.session.fullScreenShown >= caps.fullScreenPerSession { return .sessionCap }
        return nil
    }

    /// Full-screen ads today: the device ledger, with the synced counts as a floor (they survive a reinstall).
    static func fullScreenToday(_ i: AdInputs) -> Int {
        max(i.ledger.fullScreen, i.synced.adsToday + i.synced.rewardedToday)
    }

    /// The later of the synced and the device record of the last full-screen ad.
    static func lastFullScreen(_ i: AdInputs) -> Date? {
        [i.synced.lastAdAt, i.ledger.lastFullScreenAt].compactMap { $0 }.max()
    }

    /// A clock that moved backwards counts as "gap not met"; a timestamp more than a day ahead of now is read as now
    /// (the ledger also rewrites it), so a wrong clock never locks ads out for good.
    static func gapMet(since last: Date?, now: Date, gap: TimeInterval) -> Bool {
        guard var last else { return true }
        if last.timeIntervalSince(now) > AdLedger.clockSlack { last = now }
        let elapsed = now.timeIntervalSince(last)
        return elapsed >= 0 && elapsed >= gap
    }

    /// Why `AdGate.shouldShowInterstitial` said no, in its own order (for the reason only; the decision is AdGate's).
    static func interstitialReason(_ c: AdGate.Context) -> AdBlock {
        if c.isUnderThirteen || c.hasRemoveAds { return .ageOrPlus }
        if c.choice != .oneMore && c.choice != .playSoonAfterEnough { return .notApplicable }
        if c.isNight { return .night }
        if c.midRound { return .puzzle }
        if c.aroundDailyBloom { return .daily }
        if c.lastRoundWasLoss { return .loss }
        if c.roundsSinceAd < c.frequency { return .formatCap }
        if c.completedSessions < 1 { return .firstSession }
        if c.completedSessions < 3 && c.wordLevelUps < 1 { return .grace }
        if let last = c.lastAdAt, c.now.timeIntervalSince(last) < c.minGapSeconds { return .gap }
        if c.adsToday >= c.maxPerDay { return .dayCap }
        return .ceremony                                                  // the celebration's quiet window
    }

    // MARK: Rewarded perks (spec section 2, with the rulings)

    /// Whether the perk's row belongs on screen at all, for anyone (ad or free).
    static func perkApplies(_ perk: RewardedPerk, _ i: AdInputs) -> Bool {
        switch perk {
        case .water:
            return i.perk.water == 0 && !i.quietGarden                    // Quiet Garden never uses drops
        case .hint:
            // Never after a loss, on the Daily Bloom card, in Quiet Garden (one rule for every age and Plus), or
            // under the "A short ad may play first." note. A banked whisper shows a line, not a button.
            return !i.lastRoundWasLoss && !i.aroundDailyBloom && !i.quietGarden && !i.perk.shortAdNoteShowing && !i.perk.whisperBanked
        case .wake:
            return i.perk.wakeDreamsInARow >= 1                            // after one "still dreaming" try
        }
    }

    /// Ad and free uses of one perk today (the same cap for both paths).
    static func perkUsedToday(_ perk: RewardedPerk, _ l: AdLedger) -> Int {
        switch perk {
        case .water: l.adWater + l.freeWater
        case .hint: l.adHint + l.freeHint
        case .wake: l.adWake + l.freeWake
        }
    }

    /// Plus, under 13 and an unknown age get the perk free (no video, no prompt to watch) and read only the per-perk
    /// day cap, never the visit or full-screen budgets (ruling H7). Teens and adults get the video when `decide` says
    /// yes, else nothing.
    static func path(_ perk: RewardedPerk, _ i: AdInputs, caps: AdCaps = .current) -> PerkPath {
        let t = treatment(ageBand: i.ageBand, hasPlus: i.hasPlus)
        if t == .none {
            guard i.entitlementsLoaded, i.onboardingComplete, !i.onPaywall, !i.roundInProgress, !i.session.quietVisit,
                  i.completedSessions >= 1, perkApplies(perk, i),
                  perkUsedToday(perk, i.ledger) < caps.perPerkPerDay(perk) else { return .hidden }
            return .free
        }
        if case .yes(let tt) = decide(.rewarded(perk), i, caps: caps) { return .ad(tt) }
        return .hidden
    }
}
