import SwiftUI
import AVFoundation

struct GameView: View {
    let daily: Bool
    var level: Int? = nil
    var tutorial = false
    var onTutorialFinished: () -> Void = {}

    @Environment(AppModel.self) private var app
    @Environment(GameRouter.self) private var router
    @State private var started = false
    @State private var showEarned = false
    @State private var showRain = false
    @State private var showRestCard = false
    @State private var badgeToast: String?
    @State private var speaker = AVSpeechSynthesizer()

    private var vm: GameViewModel { app.game }
    private var correctCount: Int { vm.guessedLetters.filter { vm.currentWord.contains($0) }.count }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            VStack(spacing: 10) {
                topBar
                FlowerView(petals: vm.petalsRemaining, resting: vm.phase == .restingOffer || vm.phase == .rested)
                    .frame(height: 170)
                hintCard
                WordTilesView(word: vm.currentWord, guessed: vm.guessedLetters, revealAll: vm.phase == .rested)
                    .padding(.horizontal, 8)
                if tutorial && vm.guessedLetters.isEmpty {
                    Text("Tap a letter to guess").font(Theme.font(.callout, weight: .semibold)).foregroundStyle(Color.successText)
                        .symbolEffect(.pulse)
                }
                Spacer(minLength: 4)
                KeyboardView(state: { vm.keyState(for: $0) }, onTap: tap, enabled: vm.phase == .playing)
                    .padding(.bottom, 8)
            }
            .padding(.horizontal, 12)
            .focusable()
            .onKeyPress { press in
                guard let ch = press.characters.uppercased().first, ch.isLetter, vm.phase == .playing else { return .ignored }
                tap(ch); return .handled
            }

            overlays
        }
        .navigationBarBackButtonHidden(true)
        .modifier(GameHaptics(enabled: app.settings.hapticsOn, correctCount: correctCount, petals: vm.petalsRemaining, won: vm.phase == .won))
        .onAppear {
            guard !started else { return }
            started = true
            vm.soundEnabled = app.settings.soundOn
            if tutorial { vm.startTutorial(entry: Self.tutorialEntry(in: app.bank)) }
            else if daily { vm.startDaily() } else { vm.startRound(level: level) }
        }
        .onChange(of: vm.phase) { _, phase in
            if phase == .won || phase == .rested { showBadges(app.roundFinished()) }
            if phase == .won {
                app.play(vm.leveledUp ? .levelUp : .earned)
                showRain = !app.settings.calmMode
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { showEarned = true }
            }
        }
    }

    // MARK: Pieces

    private var topBar: some View {
        HStack {
            if tutorial {
                Color.clear.frame(width: Theme.minTap, height: Theme.minTap)
            } else {
                Button { router.home() } label: { Image(systemName: "house.fill").frame(width: Theme.minTap, height: Theme.minTap) }
                    .accessibilityLabel("Home")
            }
            Spacer()
            Text(tutorial ? "Your first word" : daily ? "Daily Bloom" : "Level \(level ?? vm.currentLevel)").font(Theme.font(.headline))
                .lineLimit(2).multilineTextAlignment(.center)
            Spacer()
            Button { vm.useHelp() } label: {
                Label("Help", systemImage: "lightbulb.fill").labelStyle(.titleAndIcon).font(Theme.font(.subheadline, weight: .semibold))
                    .padding(.horizontal, 10).frame(minHeight: Theme.minTap)
            }
            .disabled(!vm.canUseHelp)
            .symbolEffect(.pulse, isActive: helpPulse)
            .accessibilityHint("Gives a free clue")
        }
        .foregroundStyle(Color.appPrimaryText)
    }

    private var helpPulse: Bool {
        guard vm.canUseHelp, !(UIAccessibility.isReduceMotionEnabled) else { return false }
        let after = AssistTuner.pulseAfterWrongGuesses(level: app.settings.assistLevel)
        return vm.wrongStreak >= after || vm.petalsRemaining <= 2
    }

    private var hintCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 6) {
                Text(vm.hint).font(Theme.font(.body)).foregroundStyle(Color.appPrimaryText)
                if let extra = vm.extraHint {
                    Divider()
                    Text(extra).font(Theme.font(.callout)).foregroundStyle(Color.secondaryText).transition(.opacity)
                }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: vm.extraHint)
    }

    @ViewBuilder private var overlays: some View {
        if vm.phase == .restingOffer { restingOffer }
        if vm.phase == .rested { restedCard }
        if showEarned { earnedCard }
        if showRestCard { restCard }
        if let badgeToast { badgeBanner(badgeToast) }
    }

    private var restingOffer: some View {
        dimmed {
            VStack(spacing: 14) {
                Image("rose_of_jericho").resizable().scaledToFit().frame(height: 80)
                Text("This one's resting").font(Theme.font(.title2, weight: .bold))
                Text("Your Rose of Jericho can wake it up with 4 petals.").font(Theme.font(.callout)).multilineTextAlignment(.center)
                Button("Wake it up") { app.wakeFlower() }.buttonStyle(PrimaryButtonStyle())
                Button("Show me the word") { vm.declineWake() }.buttonStyle(SecondaryButtonStyle())
            }
        }
    }

    private var restedCard: some View {
        dimmed {
            VStack(spacing: 12) {
                Text("This one's resting.").font(Theme.font(.title3, weight: .bold))
                Text("Here's the word:").font(Theme.font(.callout))
                WordTilesView(word: vm.currentWord, guessed: [], revealAll: true)
                if let fact = vm.factAfterRound { Text(fact).font(Theme.font(.callout)).multilineTextAlignment(.center).foregroundStyle(Color.appPrimaryText.opacity(0.85)) }
                Button { speak(vm.currentWord.capitalized) } label: { Label("Say it", systemImage: "speaker.wave.2.fill") }
                    .buttonStyle(SecondaryButtonStyle())
                Button("Next word") { afterRound() }.buttonStyle(PrimaryButtonStyle())
            }
        }
    }

    private var earnedCard: some View {
        dimmed(rain: showRain) {
            VStack(spacing: 12) {
                if vm.leveledUp { Label("Level up! New plants are waiting", systemImage: "sparkles").font(Theme.font(.headline)).foregroundStyle(Color.accentText) }
                Text(vm.earnedPlantIsNew ? "New plant found!" : "Your garden grew").font(Theme.font(.title2, weight: .bold))
                if let name = vm.earnedPlantName, let plant = app.plants().first(where: { $0.name == name }) {
                    PlantCard(plant: plant).frame(maxWidth: 220)
                    Text(plant.botanicalFact).font(Theme.font(.callout)).multilineTextAlignment(.center).foregroundStyle(Color.appPrimaryText.opacity(0.85))
                }
                shareButton
                if vm.roseDropped { Label("A Rose of Jericho is in your satchel", systemImage: "leaf.circle.fill").font(Theme.font(.subheadline, weight: .semibold)).foregroundStyle(Color.successText) }
                Button("Continue") { showEarned = false; app.markPeakDismissed(); afterRound() }.buttonStyle(PrimaryButtonStyle())
            }
        }
    }

    @ViewBuilder private var shareButton: some View {
        if vm.isDaily {
            ShareLink(item: DailyShare.text(date: .now, calendar: .current, solved: true, petalsRemaining: vm.petalsRemaining,
                                            maxPetals: Economy.default.maxPetals, helpers: vm.helpersUsed, word: vm.currentWord)) {
                Label("Share your Daily Bloom", systemImage: "square.and.arrow.up")
            }.buttonStyle(SecondaryButtonStyle())
        } else if let name = vm.earnedPlantName, let plant = app.plants().first(where: { $0.name == name }),
                  let card = PlantShareCard(plantName: plant.name, botanicalName: plant.botanicalName, imageName: plant.imageName, fact: plant.botanicalFact).rendered() {
            ShareLink(item: card, preview: SharePreview(PlantShare.caption(plantName: plant.name, nickname: plant.nickname), image: card)) {
                Label("Share this plant", systemImage: "square.and.arrow.up")
            }.buttonStyle(SecondaryButtonStyle())
        }
    }

    private var restCard: some View {
        dimmed {
            VStack(spacing: 14) {
                FlowerView(petals: 8, sway: false).frame(height: 110)
                Text("The garden is resting").font(Theme.font(.title2, weight: .bold))
                Text("Take a breath. Come back whenever you like.").font(Theme.font(.callout)).multilineTextAlignment(.center)
                HStack(spacing: 12) {
                    Button("One more") { showRestCard = false; Task { await app.adBeforeNextRound(); vm.startRound() } }.buttonStyle(PrimaryButtonStyle())
                    Button("That's enough for now") { showRestCard = false; router.home() }.buttonStyle(SecondaryButtonStyle())
                }
                if app.showBanner {
                    Button("Go ad-free") { showRestCard = false; router.home(); router.go(.plus) }
                        .font(Theme.font(.footnote)).foregroundStyle(Color.secondaryText).frame(minHeight: Theme.minTap)
                }
            }
        }
    }

    /// Dim, then (optionally) the flower rain, then the card on top so text is never covered.
    private func dimmed<C: View>(rain: Bool = false, @ViewBuilder _ content: () -> C) -> some View {
        ZStack {
            Color.black.opacity(0.45).ignoresSafeArea()
            if rain { FlowerRainView(onFinish: { showRain = false }).ignoresSafeArea() }
            ScrollView { content().padding(20).background(Color.appBackground, in: RoundedRectangle(cornerRadius: 24)).padding(24) }
                .scrollBounceBehavior(.basedOnSize)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.96)))
    }

    private func badgeBanner(_ text: String) -> some View {
        VStack {
            Label(text, systemImage: "rosette").font(Theme.font(.subheadline, weight: .bold)).foregroundStyle(Color.appPrimaryText)
                .padding(.horizontal, 16).padding(.vertical, 10).background(Color.appSurface, in: Capsule()).shadow(radius: 6, y: 2)
                .transition(.move(edge: .top).combined(with: .opacity))
            Spacer()
        }.padding(.top, 8).allowsHitTesting(false)
    }

    /// One badge toast at a time, shown after the round's own celebration so it never stacks with it.
    private func showBadges(_ unlocks: [BadgeUnlock]) {
        guard let u = unlocks.max(by: { $0.tier < $1.tier }) else { return }
        let defs = (try? BadgeCatalog.load()) ?? []
        let title = defs.first { $0.id == u.badgeId }?.title ?? "Badge"
        let tier = ["Bronze", "Silver", "Gold"][max(0, min(2, u.tier - 1))]
        app.markPeakDismissed()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            app.play(.badge(tier: u.tier))
            withAnimation { badgeToast = "\(tier) \(title)" }
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) { withAnimation { badgeToast = nil } }
        }
    }

    // MARK: Actions

    private func tap(_ ch: Character) {
        vm.guessInput = String(ch)
        withAnimation { vm.submitGuess() }
    }

    static func tutorialEntry(in bank: WordBank) -> WordEntry {
        bank.entries.first { $0.id == "l1-seed" } ?? bank.entries.first { $0.level == 1 && $0.kind == .vocab } ?? bank.entries[0]
    }

    private func afterRound() {
        if tutorial { onTutorialFinished(); return }
        if vm.sessionBeat { showRestCard = true } else if daily { router.home() } else { vm.startRound() }
    }

    private func speak(_ text: String) {
        let u = AVSpeechUtterance(string: text)
        u.rate = 0.42
        speaker.stopSpeaking(at: .immediate)
        speaker.speak(u)
    }
}
