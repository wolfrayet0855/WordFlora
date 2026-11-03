import SwiftUI

struct SettingsView: View {
    @Environment(AppModel.self) private var app
    @Environment(GameRouter.self) private var router
    @State private var reminderDenied = false

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
            Section("Comfort") {
                Toggle("Sound", isOn: $s.soundOn).onChange(of: s.soundOn) { _, v in app.game.soundEnabled = v; app.updateAmbience() }
                Toggle("Garden ambience", isOn: $s.ambienceOn).onChange(of: s.ambienceOn) { _, _ in app.updateAmbience() }
                Toggle("Haptics", isOn: $s.hapticsOn)
                Toggle("Calm mode", isOn: $s.calmMode)
                Toggle("Quiet Garden", isOn: $s.quietGarden)
                Text("Calm mode removes the thirsty look and halves celebrations. Quiet Garden hides counters and timers so tending is just relaxing.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
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
                Text("At most one a day, never at night, and they stop on their own if you take a break.").font(.footnote).foregroundStyle(.secondary)
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
            Section("WordFlora Plus") {
                Button { router.go(.plus) } label: { Label("Remove ads and sync with iCloud", systemImage: "sparkles") }
            }
            Section("Privacy and ads") {
                Link("Report an ad", destination: Links.reportAd)
                Link("Privacy Policy", destination: Links.privacy)
                if app.ads.privacyOptionsRequired {
                    Button("Ad privacy choices") { Task { await app.ads.presentPrivacyOptions() } }
                }
            }
            Section("About") {
                LabeledContent("Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .scrollContentBackground(.hidden)
        .background(Color.appBackground.ignoresSafeArea())
    }
}
