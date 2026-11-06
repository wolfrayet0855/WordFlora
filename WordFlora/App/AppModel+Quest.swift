import Foundation

/// The daily tiny quest (Rules/DailyQuest.swift): picked from the player's seed and the day, moved along by care, hellos,
/// words and a visit to the Visitors page, and worth one shed point when done. Hidden, and never counted, in Quiet Garden.
extension AppModel {
    var questDayKey: Int { WeatherDay.key(nowDate) }

    /// Today's quest, or nil (Quiet Garden, the first session, or no plant found yet). Home passes the stats it already has.
    func dailyQuest(stats: UnlockStats?) -> DailyQuest.Quest? {
        guard DailyQuest.isShown(quietGarden: settings.quietGarden, onboardingDone: settings.onboardingComplete),
              !questHiddenForUITests else { return nil }
        if let k = questTestOverride { return DailyQuest.Quest(kind: k, target: DailyQuest.target(k)) }
        let s = stats ?? unlockStats, all = settings.showEverything
        let open = DailyQuest.Availability(plantsFound: s.plantsEarned,
                                           sunOpen: FeatureUnlockPolicy.isUnlocked(.sun, stats: s, showEverything: all),
                                           visitorsOpen: FeatureUnlockPolicy.isUnlocked(.butterfly, stats: s, showEverything: all))
        return DailyQuest.quest(day: questDayKey, seed: profile?.weatherSeed ?? 0, availability: open)
    }

    var todaysQuest: DailyQuest.Quest? { dailyQuest(stats: nil) }

    /// Today's progress (a stored state from another day reads as fresh).
    var questState: QuestState {
        guard let p = profile else { return QuestState(day: questDayKey) }
        return DailyQuest.current(QuestState(day: p.questDay, progress: p.questProgress, done: p.questDone), today: questDayKey)
    }

    /// Moves today's quest along; the moment it is done, one shed point. Saves only when something changed.
    func recordQuest(_ event: DailyQuest.Event) {
        guard let p = profile, let quest = todaysQuest else { return }
        let before = QuestState(day: p.questDay, progress: p.questProgress, done: p.questDone)
        let after = DailyQuest.step(event, quest: quest, state: before, today: questDayKey)
        guard after != before else { return }
        p.questDay = after.day; p.questProgress = after.progress; p.questDone = after.done
        p.shedPoints += DailyQuest.reward(before: before, after: after, quietGarden: settings.quietGarden)
        try? context.save()
    }

    /// After a hello or any tending (both count as love): the plants greeted today, and for water the plants watered.
    func recordQuestCare(_ action: TendAction?) {
        guard todaysQuest != nil else { return }
        let date = now(), cal = Calendar.current
        let found = plants().filter { $0.earnedCount > 0 }
        if case .water? = action {
            recordQuest(.watered(plantsToday: found.filter { TendingEngine.waterings($0, now: date, calendar: cal) > 0 }.count))
        }
        if case .sun? = action { recordQuest(.sunned) }
        recordQuest(.greeted(plantsToday: found.filter { TendingEngine.isToday($0.lastLovedAt, now: date, calendar: cal) }.count))
    }

    /// Hellos and drinks given from the widget (another process) are counted when the app comes back to the front: the
    /// plants greeted and watered today, read from the garden. Counts only ever go up, so repeating it is safe.
    func refreshQuestFromGarden() {
        guard let quest = todaysQuest else { return }
        let date = now(), cal = Calendar.current
        let found = plants().filter { $0.earnedCount > 0 }
        switch quest.kind {
        case .waterPlants: recordQuest(.watered(plantsToday: found.filter { TendingEngine.waterings($0, now: date, calendar: cal) > 0 }.count))
        case .helloPlants: recordQuest(.greeted(plantsToday: found.filter { TendingEngine.isToday($0.lastLovedAt, now: date, calendar: cal) }.count))
        default: break
        }
    }
}
