import SwiftUI

/// Wraps tiles by word so long answers like "VENUS FLYTRAP" break at the space.
struct WordTilesView: View {
    let word: String
    let guessed: Set<Character>
    var revealAll = false
    /// The letter just found: its tiles pop 1.1x with a marigold wash and a small puff of petals.
    var pop: TilePop? = nil

    var body: some View {
        FlowLayout(spacing: 14, lineSpacing: 10) {
            ForEach(Array(word.split(separator: " ").enumerated()), id: \.offset) { _, part in
                HStack(spacing: 6) {
                    ForEach(Array(part.enumerated()), id: \.offset) { _, ch in tile(ch) }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spokenState)
    }

    private func tile(_ ch: Character) -> some View {
        let shown = revealAll || guessed.contains(ch)
        let hot = pop.flatMap { $0.letter == ch ? $0 : nil }
        let fresh = hot.map { Date.now.timeIntervalSince($0.at) < 0.9 } ?? false
        return TilePopFrame(pop: hot) { wash, scale in
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(shown ? Color.appAccent.opacity(0.22) : Color.appSurface)
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(hex: PetalKit.marigold).opacity(wash))
                RoundedRectangle(cornerRadius: 10)
                    .stroke(shown ? Color.appAccent : Color.appPrimaryText.opacity(0.18), lineWidth: 2)
                Text(shown ? String(ch) : "")
                    .font(Theme.font(.title2, weight: .heavy))
                    .foregroundStyle(Color.appPrimaryText)
                    .transition(.scale.combined(with: .opacity))
            }
            .frame(width: 30, height: 42)
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
