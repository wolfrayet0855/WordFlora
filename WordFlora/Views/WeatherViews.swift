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

/// The forecast card on Home, the day before: what is coming, one gentle step, and "Got it".
struct ForecastCard: View {
    let kind: WeatherKind
    let onGotIt: () -> Void
    @Environment(\.dynamicTypeSize) private var typeSize
    @ScaledMetric(relativeTo: .title3) private var iconSize: CGFloat = 24
    private var shape: RoundedRectangle { RoundedRectangle(cornerRadius: 20, style: .continuous) }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                if !typeSize.isAccessibilitySize {
                    Image(systemName: kind.symbol).font(.system(size: iconSize)).foregroundStyle(Color.accentText)
                        .accessibilityHidden(true)
                }
                Text(WeatherCopy.forecastTitle(kind))
                    .font(Theme.font(.headline)).foregroundStyle(Color.appPrimaryText)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
            }
            Text(WeatherUICopy.cardLine).font(Theme.font(.subheadline)).foregroundStyle(Color.appPrimaryText)
                .fixedSize(horizontal: false, vertical: true)
            // HOOK (weather helpers, E-7): the "Set out the <helper>" step and button go here.
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
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.appSurface, in: shape)
        .overlay(shape.stroke(Color.appPrimaryText.opacity(0.12)))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("weather-forecast-card")
    }
}

/// The soft banner on the weather day itself.
struct WeatherBanner: View {
    let kind: WeatherKind
    @Environment(\.dynamicTypeSize) private var typeSize
    @ScaledMetric(relativeTo: .title3) private var iconSize: CGFloat = 22
    private var shape: RoundedRectangle { RoundedRectangle(cornerRadius: 20, style: .continuous) }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            if !typeSize.isAccessibilitySize {
                Image(systemName: kind.symbol).font(.system(size: iconSize)).foregroundStyle(Color.accentText)
                    .accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(WeatherCopy.eventLine(kind)).font(Theme.font(.headline)).foregroundStyle(Color.appPrimaryText)
                    .fixedSize(horizontal: false, vertical: true)
                Text(WeatherUICopy.bannerLine).font(Theme.font(.subheadline)).foregroundStyle(Color.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
                // HOOK (weather puzzle, E-8): the optional "Weather puzzle" entry goes here.
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.tileGardenFill, in: shape)
        .overlay(shape.stroke(Color.appPrimaryText.opacity(0.12)))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("weather-banner")
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
            Section(WeatherUICopy.sectionTitle) {
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
