import AppIntents

struct GardenShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: WaterGardenIntent(), phrases: ["Water my garden in \(.applicationName)", "Give my \(.applicationName) garden a drink"],
                    shortTitle: "Water my garden", systemImageName: "drop.fill")
        AppShortcut(intent: OpenGardenIntent(), phrases: ["Open my garden in \(.applicationName)", "Play \(.applicationName)"],
                    shortTitle: "Open my garden", systemImageName: "leaf.fill")
    }
}

/// Opens the app (to Home, where today's Daily Bloom is the main card). App target only.
struct OpenGardenIntent: AppIntent {
    static var title: LocalizedStringResource = "Open my garden"
    static var openAppWhenRun: Bool { true }

    @MainActor
    func perform() async throws -> some IntentResult {
        AdLinkLaunch.mark()                  // opened for something specific: no return cue this time
        return .result()
    }
}
