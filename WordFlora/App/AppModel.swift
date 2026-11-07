import SwiftUI
import SwiftData

/// Composition root: owns the store, settings, the round view model and first-session flow.
@Observable
@MainActor
final class AppModel {
    let container: ModelContainer
    let settings: AppSettings
    let game: GameViewModel
    let bank: WordBank
    var onboarding: OnboardingFlow
    private(set) var badges = BadgeState(defs: [])
    let entitlements: EntitlementService
    let ads = AdsService()
    let reminders: ReminderScheduler
    private var lastPeakAt: Date?
    /// Master switch used by UI tests; real launches always have ads available (subject to every rule in AdGate).
    var adsEnabled = true
    /// True when this launch opened the iCloud-synced store.
    let launchedWithCloud: Bool
    private(set) var syncNeedsRestart = false
    private(set) var showWelcomeBack = false
    private(set) var welcomeLine = WelcomeBack.lines[0]
    /// True when the saved garden could not be opened and this launch is running on a temporary store.
    let storeDegraded: Bool
    static let degradedStoreMessage = "We couldn't open your saved garden just now. Please close and reopen the app. Your saved garden is safe."
    private var lastBadgedRoundId: String?
    let now: () -> Date
    /// The model's clock (tests pass a fixed one).
    var nowDate: Date { now() }
    /// UI tests only (`-uitest-forecast=`, `-uitest-weather=`): replaces the weather schedule; every gate still applies.
    var weatherTestOverride: GardenWeather.Override?
    /// Tests and `-uitest-quest=<kind>`: today's quest kind (every other quest rule still applies).
    var questTestOverride: QuestKind?
    /// Tests and `-uitest-tidytrim`: every day is a faded bloom day (stage, shears and the shears' rest still apply).
    var fadedBloomTestOverride = false
    /// UI tests leave the quest card off unless they ask for it with `-uitest-quest`, so older layouts stay as tested.
    var questHiddenForUITests = false
    /// This visit showed an ending ceremony or the weather puzzle: no Plus card and no ads for the rest of it
    /// (endgame-and-events spec 2.4 and 8). Set by `markQuietVisit()`; a new launch starts clear.
    private(set) var quietVisit = false
    func markQuietVisit() { quietVisit = true }

    var context: ModelContext { container.mainContext }

    init(container: ModelContainer, settings: AppSettings = AppSettings(), bank: WordBank? = nil, now: @escaping () -> Date = { .now }, storeEnabled: Bool = false,
         notifications: NotificationCenterProviding = SystemNotificationCenter(), launchedWithCloud: Bool = false, storeDegraded: Bool = false) {
        self.storeDegraded = storeDegraded
        self.launchedWithCloud = launchedWithCloud
        self.now = now
        self.reminders = ReminderScheduler(center: notifications)
        self.entitlements = EntitlementService(startListening: storeEnabled)
        self.container = container
        self.settings = settings
        let loaded = bank ?? (try? WordBank.load()) ?? WordBank(schemaVersion: 1, bankVersion: "empty", entries: [],
                                                            daily: DailyConfig(epoch: "2026-01-01", seed: 1))
        self.bank = loaded
        self.game = GameViewModel(modelContext: container.mainContext, bank: loaded, now: now)
        self.onboarding = OnboardingFlow(restoredComplete: settings.onboardingComplete, ageBand: settings.ageBand)
        game.soundEnabled = settings.soundOn
        game.ai = GardenAIProvider.current(); game.aiIsModelBacked = GardenAIProvider.isModelBacked()
        game.speedBloomPrefs = { [weak settings] in settings?.speedBloomPrefs ?? .off }
        game.seedPlantsIfNeeded()
        reconcileSyncedData()
        SoundPlayer.configureSession()
        if settings.onboardingComplete { settings.completedSessions += 1 }
        if settings.remindMe { reminders.restore() }
        let defs = (try? BadgeCatalog.load()) ?? []
        badges = BadgeState(json: game.playerProfile?.badgesJSON ?? "", defs: defs)
        refreshFreeDrops()
        refreshBadgeFacts(announce: false)       // badges added in an update arrive quietly for what is already done
        checkWelcomeBack()
        GardenIntentHost.container = container
    }

    /// Evaluated at launch and every time the app comes to the front, so a resume after a long absence is noticed too.
    func checkWelcomeBack() {
        guard settings.onboardingComplete else { return }
        if WelcomeBack.shouldShow(lastOpened: settings.lastOpenedAt, now: now(), calendar: .current) {
            showWelcomeBack = true
            welcomeLine = WelcomeBack.lines[abs(Int(now().timeIntervalSince1970 / 86_400)) % WelcomeBack.lines.count]
        }
        settings.lastOpenedAt = now()
    }

    func dismissWelcomeBack() { showWelcomeBack = false }

    // MARK: Data

    /// Merges duplicates that iCloud sync can create, then reloads what depends on them.
    func reconcileSyncedData() {
        let defs = (try? BadgeCatalog.load()) ?? []
        DataReconciler.reconcile(context: context, badgeDefs: defs)
        game.reloadProfile()
        game.refreshLevel()
        badges = BadgeState(json: game.playerProfile?.badgesJSON ?? "", defs: defs)
        refreshWeather()          // a seed for a new garden, the clock high-water mark and the gate day
    }

    /// Merges a garden backup file best-of-each, then reloads what depends on the profile.
    func restoreGarden(from data: Data) -> Result<GardenBackup.RestoreReport, GardenBackup.ImportError> {
        let defs = (try? BadgeCatalog.load()) ?? []
        let result = GardenBackup.restore(data, into: context, badgeDefs: defs)
        if case .success = result { reconcileSyncedData(); syncToolUnlocks(); refreshBadgeFacts(announce: false) }
        return result
    }

    func plants() -> [PlantCollectible] {
        let d = FetchDescriptor<PlantCollectible>(sortBy: [SortDescriptor(\.level), SortDescriptor(\.name)])
        return (try? context.fetch(d)) ?? []
    }

    var profile: PlayerProfile? { game.playerProfile }

    var unlockStats: UnlockStats {
        let p = profile
        var s = UnlockStats()
        s.plantsEarned = plants().filter { $0.earnedCount > 0 }.count
        s.gardenDays = p?.gardenDays ?? 0
        s.badgesEarned = badges.unlocked.count
        s.wordLevelUps = max(0, (p?.currentLevel ?? 1) - 1)
        s.sawTwoPetalsLeft = (p?.roseSeedProgress ?? 0) > 0 || (p?.roseOfJerichoCount ?? 0) > 0 || game.petalsRemaining <= 2
        return s
    }

    func isUnlocked(_ f: Feature) -> Bool {
        FeatureUnlockPolicy.isUnlocked(f, stats: unlockStats, showEverything: settings.showEverything)
    }

    // MARK: Onboarding

    func finishOnboarding() {
        settings.onboardingComplete = true
        onboarding.skip()
    }

    /// The Quiet Garden offer after "Under 13" (age defaults already applied): Yes also turns Quiet Garden on; either
    /// answer picks under 13 and moves on, keeping a guide already seen on another device.
    func answerQuietOffer(keepQuiet: Bool) {
        if keepQuiet { settings.quietGarden = true }
        onboarding.selectAge(.under13, guideSeen: profile?.guideSeen ?? false)
    }

    /// The guide closed (Skip, Start playing, Close or Done). Records it on the synced profile and, in the first
    /// session, moves on to the tutorial word. Writes nothing else: nothing earned changes.
    func finishGuide() {
        if let p = profile, !p.guideSeen { p.guideSeen = true; try? context.save() }
        onboarding.guideFinished()
    }

    // MARK: Tools and tending

    var inventory: ToolInventory {
        get { ToolInventory(json: profile?.toolsJSON ?? "") }
        set { profile?.toolsJSON = newValue.json; try? context.save() }
    }

    enum TendAction: Equatable { case water, feed, sun, prune, mist, repot(SoilType) }

    /// The Mist button shows once the mister is in the Shed, with Show everything, or in Quiet Garden (no tool needed).
    var showsMist: Bool { inventory.tier(of: .mister) > 0 || settings.showEverything || settings.quietGarden }

    struct TendOutcome: Equatable {
        var applied: Bool
        var stageUp = false
        var message: String
        /// Pruning Pro: this trim snipped a faded bloom (the plant page drops a dry petal).
        var tidy = false
    }

    func refreshFreeDrops() {
        guard let p = profile else { return }
        ToolEngine.applyTrickle(p, inventory: inventory, now: now(), economy: .default)   // the mister speeds the drops
        // Mist Maker counts real mists now (`.mistSprays` in `tend`); the old `mists` drop count stays in the JSON only.
        try? context.save()
    }

    // MARK: Love (petals, rain, seed)

    /// No rain and no seeds: Quiet Garden, Calm, and every player under 13 (owner ruling). The widget reads the same rule
    /// from the shared defaults (`SharedDefaults.loveExempt`).
    var loveExempt: Bool { settings.quietGarden || settings.calmMode || settings.isUnderThirteen }

    func loveState(_ plant: PlantCollectible) -> LoveEngine.State {
        LoveEngine.state(lastLoved: plant.lastLovedAt, now: now(), exempt: loveExempt)
    }

    /// A tap hello, or any tending, counts as love. A seed ignores it until it has been woken.
    func love(_ plant: PlantCollectible) {
        guard !loveState(plant).isSeed else { return }
        plant.lastLovedAt = now(); try? context.save()
        recordQuestCare(nil)
    }

    /// The plant's short answer to a tap hello (PlantVoice), seeded like the tend lines; `tap` moves to the next line.
    func helloLine(_ plant: PlantCollectible, tap: Int) -> String {
        let day = Int(now().timeIntervalSince1970 / 86_400) &+ plant.earnedCount
        return PlantVoice.helloLine(plantId: plant.plantId, daySeed: day, tap: tap)
    }

    /// Called when a wake-up challenge succeeds.
    func wake(_ plant: PlantCollectible) {
        plant.lastLovedAt = now(); try? context.save()
    }

    /// The plant page records the love petal count it last animated, so a fall or regrowth plays once per change.
    func markPetalsShown(_ plant: PlantCollectible, pips: Int) {
        guard plant.lastShownPips != pips else { return }
        plant.lastShownPips = pips; try? context.save()
    }

    // MARK: Wake the seed

    /// The seed card (and its quiet "Wake" button) shows only for a seed; Quiet Garden and Calm mode never make one.
    func showsWakeCard(_ plant: PlantCollectible) -> Bool { loveState(plant).isSeed }

    var wakeSuggestion: WakeChallenge { WakeRule.suggestion(last: settings.lastWakeChallenge, lastResult: settings.lastWakeResult) }
    var wakeIsEasier: Bool { WakeRule.isEasier(dreamsInARow: settings.wakeDreamsInARow) }
    var wakeButterflyGoal: Int { WakeRule.butterflyGoal(dreamsInARow: settings.wakeDreamsInARow) }

    /// Today's word puzzle for this seed: a name from the plants the player has found when there are enough, else any.
    func wakePuzzle(for plant: PlantCollectible) -> WakePuzzle? {
        let all = plants()
        let found = all.filter { $0.earnedCount > 0 }.map(\.name)
        let names = WakePuzzle.candidates(from: found).count >= 3 ? found : all.map(\.name)
        return WakePuzzle.make(plantId: plant.plantId, day: WakePuzzle.day(for: now()), names: names, easier: wakeIsEasier,
                               meanings: plantMeanings)
    }

    /// The one-line meaning clue for each plant name, from the word bank's plant clues (wake and gentle weather puzzles).
    var plantMeanings: [String: String] { WakePuzzle.meanings(from: bank.entries) }

    /// Records a wake try. A win wakes the seed; "still dreaming" changes nothing but the next suggestion.
    func finishWake(_ plant: PlantCollectible, challenge: WakeChallenge, woke: Bool) {
        settings.lastWakeChallenge = challenge
        settings.lastWakeResult = woke ? .woke : .stillDreaming
        settings.wakeDreamsInARow = woke ? 0 : settings.wakeDreamsInARow + 1
        if woke { wake(plant); play(.wake) }
    }

    func tend(_ action: TendAction, plant: PlantCollectible) -> TendOutcome {
        guard let p = profile else { return TendOutcome(applied: false, message: "Something went wrong. Try again.") }
        if loveState(plant).isSeed { return TendOutcome(applied: false, message: LoveEngine.seedLine(name: plant.nickname.isEmpty ? plant.name : plant.nickname)) }
        let quiet = settings.quietGarden
        let date = now(), cal = Calendar.current, eco = Economy.default
        let inv = inventory
        var result = TendResult()
        var repotOutcome: RepotResult.Outcome?
        // Pruning Pro: read the cue before the trim, which starts the shears' rest and so ends the cue.
        let tidy: Bool = { if case .prune = action { return showsFadedBloom(plant) } else { return false } }()

        switch action {
        case .water: result = ToolEngine.waterWithCan([plant], profile: p, inventory: inv, now: date, calendar: cal, economy: eco, quiet: quiet).first ?? .blocked(.noWater)
        case .feed: result = ToolEngine.addSoil(plant, profile: p, inventory: inv, now: date, calendar: cal, economy: eco, quiet: quiet)
        case .sun: result = ToolEngine.sunWithLamp(plant, profile: p, inventory: lampOrBasic(inv), now: date, calendar: cal, economy: eco, quiet: quiet)
        case .prune: result = ToolEngine.prune(plant, inventory: inv, now: date, calendar: cal, economy: eco, quiet: quiet)
        case .mist: result = ToolEngine.mist(plant, inventory: inv, traits: traits(of: plant), now: date, calendar: cal, economy: eco, quiet: quiet)
        case .repot(let soil):
            let r = ToolEngine.repot(plant, to: soil, profile: p, now: date, calendar: cal, economy: eco, quiet: quiet)
            result = r.applied ? TendResult(applied: true, gpGained: r.tend.gpGained, stageUp: r.tend.stageUp) : .blocked(.noSoil)
            repotOutcome = r.outcome
        }

        guard result.applied else { return TendOutcome(applied: false, message: Self.message(for: result.reason, action: action, plant: plant)) }

        plant.lastLovedAt = date
        let turnedGolden = recordGoldenDay(plant, tending: action, at: date)
        let counter: BadgeCounter = { switch action { case .water: return .waterings; case .feed: return .feeds; case .prune: return .prunes; case .repot: return .repots; case .sun: return .suns; case .mist: return .mistSprays } }()
        var unlocks = badges.record(counter, now: date, quiet: quiet)
        if repotOutcome == .happy { unlocks += badges.recordMark(.soilMatches, item: plant.plantId, now: date, quiet: quiet) }   // each plant once
        if tidy { unlocks += badges.record(.tidyTrims, now: date, quiet: quiet) }       // Pruning Pro: a trim at the right time
        unlocks += badges.recordDay(.tendDays, day: BadgeFacts.dayNumber(date, calendar: cal), now: date, quiet: quiet)
        if result.stageUp {
            unlocks += recordCollectionFacts(now: date, quiet: quiet)     // in flower, full bloom
            unlocks += Self.recordLanternKeeperGrowth(plant, into: &badges, on: date, quiet: quiet)
        }
        // The tidy trim's line stays up on its own first (at least 1.2 s) before a badge moment.
        enqueueBadgeMoments(unlocks, after: tidy ? 1.6 : 1.0); p.badgesJSON = badges.json
        try? context.save()
        recordQuestCare(action)

        let name = plant.nickname.isEmpty ? plant.name : plant.nickname
        if turnedGolden { return TendOutcome(applied: true, message: EndgameCopy.goldenLine(name: name), tidy: tidy) }
        let day = Int(date.timeIntervalSince1970 / 86_400) &+ plant.earnedCount
        let event: PlantVoice.Event = { switch action { case .water, .mist: return .water; case .feed, .repot: return .soil; case .sun: return .sun; case .prune: return .prune } }()
        if case .mist = action, !result.stageUp {
            // Mist Maker's own lines: "Fern loves misty air!" for the +2 plants, else "Daisy has fresh, misty leaves."
            let line = ToolEngine.mistGrowth(traits: traits(of: plant)) > 1 ? MistMakerCopy.loves(name: name) : MistMakerCopy.misted(name: name)
            return TendOutcome(applied: true, message: line)
        }
        if result.stageUp { return TendOutcome(applied: true, stageUp: true, message: "\(name) grew a little! " + PlantVoice.line(plantId: plant.plantId, event: .grew, daySeed: day), tidy: tidy) }
        if tidy {
            let line = PruningProCopy.tidy + " " + PruningProCopy.fact
            return TendOutcome(applied: true, message: quiet ? line : "\(line) +\(result.gpGained) growth", tidy: true)
        }
        if repotOutcome == .happy { return TendOutcome(applied: true, message: "\(name) loves its new pot!") }
        if repotOutcome == .neutral { return TendOutcome(applied: true, message: "Repotted.") }
        let voice = PlantVoice.line(plantId: plant.plantId, event: event, daySeed: day)
        return TendOutcome(applied: true, message: quiet ? voice : "\(voice) +\(result.gpGained) growth")
    }

    /// The sun tap is free for everyone; owning the lamp only makes it stronger.
    private func lampOrBasic(_ inv: ToolInventory) -> ToolInventory {
        var i = inv; i.unlock(.lamp); return i
    }

    // MARK: Action states (THE RULE: each action has its own done state, and a blocked tap says why and what next)

    struct ActionState: Equatable {
        enum Status: Equatable {
            /// The button works and visibly does something.
            case ready
            /// Today's allowance for this action is used up; its meter is full. More tomorrow.
            case done
            /// Today's allowance is there, but the can is dry or the scoops are out.
            case needsSupply
            /// The plant rests as a seed: every action waits until it is woken (tend refuses with the same line).
            case seed
        }
        var status: Status
        /// The button's words: the action name, or its done label ("Fed today").
        var label: String
        /// When not ready: the kind reason and next step a tap shows.
        var line: String?
        var isReady: Bool { status == .ready }
    }

    static let doneLabels = (water: "Had a drink", feed: "Fed today", sun: "Sunny today")
    static let wakeFirstLabel = "Wake first"

    /// What the plant page's buttons show before a tap, using the very same rules `tend` applies.
    func actionState(_ action: TendAction, plant: PlantCollectible) -> ActionState {
        let quiet = settings.quietGarden
        let date = now(), cal = Calendar.current, eco = Economy.default
        let name = Self.displayName(plant)
        let p = profile
        if loveState(plant).isSeed { return ActionState(status: .seed, label: Self.wakeFirstLabel, line: LoveEngine.seedLine(name: name)) }
        func state(_ care: TendingEngine.Care, label: String, done: String, supply: Bool, noSupply: TendResult.Reason) -> ActionState {
            if TendingEngine.isDone(care, plant: plant, now: date, calendar: cal, economy: eco) {
                return ActionState(status: .done, label: done, line: Self.message(for: .doneForToday, action: action, name: name))
            }
            if !quiet && !supply { return ActionState(status: .needsSupply, label: label, line: Self.message(for: noSupply, action: action, name: name)) }
            return ActionState(status: .ready, label: label, line: nil)
        }
        switch action {
        case .water: return state(.water, label: "Water", done: Self.doneLabels.water, supply: (p?.water ?? 0) > 0, noSupply: .noWater)
        case .feed: return state(.feed, label: "Feed", done: Self.doneLabels.feed, supply: (p?.soil ?? 0) > 0, noSupply: .noSoil)
        case .sun: return state(.sun, label: "Sun", done: Self.doneLabels.sun, supply: true, noSupply: .noWater)
        case .prune:
            if !quiet && inventory.tier(of: .shears) == 0 { return ActionState(status: .needsSupply, label: "Prune", line: Self.message(for: .notOwned, action: action, name: name)) }
            if let last = plant.lastPrunedAt, date.timeIntervalSince(last) < ToolEngine.pruneCooldownDays * 86_400 {
                return ActionState(status: .done, label: "Prune", line: Self.message(for: .cooldown, action: action, name: name))
            }
            return ActionState(status: .ready, label: "Prune", line: nil)
        case .mist:
            if !quiet && inventory.tier(of: .mister) == 0 { return ActionState(status: .needsSupply, label: MistMakerCopy.button, line: MistMakerCopy.needMister) }
            if let last = plant.lastMistedAt, cal.isDate(last, inSameDayAs: date) {
                return ActionState(status: .done, label: MistMakerCopy.doneLabel, line: MistMakerCopy.done(name: name))
            }
            return ActionState(status: .ready, label: MistMakerCopy.button, line: nil)
        case .repot:
            if !quiet && (p?.soil ?? 0) == 0 { return ActionState(status: .needsSupply, label: "Repot", line: Self.message(for: .noSoil, action: action, name: name)) }
            return ActionState(status: .ready, label: "Repot", line: nil)
        }
    }

    private static func displayName(_ plant: PlantCollectible) -> String { plant.nickname.isEmpty ? plant.name : plant.nickname }

    private static func message(for reason: TendResult.Reason?, action: TendAction, plant: PlantCollectible) -> String {
        message(for: reason, action: action, name: displayName(plant))
    }

    /// Grade-2 words, no banned words (CopySafety), and the plant's nickname when it has one.
    static func message(for reason: TendResult.Reason?, action: TendAction, name: String) -> String {
        switch reason {
        case .noWater: return TendCopy.canDry
        case .noSoil: return TendCopy.noScoops
        case .doneForToday:
            switch action {
            case .water: return TendCopy.done(.water, name: name)
            case .sun: return TendCopy.done(.sun, name: name)
            case .feed, .repot: return TendCopy.done(.feed, name: name)
            case .prune: return TendCopy.trimmed(name: name)
            case .mist: return MistMakerCopy.done(name: name)
            }
        case .notOwned: return action == .mist ? MistMakerCopy.needMister : TendCopy.needShears
        case .cooldown: return TendCopy.trimmed(name: name)
        case nil: return "Not right now."
        }
    }

    /// Every blocked line and done label, for the copy tests.
    static func ruleLines(name: String) -> [String] {
        let reasons: [TendResult.Reason?] = [.noWater, .noSoil, .doneForToday, .notOwned, .cooldown, nil]
        let actions: [TendAction] = [.water, .feed, .sun, .prune]
        return reasons.flatMap { r in actions.map { message(for: r, action: $0, name: name) } }
            + [doneLabels.water, doneLabels.feed, doneLabels.sun, wakeFirstLabel, LoveEngine.seedLine(name: name)]
    }

    // MARK: Ads (spec sections 12, 16, 18, 19; ruling in section 20)

    func markPeakDismissed() { lastPeakAt = now() }

    /// `-uitest-daytime`: UI tests that check the ad note judge the rules as by day, so they pass at any hour.
    var uiTestDaytime = false
    /// UI tests: a short butterfly round (`-uitest-butterfly-short`) and a fixed seed (`-uitest-butterfly-seed=`).
    var butterflyRoundOverride: Double?
    var butterflySeedOverride: UInt64?

    func adContext(choice: AdGate.Choice?) -> AdGate.Context {
        var c = AdGate.Context(now: now())
        let p = profile
        c.roundsSinceAd = p?.roundsSinceAd ?? 0
        c.choice = choice
        c.isUnderThirteen = ParentalGate.isRequired(ageBand: settings.ageBand)     // unknown age is treated as young
        c.hasRemoveAds = entitlements.state.hasRemoveAds
        c.midRound = game.phase == .playing
        c.aroundDailyBloom = game.isDaily
        c.lastRoundWasLoss = game.lastRoundWasLoss
        c.completedSessions = settings.completedSessions
        c.wordLevelUps = max(0, (p?.currentLevel ?? 1) - 1)
        c.lastAdAt = p?.lastAdAt
        if let day = p?.adsDay, Calendar.current.isDate(day, inSameDayAs: now()) { c.adsToday = p?.adsToday ?? 0 }
        c.lastPeakAt = lastPeakAt
        c.isNight = AdGate.isNight(c.now) && !uiTestDaytime
        return c
    }

    func recordAdShown() {
        guard let p = profile else { return }
        let d = now(), cal = Calendar.current
        p.roundsSinceAd = 0
        adShownThisSession = true
        p.lastAdAt = d
        if let day = p.adsDay, cal.isDate(day, inSameDayAs: d) { p.adsToday += 1 } else { p.adsDay = cal.startOfDay(for: d); p.adsToday = 1 }
        try? context.save()
    }

    var canOfferRewarded: Bool {
        guard let p = profile else { return false }
        guard settings.completedSessions >= 1, entitlements.hasLoaded,
              !ParentalGate.isRequired(ageBand: settings.ageBand), !entitlements.state.hasRemoveAds else { return false }
        let today = p.rewardedDay.map { Calendar.current.isDate($0, inSameDayAs: now()) } ?? false
        return (today ? p.rewardedToday : 0) < ButterflyRewards.rewardedPlaysPerDay
    }

    /// Two water drops per watched ad, three a day, never above the bank cap.
    func grantRewardedDrops() {
        guard let p = profile else { return }
        let d = now(), cal = Calendar.current
        if let day = p.rewardedDay, cal.isDate(day, inSameDayAs: d) { p.rewardedToday += 1 } else { p.rewardedDay = cal.startOfDay(for: d); p.rewardedToday = 1 }
        p.water = min(Economy.default.waterBankCap, p.water + 2)
        try? context.save()
    }

    /// Checked again after every wait inside ad setup, so changes mid-way (age, subscription) stop everything.
    var mayStillLoadAds: Bool {
        adsEnabled && entitlements.hasLoaded
            && AdGate.mayLoadAnyAd(isUnderThirteen: ParentalGate.isRequired(ageBand: settings.ageBand), hasRemoveAds: entitlements.state.hasRemoveAds)
    }

    /// Banner shows on Home and Garden only, from the second session, for free players who are not young.
    var showBanner: Bool {
        adsEnabled && !quietVisit && entitlements.hasLoaded && onboarding.isComplete && settings.completedSessions >= 1
            && AdGate.mayLoadAnyAd(isUnderThirteen: ParentalGate.isRequired(ageBand: settings.ageBand), hasRemoveAds: entitlements.state.hasRemoveAds)
    }

    /// Runs when the player taps "One more" on the resting card: at most one ad, only if every rule allows it.
    func adBeforeNextRound() async {
        guard adsEnabled, !quietVisit else { return }
        let ctx = adContext(choice: .oneMore)
        guard AdGate.shouldShowInterstitial(ctx) else { return }
        await ads.prepare(ageBand: settings.ageBand, isStillAllowed: { self.mayStillLoadAds })
        if await ads.showInterstitial() { recordAdShown() }
    }

    /// True when tapping "One more" on the resting card would try an ad, so the card can say so beside the button.
    /// The same rules as `adBeforeNextRound`, judged as of the end of the celebration's quiet window: the card opens
    /// the moment a celebration is dismissed, and the earliest deliberate tap comes after that window.
    var adWouldPlayOnOneMore: Bool {
        guard adsEnabled, !quietVisit else { return false }
        var ctx = adContext(choice: .oneMore)
        ctx.now = ctx.now.addingTimeInterval(ctx.peakWindowSeconds)
        return AdGate.shouldShowInterstitial(ctx)
    }

    // MARK: Coming back soon after "That's enough for now" (docs/pm/ad-gate-return-nudge.md)

    /// When the player last tapped "That's enough for now" on the resting card; cleared by their next Play on Home.
    private(set) var restExitAt: Date?

    /// The exit itself never plays or counts an ad; it only starts the 3 minute window.
    func markRestExit() { restExitAt = now() }

    /// What Home's Play does right now (AdGate.returnVisit): ordinary, "A short ad may play first.", or the nudge card.
    /// As with the resting card's note, the ad rules are judged as of the end of the celebration's quiet window, so a
    /// note decided as Home appears right after the last word still holds for the player's tap.
    var returnVisit: AdGate.ReturnVisit {
        let t = now()
        var ad = adContext(choice: .playSoonAfterEnough)
        ad.now = t.addingTimeInterval(ad.peakWindowSeconds)
        ad.isNight = AdGate.isNight(t) && !uiTestDaytime
        var r = AdGate.ReturnContext(now: t, enoughAt: restExitAt, ad: ad)
        r.calmMode = settings.calmMode
        r.quietGarden = settings.quietGarden
        r.adsAvailable = adsEnabled && !quietVisit
        return AdGate.returnVisit(r)
    }

    /// The player's Play tap on Home. True: start the round. False: show the nudge card (which can still play).
    /// The window is answered once: the next Play, from the nudge card or later, starts at once.
    /// `adNoteShown`: an ad only ever follows a Play that said "A short ad may play first."; otherwise the nudge.
    func playTappedOnHome(adNoteShown: Bool = true) async -> Bool {
        let visit = returnVisit
        restExitAt = nil
        switch visit {
        case .free: return true
        case .nudge: return false
        case .adMayPlay:
            guard adNoteShown else { return false }
            await ads.prepare(ageBand: settings.ageBand, isStillAllowed: { self.mayStillLoadAds })
            // An ad that cannot play (not loaded, offline, refused) brings the nudge, never a wait.
            guard mayStillLoadAds, await ads.showInterstitial() else { return false }
            recordAdShown()
            return true
        }
    }

    func prepareBannerIfAllowed() async {
        guard showBanner else { return }
        await ads.prepare(ageBand: settings.ageBand, isStillAllowed: { self.mayStillLoadAds })
    }

    /// Shows a player-initiated rewarded ad and, if completed, grants the drops.
    func watchRewardedAd() async -> Bool {
        guard adsEnabled, canOfferRewarded else { return false }
        await ads.prepare(ageBand: settings.ageBand, isStillAllowed: { self.mayStillLoadAds })
        let earned = await ads.showRewarded()
        adShownThisSession = true
        if earned { grantRewardedDrops() }
        return earned
    }

    // MARK: Gentle Plus offer (PlusOfferPolicy)

    /// Switched off for UI tests so launches stay deterministic.
    var plusOfferEnabled = true
    /// An interstitial or rewarded ad appeared during this launch; the Plus card then waits for another session.
    private(set) var adShownThisSession = false
    private(set) var plusOffer: PlusOfferPolicy.Milestone?

    /// Called when Home appears. Records the offer as soon as it shows, so it appears once per milestone.
    func checkPlusOffer() {
        // Never beside the weather, a ceremony or the weather puzzle.
        guard plusOfferEnabled, plusOffer == nil, !homeWeather.quietsOffers, !quietVisit, pendingCeremony == nil else { return }
        var c = PlusOfferPolicy.Context(now: now())
        c.ageBand = settings.ageBand
        c.hasPlus = entitlements.state.hasPlus
        c.entitlementsLoaded = entitlements.hasLoaded
        c.quietGarden = settings.quietGarden
        c.adShownThisSession = adShownThisSession
        c.lastRoundWasRest = game.lastRoundWasLoss
        c.currentLevel = profile?.currentLevel ?? 1
        c.plantsEarned = plants().filter { $0.earnedCount > 0 }.count
        c.offered = Set(settings.plusOfferMilestones.compactMap(PlusOfferPolicy.Milestone.init(rawValue:)))
        c.lastOfferAt = settings.plusOfferLastAt
        guard let m = PlusOfferPolicy.milestoneToOffer(c) else { return }
        plusOffer = m
        // Every milestone already reached is covered by this one card.
        let covered = PlusOfferPolicy.reached(currentLevel: c.currentLevel, plantsEarned: c.plantsEarned).map(\.rawValue)
        settings.plusOfferMilestones = Array(Set(settings.plusOfferMilestones).union(covered)).sorted()
        settings.plusOfferLastAt = now()
    }

    func dismissPlusOffer() { plusOffer = nil }

    // MARK: Shed and badges

    private func plantProgress() -> [PlantProgress] {
        plants().map { PlantProgress(level: $0.level, earned: $0.earnedCount > 0, stage: $0.stage) }
    }

    /// Tools arrive through play and are never taken away: the net with the butterfly game, then the
    /// mister, shears and lamp as garden levels are completed (prototype round 8).
    func syncToolUnlocks() {
        var inv = inventory
        let before = inv
        let progress = plantProgress()
        if settings.showEverything { ToolID.allCases.forEach { inv.unlock($0) } }
        if isUnlocked(.butterfly) { inv.unlock(.net) }
        let completed = (1...5).filter { ProgressionPolicy.gardenLevelComplete($0, plants: progress) }.count
        FeatureUnlockPolicy.gardenTools(completedGardenLevels: completed).forEach { inv.unlock($0) }
        if inv != before { inventory = inv }
    }

    @discardableResult
    func upgradeTool(_ tool: ToolID) -> Bool {
        guard let p = profile else { return false }
        var inv = inventory
        var points = p.shedPoints
        guard inv.upgrade(tool, shedPoints: &points) else { return false }
        p.shedPoints = points
        inventory = inv
        recordBadgeValue(.shedUpgrades, BadgeFacts.shedUpgrades(inv))
        return true
    }

    /// Records badge progress for the round that just ended, once. Returns any newly unlocked tiers.
    @discardableResult
    func roundFinished() -> [BadgeUnlock] {
        guard let p = profile, let id = game.finishedRoundId, id != lastBadgedRoundId,
              game.phase == .won || game.phase == .rested else { return [] }
        lastBadgedRoundId = id
        let t = now(), quiet = settings.quietGarden
        var unlocks = [BadgeUnlock]()
        if game.phase == .won && !game.isTutorial {
            let all = plants()
            unlocks += badges.record(.plantsOwned, value: all.filter { $0.earnedCount > 0 }.count, now: t, quiet: quiet)
            let levelsDone = (1...5).filter { lvl in let inLvl = all.filter { $0.level == lvl }; return inLvl.count == 10 && inLvl.allSatisfy { $0.earnedCount > 0 } }.count
            unlocks += badges.record(.levelSets, value: levelsDone, now: t, quiet: quiet)
            if game.missesThisRound == 0 { unlocks += badges.record(.perfectBlooms, now: t, quiet: quiet) }
            if game.isDaily {
                unlocks += badges.record(.dailyBloomsDone, now: t, quiet: quiet)
                unlocks += recordSeasonBloom(into: &badges, on: t, quiet: quiet)    // the season's earned pot
            }
            recordQuest(.wordFound(letters: game.currentWord.filter(\.isLetter).count))
            unlocks += badges.record(.wordsSolved, now: t, quiet: quiet)
            if BadgeFacts.isSteady(misses: game.missesThisRound) { unlocks += badges.record(.steadySolves, now: t, quiet: quiet) }
            if BadgeFacts.isLongWord(game.currentWord) { unlocks += badges.record(.longWords, now: t, quiet: quiet) }
            unlocks += recordCollectionFacts(now: t, quiet: quiet)       // the plant that arrived, the level reached
            if game.quickBloom { unlocks += badges.record(.quickBlooms, now: t, quiet: quiet) }
        }
        if !game.isTutorial && BadgeFacts.isMorning(t, calendar: .current) {
            unlocks += badges.recordDay(.morningDays, day: BadgeFacts.dayNumber(t, calendar: .current), now: t, quiet: quiet)
        }
        unlocks += badges.record(.streak, value: p.streak, now: t, quiet: quiet)
        enqueueBadgeMoments(unlocks)                // shown when the round's card closes (GameView pauses them until then)
        p.badgesJSON = badges.json
        try? context.save()
        syncToolUnlocks()
        return unlocks
    }

    /// Changes the badge state through `change` (handed Quiet Garden and the time), queues the moments (or not, for a
    /// quiet catch-up) and saves. The badge helpers in `AppModel+Badges` go through here.
    @discardableResult
    func updateBadges(announce: Bool = true, after delay: Double = 0,
                      _ change: (inout BadgeState, _ quiet: Bool, _ now: Date) -> [BadgeUnlock]) -> [BadgeUnlock] {
        let unlocks = change(&badges, settings.quietGarden, now())
        if announce { enqueueBadgeMoments(unlocks, after: delay) }
        profile?.badgesJSON = badges.json
        try? context.save()
        return unlocks
    }

    /// One step on a badge counter, with its moments queued and the profile saved (the weather puzzle's Weathered step).
    @discardableResult
    func recordBadgeStep(_ counter: BadgeCounter, after delay: Double = 0) -> [BadgeUnlock] {
        let unlocks = badges.record(counter, now: now(), quiet: settings.quietGarden)
        enqueueBadgeMoments(unlocks, after: delay)
        profile?.badgesJSON = badges.json
        try? context.save()
        return unlocks
    }

    /// Uses a Rose of Jericho and records the badge when the flower wakes up.
    func wakeFlower() {
        let before = profile?.roseOfJerichoCount ?? 0
        game.wakeUp()
        guard (profile?.roseOfJerichoCount ?? 0) < before else { return }
        play(.wake)
        enqueueBadgeMoments(badges.record(.revives, now: now(), quiet: settings.quietGarden), after: 0.6)
        profile?.badgesJSON = badges.json
        try? context.save()
    }

    // MARK: Butterfly game

    var album: StickerAlbum { StickerAlbum(json: profile?.albumJSON ?? "") }

    var butterflyPlaysToday: Int {
        guard let json = profile?.butterflyPlaysJSON, let data = json.data(using: .utf8),
              let counter = try? JSONDecoder().decode(DailyPlayCounter.self, from: data) else { return 0 }
        return counter.playsToday(on: now(), calendar: .current)
    }

    /// The pace a round would start at now (ButterflyPace.resolve): Calm, the gentle game, or Quick wings for 13 and up.
    func butterflyPace(reduceMotion: Bool = false, voiceOver: Bool = false, switchControl: Bool = false, wake: Bool = false) -> ButterflyPace {
        ButterflyPace.resolve(.init(calmMode: settings.calmMode, wake: wake, reduceMotion: reduceMotion, voiceOver: voiceOver,
                                    switchControl: switchControl, ageBand: settings.ageBand, easierButterflies: settings.easierButterflies))
    }

    /// Calm mode gives the gentle round (no clock, slower visitors, 5 hellos); 13 and up get Quick wings unless Easier
    /// butterflies is on. The wake game always keeps its own gentle tuning.
    func startButterflyGame(seed: UInt64 = UInt64.random(in: .min ... .max), useLantern: Bool = false, reduceMotion: Bool = false,
                            wake: Bool = false, voiceOver: Bool = false, switchControl: Bool = false) -> ButterflyGameModel {
        let evening = VisitorSpawner.isEvening(now(), calendar: .current)
        var lantern = false
        if useLantern, !evening, let p = profile, p.glowLanterns > 0 { p.glowLanterns -= 1; lantern = true; try? context.save() }
        let flowering = plants().filter { $0.earnedCount > 0 && $0.stage >= 3 }.count
        let pace = butterflyPace(reduceMotion: reduceMotion, voiceOver: voiceOver, switchControl: switchControl, wake: wake)
        return ButterflyGameModel(pool: VisitorSpawner.pool(evening: evening, lantern: lantern), floweringPlants: flowering,
                                  reduceMotion: reduceMotion, seed: butterflySeedOverride ?? seed, pace: pace,
                                  roundSeconds: wake || pace == .calm ? nil : butterflyRoundOverride)
    }

    /// Applies the end-of-game rewards. Stickers always count; currency respects the 3-a-day limit and Quiet Garden.
    /// A wake game (`wake: true`) credits the album and badges only: no water, shed points or soil, and no rewarded play used.
    @discardableResult
    func finishButterflyGame(_ game: ButterflyGameModel, wake: Bool = false) -> ButterflyRewards.Summary {
        guard let p = profile else { return ButterflyRewards.Summary() }
        let quiet = settings.quietGarden, t = now()
        var rng = SystemRandomNumberGenerator()
        var summary = ButterflyRewards.summary(catches: game.caught, playsToday: butterflyPlaysToday, using: &rng)
        if quiet || wake { summary.water = 0; summary.shedPoints = 0; summary.scoops = 0 }
        summary.newFriendIds = summary.newStickerIds.filter { album.count(of: $0) == 0 }

        p.water = min(Economy.default.waterBankCap, p.water + summary.water)
        p.shedPoints += summary.shedPoints
        p.soil += summary.scoops

        var a = album
        a.add(game.caught, on: t)
        p.albumJSON = a.json

        if !wake {
            var counter = (p.butterflyPlaysJSON.data(using: .utf8).flatMap { try? JSONDecoder().decode(DailyPlayCounter.self, from: $0) }) ?? DailyPlayCounter()
            counter.record(on: t, calendar: .current)
            p.butterflyPlaysJSON = (try? JSONEncoder().encode(counter)).flatMap { String(data: $0, encoding: .utf8) } ?? ""
        }

        var unlocks = badges.record(.visitorSpecies, value: a.species, now: t, quiet: quiet) + badges.record(.butterflyPlays, now: t, quiet: quiet)
        // Gentle Net: hellos to resting friends (wake games count too). Quiet Garden records nothing and shows no count.
        if !game.caughtGently.isEmpty { unlocks += badges.record(.gentleHellos, amount: game.caughtGently.count, now: t, quiet: quiet) }
        summary.gentleHellos = quiet ? 0 : game.caughtGently.count
        for (counter, n) in BadgeFacts.catches(game.caught).sorted(by: { $0.key.rawValue < $1.key.rawValue }) where n > 0 {
            unlocks += badges.record(counter, amount: n, now: t, quiet: quiet)
        }
        for (counter, n) in BadgeFacts.album(a).sorted(by: { $0.key.rawValue < $1.key.rawValue }) {
            unlocks += badges.record(counter, value: n, now: t, quiet: quiet)
        }
        enqueueBadgeMoments(unlocks, after: wake ? 0.6 : 1.9)     // after the summary's petals (a wake waits for its sheet to close)
        p.badgesJSON = badges.json
        try? context.save()
        syncToolUnlocks()
        return summary
    }

    // MARK: Reminders

    var dailyBloomDoneToday: Bool { game.dailyBloomDoneToday }

    /// Asks for permission only now, because the player just turned reminders on.
    func enableReminders() async -> Bool {
        let ok = await reminders.enable(now: now(), hour: settings.reminderHour, minute: settings.reminderMinute,
                                        lastOpened: now(), dailyBloomDoneToday: dailyBloomDoneToday, forecast: reminderForecast)
        settings.remindMe = ok
        return ok
    }

    func disableReminders() {
        reminders.disable()
        settings.remindMe = false
    }

    /// Re-plans from "now" every time the player leaves the app, so the 3-days-without-a-visit rule always holds.
    func refreshReminders() {
        guard settings.remindMe else { return }
        reminders.refresh(now: now(), hour: settings.reminderHour, minute: settings.reminderMinute, lastOpened: now(), dailyBloomDoneToday: dailyBloomDoneToday,
                           forecast: reminderForecast)      // the opt-in forecast shares this one daily slot
    }

    // MARK: Badge moments

    /// Badges earned and not yet shown, oldest first. Every unlock site feeds this (rounds, tending, revives, butterflies).
    private(set) var pendingBadges: [BadgeUnlock] = []
    var pendingBadge: BadgeUnlock? { pendingBadges.first }
    /// The badge moment on screen now (BadgeMomentView at the root).
    private(set) var shownBadge: BadgeUnlock?
    /// How long the next moment waits, so it follows the moment's own celebration instead of covering it.
    private(set) var badgeMomentDelay: Double = 0

    /// Screens with their own celebration card hold badge moments until it closes; a sheet holds them because the
    /// root overlay would sit under it.
    enum BadgePause: Hashable { case round, sheet }
    private(set) var badgePauses: Set<BadgePause> = []
    var badgeMomentsPaused: Bool { !badgePauses.isEmpty }

    /// Releasing the last hold shows a waiting badge at once, in the same update as the tap that closed the card,
    /// so the next screen never takes a tap meant for it first.
    func pauseBadgeMoments(_ reason: BadgePause, _ paused: Bool) {
        if paused { badgePauses.insert(reason); return }
        guard badgePauses.remove(reason) != nil else { return }
        if !badgeMomentsPaused && badgeMomentDelay == 0 { presentNextBadge() }
    }

    /// One moment per badge (its highest new tier), in the order they were earned. Quiet Garden never unlocks badges,
    /// so nothing arrives here.
    func enqueueBadgeMoments(_ unlocks: [BadgeUnlock], after delay: Double = 0) {
        guard !unlocks.isEmpty else { return }
        var best = [String: BadgeUnlock](), order = [String]()
        for u in unlocks {
            if let b = best[u.badgeId] { if u.tier > b.tier { best[u.badgeId] = u } } else { best[u.badgeId] = u; order.append(u.badgeId) }
        }
        pendingBadges += order.compactMap { best[$0] }
        badgeMomentDelay = delay
    }

    /// Moves the next badge on screen (with its tier sound; no haptic). Nil while paused or while one is showing.
    @discardableResult
    func presentNextBadge() -> BadgeUnlock? {
        guard shownBadge == nil, !badgeMomentsPaused, !pendingBadges.isEmpty else { return nil }
        let next = pendingBadges.removeFirst()
        shownBadge = next
        play(.badge(tier: next.tier))
        return next
    }

    func dismissBadgeMoment() {
        shownBadge = nil
        badgeMomentDelay = 0.3
    }

    // MARK: Celebrations

    /// The celebration a moment plays here and now (CelebrationStyle: Reduce Motion, Calm, Quiet Garden, Low Power).
    func celebrationLevel(_ requested: CelebrationLevel, systemReduceMotion: Bool) -> CelebrationLevel {
        CelebrationStyle.resolve(requested: requested, settings: settings, systemReduceMotion: systemReduceMotion,
                                 lowPower: ProcessInfo.processInfo.isLowPowerModeEnabled)
    }

    // MARK: Sound

    /// One place that honours the Sound setting for every non-round sound.
    func play(_ event: SoundEvent, volume: Float = 1) {
        SoundPlayer.shared.enabled = settings.soundOn
        SoundPlayer.shared.play(event, volume: volume)
    }

    /// When the last thunder roll played, app-wide, for the 3-minute cooldown (ThunderGate.rollCooldown).
    var lastThunderRoll: Date?

    /// The soft thunder roll after a flash on the plant page. Counts toward the cooldown only when heard.
    func rollThunder() {
        guard settings.soundOn else { return }
        lastThunderRoll = now()
        play(.thunder, volume: ThunderGate.soundVolume)
    }

    func updateAmbience() {
        SoundPlayer.shared.enabled = settings.soundOn
        if settings.soundOn && settings.ambienceOn { SoundPlayer.shared.startAmbient() } else { SoundPlayer.shared.stopAmbient() }
    }

    // MARK: iCloud sync (WordFlora Plus)

    /// SwiftData opens its store once per launch, so entitlement changes take effect on the next launch.
    /// A lapsed subscription reopens the same store without sync: nothing is deleted or reset.
    func updateSyncFlag() {
        guard entitlements.hasLoaded else { return }          // a slow StoreKit start must never switch sync off
        let entitled = entitlements.state.hasCloudSync
        settings.cloudSyncEnabled = entitled
        syncNeedsRestart = entitled != launchedWithCloud
    }

    // MARK: Break suggestion for young players

    private var sittingStart: Date?
    private var lastBreakSuggestedAt: Date?

    func beginSitting() { if sittingStart == nil { sittingStart = now() } }

    var shouldSuggestBreak: Bool {
        guard let start = sittingStart else { return false }
        return BreakPolicy.shouldSuggest(isUnderThirteen: settings.isUnderThirteen, sittingStart: start, now: now(), lastSuggestedAt: lastBreakSuggestedAt)
    }

    func markBreakSuggested() { lastBreakSuggestedAt = now() }
}
