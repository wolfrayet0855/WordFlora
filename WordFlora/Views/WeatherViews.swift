import SwiftUI

// Garden weather on Home and in Settings (ticket E-5, E-10, E-12). Plain, calm, no countdowns, no red, no alarm icons.
// Calm mode and Quiet Garden show none of it (AppModel.homeWeather is empty there).

extension WeatherKind {
    /// A soft SF Symbol for each kind (never an alarm or warning glyph).
    var symbol: String {
        switch self {
        case .drySpell: return "sun.haze.fill"
        case .busyBugs: return "ladybug.fill"
        case .bigWind: return "wind"
        case .frostyNight: return "snowflake"
        case .hotDay: return "sun.max.fill"
        case .hailShower: return "cloud.hail.fill"
        case .bigPuddles: return "cloud.rain.fill"
        }
    }
}

/// "Tomorrow: windy" under the Home header.
struct WeatherChip: View {
    let text: String
    let kind: WeatherKind?

    var body: some View {
        Label {
            Text(text).font(Theme.font(.footnote, weight: .semibold)).foregroundStyle(Color.appPrimaryText)
                .fixedSize(horizontal: false, vertical: true)
        } icon: {
            Image(systemName: kind?.symbol ?? "cloud.sun.fill").foregroundStyle(Color.accentText)
        }
        .padding(.horizontal, 12).padding(.vertical, 6)
        .frame(minHeight: 32)
        // A rounded rectangle, not a capsule: at accessibility sizes the chip wraps and a capsule's ends cut the text.
        .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.appPrimaryText.opacity(0.12)))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(WeatherUICopy.chipLabel(text))
        .accessibilityIdentifier("weather-chip")
    }
}

/// The weather picture across the top of the Home card (builder C's `WeatherStage` on a full-width sky): a found
/// plant in its pot, posed by the weather. Decorative (hidden from VoiceOver; the card's words say it all). Reduce
/// Motion (system or the app's switch) and Low Power hold one still frame; it pauses when the app is not active.
struct WeatherCardArt: View {
    let kind: WeatherKind
    var look: WeatherEffect = .full
    let imageName: String
    @Environment(AppModel.self) private var app
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.colorScheme) private var scheme
    @State private var lowPower = LowPowerWatch()
    /// Home is a hub: the weather plays for a few seconds as the card shows, then holds one frame.
    @State private var settled = false
    static let plantSize: CGFloat = 80
    static let playSeconds = 5.0

    var body: some View {
        let r = WeatherOverlay.sceneRect(plantSize: Self.plantSize)
        let still = reduceMotion || app.settings.reduceMotionOverride || lowPower.isOn || settled
        ZStack(alignment: .bottom) {
            WeatherSky(kind: kind, look: look)
            Color(hex: scheme == .dark ? 0x3A503A : 0xE3D9C0)
                .frame(height: (WeatherOverlay.sceneHeight - WeatherOverlay.floorY) * r.height / WeatherOverlay.sceneHeight)
            WeatherStage(kind: kind, look: look, plantSize: Self.plantSize, still: still, paused: scenePhase != .active) {
                WeatherPreviewPlant(imageName: imageName, size: Self.plantSize)
            }
        }
        .frame(maxWidth: .infinity).frame(height: r.height)
        .clipped()
        .accessibilityHidden(true)
        .accessibilityIdentifier("weather-card-art")
        .task {
            try? await Task.sleep(for: .seconds(Self.playSeconds))
            settled = true
        }
    }
}

/// The forecast card on Home, the day before: what is coming, one gentle step, the helper to set out, and "Got it".
struct ForecastCard: View {
    let kind: WeatherKind
    let onGotIt: () -> Void
    @Environment(AppModel.self) private var app
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var kitNew = false
    /// Read once as the card opens and after a tap, not live: a card that re-reads the garden on every pass redraws
    /// Home, and the Dynamic Type audit then reports the texts around it (as found with the rest card's ad note).
    @State private var helperState: ShelterPolicy.HelperState = .ready
    @State private var plantImage: String?
    private var helper: WeatherHelper { WeatherHelper.helper(for: kind) }
    private var shape: RoundedRectangle { RoundedRectangle(cornerRadius: 20, style: .continuous) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Accessibility sizes drop the picture so the words get the room.
            if !typeSize.isAccessibilitySize, let plantImage { WeatherCardArt(kind: kind, look: .light, imageName: plantImage) }
            VStack(alignment: .leading, spacing: 8) {
                Text(WeatherCopy.forecastTitle(kind))
                    .font(Theme.font(.headline)).foregroundStyle(Color.appPrimaryText)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                Text(WeatherUICopy.cardLine).font(Theme.font(.subheadline)).foregroundStyle(Color.appPrimaryText)
                    .fixedSize(horizontal: false, vertical: true)
                helperStep
                Text(WeatherUICopy.cardReady).font(Theme.font(.subheadline)).foregroundStyle(Color.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
                Button(action: onGotIt) {
                    Text(WeatherUICopy.gotIt).font(Theme.font(.callout, weight: .bold)).foregroundStyle(Color.ink)
                        .padding(.horizontal, 18).frame(minHeight: Theme.minTap)
                        .background(Color.appAccent, in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityHint(WeatherUICopy.gotItHint)
                .accessibilityIdentifier("weather-gotit")
            }
            .padding(Space.card)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.appSurface, in: shape)
        .clipShape(shape)
        .overlay(shape.stroke(Color.appPrimaryText.opacity(0.12)))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("weather-forecast-card")
        .onAppear {
            if app.receiveWeatherKitIfDue() { kitNew = true }
            helperState = app.helperState(helper)
            plantImage = app.weatherCardPlantImage
        }
    }

    /// E-7: one tap sets out tomorrow's helper (free, nothing used up); then it reads as done. Hidden in Calm (looks only).
    @ViewBuilder private var helperStep: some View {
        switch helperState {
        case .setOut:
            Label {
                Text(ShelterCopy.cardDone(helper)).font(Theme.font(.subheadline, weight: .semibold)).foregroundStyle(Color.appPrimaryText)
                    .fixedSize(horizontal: false, vertical: true)
            } icon: {
                Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.successText)
            }
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("weather-helper-done")
        case .canSetOut:
            if kitNew {
                Text(WeatherCopy.kitLine).font(Theme.font(.subheadline)).foregroundStyle(Color.appPrimaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Button { app.setOutHelper(); helperState = app.helperState(helper) } label: {
                Label { Text(ShelterCopy.cardStep(helper)) } icon: { HelperArt(helper: helper).frame(width: 28, height: 28) }
                    .font(Theme.font(.callout, weight: .bold)).foregroundStyle(Color.appPrimaryText)
                    .padding(.horizontal, 16).frame(minHeight: Theme.minTap)
                    .overlay(Capsule().stroke(Color.successText, lineWidth: 2))
            }
            .buttonStyle(.plain)
            .accessibilityHint(ShelterCopy.setOutHint)
            .accessibilityIdentifier("weather-setout")
        case .ready:
            EmptyView()
        }
    }
}

/// The soft banner on the weather day itself, with the weather puzzle's entry while it is open (never in Calm).
struct WeatherBanner: View {
    let kind: WeatherKind
    /// Opens the weather puzzle (Home presents it, so the cover does not live inside the scrolling content).
    let onPuzzle: () -> Void
    /// Changes when the puzzle closes, so the entry and the look are read again (a solve removes the entry).
    var refreshToken = 0
    @Environment(AppModel.self) private var app
    @Environment(\.dynamicTypeSize) private var typeSize
    /// Read as the banner opens and when the puzzle closes, not live (see `ForecastCard`).
    @State private var open = false
    @State private var reward = WeatherPuzzlePolicy.Reward.none
    @State private var sheltered = false
    @State private var plantImage: String?
    private var shape: RoundedRectangle { RoundedRectangle(cornerRadius: 20, style: .continuous) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if !typeSize.isAccessibilitySize, let plantImage {
                WeatherCardArt(kind: kind, look: sheltered ? .snug : .full, imageName: plantImage)
            }
            VStack(alignment: .leading, spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(WeatherCopy.eventLine(kind)).font(Theme.font(.headline)).foregroundStyle(Color.appPrimaryText)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("weather-banner-text")
                    Text(WeatherUICopy.bannerLine).font(Theme.font(.subheadline)).foregroundStyle(Color.appPrimaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if open {
                    Text(WeatherPuzzleCopy.rewardLine(reward)).font(Theme.font(.subheadline))
                        .foregroundStyle(Color.appPrimaryText).fixedSize(horizontal: false, vertical: true)
                    Button(action: onPuzzle) {
                        Text(WeatherPuzzleCopy.bannerButton).font(Theme.font(.callout, weight: .bold)).foregroundStyle(Color.ink)
                            .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal, 18).padding(.vertical, 6).frame(maxWidth: .infinity, minHeight: Theme.minTap)
                            .background(Color.appAccent, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("weather-puzzle")
                }
            }
            .padding(Space.card)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.tileGardenFill, in: shape)
        .clipShape(shape)
        .overlay(shape.stroke(Color.appPrimaryText.opacity(0.12)))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("weather-banner")
        .onAppear(perform: refresh)
        .onChange(of: refreshToken) { _, _ in refresh() }
    }

    private func refresh() {
        open = app.weatherPuzzleOpen
        reward = app.weatherPuzzleReward
        sheltered = app.weatherSheltered
        plantImage = app.weatherCardPlantImage
    }
}

/// Settings > Garden weather: the weather switch, the Wild Weather opt-in (with a confirmation) and the forecast
/// reminder. Hidden in Quiet Garden; in Calm mode it only says Calm keeps the weather away (no second calm control).
struct GardenWeatherSettingsSection: View {
    @Environment(AppModel.self) private var app
    @State private var confirmWild = false

    var body: some View {
        let s = app.settings
        if !s.quietGarden {
            Section(settings: WeatherUICopy.sectionTitle) {
                if s.calmMode {
                    Text(WeatherUICopy.calmFootnote).font(Theme.font(.footnote)).foregroundStyle(Color.secondaryText)
                        .accessibilityIdentifier("settings.weatherCalm")
                } else {
                    Toggle(WeatherUICopy.toggle, isOn: Binding(get: { s.gardenWeather },
                                                               set: { s.gardenWeather = $0; app.refreshWeather(); app.refreshReminders() }))
                        .accessibilityIdentifier("settings.gardenWeather")
                    Text(WeatherUICopy.footnote).font(Theme.font(.footnote)).foregroundStyle(Color.secondaryText)
                    if app.wildWeatherAvailable {
                        Toggle(WeatherUICopy.wildToggle, isOn: Binding(get: { app.wildWeatherOn },
                                                                       set: { on in if on { confirmWild = true } else { app.setWildWeather(false) } }))
                            .accessibilityIdentifier("settings.wildWeather")
                        Text(WeatherUICopy.wildFootnote).font(Theme.font(.footnote)).foregroundStyle(Color.secondaryText)
                        if WeatherUICopy.showsWildGrownUpNote(ageBand: s.ageBand) {
                            Text(WeatherUICopy.wildGrownUpNote).font(Theme.font(.footnote)).foregroundStyle(Color.secondaryText)
                                .accessibilityIdentifier("settings.wildGrownUpNote")
                        }
                    }
                    if app.weatherNotifyAvailable {
                        Toggle(WeatherUICopy.notifyToggle, isOn: Binding(get: { s.weatherNotify },
                                                                         set: { s.weatherNotify = $0; app.refreshReminders() }))
                            .accessibilityIdentifier("settings.weatherNotify")
                        Text(WeatherUICopy.notifyFootnote).font(Theme.font(.footnote)).foregroundStyle(Color.secondaryText)
                    }
                }
            }
            .alert(WeatherUICopy.wildConfirmTitle, isPresented: $confirmWild) {
                Button(WeatherUICopy.wildConfirm) { app.setWildWeather(true) }
                Button(WeatherUICopy.wildCancel, role: .cancel) {}
            } message: {
                Text(WeatherUICopy.wildConfirmMessage)
            }
        }
    }
}
