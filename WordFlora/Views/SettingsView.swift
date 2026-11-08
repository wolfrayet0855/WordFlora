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
    @State private var seasonsGate: ParentalGate.Challenge?

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
                // Speed bloom: 13+ only, Calm and Quiet Garden off; off by default and never suggested anywhere else.
                if SpeedBloom.isOffered(ageBand: s.ageBand, calmMode: s.calmMode, quietGarden: s.quietGarden) {
                    Toggle(SpeedBloomCopy.toggle, isOn: $s.speedBloomOn).accessibilityIdentifier("settings.speedBloom")
                    if s.speedBloomOn {
                        Toggle(SpeedBloomCopy.extraTime, isOn: $s.speedBloomExtraTime)
                            .accessibilityHint(SpeedBloomCopy.extraTimeHint)
                            .accessibilityIdentifier("settings.speedBloomExtraTime")
                    }
                    Text(SpeedBloomCopy.footnote).font(Theme.font(.footnote)).foregroundStyle(Color.secondaryText)
                        .accessibilityIdentifier("settings.speedBloomNote")
                }
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
                Text("Calm mode removes the thirsty look and halves celebrations. Quiet Garden hides counters and wait times so tending is just relaxing.")
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
            // Light and dark follow the system (owner ruling 2026-11-07): no theme picker.
            Section("Garden") {
                Toggle("Show everything", isOn: $s.showEverything)
            }
            Section(PlusEntry.sectionTitle(ageBand: s.ageBand)) {
                // Once Plus is on the row says so, with the plan ("WordFlora Plus is on · Yearly"), for every age.
                let state = app.entitlements.state
                Button { router.go(.plus) } label: {
                    HStack {
                        Label(PlusEntry.rowTitle(ageBand: s.ageBand, hasPlus: state.hasPlus), systemImage: "sparkles")
                        if state.hasPlus, let short = PaywallCopy.planShort(state) {
                            Spacer(minLength: 8)
                            Text(short).foregroundStyle(Color.secondaryText)
                        }
                    }
                }
                .accessibilityIdentifier("settings.plus")
                // Seasons: only while a pack is live (offered or owned); behind the grown-up question for under 13.
                if PackCatalog.all.contains(where: { app.entitlements.packIsLive($0.id) }) {
                    Button { openSeasons() } label: {
                        Label { Text(PackCatalog.Copy.seasonsTitle) } icon: {
                            Image("seasons-row-glyph").renderingMode(.template).resizable().scaledToFit()
                                .frame(width: 22, height: 22)
                        }
                    }
                    .accessibilityIdentifier("settings.seasons")
                }
                FamilyShareNudgeRow()
                cloudRow
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
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $seasonsGate) { challenge in
            ParentalGateSheet(challenge: challenge, onPass: { seasonsGate = nil; router.go(.seasons) }, onCancel: { seasonsGate = nil })
        }
    }

    /// iCloud sync as a status row (not a caption), for everyone: on, starts next time, needs Plus, needs a sign-in, or
    /// unavailable, with what to do and, when this launch syncs, "Synced 5 minutes ago" (docs/pm/plus-flow-fable-review.md N4).
    private var cloudRow: some View {
        let status = app.cloudSyncStatus
        return VStack(alignment: .leading, spacing: 4) {
            Label(status.title, systemImage: status.symbol)
                .font(Theme.font(.body)).foregroundStyle(Color.appPrimaryText)
                .fixedSize(horizontal: false, vertical: true)
            if status == .on, let at = app.cloudSync?.syncedAt {
                Text(CloudSyncStatus.Copy.synced(at)).font(Theme.font(.footnote)).foregroundStyle(Color.secondaryText)
                    .accessibilityIdentifier("settings.cloudSync.synced")
            }
            if let note = status.footnote {
                Text(note).font(Theme.font(.footnote)).foregroundStyle(Color.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("settings.cloudSync")
    }

    private func openSeasons() {
        if ParentalGate.isRequired(ageBand: app.settings.ageBand) {
            seasonsGate = ParentalGate.challenge(seed: UInt64(Date().timeIntervalSince1970))
        } else { router.go(.seasons) }
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
