import Foundation

/// One shared word per local calendar day with no server (spec section 3).
struct DailyBloom {
    private let order: [String]
    private let calendar: Calendar
    private let epochStart: Date
    private let overrides: [String: String]

    init(bank: WordBank, calendar: Calendar = .current, overrides: [String: String] = [:]) {
        self.calendar = calendar
        self.overrides = overrides

        var ids = bank.entries.filter(\.dailyEligible).map(\.id).sorted()
        var rng = SplitMix64(seed: bank.daily.seed)
        if ids.count > 1 {
            for i in stride(from: ids.count - 1, to: 0, by: -1) {
                let j = Int(rng.next() % UInt64(i + 1))
                ids.swapAt(i, j)
            }
        }
        order = ids

        let parts = bank.daily.epoch.split(separator: "-").compactMap { Int($0) }
        var comps = DateComponents()
        if parts.count == 3 { comps.year = parts[0]; comps.month = parts[1]; comps.day = parts[2] }
        epochStart = calendar.date(from: comps).map { calendar.startOfDay(for: $0) } ?? Date(timeIntervalSince1970: 0)
    }

    /// Whole local days since the epoch (negative before it). Uses calendar
    /// day arithmetic so DST changes and time zones never skew the count.
    func dayIndex(for date: Date) -> Int {
        calendar.dateComponents([.day], from: epochStart, to: calendar.startOfDay(for: date)).day ?? 0
    }

    func wordId(for date: Date) -> String? {
        if let forced = overrides[dayKey(for: date)] { return forced }
        guard !order.isEmpty else { return nil }
        let n = order.count
        return order[((dayIndex(for: date) % n) + n) % n]
    }

    private func dayKey(for date: Date) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }
}
