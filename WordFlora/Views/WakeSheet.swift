import SwiftUI

/// The quiet card a seed shows on its plant page. Its one button opens the wake sheet (presented by the host screen,
/// so it stays up while the seed wakes and the card goes away).
struct WakeSeedCard: View {
    let plant: PlantCollectible
    @Binding var isPresented: Bool

    private var name: String { plant.nickname.isEmpty ? plant.name : plant.nickname }

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                Text(WakeCopy.seedCard(name: name)).font(Theme.font(.callout)).foregroundStyle(Color.appPrimaryText)
                    .fixedSize(horizontal: false, vertical: true)
                Button { isPresented = true } label: { Label(WakeCopy.wakeButton(name: name), systemImage: "sun.horizon.fill") }
                    .buttonStyle(SecondaryButtonStyle())
            }
        }
    }
}

/// The wake flow: pick a challenge, read one line, play, then the petals come back (or "still dreaming").
/// A plain X or a swipe down closes it at any point and changes nothing.
struct WakeSheet: View {
    let plant: PlantCollectible
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var typeSize

    enum Step: Equatable { case choose, intro(WakeChallenge), play(WakeChallenge), awake, dreaming(WakeChallenge) }
    @State private var step: Step = .choose
    @State private var detent: PresentationDetent = .medium

    private var name: String { plant.nickname.isEmpty ? plant.name : plant.nickname }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Group {
                switch step {
                case .choose: chooser
                case .intro(let c): intro(c)
                case .play(.butterflies): WakeButterflyGame(goal: app.wakeButterflyGoal) { woke in finish(.butterflies, woke: woke) }
                case .play(.wordPuzzle): puzzle
                case .awake: WakeSuccessView(plant: plant, name: name) { dismiss() }
                case .dreaming(let c): dreaming(c)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

            Button { dismiss() } label: {
                Image(systemName: "xmark").font(.body.weight(.semibold)).foregroundStyle(Color.secondaryText)
                    .frame(width: 32, height: 32).background(Color.appSurface, in: Circle())
            }
            .tapTarget()
            .accessibilityLabel(WakeCopy.close)
            .accessibilitySortPriority(-1)          // VoiceOver: title, tiles, then Close
            .padding(8)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .rewardToast($toast, announce: false)          // R3: the success view says it too, so VoiceOver hears it once
        .presentationDetents([.medium, .large], selection: $detent)
        .presentationDragIndicator(.visible)
        .onAppear { detent = needsLarge(.choose) ? .large : .medium; app.pauseBadgeMoments(.sheet, true) }
        .onDisappear { app.pauseBadgeMoments(.sheet, false) }      // badges from the wake game pop once the sheet is closed
        .onChange(of: step) { _, s in withAnimation { detent = needsLarge(s) ? .large : .medium } }
    }

    private func needsLarge(_ s: Step) -> Bool {
        if typeSize.isAccessibilitySize { return true }
        switch s { case .choose, .intro: return false; default: return true }
    }

    // MARK: Choose

    private var chooser: some View {
        let suggested = app.wakeSuggestion
        return ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(WakeCopy.sheetTitle(name: name)).font(Theme.font(.title2, weight: .bold)).foregroundStyle(Color.appPrimaryText)
                        .accessibilityAddTraits(.isHeader)
                    Text(WakeCopy.sheetSubtitle).font(Theme.font(.callout)).foregroundStyle(Color.secondaryText)
                }
                .padding(.trailing, 48)
                ForEach(WakeRule.ordered(suggested: suggested), id: \.self) { c in
                    WakeTile(challenge: c, suggested: c == suggested) { step = .intro(c) }
                }
                gentleWakeRow
            }
            .padding(20)
        }
        .scrollBounceBehavior(.basedOnSize)
    }

    @State private var toast: String?
    @State private var watching = false

    /// R3: a third, quieter way to wake, only after one "still dreaming" try; once a day. A video for 13 and over
    /// without Plus ("The two challenges stay free"), free for Plus, under 13 and an unknown age. It wakes the seed
    /// like a win but grants no sticker, badge progress, water, shed points or soil.
    @ViewBuilder private var gentleWakeRow: some View {
        RewardedPromptRow.forPath(app.perkPath(.wake), adTitle: AdPerkCopy.Wake.adTitle, freeTitle: AdPerkCopy.Wake.freeTitle,
                                  adSubtitle: AdPerkCopy.Wake.adSubtitle, freeSubtitle: AdPerkCopy.Wake.freeSubtitle,
                                  hasPlus: app.entitlements.state.hasPlus, identifier: "wake.gentle", busy: watching) {
            guard !watching else { return }
            watching = true
            Task {
                if await app.watchRewarded(.wake) {
                    app.gentleWake(plant)
                    toast = AdPerkCopy.Wake.toast(name: name)
                    step = .awake
                }
                watching = false
            }
        }
        .disabled(watching)
    }

    // MARK: Intro

    private func intro(_ c: WakeChallenge) -> some View {
        let line = c == .butterflies ? WakeCopy.butterflyIntro(goal: app.wakeButterflyGoal) : (app.wakePuzzle(for: plant)?.intro ?? WakeCopy.puzzleIntroAnagram)
        return ScrollView {
            VStack(spacing: 16) {
                WakeTileArt(challenge: c).frame(width: 72, height: 72)
                Text(WakeCopy.title(c)).font(Theme.font(.title2, weight: .bold)).foregroundStyle(Color.appPrimaryText)
                    .accessibilityAddTraits(.isHeader)
                Text(line).font(Theme.font(.body)).foregroundStyle(Color.appPrimaryText).multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                Button(WakeCopy.start) { step = .play(c) }.buttonStyle(PrimaryButtonStyle())
            }
            .padding(.horizontal, 24).padding(.top, 36).padding(.bottom, 20)
        }
        .scrollBounceBehavior(.basedOnSize)
    }

    // MARK: Play

    @ViewBuilder private var puzzle: some View {
        if let p = app.wakePuzzle(for: plant) {
            WakePuzzleView(puzzle: p, validNames: app.plants().map(\.name),
                           onSolved: { finish(.wordPuzzle, woke: true) },
                           onTryButterflies: { app.finishWake(plant, challenge: .wordPuzzle, woke: false); step = .intro(.butterflies) })
        } else {
            // No usable plant names (should not happen with the shipped catalog): offer the butterflies instead.
            dreaming(.wordPuzzle)
        }
    }

    private func finish(_ c: WakeChallenge, woke: Bool) {
        app.finishWake(plant, challenge: c, woke: woke)
        step = woke ? .awake : .dreaming(c)
        if !woke { AccessibilityNotification.Announcement(WakeCopy.stillDreamingShort).post() }
    }

    // MARK: Still dreaming

    private func dreaming(_ c: WakeChallenge) -> some View {
        // After two tries in a row, the easier butterflies become the main button.
        let butterfliesFirst = c == .wordPuzzle && app.wakeIsEasier
        return ScrollView {
            VStack(spacing: 14) {
                Image(plant.imageName).resizable().scaledToFit().frame(height: 72).saturation(0.4).opacity(0.8).accessibilityHidden(true)
                Text(WakeCopy.stillDreaming(name: name)).font(Theme.font(.title3, weight: .bold)).foregroundStyle(Color.appPrimaryText)
                    .multilineTextAlignment(.center).accessibilityAddTraits(.isHeader)
                Text(WakeCopy.tryAgainAnyTime).font(Theme.font(.callout)).foregroundStyle(Color.secondaryText).multilineTextAlignment(.center)
                if c == .butterflies {
                    Button(WakeCopy.tryAgain) { step = .intro(.butterflies) }.buttonStyle(PrimaryButtonStyle())
                } else if butterfliesFirst {
                    Button(WakeCopy.tryButterflies) { step = .intro(.butterflies) }.buttonStyle(PrimaryButtonStyle())
                    Button(WakeCopy.tryAgain) { step = .intro(.wordPuzzle) }.buttonStyle(SecondaryButtonStyle())
                } else {
                    Button(WakeCopy.tryAgain) { step = .intro(.wordPuzzle) }.buttonStyle(PrimaryButtonStyle())
                    Button(WakeCopy.tryButterflies) { step = .intro(.butterflies) }.buttonStyle(SecondaryButtonStyle())
                }
            }
            .padding(.horizontal, 24).padding(.top, 36).padding(.bottom, 20)
        }
        .scrollBounceBehavior(.basedOnSize)
    }
}

// MARK: Tiles

private struct WakeTile: View {
    let challenge: WakeChallenge
    let suggested: Bool
    let tap: () -> Void
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        Button(action: tap) {
            HStack(alignment: .center, spacing: 14) {
                WakeTileArt(challenge: challenge).frame(width: typeSize.isAccessibilitySize ? 56 : 64, height: typeSize.isAccessibilitySize ? 56 : 64)
                VStack(alignment: .leading, spacing: 6) {
                    if suggested {
                        Text(WakeCopy.suggestedBadge).font(Theme.font(.caption, weight: .bold)).foregroundStyle(Color.ink)
                            .padding(.horizontal, 8).padding(.vertical, 3).background(Color.appAccent, in: Capsule())
                    }
                    // The title takes its full height (it was squeezed a fraction at the default size: clipped text).
                    Text(WakeCopy.title(challenge)).font(Theme.font(.headline, weight: .bold)).foregroundStyle(Color.appPrimaryText)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(WakeCopy.subtitle(challenge)).font(Theme.font(.subheadline)).foregroundStyle(Color.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                    if typeSize.isAccessibilitySize {
                        VStack(alignment: .leading, spacing: 6) { chips }
                    } else {
                        HStack(spacing: 6) { chips }
                    }
                }
                Spacer(minLength: 0)
            }
            .multilineTextAlignment(.leading)
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 96, alignment: .leading)
            .background(Color.appSurface, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
            .overlay(RoundedRectangle(cornerRadius: Theme.cardRadius)
                .stroke(suggested ? Color.appAccent : Color.appPrimaryText.opacity(0.1), lineWidth: suggested ? 2 : 1))
            .contentShape(RoundedRectangle(cornerRadius: Theme.cardRadius))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(WakeCopy.tileLabel(challenge, suggested: suggested))
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier("wake-\(challenge.rawValue)")
    }

    @ViewBuilder private var chips: some View {
        chip(WakeCopy.lengthChip(challenge))
        chip(WakeCopy.feelChip(challenge))
    }

    private func chip(_ text: String) -> some View {
        Text(text).font(Theme.font(.caption, weight: .semibold)).foregroundStyle(Color.appPrimaryText)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 10).padding(.vertical, 4)
            .background(Color.appPrimaryText.opacity(0.07), in: Capsule())
    }
}

private struct WakeTileArt: View {
    let challenge: WakeChallenge
    var body: some View {
        Group {
            switch challenge {
            case .butterflies: Image("visitor_monarch_idle").resizable().scaledToFit()
            case .wordPuzzle: Image(systemName: "textformat.abc").resizable().scaledToFit().padding(12).foregroundStyle(Color.successText)
            }
        }
        .background(Color.appPrimaryText.opacity(0.05), in: RoundedRectangle(cornerRadius: 14))
        .accessibilityHidden(true)
    }
}

// MARK: Butterflies (the garden visitor game, ending as soon as the gentle goal is met)

struct WakeButterflyGame: View {
    let goal: Int
    let onEnd: (Bool) -> Void
    @Environment(AppModel.self) private var app
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @State private var game: ButterflyGameModel?
    @State private var lastTick = Date()
    @State private var ended = false
    private let ticker = Timer.publish(every: 1.0 / 30.0, on: .main, in: .common).autoconnect()

    private var reduceMotion: Bool { systemReduceMotion || app.settings.reduceMotionOverride }

    var body: some View {
        VStack(spacing: 8) {
            Text(WakeCopy.caughtSoFar(game?.caught.count ?? 0, goal: goal))
                .font(Theme.font(.headline, weight: .bold)).foregroundStyle(Color.appPrimaryText)
                .padding(.top, 20).accessibilityAddTraits(.updatesFrequently)
            GeometryReader { geo in
                ZStack {
                    LinearGradient(colors: [Color(hex: 0xBFE6F5), Color(hex: 0xE9F6E0)], startPoint: .top, endPoint: .bottom)
                    ForEach(game?.visitors ?? []) { v in
                        Image(v.resting ? "visitor_\(v.speciesId)_idle" : "visitor_\(v.speciesId)_\(Int((game?.elapsed ?? 0) * 4) % 2 == 0 ? "a" : "b")")
                            .resizable().scaledToFit().frame(width: 64, height: 64)
                            .scaleEffect(x: v.vx < 0 ? -1 : 1, y: 1)
                            .position(x: v.x * geo.size.width, y: v.y * geo.size.height)
                            .accessibilityElement().accessibilityLabel(VisitorCatalog.species(v.speciesId)?.name ?? "Visitor")
                            .accessibilityAddTraits(.isButton)
                            .accessibilityAction { catchAt(CGPoint(x: v.x * geo.size.width, y: v.y * geo.size.height), in: geo.size) }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius))
                .contentShape(Rectangle())
                .gesture(DragGesture(minimumDistance: 0).onChanged { catchAt($0.location, in: geo.size) })
            }
            .padding(16)
        }
        .onAppear {
            if game == nil { game = app.startButterflyGame(reduceMotion: reduceMotion, wake: true); lastTick = Date() }
        }
        .onDisappear {
            // Closed partway: the hellos so far still go to the album (no wake result is recorded).
            guard !ended, let game, !game.caught.isEmpty else { return }
            ended = true
            app.finishButterflyGame(game, wake: true)
        }
        .onReceive(ticker) { now in
            guard var g = game, !ended else { return }
            let dt = min(0.1, max(0, now.timeIntervalSince(lastTick)))
            lastTick = now
            g.tick(dt); game = g
            if g.isFinished { end(WakeRule.butterfliesWoke(caught: g.caught.count, goal: goal)) }
        }
    }

    private func catchAt(_ point: CGPoint, in size: CGSize) {
        guard var g = game, !ended, size.width > 0, size.height > 0 else { return }
        let radius = ToolEngine.netCatchRadius(tier: app.inventory.tier(of: .net)) / size.width
        guard let species = g.catchAt(x: point.x / size.width, y: point.y / size.height, radius: max(0.08, radius)) else { return }
        game = g
        app.play(.butterfly)
        AccessibilityNotification.Announcement("\(VisitorCatalog.species(species)?.name ?? "Visitor") says hello").post()
        if WakeRule.butterfliesWoke(caught: g.caught.count, goal: goal) { end(true) }
    }

    private func end(_ woke: Bool) {
        guard !ended else { return }
        ended = true
        // Every hello counts toward the album and badges (no shed points from a wake game).
        if let game { app.finishButterflyGame(game, wake: true) }
        onEnd(woke)
    }
}

// MARK: Success

/// The plant wakes, then her love pips return one at a time (0.3 s apart, 2.4 s at most). A tap shows them all;
/// Reduce Motion shows them all at once. A soft haptic on the first petal and when all are back. One announcement.
struct WakeSuccessView: View {
    let plant: PlantCollectible
    let name: String
    let done: () -> Void
    @Environment(AppModel.self) private var app
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @State private var shown = 0
    @State private var glow = false
    @State private var skipped = false

    private var reduceMotion: Bool { systemReduceMotion || app.settings.reduceMotionOverride }
    private let total = LoveEngine.maxPetals

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                Image(plant.imageName).resizable().scaledToFit().frame(height: 120)
                    .background(Circle().fill(Color.appAccent.opacity(glow ? 0.35 : 0)).blur(radius: 18))
                    .accessibilityHidden(true)
                Text(WakeCopy.awake(name: name)).font(Theme.font(.title2, weight: .bold)).foregroundStyle(Color.appPrimaryText)
                    .accessibilityAddTraits(.isHeader)
                Text(WakeCopy.petalsComing).font(Theme.font(.callout)).foregroundStyle(Color.secondaryText)
                LovePips(shown: shown, total: total)
                if shown < total {
                    Text(WakeCopy.tapToSeeAll).font(Theme.font(.footnote)).foregroundStyle(Color.secondaryText)
                }
                Button(WakeCopy.done, action: done).buttonStyle(PrimaryButtonStyle()).padding(.top, 6)
            }
            .padding(.horizontal, 24).padding(.top, 36).padding(.bottom, 20)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .onTapGesture { showAll() }
        }
        .scrollBounceBehavior(.basedOnSize)
        .background { CelebrationBurst(requested: [.medium], origin: .fromTop(36 + 100)) }     // petals from behind the plant
        .modifier(PetalHaptics(enabled: app.settings.hapticsOn, shown: shown, total: total))
        .task { await run() }
    }

    private func run() async {
        AccessibilityNotification.Announcement(WakeCopy.awakeAnnouncement(name: name)).post()
        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.6)) { glow = true }
        var elapsed = 0.0
        for (i, delay) in PetalReturn.delays(count: total, reduceMotion: reduceMotion).enumerated() {
            if delay > elapsed { try? await Task.sleep(for: .seconds(delay - elapsed)); elapsed = delay }
            if skipped || Task.isCancelled { return }
            withAnimation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.6)) { shown = max(shown, i + 1) }
        }
    }

    private func showAll() {
        guard shown < total else { return }
        skipped = true
        shown = total
    }
}

private struct PetalHaptics: ViewModifier {
    let enabled: Bool
    let shown: Int
    let total: Int
    func body(content: Content) -> some View {
        if enabled {
            content.sensoryFeedback(trigger: shown) { old, new in
                (old == 0 && new > 0) || (new == total && old < total) ? .impact(flexibility: .soft, intensity: 0.6) : nil
            }
        } else {
            content
        }
    }
}

/// The love row: a small love flower, then one pip per petal (pink for love, a dashed outline for the rest).
struct LovePips: View {
    let shown: Int
    let total: Int
    static let pink = Color(hex: 0xE76F9A)

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "camera.macro").foregroundStyle(Self.pink).font(.title3)
            ForEach(0..<total, id: \.self) { i in
                if i < shown {
                    Circle().fill(Self.pink).frame(width: 18, height: 18).transition(.scale.combined(with: .opacity))
                } else {
                    Circle().fill(Self.pink.opacity(0.08)).overlay(Circle().strokeBorder(Self.pink.opacity(0.6), style: StrokeStyle(lineWidth: 1.5, dash: [3, 3])))
                        .frame(width: 18, height: 18)
                }
            }
        }
        .frame(minHeight: Theme.minTap)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(shown) of \(total) petals")
    }
}
