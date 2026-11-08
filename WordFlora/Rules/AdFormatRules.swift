import Foundation

// G4b: the pure rules around the three new formats (docs/pm/g4b-builder-brief.md sections 2 to 4). Every format still
// goes through `AdPolicy.decide`, which checks the age-and-Plus treatment first; these helpers only add what decide
// cannot see (the screen the player is on, a cached treatment before the store answers, a cached native ad, the
// collapsible handoff). No age or Plus check lives here except through `AdPolicy.treatment`.

/// The consent answers the formats read (ruling H1: app open and native never ask; they only read what is settled).
struct AdConsentSnapshot: Equatable {
    /// The consent status is obtained or not required.
    var consentResolved = false
    /// The consent SDK says ads may be requested.
    var canRequestAds = false
    /// The tracking answer is known (adults only; teens are never asked).
    var trackingResolved = false
}

enum AdConsentRules {
    /// `AdSessionState.consentResolved` and `attResolved` for a treatment. `.none` reads nothing and resolves nothing.
    static func resolved(_ t: AdTreatment, _ s: AdConsentSnapshot) -> (consent: Bool, att: Bool) {
        switch t {
        case .none: return (false, false)
        case .teen: return (s.consentResolved && s.canRequestAds, true)       // teens never get the tracking prompt
        case .adult: return (s.consentResolved && s.canRequestAds, s.trackingResolved)
        }
    }
}

extension AdLedger {
    /// H4: the treatment last confirmed by the store, or nil when never confirmed.
    var lastTreatment: AdTreatment? {
        get {
            switch cachedTreatment {
            case "none": return AdTreatment.none
            case "teen": return .teen
            case "adult": return .adult
            default: return nil
            }
        }
        set {
            switch newValue {
            case .some(.none): cachedTreatment = "none"
            case .some(.teen): cachedTreatment = "teen"
            case .some(.adult): cachedTreatment = "adult"
            case nil: cachedTreatment = ""
            }
        }
    }
}

// MARK: App open (spec 1.2, rulings H1, H3, H4)

/// What is on screen when the app comes back. The return cue never covers any of these.
struct AppOpenScreen: Equatable {
    var onboarding = false
    var tutorial = false
    /// The puzzle (a word in progress, its result or the Daily Bloom result), the butterfly round, Plus or Seasons.
    var blockedRoute = false
    /// Any presented controller: our own sheets, the consent form, a purchase sheet, the grown-up question.
    var sheetUp = false
    /// A badge moment is on screen.
    var badgeMoment = false
}

enum AppOpenFlow {
    enum Start: Equatable {
        case none(AdBlock)
        /// Raise the cue. `awaitingEntitlements`: a cold launch before the store answered, raised from the cached
        /// treatment (H4); the ad is presented only after the store confirms.
        case cue(AdTreatment, awaitingEntitlements: Bool)
    }

    /// Whether the return cue goes up as the app becomes active.
    static func start(_ i: AdInputs, cachedTreatment: AdTreatment?, screen: AppOpenScreen, caps: AdCaps = .current) -> Start {
        var j = i
        if !i.entitlementsLoaded {
            // H4: before the store answers, only a cached ad treatment may raise the cue; a cached none (Plus last
            // time) or no cache means no cue at all.
            guard let cached = cachedTreatment, cached != .none else { return .none(.notLoaded) }
            j.entitlementsLoaded = true
            j.hasPlus = false
        }
        guard AdPolicy.treatment(ageBand: j.ageBand, hasPlus: j.hasPlus) != .none else { return .none(.ageOrPlus) }
        if screen.onboarding { return .none(.onboarding) }
        if screen.tutorial || screen.blockedRoute { return .none(.puzzle) }
        if screen.sheetUp { return .none(.sheetUp) }
        if screen.badgeMoment { return .none(.ceremony) }
        switch AdPolicy.decide(.appOpen, j, caps: caps) {
        case .no(let b): return .none(b)
        case .yes(let t): return .cue(t, awaitingEntitlements: !i.entitlementsLoaded)
        }
    }

    /// Right before presenting: the store has answered, the live rules still say yes (so Plus, an under-13 answer or a
    /// new sheet stops it), the cue is still up and not skipped, and the ad arrived within the load budget.
    static func mayPresent(_ i: AdInputs, screen: AppOpenScreen, cueUp: Bool, skipped: Bool, elapsed: TimeInterval,
                           caps: AdCaps = .current) -> Bool {
        guard i.entitlementsLoaded, cueUp, !skipped, elapsed <= caps.appOpenLoadBudget else { return false }
        guard case .cue(_, false) = start(i, cachedTreatment: nil, screen: screen, caps: caps) else { return false }
        return true
    }
}

// MARK: Collapsible Garden banner (spec 1.3)

enum CollapsibleRules {
    /// True: the first Garden banner request of this ad visit carries the collapsible extras. False: the ordinary
    /// Garden banner (VoiceOver, Switch Control, the accessibility text sizes, Calm and Quiet Garden all get it).
    static func wantsCollapsible(_ i: AdInputs, requestedThisVisit: Bool, caps: AdCaps = .current) -> Bool {
        guard !requestedThisVisit, AdPolicy.decide(.banner(.garden), i, caps: caps).isYes else { return false }
        return AdPolicy.decide(.collapsible, i, caps: caps).isYes
    }

    /// Counted only when Google really returned a collapsible ad (a plain one can come back for the same request).
    static func record(isCollapsible: Bool, session: inout AdSessionState, ledger: inout AdLedger) {
        guard isCollapsible else { return }
        session.collapsibleShown += 1
        ledger.collapsible += 1
    }

    /// Option (a): one banner view has one unit id. A plain ad from the collapsible unit (refresh off) is swapped for
    /// the Garden unit at once; a collapsible one stays until it is collapsed or the refresh interval passes.
    static func swapNow(requestedCollapsible: Bool, isCollapsible: Bool) -> Bool { requestedCollapsible && !isCollapsible }

    /// The Garden unit's refresh interval; a collapsed collapsible ad is swapped after this long at most.
    static let swapAfter: TimeInterval = 60
}

// MARK: Native Shed card (spec 1.4)

/// A loaded native ad as the rules see it.
struct NativeAdSlot: Equatable {
    var loadedAt: Date
    var hasVideo: Bool
}

enum NativeAdRules {
    enum Step: Equatable {
        /// Show the cached ad.
        case show
        /// Load one ad with this treatment.
        case load(AdTreatment)
        /// Show nothing (no header either). `dropCached`: release the cached ad.
        case nothing(AdBlock, dropCached: Bool)
    }

    /// A loaded ad is reused across Shed visits for 30 minutes, then dropped (Google's ceiling is an hour).
    static func isFresh(_ slot: NativeAdSlot, now: Date, caps: AdCaps = .current) -> Bool {
        let age = now.timeIntervalSince(slot.loadedAt)
        return age >= 0 && age < caps.nativeReuse
    }

    /// Calm and Reduce Motion never show a video ad (there is no image-only switch in the loader).
    static func mayDisplay(hasVideo: Bool, calm: Bool, reduceMotion: Bool) -> Bool { !(hasVideo && (calm || reduceMotion)) }

    /// The rules for showing a cached ad: everything `decide` checks except the load gap and the daily load cap.
    static func mayShowCached(_ i: AdInputs, caps: AdCaps = .current) -> Bool {
        var c = caps
        c.nativeLoadGap = 0
        c.nativeLoadsPerDay = .max
        return AdPolicy.decide(.native, i, caps: c).isYes
    }

    /// What the Shed does when it appears.
    static func onShedAppear(_ i: AdInputs, cached: NativeAdSlot?, videoDroppedThisVisit: Bool, loading: Bool,
                             caps: AdCaps = .current) -> Step {
        guard AdPolicy.treatment(ageBand: i.ageBand, hasPlus: i.hasPlus) != .none else { return .nothing(.ageOrPlus, dropCached: true) }
        if let cached, isFresh(cached, now: i.now, caps: caps) {
            guard mayDisplay(hasVideo: cached.hasVideo, calm: i.calm, reduceMotion: i.reduceMotion) else { return .nothing(.calm, dropCached: true) }
            return mayShowCached(i, caps: caps) ? .show : .nothing(.notApplicable, dropCached: false)
        }
        let stale = cached != nil
        if videoDroppedThisVisit { return .nothing(.calm, dropCached: stale) }
        if loading { return .nothing(.notApplicable, dropCached: stale) }
        switch AdPolicy.decide(.native, i, caps: caps) {
        case .yes(let t): return .load(t)
        case .no(let b): return .nothing(b, dropCached: stale)
        }
    }

    /// Whether the Shed shows the "SPONSORED" section now (pure read for the view; no load, no side effect).
    static func shows(_ i: AdInputs, slot: NativeAdSlot?, caps: AdCaps = .current) -> Bool {
        guard let slot, isFresh(slot, now: i.now, caps: caps),
              mayDisplay(hasVideo: slot.hasVideo, calm: i.calm, reduceMotion: i.reduceMotion) else { return false }
        return mayShowCached(i, caps: caps)
    }
}
