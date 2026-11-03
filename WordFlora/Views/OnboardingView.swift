import SwiftUI

/// First session (spec section 19, P-03): rain intro, one neutral age question, an unloseable tutorial word,
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

private struct IntroView: View {
    @Environment(AppModel.self) private var app
    @State private var showTitle = false

    var body: some View {
        ZStack {
            VStack(spacing: 8) {
                WordmarkView(style: .largeTitle).scaleEffect(1.25)
                Text("Guess words. Grow a garden.").font(Theme.font(.callout, weight: .medium)).foregroundStyle(Color.secondaryText)
            }
            .opacity(showTitle ? 1 : 0)
            FlowerRainView(onFinish: { withAnimation { app.onboarding.introFinished() } })
        }
        .onAppear { withAnimation(.easeOut(duration: 0.8).delay(0.5)) { showTitle = true } }
        .accessibilityLabel("WordFlora")
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
            if band == .under13 { offerQuiet = true } else { app.onboarding.selectAge(band) }
        } label: { Text(title) }
        .buttonStyle(SecondaryButtonStyle())
        .confirmationDialog("Would you like a quieter garden?", isPresented: $offerQuiet, titleVisibility: .visible) {
            Button("Yes, keep it quiet") { app.settings.quietGarden = true; app.onboarding.selectAge(.under13) }
            Button("No thanks") { app.onboarding.selectAge(.under13) }
        } message: { Text("Quiet Garden hides numbers and timers so tending is just relaxing. You can change it any time in Settings.") }
    }
}

private struct FirstGardenTipView: View {
    @Environment(AppModel.self) private var app
    @State private var watered = false

    private var plant: PlantCollectible? { app.plants().first { $0.earnedCount > 0 } }

    var body: some View {
        VStack(spacing: 18) {
            Spacer()
            Text(watered ? "Lovely. It will grow a little every day." : "Your first plant!").font(Theme.font(.title, weight: .bold)).multilineTextAlignment(.center)
            if let plant {
                PlantCard(plant: plant).frame(maxWidth: 240)
                    .scaleEffect(watered ? 1.04 : 1).animation(.spring(response: 0.4, dampingFraction: 0.5), value: watered)
            }
            Text(watered ? "Plants need water, sun and soil. You will find them all in your garden." : "Plants like a drink. Tap the button to water it.")
                .font(Theme.font(.callout)).multilineTextAlignment(.center).foregroundStyle(Color.secondaryText)
            if watered {
                Button("Play another word") { app.finishOnboarding() }.buttonStyle(PrimaryButtonStyle())
            } else {
                Button { water() } label: { Label("Water your plant", systemImage: "drop.fill") }.buttonStyle(PrimaryButtonStyle())
                Button("Skip") { app.finishOnboarding() }.font(Theme.font(.subheadline)).foregroundStyle(Color.secondaryText).frame(minHeight: Theme.minTap)
            }
            Spacer()
        }
        .padding(24)
    }

    private func water() {
        guard let plant, let profile = app.profile else { watered = true; return }
        profile.water += 1                       // the free first drop
        _ = TendingEngine.water(plant, profile: profile, now: .now, calendar: .current, economy: .default)
        try? app.context.save()
        withAnimation { watered = true }
    }
}
