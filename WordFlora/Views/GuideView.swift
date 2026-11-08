import SwiftUI
import UIKit

/// The first-run onboarding guide (design-preview/onboarding-guide/README.md): eight short pages, a Skip on every page,
/// dots for progress, Back and Next. In the first session it sits between the age question and the tutorial word; from
/// Settings ("Show the guide again") it opens as a full-screen cover where Skip reads Close and the last button Done.
/// No ads, Plus, prices or prompts in here, and the guide writes nothing but `guideSeen`.
///
/// Each illustration is drawn into one `Canvas` and read by VoiceOver as one image with its label. The small words
/// inside a picture are part of the drawing, so they stay the same size at every text size (the picture shrinks at
/// accessibility sizes while the page text grows and scrolls).
struct GuideView: View {
    let mode: GuideMode
    /// Replay only: closes the cover. The first session moves on through the onboarding flow instead.
    var onClose: (() -> Void)? = nil

    @Environment(AppModel.self) private var app
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var pager: GuidePager
    @State private var forward = true
    @AccessibilityFocusState private var titleFocused: Bool

    init(mode: GuideMode, onClose: (() -> Void)? = nil) {
        self.mode = mode
        self.onClose = onClose
        _pager = State(initialValue: GuidePager(mode: mode))
    }

    private var still: Bool {
        GuideLook.still(systemReduceMotion: systemReduceMotion, reduceMotionOverride: app.settings.reduceMotionOverride,
                        calm: app.settings.calmMode)
    }
    private var quiet: Bool { GuideLook.quietCopy(calm: app.settings.calmMode, quiet: app.settings.quietGarden, underThirteen: app.settings.isUnderThirteen) }
    private var large: Bool { typeSize.isAccessibilitySize }

    var body: some View {
        VStack(spacing: 0) {
            topBar
            ZStack {
                GuidePageView(page: GuideCopy.pages[pager.page], index: pager.page, still: still, quiet: quiet,
                              showsPoints: GuideLook.showsPoints(quiet: app.settings.quietGarden), large: large,
                              titleFocused: $titleFocused)
                    .id(pager.page)
                    .transition(pageTransition)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            // Keeps a sliding page inside the pager (as a clip did), and fades the last 24 pt instead of a hard edge,
            // so words that run on below read as "there is more" (the page's scroll indicator shows it too).
            .mask {
                VStack(spacing: 0) {
                    Color.black
                    LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom).frame(height: GuideLook.bottomFade)
                }
            }
            .contentShape(Rectangle())
            .simultaneousGesture(swipe)
            footer
        }
        .background(Color.appBackground.ignoresSafeArea())
        .sensoryFeedback(.selection, trigger: pager.page) { _, _ in app.settings.hapticsOn }
    }

    private var pageTransition: AnyTransition {
        if still { return .opacity }
        return .asymmetric(insertion: .move(edge: forward ? .trailing : .leading),
                           removal: .move(edge: forward ? .leading : .trailing))
    }

    // MARK: Top bar: wordmark (decorative here) and Skip

    private var topBar: some View {
        HStack {
            GuideWordmark(height: large ? 20 : 24)
            Spacer(minLength: 8)
            if pager.showsSkip {
                Button { finish() } label: {
                    Text(pager.skipLabel)
                        .font(Theme.font(.body, weight: .heavy)).foregroundStyle(Color.accentText)
                        .padding(.horizontal, 12)
                        .frame(minWidth: Theme.minTap, minHeight: Theme.minTap)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityHint(pager.skipHint)
                .accessibilityIdentifier("onboardingGuide.skip")
            } else {
                // Skip steps aside on the last page; a plain spacer keeps the bar's height. No accessibility modifiers here:
                // even a hidden view becomes an (empty) element in the audit tree.
                Spacer(minLength: 0).frame(width: Theme.minTap, height: Theme.minTap)
            }
        }
        // The wordmark and the Skip text both sit on the screen gutter (Skip carries 12 points of its own tap padding).
        .padding(.leading, Space.gutter).padding(.trailing, Space.gutter - 12)
        .frame(minHeight: 52)
    }

    // MARK: Footer: dots, then Back and Next

    private var footer: some View {
        VStack(spacing: 0) {
            GuideDots(pager: pager) { go(to: $0) }
            if large {
                VStack(spacing: 8) {
                    nextButton
                    if pager.showsBack { backButton }
                }
            } else {
                HStack(spacing: 10) {
                    // Page one keeps Back's place, so Next is the same width on every page.
                    if pager.showsBack { backButton.frame(width: 104) } else { Color.clear.frame(width: 104, height: 1) }
                    nextButton
                }
            }
        }
        .padding(.horizontal, Space.gutter).padding(.top, 0).padding(.bottom, Space.s)
    }

    private var backButton: some View {
        Button { go(to: pager.page - 1) } label: {
            Text(GuideCopy.UI.back)
                .font(Theme.font(.title3, weight: .heavy)).foregroundStyle(Color.appPrimaryText)
                .multilineTextAlignment(.center)
                .padding(.vertical, large ? 10 : 0).padding(.horizontal, 8)
                .frame(maxWidth: .infinity, minHeight: 56)
                .background(Color.appSurface, in: RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                    .strokeBorder(Color.appPrimaryText.opacity(0.16), lineWidth: 1.5))
                .contentShape(Rectangle())
        }
        .buttonStyle(GuidePressStyle())
        .accessibilityIdentifier("onboardingGuide.back")
    }

    private var nextButton: some View {
        Button { next() } label: {
            HStack(spacing: 8) {
                Text(pager.nextLabel)
                if pager.nextShowsChevron {
                    Image(systemName: "chevron.right").font(Theme.font(.body, weight: .heavy)).accessibilityHidden(true)
                }
            }
            .multilineTextAlignment(.center)
            .padding(.vertical, large ? 10 : 0).padding(.horizontal, 8)
        }
        .buttonStyle(PrimaryButtonStyle())        // flat accent: the audit reads gradients as low contrast
        .accessibilityLabel(pager.nextLabel)
        .accessibilityIdentifier("onboardingGuide.next")
    }

    // MARK: Paging

    private var swipe: some Gesture {
        DragGesture(minimumDistance: 24).onEnded { v in
            let dx = v.translation.width
            guard abs(dx) > 40, abs(dx) > abs(v.translation.height) else { return }
            if dx < 0 { if !pager.isLast { go(to: pager.page + 1) } } else { go(to: pager.page - 1) }
        }
    }

    private func next() {
        if pager.isLast { finish() } else { go(to: pager.page + 1) }
    }

    private func go(to page: Int) {
        let target = min(pager.count - 1, max(0, page))
        guard target != pager.page else { return }
        forward = target > pager.page
        withAnimation(still ? .easeInOut(duration: 0.25) : .spring(response: 0.42, dampingFraction: 0.9)) { pager.go(to: target) }
        if UIAccessibility.isVoiceOverRunning {
            // VoiceOver moves to the new page's title once the page has come in.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { titleFocused = true }
        }
    }

    private func finish() {
        app.finishGuide()
        onClose?()
    }
}

/// The v3 wordmark at a fixed 24 point height, held to the leading edge (decorative inside the guide, so hidden from
/// VoiceOver). Increase Contrast swaps in the one-colour art, as WordmarkView does.
private struct GuideWordmark: View {
    let height: CGFloat
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        Group {
            if contrast == .increased {
                Image("WordmarkMono").renderingMode(.template).resizable().scaledToFit().foregroundStyle(Color.appPrimaryText)
            } else {
                Image("Wordmark").renderingMode(.original).resizable().scaledToFit()
            }
        }
        .frame(height: height)
        .accessibilityHidden(true)
    }
}

/// The page dots: the current page is a wider capsule (shape, not only colour). One adjustable element for VoiceOver.
private struct GuideDots: View {
    let pager: GuidePager
    let go: (Int) -> Void

    var body: some View {
        // A full-width, 44 point tall strip, so the adjustable element has a proper hit area.
        Color.clear
            .frame(maxWidth: .infinity, minHeight: Theme.minTap, maxHeight: Theme.minTap)
            .overlay(alignment: .bottom) {
                HStack(spacing: 8) {
                    ForEach(0..<pager.count, id: \.self) { i in
                        Capsule()
                            .fill(i == pager.page ? Color.appPrimaryText : Color.appPrimaryText.opacity(0.28))
                            .frame(width: i == pager.page ? 24 : 8, height: 8)
                    }
                }
                .padding(.bottom, Space.m)          // dots to buttons: 12
            }
            .contentShape(Rectangle())
            .accessibilityElement(children: .ignore)
        .accessibilityLabel(GuideCopy.UI.dotsLabel)
        .accessibilityValue(pager.dotsValue)
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: go(pager.page + 1)
            case .decrement: go(pager.page - 1)
            @unknown default: break
            }
        }
        .accessibilityIdentifier("onboardingGuide.page")
    }
}

private struct GuidePressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: One page

private struct GuidePageView: View {
    let page: GuideCopy.Page
    let index: Int
    let still: Bool
    let quiet: Bool
    let showsPoints: Bool
    let large: Bool
    var titleFocused: AccessibilityFocusState<Bool>.Binding

    var body: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(spacing: 0) {
                    GuideArtCard(page: page.id, still: still, quiet: quiet, showsPoints: showsPoints, large: large)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(page.art)
                        .accessibilityAddTraits(.isImage)
                        .accessibilityIdentifier("onboardingGuide.art")
                    VStack(alignment: large ? .leading : .center, spacing: Space.s) {
                        Text(page.title)
                            .font(Theme.font(.title, weight: .heavy)).foregroundStyle(Color.appPrimaryText)
                            .multilineTextAlignment(large ? .leading : .center)
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityAddTraits(.isHeader)
                            .accessibilityFocused(titleFocused)
                            .accessibilityIdentifier("onboardingGuide.title")
                        ForEach(page.lines(quiet: quiet), id: \.self) { line in
                            Text(line)
                                .font(Theme.font(.body, weight: .medium)).foregroundStyle(Color.secondaryText)
                                .multilineTextAlignment(large ? .leading : .center)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .frame(maxWidth: large ? .infinity : 330, alignment: large ? .leading : .center)
                    .frame(maxWidth: .infinity, alignment: large ? .leading : .center)
                    .padding(.top, large ? Space.card : Space.section).padding(.horizontal, large ? 4 : 8)
                }
                .padding(.horizontal, Space.gutter).padding(.top, Space.xs).padding(.bottom, Space.section)
                // The picture and its words sit in the middle of the free space, not pinned to the top over a gap.
                .frame(minHeight: geo.size.height)
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollIndicators(.visible)
        }
    }
}

// MARK: Illustration card

/// The 160 degree two-colour card behind each picture (README "Colours").
private struct GuideArtCard: View {
    let page: String
    let still: Bool
    let quiet: Bool
    let showsPoints: Bool
    let large: Bool

    static let artSize = CGSize(width: 361, height: 372)
    private var scale: CGFloat { large ? 0.6 : 1 }
    private var shape: RoundedRectangle { RoundedRectangle(cornerRadius: 28, style: .continuous) }

    private var colors: (Color, Color) {
        switch page {
        case "guess", "tend", "levels": return (.tileLevelsFill, .tileGardenFill)
        case "plants": return (.tileGardenFill, .tileBadgesFill)
        case "love": return (.bloomFill, .tileGardenFill)
        case "garden": return (.tileVisitorsFill, .tileShedFill)
        case "daily": return (.bloomFill, .tileBadgesFill)
        default: return (.tileBadgesFill, .tileVisitorsFill)
        }
    }

    var body: some View {
        let (a1, a2) = colors
        ZStack(alignment: .top) {
            shape.fill(LinearGradient(stops: [.init(color: a1, location: 0), .init(color: a2, location: 0.75)],
                                      startPoint: UnitPoint(x: 0.33, y: 0), endPoint: UnitPoint(x: 0.67, y: 1)))
            if still {
                drawing(t: GuideArt.stillTime)
            } else {
                TimelineView(.animation(minimumInterval: 1.0 / 30)) { ctx in
                    drawing(t: ctx.date.timeIntervalSinceReferenceDate)
                }
            }
        }
        .frame(height: Self.artSize.height * scale)
        .frame(maxWidth: .infinity)
        .clipShape(shape)
        .overlay(shape.strokeBorder(Color.appPrimaryText.opacity(0.08), lineWidth: 1))
    }

    private func drawing(t: Double) -> some View {
        Canvas { ctx, size in
            guard let art = ctx.resolveSymbol(id: 0) else { return }
            ctx.draw(art, at: CGPoint(x: size.width / 2, y: size.height / 2))
        } symbols: {
            GuideArt(page: page, t: t, still: still, quiet: quiet, showsPoints: showsPoints)
                .frame(width: Self.artSize.width, height: Self.artSize.height)
                .scaleEffect(scale, anchor: .top)
                .frame(width: Self.artSize.width, height: Self.artSize.height * scale, alignment: .top)
                .tag(0)
        }
        .frame(width: Self.artSize.width, height: Self.artSize.height * scale)
    }
}

// MARK: The pictures (361 x 372 points, positions from design-preview/onboarding-guide/index.html)

private struct GuideArt: View {
    let page: String
    let t: Double
    let still: Bool
    let quiet: Bool
    let showsPoints: Bool

    /// Space between the box edge and the nearest drawing, the same on all four sides.
    private let inset = Space.card

    /// The frame the mockup shots freeze on (0.7 s into every loop).
    static let stillTime = 0.7

    // Gentle loops (README "Motion"); all zero when still.
    private func wave(_ period: Double, _ delay: Double = 0) -> Double { still ? 0 : sin((t + delay) * 2 * .pi / period) }
    private var sway: Angle { .degrees(1.6 * wave(3.2)) }
    private var bob: CGFloat { still ? 0 : CGFloat(-2.5 + 2.5 * cos(t * 2 * .pi / 2.6)) }
    private func pulse(_ period: Double = 1.8) -> CGFloat { still ? 1 : CGFloat(1.04 - 0.04 * cos(t * 2 * .pi / period)) }
    private func twinkle(_ delay: Double = 0) -> Double { still ? 1 : 0.725 + 0.275 * cos((t + delay) * 2 * .pi / 2.2) }
    private var flutter: CGFloat { still ? 1 : CGFloat(0.86 + 0.14 * cos(t * 2 * .pi / 0.5)) }
    private var drift: CGSize {
        guard !still else { return .zero }
        let k = (1 - cos(t * 2 * .pi / 4)) / 2
        return CGSize(width: 10 * k, height: -8 * k)
    }
    private var rays: Angle { still ? .zero : .degrees((t.truncatingRemainder(dividingBy: 40)) * 9) }
    private func drop(_ delay: Double = 0) -> (CGFloat, Double) {
        guard !still else { return (4, 1) }
        let p = ((t + delay).truncatingRemainder(dividingBy: 1.6)) / 1.6
        return (CGFloat(-6 + 24 * p), p < 0.25 ? p / 0.25 : 1 - (p - 0.25) / 0.75)
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            switch page {
            case "guess": guess
            case "plants": plants
            case "tend": tend
            case "love": love
            case "garden": garden
            case "daily": daily
            case "levels": levels
            default: peeks
            }
        }
        .frame(width: 361, height: 372, alignment: .topLeading)
    }

    // MARK: 1. Guess the word

    private var guess: some View {
        ArtCanvas {
            (Text(GuideCopy.Art.clue).foregroundStyle(Color.appPrimaryText).fontWeight(.heavy)
             + Text(" · " + GuideCopy.Art.clueText).foregroundStyle(Color.secondaryText))
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .padding(.vertical, 10).padding(.horizontal, 14)
                .frame(width: 361 - 2 * inset, alignment: .leading)
                .background(ArtCard())
                .at(inset, inset)
            FlowerView(petals: 6, sway: false).frame(width: 150, height: 180)
                .rotationEffect(sway, anchor: .bottom).at(22, 74)
            ArtChip(text: GuideCopy.Art.petalsTries, size: 12) { Spark().fill(Color.bloomIcon).frame(width: 14, height: 14) }.at(34, 250)
            HStack(spacing: 6) {
                Image(systemName: "lightbulb.fill").font(.system(size: 14, weight: .bold))
                Text(GuideCopy.Art.help).font(.system(size: 15, weight: .heavy, design: .rounded))
            }
            .foregroundStyle(Color.ink)
            .padding(.vertical, 10).padding(.horizontal, 16)
            .background(Capsule().fill(Color.appAccent).shadow(color: .black.opacity(0.08), radius: 3, y: 2))
            .at(361 - 22 - 86, 92)
            HStack(spacing: 5) {
                ForEach(Array(["D", "A", "", "S", ""].enumerated()), id: \.offset) { _, ch in ArtTile(letter: ch, width: 30) }
            }
            .frame(width: 176).at(361 - inset - 176, 150)
            HStack(spacing: 5) {
                ForEach(Array("ABCDEIOSY".enumerated()), id: \.offset) { _, ch in
                    ArtKey(letter: String(ch), state: "ADS".contains(ch) ? .hit : ("CO".contains(ch) ? .out : .plain))
                        .scaleEffect(ch == "Y" ? pulse() : 1)
                }
            }
            .frame(width: 361).at(0, 372 - inset - 38)
        }
    }

    // MARK: 2. Three words, one plant

    private var plants: some View {
        ArtCanvas {
            HStack(spacing: 10) {
                ForEach(GuideCopy.Art.sampleWords, id: \.self) { w in
                    VStack(spacing: 4) {
                        Text(w).font(.system(size: 15, weight: .black, design: .rounded)).kerning(0.9).foregroundStyle(Color.appPrimaryText)
                        Image(systemName: "checkmark.circle.fill").font(.system(size: 20)).foregroundStyle(Color.successText)
                    }
                    .padding(.vertical, 8).frame(width: 92).background(ArtCard())
                }
            }
            .frame(width: 361).at(0, inset)
            Path { p in
                p.move(to: CGPoint(x: 70, y: 4)); p.addCurve(to: CGPoint(x: 172, y: 44), control1: CGPoint(x: 90, y: 34), control2: CGPoint(x: 150, y: 30))
                p.move(to: CGPoint(x: 180, y: 4)); p.addLine(to: CGPoint(x: 180, y: 44))
                p.move(to: CGPoint(x: 290, y: 4)); p.addCurve(to: CGPoint(x: 188, y: 44), control1: CGPoint(x: 270, y: 34), control2: CGPoint(x: 210, y: 30))
            }
            .stroke(Color.secondaryText, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, dash: [2, 7]))
            .frame(width: 361, height: 50).at(0, 96)
            Image("plant_daisy").resizable().scaledToFit().frame(width: 120, height: 120)
                .rotationEffect(sway, anchor: .bottom).at(180.5 - 70 + 10, 132)
            PotArtView(pot: PotCatalog.pot(id: "terracotta"), width: 108, soil: true).at(180.5 - 70 + 16, 132 + 98)
            ArtChip(text: GuideCopy.Art.newPlant) { Spark().fill(LifePalette.gold).frame(width: 14, height: 14).opacity(twinkle()) }
                .frame(width: 361).at(0, 372 - inset - 30)
            Spark().fill(LifePalette.gold).frame(width: 20, height: 20).opacity(twinkle()).at(96, 170)
            Spark().fill(LifePalette.petal).frame(width: 16, height: 16).opacity(twinkle(-1.1)).at(361 - 92 - 16, 200)
        }
    }

    // MARK: 3. Help your plant grow

    private var tend: some View {
        ArtCanvas {
            StageTrack(names: GuideCopy.Art.stageNames, current: 2).frame(width: 291).at(35, inset)
            HStack(alignment: .bottom) {
                SproutArt().frame(width: 84, height: 84)
                Spacer(minLength: 0)
                BudArt().frame(width: 112, height: 112)
                Spacer(minLength: 0)
                Image("plant_daisy").resizable().scaledToFit().frame(width: 148, height: 148).rotationEffect(sway, anchor: .bottom)
            }
            .padding(.horizontal, 14)
            .frame(width: 341, height: 150, alignment: .bottom).at(10, 84)
            let d = drop()
            Image(systemName: "drop.fill").font(.system(size: 12)).foregroundStyle(Color(hex: 0x5B8FD0))
                .opacity(d.1).at(44, 96 + d.0)
            HStack(spacing: 4) {
                // The guide shows the five first buttons; Mist joins the row once the mister is in the Shed.
                ForEach(TendKind.allCases.filter { $0 != .mist }, id: \.self) { k in
                    VStack(spacing: 4) {
                        Image(systemName: k.icon).font(.system(size: 20, weight: .semibold)).foregroundStyle(k.tint)
                            .frame(width: 46, height: 46)
                            .background(RoundedRectangle(cornerRadius: 15, style: .continuous).fill(Color.appSurface)
                                .shadow(color: .black.opacity(0.08), radius: 3, y: 2))
                        Text(k.title).font(.system(size: 12, weight: .heavy, design: .rounded)).foregroundStyle(Color.appPrimaryText)
                    }
                    .frame(width: 58)
                }
            }
            .frame(width: 361).at(0, 372 - inset - 66)
        }
    }

    // MARK: 4. Hearts and hellos

    private var love: some View {
        ArtCanvas {
            Image("plant_rose").resizable().scaledToFit().frame(width: 140, height: 140)
                .rotationEffect(sway, anchor: .bottom).at(24, inset)
            Text(GuideCopy.Art.hello).font(.system(size: 16, weight: .black, design: .rounded)).foregroundStyle(Color.appPrimaryText)
                .padding(.vertical, 8).padding(.horizontal, 14)
                .background(UnevenRoundedRectangle(topLeadingRadius: 18, bottomLeadingRadius: 4, bottomTrailingRadius: 18, topTrailingRadius: 18, style: .continuous)
                    .fill(Color.appSurface).shadow(color: .black.opacity(0.1), radius: 6, y: 3))
                .overlay(UnevenRoundedRectangle(topLeadingRadius: 18, bottomLeadingRadius: 4, bottomTrailingRadius: 18, topTrailingRadius: 18, style: .continuous)
                    .strokeBorder(Color.appPrimaryText.opacity(0.1), lineWidth: 1))
                .offset(y: bob).at(150, 26)
            VStack(alignment: .leading, spacing: 4) {
                Text(GuideCopy.Art.love).font(.system(size: 12, weight: .heavy, design: .rounded)).foregroundStyle(Color.secondaryText)
                HStack(spacing: 4) {
                    ForEach(0..<5, id: \.self) { i in
                        ArtHeart(filled: i < 4).frame(width: 24, height: 22).scaleEffect(i == 3 ? pulse() : 1)
                    }
                }
            }
            .at(176, 96)
            HStack(spacing: 0) {
                Spacer(minLength: 0)
                VStack(spacing: 4) {
                    ArtCanvas(width: 96, height: 114) {
                        SeedPotView(pot: PotCatalog.pot(id: "terracotta"), width: 76).at(10, 24)
                        if !quiet {
                            ArtCloud().fill(LifePalette.cloud).frame(width: 46, height: 22).at(28, 0)
                            ForEach([0.0, -0.8], id: \.self) { delay in
                                let d = drop(delay)
                                Image(systemName: "drop.fill").font(.system(size: 7)).foregroundStyle(LifePalette.drop)
                                    .opacity(d.1).at(delay == 0 ? 40 : 56, 22 + d.0 * 0.5)
                            }
                        }
                    }
                    Text(GuideCopy.Art.naps).font(.system(size: 12, weight: .heavy, design: .rounded)).foregroundStyle(Color.secondaryText)
                        .fixedSize()
                }
                Spacer(minLength: 0)
                Image(systemName: "arrow.right").font(.system(size: 22, weight: .bold)).foregroundStyle(Color.secondaryText)
                    .padding(.bottom, 18)
                Spacer(minLength: 0)
                VStack(spacing: 4) {
                    ArtCanvas(width: 96, height: 114) {
                        SproutArt().frame(width: 80, height: 80).at(8, -4)
                        PotArtView(pot: PotCatalog.pot(id: "terracotta"), width: 80, soil: true).at(8, 48)
                        Spark().fill(LifePalette.gold).frame(width: 18, height: 18).opacity(twinkle()).at(80, 12)
                    }
                    Text(GuideCopy.Art.wakes).font(.system(size: 12, weight: .heavy, design: .rounded)).foregroundStyle(Color.secondaryText)
                        .fixedSize()
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 6)
            .frame(width: 361 - 2 * inset, height: 170)
            .background(ArtCard())
            .at(inset, 372 - inset - 170)
        }
    }

    // MARK: 5. Your garden and friends

    private var garden: some View {
        ArtCanvas {
            ArtTile5(label: GuideCopy.Art.garden, icon: "leaf.fill", fill: .tileGardenFill, ink: .successText) {
                HStack(alignment: .bottom, spacing: 0) {
                    ForEach([("tulip", 62.0), ("daisy", 70), ("sunflower", 66), ("lavender", 60)], id: \.0) { id, w in
                        Image("plant_\(id)").resizable().scaledToFit().frame(width: w, height: w)
                    }
                }
            }
            .frame(width: 361 - 2 * inset, height: 124).at(inset, inset)
            ArtTile5(label: GuideCopy.Art.visitors, icon: "ladybug.fill", fill: .tileVisitorsFill, ink: .tileVisitorsIcon) {
                Image("visitor_ladybug_sticker").resizable().scaledToFit().frame(width: 62, height: 62)
            }
            .frame(width: 156, height: 150).at(inset, 372 - inset - 150)
            ArtTile5(label: GuideCopy.Art.shed, icon: "wrench.and.screwdriver.fill", fill: .tileShedFill, ink: .tileShedIcon) {
                Image("tool_can_t1").resizable().scaledToFit().frame(width: 62, height: 67)
            }
            .frame(width: 156, height: 150).at(361 - inset - 156, 372 - inset - 150)
            Path { p in
                p.move(to: CGPoint(x: 8, y: 62)); p.addCurve(to: CGPoint(x: 162, y: 62), control1: CGPoint(x: 40, y: 6), control2: CGPoint(x: 130, y: 6))
            }
            .stroke(Color.tileVisitorsIcon, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, dash: [2, 7]))
            .frame(width: 170, height: 70).at(96, 156)
            Image("visitor_monarch_a").resizable().scaledToFit().frame(width: 48, height: 48)
                .scaleEffect(x: flutter, y: 1).offset(drift).at(156, 150)
            if showsPoints {
                ArtChip(text: GuideCopy.Art.points, size: 12, padH: 9, padV: 4) { EmptyView() }.at(262, 372 - inset - 150 + 8)
            }
        }
    }

    // MARK: 6. One word for everyone

    private var daily: some View {
        ArtCanvas {
            ZStack {
                ForEach(0..<12, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 4).fill(LifePalette.gold.opacity(0.55)).frame(width: 8, height: 18)
                        .offset(y: -69).rotationEffect(.degrees(Double(i) * 30))
                }
            }
            .frame(width: 160, height: 160).rotationEffect(rays).at(100.5, 14)
            Image("plant_sunflower").resizable().scaledToFit().frame(width: 132, height: 132)
                .rotationEffect(sway, anchor: .bottom).at(114.5, 20)
            HStack(spacing: 12) {
                Image(systemName: "sun.max.fill").font(.system(size: 19)).foregroundStyle(Color.bloomIcon)
                    .frame(width: 38, height: 38).background(Circle().fill(Color.petalRose.opacity(0.3)))
                VStack(alignment: .leading, spacing: 1) {
                    Text(GuideCopy.Art.dailyTitle).font(.system(size: 17, weight: .bold, design: .rounded)).foregroundStyle(Color.appPrimaryText)
                    Text(GuideCopy.Art.dailySub).font(.system(size: 13, design: .rounded)).foregroundStyle(Color.appPrimaryText)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right").font(.system(size: 14, weight: .bold)).foregroundStyle(Color.bloomIcon)
            }
            .padding(.horizontal, 14).padding(.vertical, 12)
            .frame(width: 361 - 2 * inset)
            .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color.bloomFill).shadow(color: .black.opacity(0.08), radius: 6, y: 3))
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(Color.petalRose.opacity(0.4)))
            .at(inset, 186)
            HStack(spacing: 6) {
                ForEach(0..<5, id: \.self) { _ in ArtTile(letter: "?", width: 40, ink: .bloomIcon) }
            }
            .frame(width: 361).at(0, 372 - inset - 48)
        }
    }

    // MARK: 7. Five levels to explore

    private static let levelPoints = [CGPoint(x: 72, y: 64), CGPoint(x: 180, y: 124), CGPoint(x: 290, y: 64),
                                      CGPoint(x: 248, y: 214), CGPoint(x: 112, y: 214)]

    private var levels: some View {
        let path = Path { p in
            p.move(to: CGPoint(x: 72, y: 64))
            p.addCurve(to: CGPoint(x: 180, y: 124), control1: CGPoint(x: 110, y: 64), control2: CGPoint(x: 140, y: 124))
            p.addCurve(to: CGPoint(x: 290, y: 64), control1: CGPoint(x: 220, y: 124), control2: CGPoint(x: 250, y: 64))
            p.addCurve(to: CGPoint(x: 248, y: 214), control1: CGPoint(x: 345, y: 64), control2: CGPoint(x: 340, y: 214))
            p.addCurve(to: CGPoint(x: 112, y: 214), control1: CGPoint(x: 200, y: 214), control2: CGPoint(x: 160, y: 214))
        }
        return ArtCanvas {
            path.stroke(Color.path, style: StrokeStyle(lineWidth: 16, lineCap: .round))
            path.stroke(Color.appPrimaryText.opacity(0.22), style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [1, 9]))
            ForEach(0..<5, id: \.self) { i in
                let c = Self.levelPoints[i]
                VStack(spacing: 5) {
                    ZStack {
                        Circle().fill(Color.appSurface).shadow(color: .black.opacity(0.1), radius: 4, y: 2)
                        if i == 0 { Image("plant_daisy").resizable().scaledToFit().frame(width: 58, height: 58) }
                        else if i == 1 { Image("plant_lotus").resizable().scaledToFit().frame(width: 58, height: 58) }
                        else { SproutGlyph().fill(Color.successText.opacity(0.8)).frame(width: 30, height: 30) }
                    }
                    .frame(width: 68, height: 68)
                    .overlay { if i == 0 { Circle().strokeBorder(Color.appAccent, lineWidth: 4) } }
                    .overlay { if i == 1 { Circle().inset(by: -4.5).strokeBorder(Color.tileLevelsIcon, lineWidth: 3) } }
                    Text(GuideCopy.Art.levelLabel(i)).font(.system(size: 12, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color.appPrimaryText).fixedSize()
                }
                .frame(width: 108).at(c.x - 54, c.y - 34)
            }
            Image(systemName: "checkmark.circle.fill").font(.system(size: 20)).foregroundStyle(Color.successText)
                .background(Circle().fill(Color.appSurface)).at(89, 25)
            ArtChip(text: GuideCopy.Art.youAreHere, size: 12, padH: 10, padV: 4, fill: .tileLevelsFill) {
                Image(systemName: "mappin.circle.fill").font(.system(size: 13)).foregroundStyle(Color.tileLevelsIcon)
            }
            .offset(y: bob).at(124, 30)
            VStack(spacing: 6) {
                ArtChip(text: GuideCopy.Art.goldRing, size: 12) {
                    Circle().strokeBorder(Color.appAccent, lineWidth: 3).frame(width: 12, height: 12)
                }
                ArtChip(text: GuideCopy.Art.opensNext, size: 12) {
                    Image(systemName: "leaf.fill").font(.system(size: 12)).foregroundStyle(Color.successText)
                }
            }
            .frame(width: 361).at(0, 372 - inset - 62)
        }
    }

    // MARK: 8. Coming soon in your garden

    private var peeks: some View {
        ArtCanvas {
            Spark().fill(LifePalette.gold).frame(width: 18, height: 18).opacity(twinkle()).at(30, 22)
            Spark().fill(LifePalette.petal).frame(width: 14, height: 14).opacity(twinkle(-0.9)).at(361 - 36 - 14, 30)
            Spark().fill(LifePalette.gold).frame(width: 16, height: 16).opacity(twinkle(-1.5)).at(361 - 60 - 16, 372 - 96 - 16)
            HStack(spacing: 10) {
                PeekCard(name: GuideCopy.Art.rarePlants) { Image("plant_rafflesia").resizable().scaledToFit().frame(width: 78, height: 78) }
                PeekCard(name: GuideCopy.Art.pots) {
                    PotArtView(pot: PotCatalog.pot(id: "starlight"), width: 80).frame(height: 78)
                }
                .offset(y: still ? 0 : CGFloat(-2.5 + 2.5 * cos(t * 2 * .pi / 3.4)))
                PeekCard(name: GuideCopy.Art.badges) { Image("badge_rare_finds_t2").resizable().scaledToFit().frame(width: 78, height: 78) }
            }
            .frame(width: 361).at(0, 44)
            HStack(spacing: 10) {
                SproutGlyph().fill(Color.tileLevelsIcon).frame(width: 24, height: 24)
                    .frame(width: 44, height: 44).background(Circle().fill(Color.tileLevelsFill))
                VStack(alignment: .leading, spacing: 1) {
                    Text(GuideCopy.Art.level5).font(.system(size: 15, weight: .bold, design: .rounded)).foregroundStyle(Color.appPrimaryText)
                    Text(GuideCopy.Art.levelNames[4]).font(.system(size: 13, design: .rounded)).foregroundStyle(Color.secondaryText)
                }
                SoonChip()
            }
            .padding(.vertical, 10).padding(.leading, 10).padding(.trailing, 16)
            .background(ArtCard())
            .frame(width: 361).at(0, 372 - inset - 64)
        }
    }
}

// MARK: Small drawing parts

private extension View {
    /// Places a view by its top-left corner, as the mockup's absolute positions do.
    func at(_ x: CGFloat, _ y: CGFloat) -> some View {
        fixedSize().alignmentGuide(.leading) { _ in -x }.alignmentGuide(.top) { _ in -y }
    }
}

/// A fixed drawing area for `.at(x, y)` placements. The clear first layer pins the area's top-left corner, so the
/// placements are measured from the box edge (without it the stack shrinks to its children and the smallest offset
/// collapses to zero, pushing the drawing against the edge).
private struct ArtCanvas<Content: View>: View {
    var width: CGFloat = 361
    var height: CGFloat = 372
    @ViewBuilder var content: Content

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.clear.frame(width: width, height: height)
            content
        }
        .frame(width: width, height: height, alignment: .topLeading)
    }
}

private struct ArtCard: View {
    var radius: CGFloat = 18
    var body: some View {
        RoundedRectangle(cornerRadius: radius, style: .continuous).fill(Color.appSurface)
            .shadow(color: .black.opacity(0.08), radius: 6, y: 3)
    }
}

private struct ArtChip<Icon: View>: View {
    let text: String
    var size: CGFloat = 13
    var padH: CGFloat = 12
    var padV: CGFloat = 6
    var fill: Color = .appSurface
    @ViewBuilder var icon: Icon

    var body: some View {
        HStack(spacing: 6) {
            icon
            Text(text).font(.system(size: size, weight: .heavy, design: .rounded)).foregroundStyle(Color.appPrimaryText)
        }
        .padding(.horizontal, padH).padding(.vertical, padV)
        .background(Capsule().fill(fill).shadow(color: .black.opacity(0.08), radius: 3, y: 2))
    }
}

private struct ArtTile: View {
    let letter: String
    let width: CGFloat
    var ink: Color = .successText

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 10, style: .continuous)
        Text(letter).font(.system(size: 24, weight: .black, design: .rounded)).foregroundStyle(ink)
            .frame(width: width, height: 48)
            .background {
                if letter.isEmpty {
                    VStack { Spacer(); Capsule().fill(Color.appPrimaryText.opacity(0.45)).frame(height: 3) }
                } else {
                    shape.fill(letter == "?" ? Color.appSurface : Color.tileGardenFill)
                        .overlay(alignment: .bottom) { Capsule().fill(Color.appPrimaryText.opacity(0.14)).frame(height: 3).padding(.horizontal, 3) }
                }
            }
    }
}

private struct ArtKey: View {
    enum Look { case plain, hit, out }
    let letter: String
    let state: Look
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        Text(letter).font(.system(size: 16, weight: .heavy, design: .rounded))
            .foregroundStyle(state == .hit ? (scheme == .dark ? Color(hex: 0x1A2E1A) : .white) : Color.appPrimaryText)
            .frame(width: 30, height: 38)
            .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(state == .hit ? Color.successText : Color.appSurface)
                .shadow(color: Color.appPrimaryText.opacity(0.22), radius: 0, y: 1))
            .opacity(state == .out ? 0.38 : 1)
    }
}

private struct StageTrack: View {
    let names: [String]
    let current: Int

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Rectangle().fill(Color.appPrimaryText.opacity(0.18)).frame(height: 3).padding(.horizontal, 10)
                HStack {
                    ForEach(names.indices, id: \.self) { i in
                        if i > 0 { Spacer(minLength: 0) }
                        ZStack {
                            Circle().fill(i < current ? Color.successText : Color.appSurface)
                            Circle().strokeBorder(i <= current ? Color.successText : Color.appPrimaryText.opacity(0.22), lineWidth: i == current ? 3 : 2)
                            if i < current {
                                Image(systemName: "checkmark").font(.system(size: 10, weight: .black)).foregroundStyle(Color.appSurface)
                            } else if i == current {
                                Circle().fill(Color.successText).frame(width: 8, height: 8)
                            }
                        }
                        .frame(width: 22, height: 22)
                    }
                }
            }
            HStack(alignment: .top) {
                ForEach(names.indices, id: \.self) { i in
                    if i > 0 { Spacer(minLength: 0) }
                    Text(names[i]).font(.system(size: 11, weight: .heavy, design: .rounded)).foregroundStyle(Color.secondaryText)
                        .lineLimit(1).fixedSize().frame(width: 22)
                }
            }
        }
    }
}

private struct ArtTile5<Inner: View>: View {
    let label: String
    let icon: String
    let fill: Color
    let ink: Color
    @ViewBuilder var inner: Inner

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 20, style: .continuous)
        VStack(spacing: 4) {
            inner
            HStack(spacing: 5) {
                Image(systemName: icon).font(.system(size: 15, weight: .semibold)).foregroundStyle(ink)
                Text(label).font(.system(size: 15, weight: .black, design: .rounded)).foregroundStyle(Color.appPrimaryText)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(shape.fill(fill).shadow(color: ink.opacity(0.16), radius: 6, y: 3))
        .overlay(shape.strokeBorder(ink.opacity(0.3), lineWidth: 1))
    }
}

private struct PeekCard<Art: View>: View {
    let name: String
    @ViewBuilder var art: Art

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 18, style: .continuous)
        VStack(spacing: 6) {
            art
            Text(name).font(.system(size: 13, weight: .heavy, design: .rounded)).foregroundStyle(Color.appPrimaryText)
            SoonChip()
        }
        .padding(.top, 12).padding(.bottom, 10).padding(.horizontal, 6)
        .frame(width: 104)
        .background(shape.fill(Color.appSurface.opacity(0.82)))
        .overlay(shape.strokeBorder(Color.appPrimaryText.opacity(0.3), style: StrokeStyle(lineWidth: 1.5, dash: [5, 4])))
    }
}

/// "Soon" with a sprout, never a lock.
private struct SoonChip: View {
    var body: some View {
        HStack(spacing: 3) {
            SproutGlyph().fill(Color.successText).frame(width: 11, height: 11)
            Text(GuideCopy.Art.soon).font(.system(size: 11, weight: .black, design: .rounded)).foregroundStyle(Color.successText)
        }
        .padding(.horizontal, 8).padding(.vertical, 3)
        .background(Capsule().fill(Color.tileGardenFill))
    }
}

/// The four-point sparkle (mockup `#spark`, a 16 point box).
private struct Spark: Shape {
    func path(in r: CGRect) -> Path {
        let s = min(r.width, r.height) / 16, c = CGPoint(x: r.midX, y: r.midY)
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: c.x + x * s, y: c.y + y * s) }
        var path = Path()
        path.move(to: p(0, -7))
        path.addQuadCurve(to: p(7, 0), control: p(1, -1.5))
        path.addQuadCurve(to: p(0, 7), control: p(1, 1.5))
        path.addQuadCurve(to: p(-7, 0), control: p(-1, 1.5))
        path.addQuadCurve(to: p(0, -7), control: p(-1, -1.5))
        path.closeSubpath()
        return path
    }
}

/// The sprout icon (mockup `#sprout`, 24 point box).
private struct SproutGlyph: Shape {
    func path(in r: CGRect) -> Path {
        let s = min(r.width, r.height) / 24
        var path = Path()
        path.move(to: CGPoint(x: 12, y: 13))
        path.addCurve(to: CGPoint(x: 4, y: 6), control1: CGPoint(x: 12, y: 8), control2: CGPoint(x: 8, y: 6))
        path.addCurve(to: CGPoint(x: 12, y: 13), control1: CGPoint(x: 4, y: 10), control2: CGPoint(x: 7, y: 13))
        path.move(to: CGPoint(x: 12, y: 11))
        path.addCurve(to: CGPoint(x: 20, y: 5), control1: CGPoint(x: 12, y: 7), control2: CGPoint(x: 15, y: 5))
        path.addCurve(to: CGPoint(x: 12, y: 11), control1: CGPoint(x: 20, y: 9), control2: CGPoint(x: 17, y: 11))
        path.addRoundedRect(in: CGRect(x: 11, y: 10, width: 2, height: 11), cornerSize: CGSize(width: 1, height: 1))
        return path.applying(CGAffineTransform(scaleX: s, y: s).translatedBy(x: r.minX / s, y: r.minY / s))
    }
}

private struct ArtHeart: View {
    let filled: Bool
    private static let heart = Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: 0xF28A9C) : UIColor(hex: 0xD9566C) })

    var body: some View {
        let shape = HeartShape()
        shape.fill(filled ? Self.heart : .clear).overlay(shape.stroke(Self.heart, lineWidth: 1.6))
    }
}

/// The mockup heart (viewBox -9 -9 18 16).
private struct HeartShape: Shape {
    func path(in r: CGRect) -> Path {
        let sx = r.width / 18, sy = r.height / 16
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: r.minX + (x + 9) * sx, y: r.minY + (y + 9) * sy) }
        var path = Path()
        path.move(to: p(0, 5))
        path.addCurve(to: p(-3, -8), control1: p(-8, -1), control2: p(-8, -8))
        path.addCurve(to: p(0, -6), control1: p(-1, -8), control2: p(0, -6))
        path.addCurve(to: p(3, -8), control1: p(0, -6), control2: p(1, -8))
        path.addCurve(to: p(0, 5), control1: p(8, -8), control2: p(8, -1))
        path.closeSubpath()
        return path
    }
}

/// The small rain cloud over the napping seed (mockup cloud, 60 x 30 box).
private struct ArtCloud: Shape {
    func path(in r: CGRect) -> Path {
        let sx = r.width / 46, sy = r.height / 22
        var path = Path()
        path.addEllipse(in: CGRect(x: 0, y: 8, width: 18, height: 14))
        path.addEllipse(in: CGRect(x: 10, y: 0, width: 22, height: 20))
        path.addEllipse(in: CGRect(x: 26, y: 6, width: 20, height: 16))
        path.addRect(CGRect(x: 8, y: 12, width: 30, height: 10))
        return path.applying(CGAffineTransform(scaleX: sx, y: sy).translatedBy(x: r.minX / sx, y: r.minY / sy))
    }
}

/// A young sprout (mockup `sproutArt`, 200 point box).
private struct SproutArt: View {
    var body: some View {
        Canvas { ctx, size in
            ctx.scaleBy(x: size.width / 200, y: size.height / 200)
            ctx.fill(Path(ellipseIn: CGRect(x: 60, y: 171, width: 80, height: 12)), with: .color(Color(hex: 0x2C3E2C).opacity(0.14)))
            var stem = Path(); stem.move(to: CGPoint(x: 100, y: 176))
            stem.addCurve(to: CGPoint(x: 100, y: 138), control1: CGPoint(x: 100, y: 160), control2: CGPoint(x: 100, y: 150))
            ctx.stroke(stem, with: .color(Color(hex: 0x5E9F55)), style: StrokeStyle(lineWidth: 6, lineCap: .round))
            var left = Path(); left.move(to: CGPoint(x: 100, y: 146))
            left.addCurve(to: CGPoint(x: 60, y: 132), control1: CGPoint(x: 88, y: 128), control2: CGPoint(x: 70, y: 126))
            left.addCurve(to: CGPoint(x: 100, y: 146), control1: CGPoint(x: 70, y: 146), control2: CGPoint(x: 88, y: 150))
            ctx.fill(left, with: .color(Color(hex: 0x5FA860)))
            var right = Path(); right.move(to: CGPoint(x: 100, y: 140))
            right.addCurve(to: CGPoint(x: 142, y: 124), control1: CGPoint(x: 112, y: 120), control2: CGPoint(x: 132, y: 118))
            right.addCurve(to: CGPoint(x: 100, y: 140), control1: CGPoint(x: 132, y: 140), control2: CGPoint(x: 114, y: 144))
            ctx.fill(right, with: .color(Color(hex: 0x3F8A4A)))
        }
    }
}

/// A white bud on its stem (mockup `budArt`, 200 point box).
private struct BudArt: View {
    var body: some View {
        Canvas { ctx, size in
            ctx.scaleBy(x: size.width / 200, y: size.height / 200)
            ctx.fill(Path(ellipseIn: CGRect(x: 50, y: 171, width: 100, height: 12)), with: .color(Color(hex: 0x2C3E2C).opacity(0.14)))
            var stem = Path(); stem.move(to: CGPoint(x: 100, y: 176))
            stem.addCurve(to: CGPoint(x: 100, y: 96), control1: CGPoint(x: 99, y: 150), control2: CGPoint(x: 101, y: 120))
            ctx.stroke(stem, with: .color(Color(hex: 0x5E9F55)), style: StrokeStyle(lineWidth: 6, lineCap: .round))
            var l = Path(); l.move(to: CGPoint(x: 100, y: 160))
            l.addCurve(to: CGPoint(x: 52, y: 146), control1: CGPoint(x: 84, y: 140), control2: CGPoint(x: 62, y: 138))
            l.addCurve(to: CGPoint(x: 100, y: 160), control1: CGPoint(x: 62, y: 160), control2: CGPoint(x: 84, y: 164))
            ctx.fill(l, with: .color(Color(hex: 0x5FA860)))
            var r = Path(); r.move(to: CGPoint(x: 100, y: 150))
            r.addCurve(to: CGPoint(x: 148, y: 136), control1: CGPoint(x: 116, y: 130), control2: CGPoint(x: 138, y: 128))
            r.addCurve(to: CGPoint(x: 100, y: 150), control1: CGPoint(x: 138, y: 150), control2: CGPoint(x: 116, y: 154))
            ctx.fill(r, with: .color(Color(hex: 0x3F8A4A)))
            var bud = Path(); bud.move(to: CGPoint(x: 100, y: 98))
            bud.addCurve(to: CGPoint(x: 100, y: 56), control1: CGPoint(x: 86, y: 88), control2: CGPoint(x: 86, y: 66))
            bud.addCurve(to: CGPoint(x: 100, y: 98), control1: CGPoint(x: 114, y: 66), control2: CGPoint(x: 114, y: 88))
            ctx.fill(bud, with: .color(Color(hex: 0xF4F1E8)))
            ctx.stroke(bud, with: .color(Color(hex: 0xD9D2BE)), lineWidth: 2)
            var cup = Path(); cup.move(to: CGPoint(x: 100, y: 100))
            cup.addCurve(to: CGPoint(x: 92, y: 82), control1: CGPoint(x: 92, y: 96), control2: CGPoint(x: 90, y: 88))
            cup.addLine(to: CGPoint(x: 100, y: 90)); cup.addLine(to: CGPoint(x: 108, y: 82))
            cup.addCurve(to: CGPoint(x: 100, y: 100), control1: CGPoint(x: 110, y: 88), control2: CGPoint(x: 108, y: 96))
            ctx.fill(cup, with: .color(Color(hex: 0x5FA860)))
        }
    }
}
