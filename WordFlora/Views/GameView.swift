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
    @State private var showBreak = false
    /// Whether "One more" may lead to an ad, captured once as the resting card opens so its note never flickers.
    @State private var adNoteOnOneMore = false
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    private var reduceMotion: Bool { systemReduceMotion || app.settings.reduceMotionOverride }
    /// UI tests open the break card straight away (`-uitest-break-card`) instead of after 20 minutes.
    private static let uiTestBreakCard = ProcessInfo.processInfo.arguments.contains("-uitest-break-card")
    private let breakTimer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()
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
        .onReceive(breakTimer) { _ in
            if app.shouldSuggestBreak && vm.phase != .restingOffer { app.markBreakSuggested(); openCard { showBreak = true } }
        }
        .onAppear {
            app.beginSitting()
            guard !started else { return }
            started = true
            vm.soundEnabled = app.settings.soundOn
            if tutorial { vm.startTutorial(entry: Self.tutorialEntry(in: app.bank)) }
            else if daily { vm.startDaily() } else { vm.startRound(level: level) }
            if Self.uiTestBreakCard { showBreak = true }
        }
        .onDisappear { ReadAloud.shared.stop() }
        .onChange(of: vm.phase) { _, phase in
            if phase == .won || phase == .rested { showBadges(app.roundFinished()) }
            if phase == .won {
                // The big celebration (sound, flower rain, lub-dub) is for a plant arriving. A word that only moves
                // toward the next plant keeps the round's own win sound and gets the calm card.
                let arrived = vm.earnedPlantName != nil
                if arrived { app.play(vm.leveledUp ? .levelUp : .earned) }
                showRain = arrived && !app.settings.calmMode
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                    showEarned = true
                    if arrived && app.settings.hapticsOn {      // a soft lub-dub as the new plant appears
                        let g = UIImpactFeedbackGenerator(style: .soft); g.impactOccurred(intensity: 0.6)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.14) { g.impactOccurred(intensity: 0.9) }
                    }
                }
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
                HStack(alignment: .top) {
                    Text(vm.hint).font(Theme.font(.body)).foregroundStyle(Color.appPrimaryText)
                    Spacer(minLength: 0)
                    if ReadAloud.shouldOffer(voiceOverRunning: UIAccessibility.isVoiceOverRunning) {
                        Button { ReadAloud.shared.speak(hint: vm.hint, extra: vm.extraHint, simpler: vm.simplerClue) } label: {
                            Image(systemName: "speaker.wave.2.fill").frame(width: Theme.minTap, height: Theme.minTap)
                        }
                        .accessibilityLabel("Read the clue aloud")
                    }
                }
                if let extra = vm.extraHint {
                    Divider()
                    Text(extra).font(Theme.font(.callout)).foregroundStyle(Color.secondaryText).transition(.opacity)
                }
                if let simpler = vm.simplerClue {
                    Divider()
                    Label(simpler, systemImage: "sparkles").font(Theme.font(.callout)).foregroundStyle(Color.secondaryText).transition(.opacity)
                    Text("Written on this device").font(Theme.font(.caption)).foregroundStyle(Color.secondaryText)
                } else if vm.canAskSimplerClue {
                    Button { Task { await vm.askSimplerClue() } } label: {
                        Label("Simpler clue", systemImage: "sparkles").font(Theme.font(.subheadline, weight: .semibold)).frame(minHeight: Theme.minTap)
                    }
                    .accessibilityHint("Asks the on-device assistant to say the clue more simply. Free.")
                }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: vm.extraHint)
        .animation(.easeInOut(duration: 0.25), value: vm.simplerClue)
    }

    @ViewBuilder private var overlays: some View {
        if vm.phase == .restingOffer { restingOffer }
        if vm.phase == .rested { restedCard }
        if showEarned { earnedCard }
        if showRestCard { restCard }
        if let badgeToast { badgeBanner(badgeToast) }
        if showBreak { breakCard }
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
                if let hint = vm.roseHint {
                    Label(hint, systemImage: "sparkles").font(Theme.font(.footnote)).multilineTextAlignment(.center).foregroundStyle(Color.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Button { speak(vm.currentWord.capitalized) } label: { Label("Say it", systemImage: "speaker.wave.2.fill") }
                    .buttonStyle(SecondaryButtonStyle())
                Button("Next word") { afterRound() }.buttonStyle(PrimaryButtonStyle())
            }
        }
    }

    private var earnedCard: some View {
        dimmed(rain: showRain) {
            VStack(spacing: 12) {
                if vm.leveledUp { Label("Level up! New plants to find", systemImage: "sparkles").font(Theme.font(.headline)).foregroundStyle(Color.accentText) }
                if let name = vm.earnedPlantName {
                    Text(vm.earnedPlantIsNew ? "New plant found!" : "Your garden grew").font(Theme.font(.title2, weight: .bold))
                    if let plant = app.plants().first(where: { $0.name == name }) {
                        PlantCard(plant: plant).frame(maxWidth: 220)
                        Text(plant.botanicalFact).font(Theme.font(.callout)).multilineTextAlignment(.center).foregroundStyle(Color.appPrimaryText.opacity(0.85))
                    }
                } else {
                    // No plant this round: the word counts toward the next one.
                    Text(PlantProgressCopy.winTitle).font(Theme.font(.title2, weight: .bold))
                    // HOOK (progress meter): the visual words-toward-plant meter (mocked separately) goes here.
                    Text(PlantProgressCopy.winLine(toward: vm.wordsTowardPlant, per: vm.wordsPerPlant))
                        .font(Theme.font(.callout, weight: .semibold)).multilineTextAlignment(.center).foregroundStyle(Color.appPrimaryText)
                        .fixedSize(horizontal: false, vertical: true)
                    if let fact = vm.factAfterRound {
                        Text(fact).font(Theme.font(.callout)).multilineTextAlignment(.center).foregroundStyle(Color.appPrimaryText.opacity(0.85))
                            .fixedSize(horizontal: false, vertical: true)
                    }
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

    private var breakCard: some View {
        dimmed(padding: 0, centered: true) {
            VStack(spacing: 0) {
                RestScene(kind: .day)
                VStack(spacing: 12) {
                    cardTitle(RestCardCopy.breakTitle)
                    cardBody(RestCardCopy.breakBody)
                    // The three things to look at, as pictures; the line above already says them.
                    HStack(alignment: .top, spacing: 22) {
                        look(RestCardCopy.looks[0], systemImage: "square.split.2x2", color: .tileLevelsIcon)
                        look(RestCardCopy.looks[1], systemImage: "leaf", color: .successText)
                        look(RestCardCopy.looks[2], systemImage: "cloud.sun", color: .tileLevelsIcon)
                    }
                    .accessibilityHidden(true)
                    VStack(spacing: 10) {
                        Button(RestCardCopy.takeBreak) { showBreak = false; router.home() }
                            .buttonStyle(PrimaryButtonStyle()).accessibilityIdentifier("breakCard.takeBreak")
                        Button(RestCardCopy.keepPlaying) { closeCard { showBreak = false } }
                            .buttonStyle(SecondaryButtonStyle()).accessibilityIdentifier("breakCard.keepPlaying")
                    }
                    .padding(.top, 6)
                }
                .padding(.horizontal, 20).padding(.top, 4).padding(.bottom, 20)
            }
            .accessibilityElement(children: .contain)
            .accessibilityAddTraits(.isModal)
        }
    }

    private var restCard: some View {
        dimmed(padding: 0, centered: true) {
            VStack(spacing: 0) {
                RestScene(kind: .night)
                VStack(spacing: 12) {
                    cardTitle(RestCardCopy.restTitle)
                    cardBody(RestCardCopy.restBody)
                    Label {
                        Text(RestCardCopy.reward(isDaily: vm.isDaily, wordsPlayed: vm.roundsThisSitting))
                    } icon: {
                        Image(systemName: "leaf.fill").foregroundStyle(Color.successText)
                    }
                    .font(Theme.font(.subheadline, weight: .bold)).foregroundStyle(Color.appPrimaryText)
                    .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                    .padding(.vertical, 6).padding(.horizontal, 14)
                    .background(Color.tileGardenFill, in: Capsule())
                    .accessibilityElement(children: .combine)
                    VStack(spacing: 10) {
                        Button(RestCardCopy.oneMore) { showRestCard = false; Task { await app.adBeforeNextRound(); vm.startRound() } }
                            .buttonStyle(PrimaryButtonStyle()).accessibilityIdentifier("restCard.oneMore")
                        if adNoteOnOneMore {
                            // Said beside the choice that can lead to an ad, never hidden away.
                            Label(RestCardCopy.adNote, systemImage: "info.circle")
                                .font(Theme.font(.footnote)).foregroundStyle(Color.secondaryText)
                                .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                                .accessibilityElement(children: .combine)
                                .accessibilityIdentifier("restCard.adNote")
                        }
                        Button(RestCardCopy.enough) { showRestCard = false; router.home() }
                            .buttonStyle(SecondaryButtonStyle()).accessibilityIdentifier("restCard.enough")
                    }
                    .padding(.top, 6)
                    if app.showBanner { goAdFreeRow.padding(.top, 2) }
                }
                .padding(.horizontal, 20).padding(.top, 4).padding(.bottom, 20)
            }
            .accessibilityElement(children: .contain)
            .accessibilityAddTraits(.isModal)
        }
    }

    /// A quiet, full-width way to Plus: no price, no timer.
    private var goAdFreeRow: some View {
        Button { showRestCard = false; router.home(); router.go(.plus) } label: {
            HStack(spacing: 12) {
                Image(systemName: "sparkles").font(.system(size: 17, weight: .semibold)).foregroundStyle(Color.tileVisitorsIcon)
                    .frame(width: 32, height: 32).background(Color.tileVisitorsFill, in: Circle())
                    .accessibilityHidden(true)
                Text(RestCardCopy.goAdFree).font(Theme.font(.subheadline, weight: .semibold)).foregroundStyle(Color.appPrimaryText)
                    .multilineTextAlignment(.leading).fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "chevron.right").font(Theme.font(.footnote, weight: .semibold)).foregroundStyle(Color.secondaryText)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 12).padding(.vertical, 8)
            .frame(maxWidth: .infinity, minHeight: 52)
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.appPrimaryText.opacity(0.12)))
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityHint(RestCardCopy.goAdFreeHint)
        .accessibilityIdentifier("restCard.goAdFree")
    }

    private func cardTitle(_ text: String) -> some View {
        Text(text).font(Theme.font(.title2, weight: .bold)).foregroundStyle(Color.appPrimaryText)
            .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
            .accessibilityAddTraits(.isHeader)
    }

    private func cardBody(_ text: String) -> some View {
        Text(text).font(Theme.font(.callout)).foregroundStyle(Color.secondaryText)
            .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
    }

    private func look(_ title: String, systemImage: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: systemImage).font(.system(size: 36)).foregroundStyle(color)
            Text(title).font(Theme.font(.footnote, weight: .semibold)).foregroundStyle(Color.secondaryText)
        }
    }

    /// The resting and break cards fade in (and rise a little, unless Reduce Motion is on).
    private func openCard(_ change: () -> Void) {
        withAnimation(reduceMotion ? .easeOut(duration: 0.3) : .timingCurve(0.2, 0.8, 0.2, 1, duration: 0.45)) { change() }
    }

    private func closeCard(_ change: () -> Void) {
        withAnimation(.easeOut(duration: 0.3)) { change() }
    }

    /// Dim, then (optionally) the flower rain, then the card on top so text is never covered.
    /// `padding` is the card's inner padding (the resting and break cards bring their own, under a full-bleed header);
    /// `centered` keeps a short card in the middle of the screen while a tall one still scrolls.
    private func dimmed<C: View>(rain: Bool = false, padding: CGFloat = 20, centered: Bool = false, @ViewBuilder _ content: () -> C) -> some View {
        let shape = RoundedRectangle(cornerRadius: 24, style: .continuous)
        let card = content().padding(padding).background(Color.appBackground, in: shape).clipShape(shape).padding(24)
        return ZStack {
            Color.black.opacity(0.45).ignoresSafeArea()
            if rain { FlowerRainView(onFinish: { showRain = false }).ignoresSafeArea() }
            if centered {
                GeometryReader { geo in
                    ScrollView { card.frame(maxWidth: .infinity, minHeight: geo.size.height) }
                        .scrollBounceBehavior(.basedOnSize)
                }
            } else {
                ScrollView { card }
                    .scrollBounceBehavior(.basedOnSize)
            }
        }
        .transition(reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.96)))
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
        if vm.sessionBeat {
            adNoteOnOneMore = app.adWouldPlayOnOneMore
            openCard { showRestCard = true }
        } else if daily { router.home() } else { vm.startRound() }
    }

    private func speak(_ text: String) {
        let u = AVSpeechUtterance(string: text)
        u.rate = 0.42
        speaker.stopSpeaking(at: .immediate)
        speaker.speak(u)
    }
}
