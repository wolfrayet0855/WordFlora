import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(AppModel.self) private var app
    @Environment(GameRouter.self) private var router
    @State private var reminderDenied = false
    @State private var exportDoc: GardenBackupDocument?
    @State private var exporting = false
    @State private var importing = false
    @State private var backupMessage: (text: String, ok: Bool)?
    @State private var showGuide = false

    var body: some View {
        @Bindable var s = app.settings
        Form {
            Section("Play") {
                Picker("Word difficulty", selection: $s.difficulty) {
                    Text("Auto").tag(AppSettings.Difficulty.auto)
                    Text("Gentle").tag(AppSettings.Difficulty.gentle)
                    Text("Standard").tag(AppSettings.Difficulty.standard)
                    Text("Tricky").tag(AppSettings.Difficulty.tricky)
                }
                Toggle("Show streak", isOn: $s.showStreak)
            }
            Section(GuideCopy.UI.settingsHeader) {
                Button { showGuide = true } label: { Label(GuideCopy.UI.settingsRow, systemImage: "book.pages") }
                    .accessibilityIdentifier("settings.showGuide")
                Text(GuideCopy.UI.settingsFoot).font(Theme.font(.footnote)).foregroundStyle(Color.secondaryText)
            }
            Section("Comfort") {
                Toggle("Sound", isOn: $s.soundOn).onChange(of: s.soundOn) { _, v in app.game.soundEnabled = v; app.updateAmbience() }
                Toggle("Garden ambience", isOn: $s.ambienceOn).onChange(of: s.ambienceOn) { _, _ in app.updateAmbience() }
                Toggle("Haptics", isOn: $s.hapticsOn)
                Toggle("Calm mode", isOn: $s.calmMode)
                Toggle("Quiet Garden", isOn: $s.quietGarden)
                Text("Calm mode removes the thirsty look and halves celebrations. Quiet Garden hides counters and timers so tending is just relaxing.")
                    .font(Theme.font(.footnote)).foregroundStyle(Color.secondaryText)
            }
            GardenWeatherSettingsSection()
            Section("Reminders") {
                Toggle("Gentle daily reminder", isOn: Binding(
                    get: { s.remindMe },
                    set: { on in
                        if on { Task { reminderDenied = !(await app.enableReminders()) } } else { app.disableReminders(); reminderDenied = false }
                    }))
                if s.remindMe {
                    DatePicker("Time", selection: Binding(
                        get: { Calendar.current.date(bySettingHour: s.reminderHour, minute: s.reminderMinute, second: 0, of: .now) ?? .now },
                        set: { d in
                            let c = Calendar.current.dateComponents([.hour, .minute], from: d)
                            s.reminderHour = min(20, max(8, c.hour ?? 17)); s.reminderMinute = c.minute ?? 0
                            app.refreshReminders()
                        }), displayedComponents: .hourAndMinute)
                }
                Text("At most one a day, never at night, and they stop on their own if you take a break.").font(Theme.font(.footnote)).foregroundStyle(Color.secondaryText)
                if reminderDenied { Text("Notifications are off for WordFlora. You can allow them in your device settings.").font(.footnote).foregroundStyle(Color.appDanger) }
            }
            Section("Appearance") {
                Picker("Theme", selection: $s.appearance) {
                    Text("System").tag(AppSettings.Appearance.system)
                    Text("Light").tag(AppSettings.Appearance.light)
                    Text("Dark").tag(AppSettings.Appearance.dark)
                }.pickerStyle(.segmented)
                Toggle("Show everything", isOn: $s.showEverything)
            }
            Section(PlusEntry.sectionTitle(ageBand: s.ageBand)) {
                Button { router.go(.plus) } label: { Label(PlusEntry.rowTitle(ageBand: s.ageBand), systemImage: "sparkles") }
                    .accessibilityIdentifier("settings.plus")
                if app.entitlements.state.hasCloudSync {
                    Label(app.syncNeedsRestart ? "iCloud sync starts the next time you open WordFlora" : "iCloud sync is on", systemImage: "icloud.fill")
                        .font(Theme.font(.footnote)).foregroundStyle(Color.secondaryText)
                }
            }
            Section("Your garden") {
                Button { prepareBackup() } label: { Label(GardenBackup.Copy.backupTitle, systemImage: "square.and.arrow.up") }
                Button { importing = true } label: { Label(GardenBackup.Copy.restoreTitle, systemImage: "square.and.arrow.down") }
                Text(GardenBackup.Copy.footnote).font(Theme.font(.footnote)).foregroundStyle(Color.secondaryText)
                if let m = backupMessage {
                    Text(m.text).font(.footnote).foregroundStyle(m.ok ? Color.successText : Color.appDanger)
                        .accessibilityIdentifier("backup-message")
                }
            }
            Section("Privacy and ads") {
                GatedLink("Report an ad", url: Links.reportAd)
                GatedLink("Privacy Policy", url: Links.privacy)
                if app.ads.privacyOptionsRequired {
                    Button("Ad privacy choices") { Task { await app.ads.presentPrivacyOptions() } }
                }
            }
            Section("About") {
                LabeledContent("Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
            }
        }
        .fileExporter(isPresented: $exporting, document: exportDoc, contentType: .json,
                      defaultFilename: GardenBackup.filename(for: .now)) { result in
            if case .success = result { backupMessage = (GardenBackup.Copy.backedUp, true) }
        }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in
            guard case .success(let url) = result else { return }
            restore(from: url)
        }
        .fullScreenCover(isPresented: $showGuide) {
            GuideView(mode: .replay) { showGuide = false }
                .environment(app)
                .preferredColorScheme(app.settings.colorScheme)
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func prepareBackup() {
        guard let data = try? GardenBackup.make(context: app.context, now: .now).encoded() else { return }
        exportDoc = GardenBackupDocument(data: data)
        exporting = true
    }

    private func restore(from url: URL) {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        guard let data = try? Data(contentsOf: url) else { backupMessage = (GardenBackup.ImportError.unreadable.message, false); return }
        switch app.restoreGarden(from: data) {
        case .success: backupMessage = (GardenBackup.Copy.restored, true)
        case .failure(let e): backupMessage = (e.message, false)
        }
    }
}
