import Foundation

/// UI test launch fixtures for the full Frost & Lantern pack (G5). Read after the album fixtures, so they add to them.
///   -uitest-pack-owned        (WordFloraApp) owns the pack; here its glasshouse plants get their rows
///   -uitest-glasshouse-grown  the glasshouse plants at full bloom (stage 4), for the plant page and Garden at stage 4
///   -uitest-winter-friends    the robin met twice (the wren stays not met), for the album's winter friends
enum FrostLanternUITestFixtures {
    @MainActor
    static func apply(_ args: [String], to model: AppModel) {
        if args.contains("-uitest-pack-owned") { model.syncGlasshouse() }
        if args.contains("-uitest-glasshouse-grown") {
            for row in model.glasshouseRows() { row.stage = 4; row.growthPoints = max(row.growthPoints, 400) }
            try? model.context.save()
        }
        if args.contains("-uitest-winter-friends") {
            var album = model.album
            album.add(["robin", "robin"], on: Date.now)
            model.profile?.albumJSON = album.json
            try? model.context.save()
        }
    }
}
