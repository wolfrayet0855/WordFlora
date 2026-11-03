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
    private let now: () -> Date

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
        game.seedPlantsIfNeeded()
        reconcileSyncedData()
        SoundPlayer.configureSession()
        if settings.onboardingComplete { settings.completedSessions += 1 }
        if settings.remindMe { reminders.restore() }
        let defs = (try? BadgeCatalog.load()) ?? []
        badges = BadgeState(json: game.playerProfile?.badgesJSON ?? "", defs: defs)
        refreshFreeDrops()
        let lastOpen = settings.lastOpenedAt
        if settings.onboardingComplete, WelcomeBack.shouldShow(lastOpened: lastOpen, now: now(), calendar: .current) {
            showWelcomeBack = true
            welcomeLine = WelcomeBack.lines[abs(Int(now().timeIntervalSince1970 / 86_400)) % WelcomeBack.lines.count]
        }
        if settings.onboardingComplete { settings.lastOpenedAt = now() }
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

    // MARK: Tools and tending

    var inventory: ToolInventory {
        get { ToolInventory(json: profile?.toolsJSON ?? "") }
        set { profile?.toolsJSON = newValue.json; try? context.save() }
    }

    enum TendAction: Equatable { case water, feed, sun, prune, repot(SoilType) }

    struct TendOutcome: Equatable {
        var applied: Bool
        var stageUp = false
        var message: String
    }

    func refreshFreeDrops() {
        guard let p = profile else { return }
        TendingEngine.applyTrickle(p, now: now(), economy: .default)
        try? context.save()
    }

    func tend(_ action: TendAction, plant: PlantCollectible) -> TendOutcome {
        guard let p = profile else { return TendOutcome(applied: false, message: "Something went wrong. Try again.") }
        let quiet = settings.quietGarden
        let date = now(), cal = Calendar.current, eco = Economy.default
        let inv = inventory
        var result = TendResult()
        var repotOutcome: RepotResult.Outcome?

        switch action {
        case .water: result = ToolEngine.waterWithCan([plant], profile: p, inventory: inv, now: date, calendar: cal, economy: eco, quiet: quiet).first ?? .blocked(.noWater)
        case .feed: result = ToolEngine.addSoil(plant, profile: p, inventory: inv, now: date, calendar: cal, economy: eco, quiet: quiet)
        case .sun: result = ToolEngine.sunWithLamp(plant, profile: p, inventory: lampOrBasic(inv), now: date, calendar: cal, economy: eco, quiet: quiet)
        case .prune: result = ToolEngine.prune(plant, inventory: inv, now: date, calendar: cal, economy: eco, quiet: quiet)
        case .repot(let soil):
            let r = ToolEngine.repot(plant, to: soil, profile: p, now: date, calendar: cal, economy: eco, quiet: quiet)
            result = r.applied ? TendResult(applied: true, gpGained: r.tend.gpGained, stageUp: r.tend.stageUp) : .blocked(.noSoil)
            repotOutcome = r.outcome
        }

        guard result.applied else { return TendOutcome(applied: false, message: Self.message(for: result.reason, plant: plant)) }

        let counter: BadgeCounter? = { switch action { case .water: return .waterings; case .feed: return .feeds; case .prune: return .prunes; case .repot: return .repots; case .sun: return nil } }()
        if let counter { badges.record(counter, now: date, quiet: quiet); p.badgesJSON = badges.json }
        try? context.save()

        let name = plant.nickname.isEmpty ? plant.name : plant.nickname
        let day = Int(date.timeIntervalSince1970 / 86_400) &+ plant.earnedCount
        let event: PlantVoice.Event = { switch action { case .water: return .water; case .feed, .repot: return .soil; case .sun: return .sun; case .prune: return .prune } }()
        if result.stageUp { return TendOutcome(applied: true, stageUp: true, message: "\(name) grew a little! " + PlantVoice.line(plantId: plant.plantId, event: .grew, daySeed: day)) }
        if repotOutcome == .happy { return TendOutcome(applied: true, message: "\(name) loves its new pot!") }
        if repotOutcome == .neutral { return TendOutcome(applied: true, message: "Repotted.") }
        let voice = PlantVoice.line(plantId: plant.plantId, event: event, daySeed: day)
        return TendOutcome(applied: true, message: quiet ? voice : "\(voice) +\(result.gpGained) growth")
    }

    /// The sun tap is free for everyone; owning the lamp only makes it stronger.
    private func lampOrBasic(_ inv: ToolInventory) -> ToolInventory {
        var i = inv; i.unlock(.lamp); return i
    }

    private static func message(for reason: TendResult.Reason?, plant: PlantCollectible) -> String {
        switch reason {
        case .noWater: return "No drops left. Win a word to earn more."
        case .noSoil: return "No soil scoops left. Finding new plants earns more."
        case .fullForToday: return "\(plant.name) has had enough for today. Come back tomorrow!"
        case .alreadyDoneToday: return "\(plant.name) already soaked up the sun today."
        case .notOwned: return "You need the shears first."
        case .cooldown: return "Pruned recently. Give it a couple of days."
        case nil: return "Not right now."
        }
    }

    // MARK: Ads (spec sections 12, 16, 18, 19; ruling in section 20)

    func markPeakDismissed() { lastPeakAt = now() }

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
        return c
    }

    func recordAdShown() {
        guard let p = profile else { return }
        let d = now(), cal = Calendar.current
        p.roundsSinceAd = 0
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
        adsEnabled && entitlements.hasLoaded && onboarding.isComplete && settings.completedSessions >= 1
            && AdGate.mayLoadAnyAd(isUnderThirteen: ParentalGate.isRequired(ageBand: settings.ageBand), hasRemoveAds: entitlements.state.hasRemoveAds)
    }

    /// Runs when the player taps "One more" on the resting card: at most one ad, only if every rule allows it.
    func adBeforeNextRound() async {
        guard adsEnabled else { return }
        let ctx = adContext(choice: .oneMore)
        guard AdGate.shouldShowInterstitial(ctx) else { return }
        await ads.prepare(ageBand: settings.ageBand, isStillAllowed: { self.mayStillLoadAds })
        if await ads.showInterstitial() { recordAdShown() }
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
        if earned { grantRewardedDrops() }
        return earned
    }

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
            if game.isDaily { unlocks += badges.record(.dailyBloomsDone, now: t, quiet: quiet) }
        }
        unlocks += badges.record(.streak, value: p.streak, now: t, quiet: quiet)
        p.badgesJSON = badges.json
        try? context.save()
        syncToolUnlocks()
        return unlocks
    }

    /// Uses a Rose of Jericho and records the badge when the flower wakes up.
    func wakeFlower() {
        let before = profile?.roseOfJerichoCount ?? 0
        game.wakeUp()
        guard (profile?.roseOfJerichoCount ?? 0) < before else { return }
        play(.wake)
        badges.record(.revives, now: now(), quiet: settings.quietGarden)
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

    func startButterflyGame(seed: UInt64 = UInt64.random(in: .min ... .max), useLantern: Bool = false, reduceMotion: Bool = false) -> ButterflyGameModel {
        let evening = VisitorSpawner.isEvening(now(), calendar: .current)
        var lantern = false
        if useLantern, !evening, let p = profile, p.glowLanterns > 0 { p.glowLanterns -= 1; lantern = true; try? context.save() }
        let flowering = plants().filter { $0.earnedCount > 0 && $0.stage >= 3 }.count
        return ButterflyGameModel(pool: VisitorSpawner.pool(evening: evening, lantern: lantern), floweringPlants: flowering,
                                  reduceMotion: reduceMotion, seed: seed)
    }

    /// Applies the end-of-game rewards. Stickers always count; currency respects the 3-a-day limit and Quiet Garden.
    @discardableResult
    func finishButterflyGame(_ game: ButterflyGameModel) -> ButterflyRewards.Summary {
        guard let p = profile else { return ButterflyRewards.Summary() }
        let quiet = settings.quietGarden, t = now()
        var rng = SystemRandomNumberGenerator()
        var summary = ButterflyRewards.summary(catches: game.caught, playsToday: butterflyPlaysToday, using: &rng)
        if quiet { summary.water = 0; summary.shedPoints = 0; summary.scoops = 0 }

        p.water = min(Economy.default.waterBankCap, p.water + summary.water)
        p.shedPoints += summary.shedPoints
        p.soil += summary.scoops

        var a = album
        a.add(game.caught)
        p.albumJSON = a.json

        var counter = (p.butterflyPlaysJSON.data(using: .utf8).flatMap { try? JSONDecoder().decode(DailyPlayCounter.self, from: $0) }) ?? DailyPlayCounter()
        counter.record(on: t, calendar: .current)
        p.butterflyPlaysJSON = (try? JSONEncoder().encode(counter)).flatMap { String(data: $0, encoding: .utf8) } ?? ""

        badges.record(.visitorSpecies, value: a.species, now: t, quiet: quiet)
        badges.record(.butterflyPlays, now: t, quiet: quiet)
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
                                        lastOpened: now(), dailyBloomDoneToday: dailyBloomDoneToday)
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
        reminders.refresh(now: now(), hour: settings.reminderHour, minute: settings.reminderMinute, lastOpened: now(), dailyBloomDoneToday: dailyBloomDoneToday)
    }

    // MARK: Sound

    /// One place that honours the Sound setting for every non-round sound.
    func play(_ event: SoundEvent) {
        SoundPlayer.shared.enabled = settings.soundOn
        SoundPlayer.shared.play(event)
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
