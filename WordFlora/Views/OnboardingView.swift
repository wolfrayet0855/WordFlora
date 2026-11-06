import SwiftUI

/// First session (spec section 19, P-03): petal intro, one neutral age question, the skippable guide, an unloseable tutorial word,
/// the first plant, one gentle tip. No ads, paywall or permission prompts here.
struct OnboardingView: View {
    @Environment(AppModel.self) private var app
    @Environment(GameRouter.self) private var router

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            switch app.onboarding.step {
            // The intro leaves at once as the age question starts to fade in: a removal still running under the
            // player's first tap would take that tap (its tap-to-skip) or reset it as it finishes (the dead first tap).
            case .intro: IntroView().transition(.identity)
            case .age: AgeQuestionView()
            case .guide: GuideView(mode: .firstRun).transition(.opacity)
            case .tutorialWord:
                GameView(daily: false, tutorial: true) {
                    app.onboarding.tutorialSolved()
                    app.onboarding.plantEarnedDismissed()
                }
                .transition(.opacity)
            case .plantEarned, .gardenTip: FirstGardenTipView()
            case .home: Color.clear
            }
        }
        .animation(.easeInOut(duration: 0.3), value: app.onboarding.step)
    }
}

/// The landing intro: petals fall, land in heaps and bloom into a row of flowers under the wordmark (IntroBloomView).
private struct IntroView: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        IntroBloomView { withAnimation(.easeInOut(duration: Self.handoff)) { app.onboarding.introFinished() } }
    }

    /// UI tests (`-uitest-handoff=3`) stretch the cross-fade to the age question, to prove a tap during it counts.
    private static let handoff: Double = ProcessInfo.processInfo.arguments
        .first { $0.hasPrefix("-uitest-handoff=") }.flatMap { Double($0.dropFirst("-uitest-handoff=".count)) }
        ?? IntroTimeline.handoff
}

private struct AgeQuestionView: View {
    @Environment(AppModel.self) private var app
    @State private var offerQuiet = false

    var body: some View {
        // While the Quiet Garden offer shows, the age question leaves the hierarchy rather than sitting hidden under it
        // (on iOS 26 the accessibility audit still measures covered or hidden text).
        ZStack {
            if offerQuiet {
                QuietGardenOfferView(
                    keepQuiet: { app.answerQuietOffer(keepQuiet: true) },
                    showEverything: { app.answerQuietOffer(keepQuiet: false) },
                    back: { withAnimation(.easeInOut(duration: 0.25)) { offerQuiet = false } })
                .transition(.opacity)
            } else {
                question.transition(.opacity)
            }
        }
    }

    private var question: some View {
        ScrollView {
            VStack(spacing: Space.section) {
                FlowerView(petals: 8).frame(height: 140)
                Text("How old are you?").font(Theme.font(.largeTitle, weight: .bold)).foregroundStyle(Color.appPrimaryText)
                    .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                Text("This helps us set up the right experience. You can still play whichever way you like.")
                    .font(Theme.font(.callout)).multilineTextAlignment(.center).foregroundStyle(Color.appPrimaryText).fixedSize(horizontal: false, vertical: true)
                VStack(spacing: 12) {
                    ageButton("Under 13", .under13)
                    ageButton("13 to 17", .thirteenPlus)
                    ageButton("18 or older", .eighteenPlus)
                }
            }
            .padding(.horizontal, Space.gutter).padding(.vertical, Space.section).frame(maxWidth: .infinity)
        }
        .scrollBounceBehavior(.basedOnSize)
    }

    private func ageButton(_ title: String, _ band: AgeBand) -> some View {
        Button {
            app.settings.applyAgeDefaults(band)
            if band == .under13 { withAnimation(.easeInOut(duration: 0.25)) { offerQuiet = true } }
            else { app.onboarding.selectAge(band, guideSeen: app.profile?.guideSeen ?? false) }
        } label: { Text(title) }
        .buttonStyle(SecondaryButtonStyle())
    }
}

/// "Would you like a quiet garden?" (design-preview/quiet-garden): a full screen after "Under 13", with a calm garden
/// scene, what changes and what stays, two big choices of the same size and a note that Settings can change it.
/// Back returns to the age question, as the old dialog's Cancel did.
struct QuietGardenOfferView: View {
    var keepQuiet: () -> Void
    var showEverything: () -> Void
    var back: () -> Void

    @Environment(\.dynamicTypeSize) private var typeSize
    @ScaledMetric(relativeTo: .body) private var iconSize: CGFloat = 36

    var body: some View {
        ScrollView {
            VStack(spacing: Space.section) {
                Button(action: back) {
                    Label(QuietGardenCopy.back, systemImage: "chevron.left")
                        .font(Theme.font(.body, weight: .semibold)).foregroundStyle(Color.appPrimaryText)
                        .tapTarget()
                }
                .buttonStyle(.plain)
                .accessibilityHint(QuietGardenCopy.backHint)
                .accessibilityIdentifier("quietOffer.back")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, -Space.card)

                RestScene(kind: .garden)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

                Text(QuietGardenCopy.title)
                    .font(Theme.font(.largeTitle, weight: .heavy)).foregroundStyle(Color.appPrimaryText)
                    .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)

                rows.padding(.top, -Space.s)

                VStack(spacing: Space.m) {
                    Button(QuietGardenCopy.yes, action: keepQuiet)
                        .buttonStyle(QuietChoiceStyle(filled: true)).accessibilityIdentifier("quietOffer.yes")
                    Button(QuietGardenCopy.no, action: showEverything)
                        .buttonStyle(QuietChoiceStyle(filled: false)).accessibilityIdentifier("quietOffer.no")
                }

                Label(QuietGardenCopy.note, systemImage: "gearshape")
                    .font(Theme.font(.subheadline)).foregroundStyle(Color.secondaryText)
                    .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                    .padding(.top, -Space.m)
                    .accessibilityElement(children: .combine)
                    .accessibilityIdentifier("quietOffer.note")
            }
            .padding(.horizontal, Space.gutter).padding(.bottom, Space.section)
            .frame(maxWidth: .infinity)
        }
        .scrollBounceBehavior(.basedOnSize)
    }

    private static let tints: [(fill: Color, icon: Color)] = [
        (.tileGardenFill, .successText), (.tileLevelsFill, .tileLevelsIcon), (.bloomFill, .bloomIcon),
    ]

    private var rows: some View {
        let icon = min(iconSize, 52)
        return VStack(alignment: .leading, spacing: Space.m) {
            ForEach(Array(QuietGardenCopy.rows.enumerated()), id: \.offset) { i, row in
                HStack(alignment: typeSize.isAccessibilitySize ? .top : .center, spacing: Space.m) {
                    Image(systemName: row.symbol)
                        .font(.system(size: icon * 0.5, weight: .semibold))
                        .foregroundStyle(Self.tints[i].icon)
                        .frame(width: icon, height: icon)
                        .background(Self.tints[i].fill, in: Circle())
                        .accessibilityHidden(true)
                    Text(row.text)
                        .font(Theme.font(.body, weight: .semibold)).foregroundStyle(Color.appPrimaryText)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .accessibilityElement(children: .combine)
            }
        }
        .padding(Space.card)
        .background(Color.appSurface, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
        .overlay(RoundedRectangle(cornerRadius: Theme.cardRadius).stroke(Color.appPrimaryText.opacity(0.12)))
    }
}

/// The two choices on the Quiet Garden offer: the same size, font and shape; Yes filled, No outlined. Long labels at
/// accessibility sizes wrap inside the button instead of being cut off.
private struct QuietChoiceStyle: ButtonStyle {
    var filled: Bool

    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
        return configuration.label
            .font(Theme.font(.title3, weight: .bold))
            .foregroundStyle(filled ? Color.ink : Color.appPrimaryText)
            .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, Space.card).padding(.vertical, Space.m)
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(filled ? Color.appAccent : Color.appSurface, in: shape)
            .overlay(shape.stroke(Color.appPrimaryText.opacity(filled ? 0 : 0.22), lineWidth: 1.5))
            .contentShape(shape)
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}

/// The first win, after "New plant found!" (design-preview/fact-card frames 2-4): one tip, one free drink, then home.
private struct FirstGardenTipView: View {
    @Environment(AppModel.self) private var app
    @State private var watered = false
    @State private var toast: String?
    @State private var pour: TendPlay?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .title2) private var tipIcon: CGFloat = 44

    private var plant: PlantCollectible? { app.plants().first { $0.earnedCount > 0 } }
    private var plantName: String {
        guard let plant else { return "plant" }
        return plant.nickname.isEmpty ? plant.name : plant.nickname
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                Text(watered ? "Yum!" : "Plant tip")
                    .textCase(.uppercase).kerning(1)
                    .font(Theme.font(.footnote, weight: .heavy)).foregroundStyle(Color.accentText)
                Text(watered ? "Your \(plantName) loves it" : "Plants love water")
                    .font(Theme.font(.largeTitle, weight: .heavy)).foregroundStyle(Color.appPrimaryText)
                    .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                if let plant {
                    // The water pour plays here once, over the plant, when the free drink is poured.
                    PlantCard(plant: plant).frame(maxWidth: 220)
                        .tendMotion(pour, size: 92, calm: reduceMotion)
                        .overlay(alignment: .top) { TendAnimationView(play: pour, size: 92, calm: reduceMotion).padding(.top, 12) }
                        .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.6), trigger: pour?.id ?? 0) { old, new in new > old && app.settings.hapticsOn }
                }
                if watered {
                    Label("Watered. It will grow a little every day.", systemImage: "checkmark.circle.fill")
                        .font(Theme.font(.callout, weight: .heavy)).foregroundStyle(Color.appPrimaryText)
                        .padding(.horizontal, 16).padding(.vertical, 8)
                        .background(Color.successText.opacity(0.14), in: Capsule())
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Water it whenever you like. You can find it in your garden.")
                        .font(Theme.font(.body)).foregroundStyle(Color.appPrimaryText)
                        .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                } else {
                    HStack(spacing: 12) {
                        Image(systemName: "drop.fill").font(.title3).foregroundStyle(Color.ink)
                            .frame(width: tipIcon, height: tipIcon)
                            .background(Color.appAccent, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .accessibilityHidden(true)
                        (Text("The water button").bold() + Text(" gives your plant a drink. Your first drink is free!"))
                            .font(Theme.font(.callout)).foregroundStyle(Color.appPrimaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 16).padding(.vertical, 12)
                    .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .accessibilityElement(children: .combine)
                }
                Spacer(minLength: 16)
                if watered {
                    Button("Go home") { app.finishOnboarding() }.buttonStyle(PrimaryButtonStyle())
                } else {
                    Button { water() } label: { Label("Water my plant", systemImage: "drop.fill") }.buttonStyle(PrimaryButtonStyle())
                    Button("Not now") { app.finishOnboarding() }
                        .font(Theme.font(.body, weight: .semibold)).foregroundStyle(Color.appPrimaryText)
                        .frame(minHeight: Theme.minTap)
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity)
        }
        .scrollBounceBehavior(.basedOnSize)
        .overlay(alignment: .bottom) { toastView }
    }

    @ViewBuilder private var toastView: some View {
        if let toast {
            Text(toast).font(Theme.font(.subheadline, weight: .semibold)).foregroundStyle(Color.appPrimaryText)
                .padding(.horizontal, 16).padding(.vertical, 12)
                .background(Color.appSurface, in: Capsule()).shadow(radius: 6, y: 2).padding(.bottom, 96)
                .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    private func water() {
        guard let plant, let profile = app.profile else { withAnimation { watered = true }; return }
        profile.water += 1                       // the free first drop
        let outcome = app.tend(.water, plant: plant)
        if outcome.applied {
            app.play(.water)
            let play = TendPlay(effect: .water, startedAt: .now, id: 1)
            pour = play
            let life = TendMotion.lifetime(.water, calm: reduceMotion, hold: TendMotion.uiTestHold)
            DispatchQueue.main.asyncAfter(deadline: .now() + life) { if pour == play { pour = nil } }
        }
        withAnimation { watered = true }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { toast = outcome.message }
        AccessibilityNotification.Announcement(outcome.message).post()
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { withAnimation { toast = nil } }
    }
}
