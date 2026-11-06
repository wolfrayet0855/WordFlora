import SwiftUI

// The weather puzzle (E-8; design-preview/endgame intro, puzzle, cap and mended frames). The reward is named before
// play, Start and Skip are the same size, there is no timer anywhere, tries are free, and a peek is always coming.
// Shown full screen; the visit that opens it stays free of Plus cards and ads (`markQuietVisit`).
//
// INTEGRATION (builder A): present `WeatherPuzzleSheet { dismiss }` from the event banner, the forecast card on the
// day and the plant page of a weathered plant when `app.weatherPuzzleOpen`. Wild Weather's second part (the butterfly
// catch, E-12) can follow `onSolvedWord` before the solve is recorded.

/// A weather sticker drawn as a picture (an emoji rendered to an image, so it is never judged as text).
struct WeatherStickerImage: View {
    let sticker: WeatherSticker
    var owned = true
    @ScaledMetric(relativeTo: .title) private var size: CGFloat = 56

    var body: some View {
        Image(uiImage: Self.render(sticker.emoji))
            .resizable().scaledToFit()
            .padding(size * 0.14)
            .frame(width: size, height: size)
            .background(Circle().fill(Color.appSurface))
            .overlay(Circle().stroke(Color.appPrimaryText.opacity(0.15), style: StrokeStyle(lineWidth: 1.5, dash: owned ? [] : [4, 3])))
            .saturation(owned ? 1 : 0).opacity(owned ? 1 : 0.4)
            .accessibilityElement()
            .accessibilityLabel(EndgameCopy.stickerPage(sticker.name, owned: owned))
            .accessibilityAddTraits(.isImage)
    }

    @MainActor private static var cache: [String: UIImage] = [:]
    @MainActor static func render(_ emoji: String) -> UIImage {
        if let c = cache[emoji] { return c }
        let s = CGSize(width: 96, height: 96)
        let img = UIGraphicsImageRenderer(size: s).image { _ in
            let a = NSAttributedString(string: emoji, attributes: [.font: UIFont.systemFont(ofSize: 76)])
            let b = a.size()
            a.draw(at: CGPoint(x: (s.width - b.width) / 2, y: (s.height - b.height) / 2))
        }
        cache[emoji] = img
        return img
    }
}

struct WeatherPuzzleSheet: View {
    let close: () -> Void
    /// Called when the word is solved, before the solve is recorded (Wild Weather's part 2 hooks in here).
    var onSolvedWord: (() -> Void)?

    @Environment(AppModel.self) private var app
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @State private var stage: Stage = .intro
    @State private var harder = false
    @State private var puzzle: WakePuzzle?
    @State private var solved: AppModel.WeatherSolve?
    @AccessibilityFocusState private var titleFocus: Bool

    enum Stage { case intro, playing, plenty, solved }

    private var tier: WeatherPuzzleTier { WeatherPuzzlePolicy.tier(wild: app.weatherNow.wild, pickedHarder: harder) }

    var body: some View {
        let kind = app.weatherNow.event ?? .bigWind
        ZStack {
            Color.appBackground.ignoresSafeArea()
            switch stage {
            case .intro: intro(kind).transition(.opacity)
            case .playing:
                if let puzzle {
                    WeatherPuzzleBoardView(puzzle: puzzle, tier: tier, names: app.weatherPuzzleNames(tier: tier),
                                           newPuzzle: newPuzzle, skip: close, solved: finish)
                    .id(puzzle)
                    .transition(.opacity)
                }
            case .plenty: plenty.transition(.opacity)
            case .solved: solvedView.transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: stage)
        .onAppear { app.markQuietVisit(); app.pauseBadgeMoments(.sheet, true) }
        .onDisappear { app.pauseBadgeMoments(.sheet, false) }
    }

    // MARK: Intro

    private func intro(_ kind: WeatherKind) -> some View {
        let reward = app.weatherPuzzleReward
        return ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Label(WeatherCopy.name(kind), systemImage: "wind")
                    .font(Theme.font(.subheadline, weight: .bold)).foregroundStyle(Color.appPrimaryText)
                    .padding(.horizontal, 14).padding(.vertical, 8).background(Color.tileLevelsFill, in: Capsule())
                WeatherSkyArt(kind: kind)
                Text(WeatherPuzzleCopy.title).font(Theme.font(.largeTitle, weight: .heavy)).foregroundStyle(Color.appPrimaryText)
                    .frame(maxWidth: .infinity).multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader).accessibilityFocused($titleFocus)
                    .accessibilityIdentifier("weatherPuzzle.title")
                Text(WeatherPuzzleCopy.intro(kind)).font(Theme.font(.body)).foregroundStyle(Color.secondaryText)
                    .frame(maxWidth: .infinity).multilineTextAlignment(.center)
                HStack(spacing: 14) {
                    if let s = reward.sticker { WeatherStickerImage(sticker: s) }
                    Text(WeatherPuzzleCopy.rewardLine(reward)).font(Theme.font(.headline, weight: .bold)).foregroundStyle(Color.appPrimaryText)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("weatherPuzzle.reward")
                    Spacer(minLength: 0)
                }
                .padding(14)
                .background(Color.appAccent.opacity(0.14), in: RoundedRectangle(cornerRadius: Theme.cardRadius))
                .overlay(RoundedRectangle(cornerRadius: Theme.cardRadius).stroke(Color.appAccent.opacity(0.6)))
                if app.weatherPuzzleOffersHarder {
                    ViewThatFits {
                        HStack(spacing: 10) { tierChip(false); tierChip(true) }
                        VStack(spacing: 10) { tierChip(false); tierChip(true) }
                    }
                }
                Button(WeatherPuzzleCopy.start) { start() }.buttonStyle(PrimaryButtonStyle())
                    .accessibilityIdentifier("weatherPuzzle.start")
                Button(action: close) {
                    VStack(spacing: 2) {
                        Text(WeatherPuzzleCopy.skip).font(Theme.font(.title3, weight: .bold))
                        Text(WeatherPuzzleCopy.skipSub).font(Theme.font(.subheadline)).foregroundStyle(Color.secondaryText)
                    }
                    .frame(maxWidth: .infinity, minHeight: 56)
                }
                .buttonStyle(SecondaryButtonStyle())
                .accessibilityIdentifier("weatherPuzzle.skip")
            }
            .padding(.horizontal, 20).padding(.vertical, 16)
        }
        .onAppear { DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { titleFocus = true } }
    }

    private func tierChip(_ isHarder: Bool) -> some View {
        let on = harder == isHarder
        return Button { harder = isHarder } label: {
            VStack(spacing: 2) {
                Text(isHarder ? WeatherPuzzleCopy.harder : WeatherPuzzleCopy.gentle).font(Theme.font(.headline, weight: .bold))
                Text(isHarder ? WeatherPuzzleCopy.harderSub : WeatherPuzzleCopy.gentleSub).font(Theme.font(.footnote, weight: .semibold))
            }
            .foregroundStyle(Color.appPrimaryText)
            .frame(maxWidth: .infinity, minHeight: 56).padding(.vertical, 6)
            .background(on ? Color.successText.opacity(0.14) : Color.appSurface, in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(on ? Color.successText : Color.appPrimaryText.opacity(0.15), lineWidth: on ? 3 : 1))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(on ? .isSelected : [])
        .accessibilityIdentifier(isHarder ? "weatherPuzzle.harder" : "weatherPuzzle.gentle")
    }

    private func start() {
        puzzle = app.currentWeatherPuzzle(tier: tier)
        stage = puzzle == nil ? .plenty : .playing
    }

    private func newPuzzle() {
        if let p = app.newWeatherPuzzle(tier: tier) { puzzle = p } else { stage = .plenty }
    }

    private func finish() {
        onSolvedWord?()
        solved = app.solveWeatherPuzzle()
        stage = .solved
        AccessibilityNotification.Announcement(WeatherPuzzleCopy.solvedTitle).post()
    }

    // MARK: The cap and the solve

    private var plenty: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "sun.haze.fill").font(.system(size: 56)).foregroundStyle(Color.appAccent).accessibilityHidden(true)
            Text(WeatherPuzzleCopy.plenty).font(Theme.font(.title3, weight: .bold)).foregroundStyle(Color.appPrimaryText)
                .multilineTextAlignment(.center).accessibilityIdentifier("weatherPuzzle.plenty")
            Spacer()
            Button(WeatherPuzzleCopy.done, action: close).buttonStyle(PrimaryButtonStyle())
        }
        .padding(24)
    }

    private var solvedView: some View {
        ScrollView {
            VStack(spacing: 16) {
                Image(systemName: "rainbow").symbolRenderingMode(.multicolor).font(.system(size: 72)).padding(.top, 30).accessibilityHidden(true)
                Text(WeatherPuzzleCopy.solvedTitle).font(Theme.font(.largeTitle, weight: .heavy)).foregroundStyle(Color.appPrimaryText)
                    .accessibilityAddTraits(.isHeader).accessibilityIdentifier("weatherPuzzle.solved")
                Text(WeatherPuzzleCopy.solvedLine).font(Theme.font(.title3)).foregroundStyle(Color.appPrimaryText).multilineTextAlignment(.center)
                if let s = solved {
                    VStack(alignment: .leading, spacing: 10) {
                        if let st = s.reward.sticker {
                            HStack(spacing: 12) {
                                WeatherStickerImage(sticker: st)
                                Text(WeatherPuzzleCopy.stickerEarned(st)).font(Theme.font(.headline, weight: .bold)).foregroundStyle(Color.appPrimaryText)
                            }
                        }
                        if s.reward.word {
                            line(s.plantArrived.map { WeatherPuzzleCopy.plantArrived(name: $0) } ?? WeatherPuzzleCopy.wordEarned, "leaf.fill")
                        }
                        if let g = s.goldenPlant { line(WeatherPuzzleCopy.goldenEarned(name: g), "sun.max.fill") }
                        if s.reward.badgeStep {
                            let goal = ((try? BadgeCatalog.load()) ?? []).first { $0.id == "weathered" }?.thresholds.first { $0 > s.weathered }
                            line(goal.map { WeatherPuzzleCopy.weatheredStep(s.weathered, of: $0) } ?? WeatherPuzzleCopy.weatheredDone, "rosette")
                        }
                    }
                    .padding(16).frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.appSurface, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
                }
                Button(WeatherPuzzleCopy.done, action: close).buttonStyle(PrimaryButtonStyle()).accessibilityIdentifier("weatherPuzzle.done")
            }
            .padding(.horizontal, 20).padding(.bottom, 24)
        }
    }

    private func line(_ text: String, _ symbol: String) -> some View {
        Label(text, systemImage: symbol).font(Theme.font(.headline, weight: .semibold)).foregroundStyle(Color.appPrimaryText)
    }
}

/// A soft sky for the intro: the weather's symbols over a hill. Decoration only.
private struct WeatherSkyArt: View {
    let kind: WeatherKind
    var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(colors: [Color.tileLevelsFill, Color.tileGardenFill], startPoint: .top, endPoint: .bottom)
            Ellipse().fill(Color.successText.opacity(0.25)).frame(height: 60).offset(y: 30)
            HStack(spacing: 30) {
                ForEach(0..<3, id: \.self) { i in
                    Image(systemName: symbol).font(.system(size: 34, weight: .semibold)).foregroundStyle(Color.appPrimaryText.opacity(0.45))
                        .offset(y: i == 1 ? -70 : -40)
                }
            }
            .padding(.bottom, 30)
        }
        .frame(height: 170)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .accessibilityHidden(true)
    }
    private var symbol: String {
        switch kind {
        case .drySpell, .hotDay: return "sun.max"
        case .busyBugs: return "ladybug"
        case .bigWind: return "wind"
        case .frostyNight: return "snowflake"
        case .hailShower: return "cloud.hail"
        case .bigPuddles: return "cloud.rain"
        }
    }
}

/// The board: slots in word groups (a two-word answer shows its gap), letter tiles, Clear, Take back and the peek.
struct WeatherPuzzleBoardView: View {
    let puzzle: WakePuzzle
    let tier: WeatherPuzzleTier
    let names: [String]
    let newPuzzle: () -> Void
    let skip: () -> Void
    let solved: () -> Void

    @Environment(AppModel.self) private var app
    @State private var board: WakePuzzleBoard
    @State private var started = Date()
    @State private var now = Date()
    @State private var notQuite = false
    @State private var done = false
    @State private var order: [Int] = []
    private let clock = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    init(puzzle: WakePuzzle, tier: WeatherPuzzleTier, names: [String], newPuzzle: @escaping () -> Void, skip: @escaping () -> Void,
         solved: @escaping () -> Void) {
        self.puzzle = puzzle; self.tier = tier; self.names = names; self.newPuzzle = newPuzzle; self.skip = skip; self.solved = solved
        _board = State(initialValue: WakePuzzleBoard(puzzle: puzzle, firstPeekFree: tier == .storm))
    }

    private var elapsed: Double { now.timeIntervalSince(started) }

    /// Slot index ranges, one per word.
    private var words: [Range<Int>] {
        var out: [Range<Int>] = []
        var start = 0
        for g in puzzle.gaps.sorted() where g + 1 > start && g + 1 < puzzle.slots.count { out.append(start..<(g + 1)); start = g + 1 }
        out.append(start..<puzzle.slots.count)
        return out
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                HStack {
                    Button(WeatherPuzzleCopy.skip, action: skip).font(Theme.font(.callout, weight: .semibold)).foregroundStyle(Color.accentText).tapTarget()
                        .accessibilityIdentifier("weatherPuzzle.board.skip")
                    Spacer()
                    Button(WeatherPuzzleCopy.newPuzzle, action: newPuzzle).font(Theme.font(.callout, weight: .semibold)).foregroundStyle(Color.accentText).tapTarget()
                        .accessibilityIdentifier("weatherPuzzle.new")
                }
                VStack(spacing: 4) {
                    Text(puzzle.intro).font(Theme.font(.headline, weight: .bold)).foregroundStyle(Color.appPrimaryText)
                        .multilineTextAlignment(.center).accessibilityAddTraits(.isHeader)
                    Text(puzzle.hint).font(Theme.font(.callout)).foregroundStyle(Color.secondaryText).multilineTextAlignment(.center)
                }
                ForEach(Array(words.enumerated()), id: \.offset) { _, r in grid(Array(r)) { slot($0) } }
                if notQuite {
                    Text(WeatherPuzzleCopy.notQuite).font(Theme.font(.callout, weight: .semibold)).foregroundStyle(Color.appPrimaryText)
                        .transition(.opacity)
                }
                grid(Array(puzzle.tiles.indices)) { tile($0) }
                ViewThatFits {
                    HStack(spacing: 10) { buttons }
                    VStack(spacing: 10) { buttons }
                }
            }
            .padding(.horizontal, 20).padding(.vertical, 16)
        }
        .scrollBounceBehavior(.basedOnSize)
        .onReceive(clock) { now = $0 }
        .sensoryFeedback(.selection, trigger: board.letters.compactMap { $0 }.count) { _, _ in app.settings.hapticsOn }
    }

    @ViewBuilder private var buttons: some View {
        Button(WeatherPuzzleCopy.clear) { board.clear(); order = []; notQuite = false }.buttonStyle(SecondaryButtonStyle())
        Button(WeatherPuzzleCopy.takeBack) { takeBack() }.buttonStyle(SecondaryButtonStyle())
            .accessibilityIdentifier("weatherPuzzle.takeBack")
        Button { if board.peek(at: elapsed) { check() } } label: {
            Label(board.canPeek(at: elapsed) ? WeatherPuzzleCopy.peek : WeatherPuzzleCopy.peekSoon, systemImage: "eye")
        }
        .buttonStyle(SecondaryButtonStyle())
        .disabled(!board.canPeek(at: elapsed))
        .accessibilityIdentifier("weatherPuzzle.peek")
    }

    /// Keeps every target at least 44 pt: up to 7 a row, more rows for long words.
    private func grid<Cell: View>(_ items: [Int], @ViewBuilder cell: @escaping (Int) -> Cell) -> some View {
        let perRow = min(7, max(1, items.count <= 7 ? items.count : Int((Double(items.count) / 2).rounded(.up))))
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(minimum: Theme.minTap), spacing: 6), count: perRow), spacing: 6) {
            ForEach(items, id: \.self) { cell($0) }
        }
    }

    private func slot(_ i: Int) -> some View {
        let letter = board.letters[i]
        let locked = board.isLocked(i)
        let peeked = locked && puzzle.slots[i] == nil
        return Button { board.tapSlot(i); notQuite = false } label: {
            Text(letter.map(String.init) ?? " ").font(Theme.font(.title2, weight: .bold)).foregroundStyle(Color.appPrimaryText)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(RoundedRectangle(cornerRadius: 10).fill(locked ? Color.appPrimaryText.opacity(0.08) : Color.appSurface))
                .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.appPrimaryText.opacity(letter == nil ? 0.3 : 0.12),
                                                                        style: StrokeStyle(lineWidth: 1.5, dash: letter == nil ? [4, 3] : [])))
                .overlay(alignment: .topTrailing) {
                    if peeked { Image(systemName: "eye.fill").font(.caption2).foregroundStyle(Color.secondaryText).padding(3).accessibilityHidden(true) }
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(WeatherPuzzleCopy.slotLabel(i, letter: letter, peeked: peeked))
    }

    private func tile(_ i: Int) -> some View {
        let used = board.isUsed(i)
        return Button { board.tapTile(i); if board.placed.contains(i) { order.append(i) }; check() } label: {
            Text(String(puzzle.tiles[i])).font(Theme.font(.title2, weight: .bold)).foregroundStyle(Color.ink)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(Color.appAccent.opacity(used ? 0.25 : 1), in: RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .disabled(used)
        .accessibilityLabel("Letter \(String(puzzle.tiles[i]))")
        .accessibilityIdentifier("weatherPuzzle.tile.\(i)")
    }

    /// Takes back the most recent letter still on the board (a 44 pt button, so small slots need no precise tap).
    private func takeBack() {
        while let last = order.popLast() {
            if let slot = board.placed.firstIndex(of: last) { board.tapSlot(slot); notQuite = false; return }
        }
    }

    private func check() {
        guard !done, board.guess != nil else { return }
        if board.isSolved(validNames: names) {
            done = true
            solved()
        } else {
            withAnimation { notQuite = true }
            AccessibilityNotification.Announcement(WeatherPuzzleCopy.notQuite).post()
        }
    }
}
