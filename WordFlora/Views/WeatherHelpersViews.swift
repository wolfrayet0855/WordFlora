import SwiftUI

// The Shed's "Weather helpers" (E-7; design-preview/events shed and shed-out frames). All six arrive as a free kit;
// only the helper for tomorrow's (or today's) weather has a Set out button, the rest read Ready. No prices, no Plus
// tags, no locks, and nothing is used up. Hidden in Calm and Quiet Garden.

/// The helper's picture: a drawn icon in a ring (builder C may swap in final art by name `helper_<id>`).
struct HelperIcon: View {
    let helper: WeatherHelper
    @ScaledMetric(relativeTo: .title2) private var size: CGFloat = 52

    var body: some View {
        ZStack {
            Circle().fill(Color.appBackground)
            Circle().strokeBorder(Color(red: 0.55, green: 0.36, blue: 0.20), lineWidth: 3)
            if UIImage(named: "helper_\(helper.rawValue)") != nil {
                Image("helper_\(helper.rawValue)").resizable().scaledToFit().padding(size * 0.14)
            } else {
                Image(systemName: helper.symbol).font(.system(size: size * 0.42, weight: .semibold))
                    .foregroundStyle(Color.successText)
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

struct ShedWeatherSection: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var puzzle = false

    var body: some View {
        let w = app.weatherNow
        let coverable = ShelterPolicy.coverable(w)
        VStack(alignment: .leading, spacing: 10) {
            Text(ShelterCopy.sectionTitle.uppercased()).font(Theme.font(.footnote, weight: .heavy)).tracking(1.2)
                .foregroundStyle(Color.secondaryText)
                .accessibilityLabel(ShelterCopy.sectionTitle).accessibilityAddTraits(.isHeader)
            Text(w.forecast != nil ? ShelterCopy.sectionLine : ShelterCopy.sectionLineNoForecast)
                .font(Theme.font(.subheadline)).foregroundStyle(Color.secondaryText).fixedSize(horizontal: false, vertical: true)
            if let c = coverable {
                Label(ShelterCopy.chip(c.kind, today: c.day == w.today), systemImage: "wind")
                    .font(Theme.font(.subheadline, weight: .bold)).foregroundStyle(Color.appPrimaryText)
                    .padding(.horizontal, 14).padding(.vertical, 10).frame(minHeight: Theme.minTap)
                    .background(Color.tileLevelsFill, in: Capsule())
                    .overlay(Capsule().stroke(Color.appPrimaryText.opacity(0.25)))
                    .accessibilityIdentifier("shed.weatherChip")
            }
            ForEach(WeatherHelper.allCases) { h in row(h) }
            if app.weatherPuzzleOpen {
                Button(WeatherPuzzleCopy.bannerButton) { puzzle = true }
                    .buttonStyle(SecondaryButtonStyle())
                    .accessibilityIdentifier("shed.weatherPuzzle")
            }
        }
        .fullScreenCover(isPresented: $puzzle) { WeatherPuzzleSheet { puzzle = false }.environment(app) }
    }

    private func row(_ h: WeatherHelper) -> some View {
        let state = app.helperState(h)
        let layout = typeSize.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: 10)) : AnyLayout(HStackLayout(spacing: 14))
        return layout {
            HStack(spacing: 14) {
                HelperIcon(helper: h)
                VStack(alignment: .leading, spacing: 2) {
                    Text(ShelterCopy.name(h)).font(Theme.font(.headline, weight: .bold)).foregroundStyle(Color.appPrimaryText)
                    Text(ShelterCopy.blurb(h)).font(Theme.font(.subheadline)).foregroundStyle(Color.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .accessibilityElement(children: .combine)
            Spacer(minLength: 0)
            trailing(h, state)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.appSurface, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
        .overlay(RoundedRectangle(cornerRadius: Theme.cardRadius).stroke(state == .setOut ? Color.successText : Color.appPrimaryText.opacity(0.08),
                                                                          lineWidth: state == .setOut ? 2 : 1))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("helper.\(h.rawValue)")
    }

    @ViewBuilder private func trailing(_ h: WeatherHelper, _ state: ShelterPolicy.HelperState) -> some View {
        switch state {
        case .ready:
            Label(ShelterCopy.ready, systemImage: "checkmark").font(Theme.font(.headline, weight: .bold)).foregroundStyle(Color.appPrimaryText)
                .accessibilityLabel(ShelterCopy.ready)
        case .canSetOut:
            Button(ShelterCopy.setOut) { app.setOutHelper() }
                .font(Theme.font(.headline, weight: .bold)).foregroundStyle(Color.ink)
                .padding(.horizontal, 18).frame(minHeight: Theme.minTap)
                .background(Color.appAccent, in: Capsule())
                .accessibilityLabel("\(ShelterCopy.setOut) \(ShelterCopy.name(h))")
                .accessibilityHint(ShelterCopy.setOutHint)
                .accessibilityIdentifier("helper.\(h.rawValue).setOut")
        case .setOut:
            Label(ShelterCopy.isOut, systemImage: "checkmark.circle.fill").font(Theme.font(.headline, weight: .bold))
                .foregroundStyle(Color.successText)
                .padding(.horizontal, 14).frame(minHeight: Theme.minTap)
                .overlay(Capsule().stroke(Color.successText, lineWidth: 2))
                .accessibilityLabel(ShelterCopy.rowLabel(h, state: .setOut))
                .accessibilityIdentifier("helper.\(h.rawValue).out")
        }
    }
}
