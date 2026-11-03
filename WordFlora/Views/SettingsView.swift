import SwiftUI

struct SettingsView: View {
    @Environment(AppModel.self) private var app
    @Environment(GameRouter.self) private var router

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
                Toggle("Sound", isOn: $s.soundOn).onChange(of: s.soundOn) { _, v in app.game.soundEnabled = v }
                Toggle("Haptics", isOn: $s.hapticsOn)
                Toggle("Calm mode", isOn: $s.calmMode)
                Toggle("Quiet Garden", isOn: $s.quietGarden)
                Text("Calm mode removes the thirsty look and halves celebrations. Quiet Garden hides counters and timers so tending is just relaxing.")
                    .font(.footnote).foregroundStyle(.secondary)
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
