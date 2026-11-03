import AppIntents

struct GardenShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: WaterGardenIntent(), phrases: ["Water my garden in \(.applicationName)", "Give my \(.applicationName) garden a drink"],
                    shortTitle: "Water my garden", systemImageName: "drop.fill")
        AppShortcut(intent: OpenGardenIntent(), phrases: ["Open my garden in \(.applicationName)", "Play \(.applicationName)"],
                    shortTitle: "Open my garden", systemImageName: "leaf.fill")
    }
}
