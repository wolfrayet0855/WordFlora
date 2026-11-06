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
    /// The win: a dim at once, petals over it, the card at 0.7 s above them (design-preview/celebrate, confetti "large").
    @State private var winDim = false
    @State private var winBurst: [CelebrationLevel]?
    /// The letter just found: its tiles pop with a small puff of petals.
    @State private var tilePop: TilePop?
    @State private var showRestCard = false
    @State private var showBreak = false
    /// Whether "One more" may lead to an ad, captured once as the resting card opens so its note never flickers.
    @State private var adNoteOnOneMore = false
    /// Whether the card offers the quiet "Go ad-free" row, also captured once as the card opens: the card then does
    /// not redraw when the ad rules' inputs (store state, settings) update behind it.
    @State private var goAdFreeOnCard = false
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    private var reduceMotion: Bool { systemReduceMotion || app.settings.reduceMotionOverride }
    /// UI tests open the break card straight away (`-uitest-break-card`) instead of after 20 minutes.
    private static let uiTestBreakCard = ProcessInfo.processInfo.arguments.contains("-uitest-break-card")
    private let breakTimer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()
    @State private var speaker = AVSpeechSynthesizer()

    private var vm: GameViewModel { app.game }
    /// The resting and break cards are modal: only the flower shows, dimmed, behind them (as in the mockup).
    private var cardIsModal: Bool { showBreak || showRestCard }
    private var correctCount: Int { vm.guessedLetters.filter { vm.currentWord.contains($0) }.count }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            VStack(spacing: 10) {
                topBar.modifier(BehindModalCard(active: cardIsModal, minHeight: Theme.minTap))
                // Still behind the resting and break cards: a sway that never ends kept the app from going idle
                // while a card sat open, and the accessibility audit then measured the card's text mid-layout.
                FlowerView(petals: vm.petalsRemaining, resting: vm.phase == .restingOffer || vm.phase == .rested, sway: !cardIsModal)
                    .frame(height: 170)
                VStack(spacing: 10) {
                    hintCard
                    WordTilesView(word: vm.currentWord, guessed: vm.guessedLetters, revealAll: vm.phase == .rested, pop: tilePop)
                        .padding(.horizontal, 8)
                    if tutorial && vm.guessedLetters.isEmpty {
                        Text("Tap a letter to guess").font(Theme.font(.callout, weight: .semibold)).foregroundStyle(Color.successText)
                            .symbolEffect(.pulse)
                    }
                }
                .modifier(BehindModalCard(active: cardIsModal))
                Spacer(minLength: 4)
                KeyboardView(state: { vm.keyState(for: $0) }, onTap: tap, enabled: vm.phase == .playing)
                    .padding(.bottom, 8)
                    .modifier(BehindModalCard(active: cardIsModal))
            }
            .padding(.horizontal, 12)
            // The resting and break cards are modal: the dimmed round behind them is hidden from VoiceOver.
            .accessibilityHidden(cardIsModal || app.shownBadge != nil)
            .focusable()
            .onKeyPress { press in
                guard let ch = press.characters.uppercased().first, ch.isLetter, vm.phase == .playing, !cardIsModal else { return .ignored }
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
        .onDisappear { ReadAloud.shared.stop(); app.pauseBadgeMoments(.round, false) }
        .onChange(of: vm.phase) { _, phase in
            if phase == .won || phase == .rested {
                // Badges earned this round wait for the round's card to close, then pop at the root.
                app.pauseBadgeMoments(.round, true)
                if !app.roundFinished().isEmpty { app.markPeakDismissed() }
            }
            if phase == .won {
                // The round already played its one win sound (GameViewModel). The big petal burst is for a plant
                // arriving or the Daily Bloom, with a level up layered over it; a word that only moves toward the next
                // plant has had its puff from the last tile. Calm mode gets the gentle drift (CelebrationStyle).
                let arrived = vm.earnedPlantName != nil
                var levels = [CelebrationLevel]()
                if vm.leveledUp { levels.append(.medium) }
                if arrived || vm.isDaily { levels.append(.large) }
                winBurst = levels.isEmpty ? nil : levels
                withAnimation(.easeOut(duration: reduceMotion ? 0.15 : 0.3)) { winDim = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + (reduceMotion ? 0.15 : 0.7)) {
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
                // At accessibility sizes the word would break mid-word ("Hel-p"); the bulb alone keeps the label "Help".
                Group {
                    if dynamicTypeSize.isAccessibilitySize { Image(systemName: "lightbulb.fill") }
                    else { Label("Help", systemImage: "lightbulb.fill").labelStyle(.titleAndIcon) }
                }
                .font(Theme.font(.subheadline, weight: .semibold))
                .padding(.horizontal, 10).frame(minWidth: Theme.minTap, minHeight: Theme.minTap)
            }
            .accessibilityLabel("Help")
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
                HStack(alignment: .center) {
                    Text(vm.hint).font(Theme.font(.body)).foregroundStyle(Color.appPrimaryText)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                    if ReadAloud.shouldOffer(voiceOverRunning: UIAccessibility.isVoiceOverRunning) {
                        Button { ReadAloud.shared.speak(hint: vm.hint, extra: vm.extraHint, simpler: vm.simplerClue) } label: {
                            Image(systemName: "speaker.wave.2.fill").frame(width: Theme.minTap, height: Theme.minTap)
                        }
                        // The hit area stays 44pt; it may reach past the line so a one-line clue keeps a short card.
                        .padding(.vertical, -10)
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
                    // The 44 point hit area may reach into the card's padding, so the space under the words matches the top.
                    .padding(.bottom, -12)
                }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: vm.extraHint)
        .animation(.easeInOut(duration: 0.25), value: vm.simplerClue)
    }

    @ViewBuilder private var overlays: some View {
        if vm.phase == .restingOffer { restingOffer }
        if vm.phase == .rested { restedCard }
        if winDim { Color.black.opacity(0.45).ignoresSafeArea().transition(.opacity) }
        if winDim, let winBurst {
            CelebrationBurst(requested: winBurst, origin: .fromTop(ScreenInsets.top + 36)).accessibilityIdentifier("petalConfetti")
        }
        if showEarned { earnedCard }
        if showRestCard { restCard }
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
        dimmed(dim: false) {
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
                Button("Continue") { showEarned = false; winDim = false; winBurst = nil; app.markPeakDismissed(); afterRound() }.buttonStyle(PrimaryButtonStyle())
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
                    // The three things to look at: pictures with their names, read as one line (never buttons).
                    // At accessibility text sizes a row would break the names mid-word, so it stacks instead.
                    let looksLayout = dynamicTypeSize.isAccessibilitySize
                        ? AnyLayout(VStackLayout(spacing: 10)) : AnyLayout(HStackLayout(alignment: .top, spacing: 22))
                    looksLayout { looks }
                        .accessibilityElement(children: .combine)
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
            .accessibilityIdentifier("breakCard")
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
                        Button(RestCardCopy.enough) { showRestCard = false; app.markRestExit(); router.home() }
                            .buttonStyle(SecondaryButtonStyle()).accessibilityIdentifier("restCard.enough")
                    }
                    .padding(.top, 6)
                    if goAdFreeOnCard { goAdFreeRow.padding(.top, 2) }
                }
                .padding(.horizontal, 20).padding(.top, 4).padding(.bottom, 20)
            }
            .accessibilityElement(children: .contain)
            .accessibilityAddTraits(.isModal)
            .accessibilityIdentifier("restCard")
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

    @ViewBuilder private var looks: some View {
        look(RestCardCopy.looks[0], systemImage: "square.split.2x2", color: .tileLevelsIcon)
        look(RestCardCopy.looks[1], systemImage: "leaf", color: .successText)
        look(RestCardCopy.looks[2], systemImage: "cloud.sun", color: .tileLevelsIcon)
    }

    private func look(_ title: String, systemImage: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: systemImage).font(.system(size: 36)).foregroundStyle(color).accessibilityHidden(true)
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

    /// Dim (unless the win's own dim is already up), then the card on top so text is never covered.
    /// `padding` is the card's inner padding (the resting and break cards bring their own, under a full-bleed header);
    /// `centered` keeps a short card in the middle of the screen while a tall one still scrolls.
    private func dimmed<C: View>(dim: Bool = true, padding: CGFloat = 20, centered: Bool = false, @ViewBuilder _ content: () -> C) -> some View {
        let shape = RoundedRectangle(cornerRadius: 24, style: .continuous)
        let card = content().padding(padding).background(Color.appBackground, in: shape).clipShape(shape).padding(Space.section)
        return ZStack {
            if dim { Color.black.opacity(0.45).ignoresSafeArea() }
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

    // MARK: Actions

    private func tap(_ ch: Character) {
        let fresh = vm.phase == .playing && !vm.guessedLetters.contains(ch)
        vm.guessInput = String(ch)
        withAnimation { vm.submitGuess() }
        if fresh && vm.currentWord.contains(ch) {
            tilePop = TilePop(letter: ch, id: (tilePop?.id ?? 0) + 1,
                              level: app.celebrationLevel(.small, systemReduceMotion: systemReduceMotion), at: .now)
        }
    }

    static func tutorialEntry(in bank: WordBank) -> WordEntry {
        bank.entries.first { $0.id == "l1-seed" } ?? bank.entries.first { $0.level == 1 && $0.kind == .vocab } ?? bank.entries[0]
    }

    private func afterRound() {
        app.pauseBadgeMoments(.round, false)
        if tutorial { onTutorialFinished(); return }
        if vm.sessionBeat {
            adNoteOnOneMore = app.adWouldPlayOnOneMore
            goAdFreeOnCard = app.showBanner
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

/// Behind a modal card the round's text (top bar, clue, tiles, keyboard) is taken away and only the dimmed flower
/// stays, as in the mockup. Hiding is not enough: the accessibility audit still measures hidden or transparent text,
/// so the views leave the hierarchy. A clear box of the same size keeps the flower where it was, and the round comes
/// back unchanged when the card closes (its state lives in the view model).
private struct BehindModalCard: ViewModifier {
    var active: Bool
    var minHeight: CGFloat = 0
    @State private var size: CGSize = .zero

    func body(content: Content) -> some View {
        if active {
            Color.clear.frame(height: max(size.height, minHeight)).accessibilityHidden(true)
        } else {
            content.onGeometryChange(for: CGSize.self) { $0.size } action: { size = $0 }
        }
    }
}
