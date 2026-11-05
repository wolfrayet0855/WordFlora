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
            case .intro: IntroView()
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
        IntroBloomView { withAnimation(.easeInOut(duration: IntroTimeline.handoff)) { app.onboarding.introFinished() } }
    }
}

private struct AgeQuestionView: View {
    @Environment(AppModel.self) private var app
    @State private var offerQuiet = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
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
            .padding(24).frame(maxWidth: .infinity)
        }
        .scrollBounceBehavior(.basedOnSize)
    }

    private func ageButton(_ title: String, _ band: AgeBand) -> some View {
        Button {
            app.settings.applyAgeDefaults(band)
            if band == .under13 { offerQuiet = true } else { app.onboarding.selectAge(band, guideSeen: app.profile?.guideSeen ?? false) }
        } label: { Text(title) }
        .buttonStyle(SecondaryButtonStyle())
        .confirmationDialog("Would you like a quieter garden?", isPresented: $offerQuiet, titleVisibility: .visible) {
            Button("Yes, keep it quiet") { app.settings.quietGarden = true; app.onboarding.selectAge(.under13, guideSeen: app.profile?.guideSeen ?? false) }
            Button("No thanks") { app.onboarding.selectAge(.under13, guideSeen: app.profile?.guideSeen ?? false) }
        } message: { Text("Quiet Garden hides numbers and timers so tending is just relaxing. You can change it any time in Settings.") }
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
