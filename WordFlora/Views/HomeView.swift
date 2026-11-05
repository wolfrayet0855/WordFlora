import SwiftUI

/// Colour pair for one Explore tile (design-preview/home-v2/notes-color.md).
enum TileTint {
    case garden, levels, shed, visitors, badges

    var fill: Color {
        switch self {
        case .garden: .tileGardenFill
        case .levels: .tileLevelsFill
        case .shed: .tileShedFill
        case .visitors: .tileVisitorsFill
        case .badges: .tileBadgesFill
        }
    }
    var icon: Color {
        switch self {
        case .garden: .successText
        case .levels: .tileLevelsIcon
        case .shed: .tileShedIcon
        case .visitors: .tileVisitorsIcon
        case .badges: .accentText
        }
    }
}

/// Reports how many lines each Home label uses (read by HomeLayoutUITests via `-uitest-layout`).
private struct LabelLinesKey: PreferenceKey {
    static let defaultValue: [String: Int] = [:]
    static func reduce(value: inout [String: Int], nextValue: () -> [String: Int]) { value.merge(nextValue()) { $1 } }
}

/// Compares the label's rendered height with the height of the same text forced onto one line (only under `-uitest-layout`).
private struct LineProbe: ViewModifier {
    let key: String
    let font: Font
    static let enabled = ProcessInfo.processInfo.arguments.contains("-uitest-layout")

    func body(content: Content) -> some View {
        if Self.enabled {
            content
                .background(alignment: .topLeading) {
                    Text(key).font(font).lineLimit(1).fixedSize().hidden()
                        .background(GeometryReader { one in
                            Color.clear.preference(key: OneLineKey.self, value: one.size.height)
                        })
                }
                .overlayPreferenceValue(OneLineKey.self) { oneLine in
                    GeometryReader { g in
                        Color.clear.preference(key: LabelLinesKey.self,
                                               value: [key: oneLine > 0 ? max(1, Int((g.size.height / oneLine).rounded())) : 0])
                    }
                }
        } else {
            content
        }
    }
}

private extension View {
    func measuresLines(_ key: String, font: Font) -> some View { modifier(LineProbe(key: key, font: font)) }
}

private struct OneLineKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = max(value, nextValue()) }
}

struct HomeView: View {
    @Environment(AppModel.self) private var app
    @Environment(GameRouter.self) private var router
    @Environment(\.dynamicTypeSize) private var typeSize

    @ScaledMetric(relativeTo: .title3) private var gearSize: CGFloat = 22
    @ScaledMetric(relativeTo: .title2) private var playIcon: CGFloat = 22
    @ScaledMetric(relativeTo: .body) private var leafIcon: CGFloat = 18
    @ScaledMetric(relativeTo: .headline) private var sunDisc: CGFloat = 36
    @ScaledMetric(relativeTo: .body) private var tileIcon: CGFloat = 24
    @ScaledMetric(relativeTo: .caption) private var lockIcon: CGFloat = 13

    @State private var labelLines: [String: Int] = [:]
    /// "A short ad may play first." under Play, in the 3 minutes after "That's enough for now" (AdGate.returnVisit).
    @State private var playAdNote = false
    @State private var showNudge = false
    @State private var playStarting = false
    private let reportsLayout = LineProbe.enabled

    /// Accessibility text sizes switch the Explore grid to one column of list rows.
    private var singleColumn: Bool { typeSize.isAccessibilitySize }
    private static let radius: CGFloat = 20
    private var shape: RoundedRectangle { RoundedRectangle(cornerRadius: Self.radius, style: .continuous) }

    var body: some View {
        let profile = app.profile
        // One look at the unlock stats per render (each look fetches the garden), shared by every tile.
        let stats = app.unlockStats, showAll = app.settings.showEverything
        let unlocked = Set(Feature.allCases.filter { FeatureUnlockPolicy.isUnlocked($0, stats: stats, showEverything: showAll) })
        ZStack {
            // While the nudge card shows, Home's own content leaves the hierarchy (the audit still measures hidden text).
            if !showNudge {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        topBar
                        hero(days: profile?.gardenDays ?? 0, roseStock: profile?.roseOfJerichoCount ?? 0, roseProgress: profile?.roseSeedProgress ?? 0,
                             showRose: unlocked.contains(.rose),
                             // Before the first plant the next word brings one at once, so the count only shows after it (and not in Quiet Garden).
                             wordsTowardPlant: stats.plantsEarned > 0 && !app.settings.quietGarden ? app.game.wordsTowardPlant : nil)

                        if app.showWelcomeBack || app.plusOffer != nil {
                            VStack(spacing: 10) {
                                if app.showWelcomeBack { welcomeCard.transition(.opacity) }
                                if app.plusOffer != nil { plusOfferCard.transition(.opacity) }
                            }
                        }

                        playButton
                        playAdNoteLabel
                        if unlocked.contains(.dailyBloom) { dailyBloom.padding(.bottom, 4) }

                        Text("Explore")
                            .textCase(.uppercase).kerning(1.4)
                            .font(Theme.font(.caption, weight: .bold)).foregroundStyle(Color.secondaryText)
                            .padding(.horizontal, 4)
                            .accessibilityAddTraits(.isHeader)
                        exploreGrid(unlocked)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                    .onPreferenceChange(LabelLinesKey.self) { if reportsLayout { labelLines = $0 } }
                }
            }
            if showNudge {
                NudgeCard(puzzle: NudgeCardCopy.puzzleTarget(dailyBloomOpen: unlocked.contains(.dailyBloom),
                                                             dailyDone: app.dailyBloomDoneToday, butterflyOpen: unlocked.contains(.butterfly)),
                          onVisit: { closeNudge(); router.go(.garden) },
                          onPuzzle: {
                              closeNudge()
                              if !app.dailyBloomDoneToday && unlocked.contains(.dailyBloom) { router.go(.game(daily: true, level: nil)) }
                              else { router.go(.butterfly) }
                          },
                          onPlay: { closeNudge(); router.go(.game(daily: false, level: nil)) })
                .transition(.opacity)
            }
        }
        .background(Color.appBackground.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) { if !showNudge { bannerArea } }
        .task(id: app.restExitAt) { await followReturnWindow() }
        .task { await app.prepareBannerIfAllowed() }
        .onAppear { app.checkPlusOffer(); playAdNote = app.returnVisit == .adMayPlay }
        .navigationBarHidden(true)
        .overlay(alignment: .bottomLeading) { layoutReport }
    }

    // MARK: header

    private var topBar: some View {
        HStack {
            WordmarkView(style: .title).layoutPriority(1)
            Spacer()
            Button { router.go(.settings) } label: {
                Image(systemName: "gearshape.fill").font(.system(size: gearSize)).frame(minWidth: Theme.minTap, minHeight: Theme.minTap)
            }
            .foregroundStyle(Color.appPrimaryText)
            .accessibilityLabel("Settings")
        }
    }

    private func hero(days: Int, roseStock: Int, roseProgress: Int, showRose: Bool, wordsTowardPlant: Int?) -> some View {
        HStack(alignment: singleColumn ? .top : .center, spacing: 14) {
            FlowerView(petals: 8, sway: false)
                .frame(width: singleColumn ? 64 : 92, height: singleColumn ? 76 : 110)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 6) {
                Text("Guess words. Grow a garden.")
                    .font(Theme.font(.subheadline, weight: .medium)).foregroundStyle(Color.appPrimaryText)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 6) {
                    // At accessibility sizes the leaf would take a column of its own beside the words.
                    if !singleColumn {
                        Image(systemName: "leaf.fill").font(.system(size: leafIcon)).foregroundStyle(Color.successText)
                            .accessibilityHidden(true)
                    }
                    Text(days == 0 ? "Your garden is new" : "\(days) Garden \(days == 1 ? "Day" : "Days")")
                        .font(Theme.font(.body, weight: .bold)).foregroundStyle(Color.appPrimaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if let wordsTowardPlant {
                    // HOOK (progress meter): the visual words-toward-plant meter (mocked separately) goes here.
                    Text(PlantProgressCopy.homeLine(toward: wordsTowardPlant, per: app.game.wordsPerPlant))
                        .font(Theme.font(.subheadline)).foregroundStyle(Color.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if showRose {
                    let threshold = Economy.default.roseThreshold
                    let full = roseStock >= Economy.default.roseCap
                    Text(HomeRoseLine.text(stock: roseStock, progress: roseProgress, threshold: threshold, full: full))
                        .font(Theme.font(.caption)).foregroundStyle(Color.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14).padding(.vertical, 12)
        .background(
            LinearGradient(colors: [.tileLevelsFill, .tileGardenFill, .appBackground],
                           startPoint: UnitPoint(x: 0.2, y: 0), endPoint: UnitPoint(x: 0.9, y: 1.4)),
            in: shape)
        .overlay(shape.stroke(Color.appPrimaryText.opacity(0.08)))
        .accessibilityElement(children: .combine)
    }

    // MARK: cards above Play

    private func noteCard<Extra: View>(icon: String, title: String, detail: String, dismissLabel: String,
                                       dismiss: @escaping () -> Void, @ViewBuilder extra: () -> Extra) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon).font(.system(size: gearSize)).foregroundStyle(Color.accentText)
                .padding(.top, 10).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(Theme.font(.headline)).foregroundStyle(Color.appPrimaryText)
                    .fixedSize(horizontal: false, vertical: true)
                Text(detail).font(Theme.font(.subheadline)).foregroundStyle(Color.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
                extra()
            }
            .padding(.top, 8)
            Spacer(minLength: 0)
            Button { withAnimation { dismiss() } } label: {
                Image(systemName: "xmark").font(.body.weight(.semibold)).frame(width: Theme.minTap, height: Theme.minTap)
            }
            .foregroundStyle(Color.appPrimaryText)
            .accessibilityLabel(dismissLabel)
        }
        .padding(.leading, 14).padding(.trailing, 2).padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.appSurface, in: shape)
        .overlay(shape.stroke(Color.appPrimaryText.opacity(0.12)))
    }

    private var welcomeCard: some View {
        noteCard(icon: "cloud.rain.fill", title: "Welcome back", detail: app.welcomeLine,
                 dismissLabel: "Dismiss welcome", dismiss: { app.dismissWelcomeBack() }) { EmptyView() }
            .accessibilityIdentifier("welcome-card")
    }

    /// One gentle, dismissible card after a milestone (PlusOfferPolicy decides when).
    private var plusOfferCard: some View {
        noteCard(icon: "icloud.fill", title: PlusOfferPolicy.Copy.headline, detail: PlusOfferPolicy.Copy.detail,
                 dismissLabel: "Dismiss Plus offer", dismiss: { app.dismissPlusOffer() }) {
            Button { app.dismissPlusOffer(); router.go(.plus) } label: {
                Text(PlusOfferPolicy.Copy.button).underline()
                    .font(Theme.font(.callout, weight: .bold)).foregroundStyle(Color.accentText)
                    .frame(minHeight: Theme.minTap)
            }
        }
        .accessibilityIdentifier("plus-offer-card")
    }

    // MARK: play

    /// Play: an ordinary start, or (soon after "That's enough for now") an ad that may play first on this tap, or the
    /// nudge card (AppModel.playTappedOnHome).
    private func play() {
        guard !playStarting else { return }
        playStarting = true
        Task {
            let start = await app.playTappedOnHome(adNoteShown: playAdNote)
            playStarting = false
            playAdNote = false
            if start { router.go(.game(daily: false, level: nil)) } else { withAnimation(.easeOut(duration: 0.3)) { showNudge = true } }
        }
    }

    private func closeNudge() { showNudge = false }

    /// The honest ad note follows the 3 minute window: judged as Home appears or the window starts, and dropped when
    /// it ends. Nothing on screen counts down.
    private func followReturnWindow() async {
        playAdNote = app.returnVisit == .adMayPlay
        guard playAdNote, let since = app.restExitAt else { return }
        let left = AdGate.returnWindowSeconds - Date.now.timeIntervalSince(since)
        if left > 0 { try? await Task.sleep(for: .seconds(left)) }
        guard !Task.isCancelled else { return }
        playAdNote = app.returnVisit == .adMayPlay
    }

    @ViewBuilder private var playAdNoteLabel: some View {
        if playAdNote {
            // Said beside the choice that can lead to an ad, never hidden away (as on the resting card).
            Label(NudgeCardCopy.adNote, systemImage: "info.circle")
                .font(Theme.font(.footnote)).foregroundStyle(Color.secondaryText)
                .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("home.adNote")
        }
    }

    private var playButton: some View {
        Button { play() } label: {
            HStack(spacing: 10) {
                Image(systemName: "play.fill").font(.system(size: playIcon)).accessibilityHidden(true)
                Text("Play").measuresLines("Play", font: Theme.font(.title2, weight: .heavy))
            }
            .font(Theme.font(.title2, weight: .heavy))
            .foregroundStyle(Color.ink)
            .frame(maxWidth: .infinity, minHeight: 64)
            .padding(.vertical, singleColumn ? 8 : 0)
            .background(Color.appAccent, in: shape)       // flat accent: the audit reads gradients and glows as low contrast
            .contentShape(shape)
        }
        .buttonStyle(PressScaleStyle())
        .accessibilityLabel("Play")
    }

    private var dailyBloom: some View {
        let done = app.dailyBloomDoneToday
        // At accessibility sizes the disc sits above the words and the chevron goes, so "everyone" never breaks mid-word.
        let layout = singleColumn ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8)) : AnyLayout(HStackLayout(spacing: 12))
        return Button { router.go(.game(daily: true, level: nil)) } label: {
            layout {
                ZStack {
                    Circle().fill(done ? Color.successText.opacity(0.22) : Color.petalRose.opacity(0.3))
                    Image(systemName: done ? "checkmark.circle.fill" : "sun.max.fill")
                        .font(.system(size: sunDisc * 0.55))
                        .foregroundStyle(done ? Color.successText : Color.bloomIcon)
                }
                .frame(width: sunDisc, height: sunDisc)
                .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Daily Bloom").font(Theme.font(.headline, weight: .bold)).foregroundStyle(Color.appPrimaryText)
                        .measuresLines("Daily Bloom", font: Theme.font(.headline, weight: .bold))
                    Text(done ? "Done for today. See you tomorrow!" : "One word for everyone today")
                        .font(Theme.font(.footnote)).foregroundStyle(Color.appPrimaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if !singleColumn { Spacer(minLength: 0) }
                if !done && !singleColumn {
                    Image(systemName: "chevron.right").font(.footnote.weight(.bold)).foregroundStyle(Color.bloomIcon)
                        .accessibilityHidden(true)
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 12)
            .frame(maxWidth: .infinity, minHeight: 60, alignment: .leading)
            .background(Color.bloomFill, in: shape)
            .overlay(shape.stroke(Color.petalRose.opacity(0.4)))
            .shadow(color: .black.opacity(0.06), radius: 2, y: 1)
            .contentShape(shape)
        }
        .buttonStyle(PressScaleStyle())
        .disabled(done)
    }

    // MARK: explore

    @ViewBuilder private func exploreGrid(_ unlocked: Set<Feature>) -> some View {
        if singleColumn {
            VStack(spacing: 10) {
                featureTile(unlocked, nil, "Garden", "leaf.fill", .garden, .garden)
                featureTile(unlocked, .butterfly, "Levels", "map.fill", .levelMap, .levels)
                featureTile(unlocked, .shed, "Shed", "wrench.adjustable.fill", .shed, .shed)
                featureTile(unlocked, .butterfly, "Visitors", "ladybug.fill", .visitors, .visitors)
                featureTile(unlocked, .badges, "Badges", "medal.fill", .badges, .badges)
            }
        } else {
            Grid(horizontalSpacing: 10, verticalSpacing: 10) {
                GridRow {
                    featureTile(unlocked, nil, "Garden", "leaf.fill", .garden, .garden)
                    featureTile(unlocked, .butterfly, "Levels", "map.fill", .levelMap, .levels)
                }
                GridRow {
                    featureTile(unlocked, .shed, "Shed", "wrench.adjustable.fill", .shed, .shed)
                    featureTile(unlocked, .butterfly, "Visitors", "ladybug.fill", .visitors, .visitors)
                }
                GridRow {
                    featureTile(unlocked, .badges, "Badges", "medal.fill", .badges, .badges, wide: true)
                        .gridCellColumns(2)
                }
            }
        }
    }

    /// Every destination is visible. Ones that are not open yet are dashed and dimmed with a soft sparkle (never a lock), with a kind line on how to reach them.
    private func featureTile(_ unlocked: Set<Feature>, _ feature: Feature?, _ title: String, _ icon: String, _ route: GameRoute,
                             _ tint: TileTint, wide: Bool = false) -> some View {
        let open = feature.map { unlocked.contains($0) } ?? true
        let hint = open ? nil : feature.flatMap { FeatureUnlockPolicy.hint(for: $0) }
        let row = singleColumn || wide
        let labelFont = Theme.font(.body, weight: .heavy)

        let label = HStack(spacing: 5) {
            if !open {
                // A soft "on its way" sparkle, never a lock (no lock icons anywhere in the app).
                Image(systemName: "sparkles").font(.system(size: lockIcon)).foregroundStyle(Color.appPrimaryText)
                    .accessibilityHidden(true)
            }
            Text(title).font(labelFont).foregroundStyle(Color.appPrimaryText)
                .measuresLines(title, font: labelFont)
        }

        let text = VStack(alignment: row ? .leading : .center, spacing: 2) {
            label
            if let hint {
                Text(hint).font(Theme.font(.caption, weight: .medium)).foregroundStyle(Color.secondaryText)
                    .multilineTextAlignment(row ? .leading : .center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }

        let iconView = Image(systemName: icon)
            .font(.system(size: singleColumn ? tileIcon * 1.15 : tileIcon))
            .foregroundStyle(open ? tint.icon : Color.secondaryText)
            .frame(width: tileIcon * (singleColumn ? 1.4 : 1.2), height: tileIcon * (singleColumn ? 1.4 : 1.2))

        return Button { router.go(route) } label: {
            Group {
                if row {
                    HStack(spacing: singleColumn ? 14 : 12) {
                        iconView
                        text
                        if singleColumn { Spacer(minLength: 0) }
                    }
                    .frame(maxWidth: .infinity, alignment: singleColumn ? .leading : .center)
                } else {
                    VStack(spacing: 6) {
                        iconView
                        text
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                }
            }
            .padding(.horizontal, row ? 14 : 8)
            .padding(.top, row ? 10 : 14).padding(.bottom, row ? 10 : 12)
            // The whole tile is 96pt (rows 64pt, 72pt at accessibility sizes), padding included, as in home-v2.
            .frame(maxWidth: .infinity, minHeight: row ? (singleColumn ? 72 : 64) : 96)
            .background(open ? tint.fill : Color.appPrimaryText.opacity(0.06), in: shape)
            .background(Color.appBackground, in: shape)
            .overlay {
                if open {
                    shape.stroke(tint.icon.opacity(0.3), lineWidth: 1)
                } else {
                    shape.strokeBorder(Color.appPrimaryText.opacity(0.6), style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                }
            }
            .saturation(open ? 1 : 0.35)
            .shadow(color: open ? .black.opacity(0.06) : .clear, radius: 1, y: 1)
            .contentShape(shape)
        }
        .buttonStyle(PressScaleStyle())
        .disabled(!open)
        .accessibilityLabel(title)
        .accessibilityHint(hint ?? "")
        .accessibilityIdentifier("tile-\(title)")
        .accessibilityValue(reportsLayout ? "lines:\(labelLines[title] ?? 0)" : "")
    }

    /// Under `-uitest-layout`, one invisible-to-players element carries the line count of the Play and Daily Bloom labels.
    @ViewBuilder private var layoutReport: some View {
        if reportsLayout {
            Text(["Play", "Daily Bloom"].map { "\($0)=\(labelLines[$0] ?? 0)" }.joined(separator: ";"))
                .font(.system(size: 1)).foregroundStyle(Color.clear)
                .accessibilityIdentifier("home-layout-report")
        }
    }

    // MARK: banner

    /// Reserved, fixed-height slot so the page never jumps when an ad loads.
    @ViewBuilder private var bannerArea: some View {
        if app.showBanner {
            VStack(spacing: 2) {
                Group {
                    if app.ads.started { AdBannerView() } else { Color.clear }
                }
                .frame(height: 50)
                HStack(spacing: 16) {
                    Button("Go ad-free") { router.go(.plus) }
                    Link("Report an ad", destination: Links.reportAd)
                }
                .font(Theme.font(.caption)).foregroundStyle(Color.secondaryText)
                .opacity(app.ads.started ? 1 : 0)
            }
            .padding(.vertical, 4).frame(maxWidth: .infinity).background(Color.appBackground)
        }
    }
}

/// A gentle press for custom-drawn Home buttons.
private struct PressScaleStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
/// The small Rose of Jericho line on Home. Plain words, no symbols that read like a sum
/// (an earlier "x1 · 0 of 8" read as "1 0x8").
enum HomeRoseLine {
    static func text(stock: Int, progress: Int, threshold: Int, full: Bool) -> String {
        let have = stock == 1 ? "1 Rose of Jericho in your satchel" : "\(stock) Roses of Jericho in your satchel"
        if full { return "\(have). Your satchel is full." }
        let toGo = max(0, threshold - progress)
        let more = toGo == 1 ? "1 more word" : "\(toGo) more words"
        if stock == 0 { return "Finish \(more) to earn a Rose of Jericho." }
        return "\(have). Finish \(more) for another."
    }
}
