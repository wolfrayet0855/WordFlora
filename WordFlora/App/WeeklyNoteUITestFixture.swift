import Foundation

/// `-uitest-weekly-note`: a garden 10 days old with 12 won words (2 of them Daily Blooms), 2 new plants and 3 friends
/// met in the past week, so Home opens with the weekly garden note. Ordinary stored values only.
@MainActor
enum WeeklyNoteUITestFixture {
    static func apply(args: [String], to model: AppModel) {
        guard args.contains("-uitest-weekly-note"), let profile = model.profile else { return }
        let cal = WeeklyNote.calendar(), now = model.nowDate
        let week = WeeklyNote.pastWeek(now, calendar: cal)
        func day(_ d: Int, hour: Int) -> Date {
            cal.date(byAdding: DateComponents(day: d, hour: hour), to: week.lowerBound) ?? week.lowerBound
        }
        profile.createdAt = cal.date(byAdding: .day, value: -10, to: now) ?? now
        profile.guideSeen = true
        let found = model.plants().filter { $0.level == 1 }.sorted { $0.plantId < $1.plantId }.prefix(2)
        for p in found { p.earnedCount = 1 }
        let names = found.map(\.name)
        for i in 0..<12 {
            let plant = i < names.count ? names[i] : nil
            model.context.insert(GameRecord(wordGuessed: "WORD", triviaQuestion: "", won: true, petalsRemaining: 6,
                                            plantEarned: plant, level: 1, wordId: "ui-week-\(i)", isDaily: i >= 10,
                                            date: day(i % 6, hour: 10 + i % 5)))
        }
        var album = StickerAlbum(json: profile.albumJSON)
        album.add(["monarch", "ladybug", "honeybee"], on: day(3, hour: 16))
        profile.albumJSON = album.json
        try? model.context.save()
    }
}
