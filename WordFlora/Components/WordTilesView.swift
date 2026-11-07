import SwiftUI

/// How big the answer's letter tiles are (docs/pm/puzzle-experience-review.md V1, V2, V8). Tiles are 40 x 52 when the
/// word fits and shrink to the room there is, never below 22 pt; the gap narrows as they shrink. Only a word that still
/// does not fit at 22 pt wraps, in even pieces. Every word of a phrase uses the same size (set by the longest word).
enum TileLayout {
    static let maxSide: CGFloat = 40
    static let minSide: CGFloat = 22
    static let heightRatio: CGFloat = 1.3
    /// The room for one row when the view has not been measured yet (a 375 pt phone on the 16 pt gutter).
    static let fallbackWidth: CGFloat = 343

    struct Metrics: Equatable {
        var side: CGFloat
        var height: CGFloat
        var gap: CGFloat
        /// A word with more letters than this wraps onto the next row.
        var lettersPerRow: Int
        var fontSize: CGFloat
        var cornerRadius: CGFloat { min(10, (side / 4).rounded()) }
        func rowWidth(letters: Int) -> CGFloat { CGFloat(letters) * side + CGFloat(max(0, letters - 1)) * gap }
    }

    /// 6 pt between tiles, 4 below 26 pt tiles and 2 below 24 pt.
    static func gap(for side: CGFloat) -> CGFloat { side >= 26 ? 6 : side >= 24 ? 4 : 2 }

    /// `longest`: letters in the longest word. `width`: the room for one row. `preferred`: the tile size the text size
    /// asks for (40 at the default size, from a scaled metric); it is kept between 22 and 40.
    static func metrics(longest: Int, width: CGFloat, preferred: CGFloat = maxSide) -> Metrics {
        let cap = min(maxSide, max(minSide, preferred.isFinite ? preferred.rounded(.down) : maxSide))
        let room = width.isFinite && width > 0 ? width : fallbackWidth
        let n = max(1, longest)
        func largestSide(fitting count: Int) -> CGFloat? {
            var side = cap
            while side >= minSide {
                if CGFloat(count) * side + CGFloat(count - 1) * gap(for: side) <= room { return side }
                side -= 1
            }
            return nil
        }
        for rows in 1...n {
            let perRow = Int((Double(n) / Double(rows)).rounded(.up))
            if let side = largestSide(fitting: perRow) { return make(side: side, perRow: perRow) }
        }
        let perRow = max(1, Int((room + gap(for: minSide)) / (minSide + gap(for: minSide))))
        return make(side: minSide, perRow: perRow)
    }

    private static func make(side: CGFloat, perRow: Int) -> Metrics {
        Metrics(side: side, height: (side * heightRatio).rounded(), gap: gap(for: side), lettersPerRow: perRow,
                fontSize: (side * 0.7).rounded())
    }

    /// The word split into rows: whole words, and a word longer than a row in even pieces.
    static func pieces(of word: String, lettersPerRow: Int) -> [String] {
        let per = max(1, lettersPerRow)
        return word.split(separator: " ").flatMap { part -> [String] in
            let letters = Array(part)
            guard letters.count > per else { return [String(part)] }
            let rows = Int((Double(letters.count) / Double(per)).rounded(.up))
            let even = Int((Double(letters.count) / Double(rows)).rounded(.up))
            return stride(from: 0, to: letters.count, by: even).map { String(letters[$0..<min($0 + even, letters.count)]) }
        }
    }
}

/// Wraps tiles by word so long answers like "VENUS FLYTRAP" break at the space; one long word shrinks its tiles to fit.
struct WordTilesView: View {
    let word: String
    let guessed: Set<Character>
    var revealAll = false
    /// The letter just found: its tiles pop 1.1x with a marigold wash and a small puff of petals.
    var pop: TilePop? = nil

    /// The tile size grows and shrinks with the text size, kept between 22 and 40 by `TileLayout`.
    @ScaledMetric(relativeTo: .title) private var preferredSide: CGFloat = TileLayout.maxSide
    @State private var width: CGFloat = 0

    private var metrics: TileLayout.Metrics {
        TileLayout.metrics(longest: word.split(separator: " ").map(\.count).max() ?? 0, width: width, preferred: preferredSide)
    }

    var body: some View {
        let m = metrics
        FlowLayout(spacing: 14, lineSpacing: 10) {
            ForEach(Array(TileLayout.pieces(of: word, lettersPerRow: m.lettersPerRow).enumerated()), id: \.offset) { _, part in
                HStack(spacing: m.gap) {
                    ForEach(Array(part.enumerated()), id: \.offset) { _, ch in tile(ch, m) }
                }
            }
        }
        // minWidth 0: the measured width is the room offered, never the tiles' own width.
        .frame(minWidth: 0, maxWidth: .infinity)
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spokenState)
    }

    private func tile(_ ch: Character, _ m: TileLayout.Metrics) -> some View {
        let shown = revealAll || guessed.contains(ch)
        let hot = pop.flatMap { $0.letter == ch ? $0 : nil }
        let fresh = hot.map { Date.now.timeIntervalSince($0.at) < 0.9 } ?? false
        let shape = RoundedRectangle(cornerRadius: m.cornerRadius)
        return TilePopFrame(pop: hot) { wash, scale in
            ZStack {
                shape.fill(shown ? Color.appAccent.opacity(0.22) : Color.appSurface)
                shape.fill(Color(hex: PetalKit.marigold).opacity(wash))
                // A blank's outline is at least 3:1 on the cream and on the tile, so the word's length is easy to count.
                shape.stroke(shown ? Color.appAccent : Color.appPrimaryText.opacity(PuzzleInk.blankOutline), lineWidth: 2)
                Text(shown ? String(ch) : "")
                    .font(.system(size: m.fontSize, weight: .heavy, design: .rounded))
                    .lineLimit(1).minimumScaleFactor(0.5)
                    .foregroundStyle(Color.appPrimaryText)
                    .transition(.scale.combined(with: .opacity))
            }
            .frame(width: m.side, height: m.height)
            .scaleEffect(scale)
        }
        .overlay {
            if let hot, fresh {
                PetalPuff(trigger: hot.id, level: hot.level, arcRadius: 34).frame(width: 220, height: 220)
            }
        }
        .zIndex(fresh ? 1 : 0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: shown)
    }

    private var spokenState: String {
        word.split(separator: " ").map { part in
            part.map { guessed.contains($0) || revealAll ? String($0) : "blank" }.joined(separator: " ")
        }.joined(separator: ", then ")
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    var lineSpacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrange(width: proposal.width ?? .infinity, subviews: subviews).size
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(width: bounds.width, subviews: subviews)
        for (i, origin) in result.origins.enumerated() {
            subviews[i].place(at: CGPoint(x: bounds.minX + origin.x, y: bounds.minY + origin.y), proposal: .unspecified)
        }
    }
    private func arrange(width: CGFloat, subviews: Subviews) -> (size: CGSize, origins: [CGPoint]) {
        var origins = [CGPoint](), x: CGFloat = 0, y: CGFloat = 0, lineHeight: CGFloat = 0, maxX: CGFloat = 0
        var rows: [[Int]] = [[]], rowWidths: [CGFloat] = [0]
        for (i, sub) in subviews.enumerated() {
            let size = sub.sizeThatFits(.unspecified)
            if x > 0, x + size.width > width { x = 0; y += lineHeight + lineSpacing; lineHeight = 0; rows.append([]); rowWidths.append(0) }
            origins.append(CGPoint(x: x, y: y)); rows[rows.count - 1].append(i)
            x += size.width; rowWidths[rows.count - 1] = x; x += spacing
            lineHeight = max(lineHeight, size.height); maxX = max(maxX, rowWidths[rows.count - 1])
        }
        // centre each row
        let total = width.isFinite ? width : maxX
        for (r, idxs) in rows.enumerated() {
            let offset = max(0, (total - rowWidths[r]) / 2)
            for i in idxs { origins[i].x += offset }
        }
        return (CGSize(width: total, height: y + lineHeight), origins)
    }
}
