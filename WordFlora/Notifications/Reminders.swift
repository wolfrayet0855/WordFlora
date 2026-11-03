import Foundation
import UserNotifications

/// Gentle, opt-in reminders (spec sections 4, 18, 19): at most one a day, shared between tending and the Daily Bloom,
/// at a time the player picks, never in quiet hours (9pm to 8am), and they stop on their own after 3 days without a visit.
enum ReminderPolicy {
    static let quietStartHour = 21
    static let quietEndHour = 8
    static let maxDaysWithoutVisit = 3
    static let maxScheduled = 3

    static func nextDates(now: Date, calendar: Calendar, hour: Int, minute: Int, lastOpened: Date) -> [Date] {
        guard hour >= quietEndHour, hour < quietStartHour else { return [] }
        var dates = [Date]()
        let today = calendar.startOfDay(for: now)
        let opened = calendar.startOfDay(for: lastOpened)
        for offset in 0...(maxDaysWithoutVisit + 1) {
            guard dates.count < maxScheduled,
                  let day = calendar.date(byAdding: .day, value: offset, to: today),
                  let candidate = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day),
                  candidate > now else { continue }
            let since = calendar.dateComponents([.day], from: opened, to: calendar.startOfDay(for: candidate)).day ?? 99
            if since <= maxDaysWithoutVisit { dates.append(candidate) }
        }
        return dates
    }
}

enum ReminderCopy {
    enum Kind: CaseIterable { case tend, dailyBloom }

    static func variants(for kind: Kind) -> Int { 3 }

    static func kind(dailyBloomDoneToday: Bool) -> Kind { dailyBloomDoneToday ? .tend : .dailyBloom }

    static func message(kind: Kind, variant: Int) -> (title: String, body: String) {
        let i = ((variant % 3) + 3) % 3
        switch kind {
        case .tend:
            return [("Your garden says hello", "A few plants would love a drink. No rush."),
                    ("A quiet moment in the garden", "Pop in whenever you like to say hello to your plants."),
                    ("Garden check-in", "Your plants are happy to see you whenever you visit.")][i]
        case .dailyBloom:
            return [("Today's Daily Bloom is ready", "One new word for everyone. Take a peek when you have a moment."),
                    ("A new Daily Bloom", "Today's word is ready to guess."),
                    ("Daily Bloom time", "Come and guess today's garden word.")][i]
        }
    }
}

protocol NotificationCenterProviding: AnyObject {
    func requestAuthorization() async -> Bool
    func schedule(id: String, title: String, body: String, at date: Date)
    func removeAllPending()
}

@MainActor
final class ReminderScheduler {
    private let center: NotificationCenterProviding
    private let calendar: Calendar
    private(set) var enabled = false

    init(center: NotificationCenterProviding, calendar: Calendar = .current) {
        self.center = center
        self.calendar = calendar
    }

    /// Permission is requested here and only here: when the player turns reminders on.
    func enable(now: Date, hour: Int, minute: Int, lastOpened: Date, dailyBloomDoneToday: Bool) async -> Bool {
        guard await center.requestAuthorization() else { return false }
        enabled = true
        plan(now: now, hour: hour, minute: minute, lastOpened: lastOpened, dailyBloomDoneToday: dailyBloomDoneToday)
        return true
    }

    /// Called at launch when the player already opted in earlier: permission was granted then, so no prompt appears.
    func restore() { enabled = true }

    func refresh(now: Date, hour: Int, minute: Int, lastOpened: Date, dailyBloomDoneToday: Bool) {
        guard enabled else { return }
        plan(now: now, hour: hour, minute: minute, lastOpened: lastOpened, dailyBloomDoneToday: dailyBloomDoneToday)
    }

    func disable() {
        enabled = false
        center.removeAllPending()
    }

    private func plan(now: Date, hour: Int, minute: Int, lastOpened: Date, dailyBloomDoneToday: Bool) {
        center.removeAllPending()
        for (i, date) in ReminderPolicy.nextDates(now: now, calendar: calendar, hour: hour, minute: minute, lastOpened: lastOpened).enumerated() {
            // The first reminder reflects today's Daily Bloom; later days always have a fresh one.
            let kind: ReminderCopy.Kind = i == 0 ? ReminderCopy.kind(dailyBloomDoneToday: dailyBloomDoneToday) : .dailyBloom
            let m = ReminderCopy.message(kind: kind, variant: i)
            center.schedule(id: "reminder-\(i)", title: m.title, body: m.body, at: date)
        }
    }
}

/// The real notification centre. Passive delivery: no sound, no waking the screen.
final class SystemNotificationCenter: NotificationCenterProviding {
    private let center = UNUserNotificationCenter.current()

    func requestAuthorization() async -> Bool {
        (try? await center.requestAuthorization(options: [.alert])) ?? false
    }

    func schedule(id: String, title: String, body: String, at date: Date) {
        let content = UNMutableNotificationContent()
        content.title = title; content.body = body
        content.interruptionLevel = .passive
        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        center.add(UNNotificationRequest(identifier: id, content: content, trigger: UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)))
    }

    func removeAllPending() { center.removeAllPendingNotificationRequests() }
}
