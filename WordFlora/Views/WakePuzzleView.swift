import SwiftUI

/// Tap letters to make a plant name. No timer is shown and tries are free; a free peek opens every 30 s.
struct WakePuzzleView: View {
    let puzzle: WakePuzzle
    let validNames: [String]
    let onSolved: () -> Void
    let onTryButterflies: () -> Void

    @Environment(AppModel.self) private var app
    @State private var board: WakePuzzleBoard
    @State private var started = Date()
    @State private var now = Date()
    @State private var notQuite = false
    @State private var solved = false
    private let clock = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    init(puzzle: WakePuzzle, validNames: [String], onSolved: @escaping () -> Void, onTryButterflies: @escaping () -> Void) {
        self.puzzle = puzzle; self.validNames = validNames; self.onSolved = onSolved; self.onTryButterflies = onTryButterflies
        _board = State(initialValue: WakePuzzleBoard(puzzle: puzzle))
    }

    private var elapsed: Double { now.timeIntervalSince(started) }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                VStack(spacing: 4) {
                    Text(puzzle.intro).font(Theme.font(.headline, weight: .bold)).foregroundStyle(Color.appPrimaryText)
                        .multilineTextAlignment(.center).accessibilityAddTraits(.isHeader)
                    Text(puzzle.hint).font(Theme.font(.callout)).foregroundStyle(Color.secondaryText)
                }
                .padding(.horizontal, 36)

                grid(count: puzzle.slots.count) { i in slot(i) }
                if notQuite {
                    Text(WakeCopy.notQuite).font(Theme.font(.callout, weight: .semibold)).foregroundStyle(Color.appPrimaryText)
                        .transition(.opacity)
                }
                grid(count: puzzle.tiles.count) { i in tile(i) }

                HStack(spacing: 10) {
                    Button(WakeCopy.clear) { board.clear(); notQuite = false }.buttonStyle(SecondaryButtonStyle())
                    Button { if board.peek(at: elapsed) { check() } } label: {
                        Label(board.canPeek(at: elapsed) ? WakeCopy.peek : WakeCopy.peekSoon, systemImage: "eye")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .disabled(!board.canPeek(at: elapsed))
                }
                Button(WakeCopy.tryButterflies, action: onTryButterflies)
                    .font(Theme.font(.callout, weight: .semibold)).foregroundStyle(Color.accentText).tapTarget()
            }
            .padding(.horizontal, 20).padding(.top, 28).padding(.bottom, 20)
        }
        .scrollBounceBehavior(.basedOnSize)
        .onReceive(clock) { now = $0 }
        .sensoryFeedback(.selection, trigger: board.letters.compactMap { $0 }.count) { _, _ in app.settings.hapticsOn }
    }

    /// Wraps into two rows for long words so every target stays at least 44 pt.
    private func grid<Cell: View>(count: Int, @ViewBuilder cell: @escaping (Int) -> Cell) -> some View {
        let perRow = count <= 6 ? max(1, count) : Int((Double(count) / 2).rounded(.up))
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(minimum: Theme.minTap), spacing: 8), count: perRow), spacing: 8) {
            ForEach(0..<count, id: \.self) { cell($0) }
        }
    }

    private func slot(_ i: Int) -> some View {
        let letter = board.letters[i]
        let locked = board.isLocked(i)
        return Button { board.tapSlot(i); notQuite = false } label: {
            Text(letter.map(String.init) ?? " ").font(Theme.font(.title2, weight: .bold)).foregroundStyle(Color.appPrimaryText)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(RoundedRectangle(cornerRadius: 10).fill(locked ? Color.appPrimaryText.opacity(0.08) : Color.appSurface))
                .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.appPrimaryText.opacity(letter == nil ? 0.3 : 0.12),
                                                                        style: StrokeStyle(lineWidth: 1.5, dash: letter == nil ? [4, 3] : [])))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Spot \(i + 1), \(letter.map(String.init) ?? "empty")")
        .accessibilityHint(letter != nil && !locked ? "Tap to take the letter back" : "")
    }

    private func tile(_ i: Int) -> some View {
        let used = board.isUsed(i)
        return Button { place(i) } label: {
            Text(String(puzzle.tiles[i])).font(Theme.font(.title2, weight: .bold)).foregroundStyle(Color.ink)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(Color.appAccent.opacity(used ? 0.25 : 1), in: RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .disabled(used)
        .accessibilityLabel("Letter \(String(puzzle.tiles[i]))")
    }

    private func place(_ i: Int) {
        board.tapTile(i)
        check()
    }

    private func check() {
        guard !solved, board.guess != nil else { return }
        if board.isSolved(validNames: validNames) {
            solved = true
            onSolved()
        } else {
            withAnimation { notQuite = true }
            AccessibilityNotification.Announcement(WakeCopy.notQuite).post()
        }
    }
}
