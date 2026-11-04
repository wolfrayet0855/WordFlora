import SwiftUI

/// The Life panel's rows: three meters (icon, word label, soft bar, never a number), the stage path,
/// today's hearts and the love petal key. `large` is the accessibility-size sheet layout.
struct LifePanelContent: View {
    let snapshot: LifeStats.Snapshot
    var large = false

    var body: some View {
        VStack(alignment: .leading, spacing: large ? 12 : 7) {
            meter(snapshot.water, icon: "drop.fill", tint: LifePalette.water)
            meter(snapshot.sunshine, icon: "sun.max.fill", tint: LifePalette.sun)
            meter(snapshot.happiness, icon: "face.smiling.inverse", tint: LifePalette.leaf)
            Divider().overlay(LifePalette.line)
            growth
            Divider().overlay(LifePalette.line)
            love
        }
    }

    private var nameFont: Font { Theme.font(large ? .title3 : .caption, weight: .heavy) }
    private var smallFont: Font { Theme.font(large ? .body : .caption, weight: .bold) }
    private var iconSize: CGFloat { large ? 30 : 17 }

    private func meter(_ m: LifeStats.Meter, icon: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: large ? 10 : 5) {
                Image(systemName: icon).font(.system(size: iconSize * 0.85, weight: .semibold)).foregroundStyle(tint)
                    .frame(width: iconSize, height: iconSize)
                Text(m.name).font(nameFont).foregroundStyle(Color.appPrimaryText)
                    .lineLimit(1).minimumScaleFactor(0.8)
            }
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    Capsule().fill(LifePalette.track)
                    Capsule().fill(tint).frame(width: max(g.size.height, g.size.width * m.fill))
                }
            }
            .frame(height: large ? 14 : 9)
            .animation(.easeInOut(duration: 0.6), value: m.fill)
            Text(m.word).font(smallFont).foregroundStyle(Color.appPrimaryText).fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(m.accessibilityLabel)
    }

    private var growth: some View {
        let dot: CGFloat = large ? 30 : 17
        return VStack(alignment: .leading, spacing: 4) {
            Text(LifeStats.growingTitle).font(nameFont).foregroundStyle(Color.appPrimaryText)
            ZStack {
                Rectangle().fill(LifePalette.line).frame(height: 3).padding(.horizontal, dot / 2)
                HStack(spacing: 0) {
                    ForEach(0..<5, id: \.self) { i in
                        if i > 0 { Spacer(minLength: 0) }
                        ZStack {
                            if i < snapshot.stage {
                                Circle().fill(LifePalette.leafBright)
                                Image(systemName: "checkmark").font(.system(size: dot * 0.5, weight: .heavy)).foregroundStyle(LifePalette.leafInk)
                            } else if i == snapshot.stage {
                                Circle().fill(Color.appSurface)
                                Circle().stroke(LifePalette.leafBright, lineWidth: large ? 4 : 3)
                                Circle().fill(LifePalette.leaf).padding(dot * 0.3)
                            } else {
                                Circle().fill(Color.appSurface)
                                Circle().stroke(LifePalette.line, lineWidth: 2)
                            }
                        }
                        .frame(width: dot, height: dot)
                    }
                }
            }
            Text(LifeStats.stageWord(snapshot.stage, seed: snapshot.isSeed)).font(smallFont).foregroundStyle(Color.appPrimaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(snapshot.stageLabel + (snapshot.isSeed ? ", kept safe" : ""))
    }

    private var love: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(LifeStats.loveTitle).font(nameFont).foregroundStyle(Color.appPrimaryText)
                .accessibilityHidden(true)
            HStack(spacing: large ? 4 : 0) {
                ForEach(0..<5, id: \.self) { i in
                    Image(systemName: i < snapshot.hearts ? "heart.fill" : "heart")
                        .font(.system(size: large ? 26 : 14, weight: .semibold)).foregroundStyle(LifePalette.heart)
                        .frame(width: large ? 32 : 18, height: large ? 32 : 18)
                }
            }
            .accessibilityHidden(true)
            // The hearts and pips are pictures of the words next to them, so VoiceOver reads them on the text.
            Text(snapshot.loveLine).font(smallFont).foregroundStyle(Color.appPrimaryText)
                .fixedSize(horizontal: false, vertical: true).frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityLabel(snapshot.heartsLabel)
            PetalPips(count: snapshot.pips, pipWidth: large ? 19 : 10).padding(.top, 3)
            Text(LifeStats.keyLine).font(smallFont).foregroundStyle(Color.appPrimaryText).fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityLabel(LifeStats.keyLabel(pips: snapshot.pips))
        }
    }
}

/// The left-edge Life panel (standard text sizes).
struct LifePanel: View {
    let snapshot: LifeStats.Snapshot
    let onHide: () -> Void
    @ScaledMetric(relativeTo: .caption) private var width: CGFloat = 118

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(LifeStats.title).font(Theme.font(.subheadline, weight: .heavy)).foregroundStyle(Color.appPrimaryText)
                    .accessibilityAddTraits(.isHeader)
                Spacer(minLength: 0)
                Button(action: onHide) {
                    Image(systemName: "chevron.left").font(.system(size: 16, weight: .bold)).foregroundStyle(Color.appPrimaryText)
                        .frame(width: Theme.minTap, height: Theme.minTap).contentShape(Rectangle())
                }
                .padding(.trailing, -10).padding(.vertical, -6)
                .accessibilityLabel(LifeStats.hideLabel)
                .accessibilityIdentifier("life-hide")
            }
            LifePanelContent(snapshot: snapshot)
        }
        .padding(.leading, 10).padding(.trailing, 10).padding(.top, 8).padding(.bottom, 11)
        .frame(width: min(width, 150))
        .background(LifePalette.glass, in: RoundedRectangle(cornerRadius: 22))
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(LifePalette.line))
        .shadow(color: .black.opacity(0.1), radius: 8, y: 3)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(LifeStats.title)
    }
}

/// The minimised panel: a plain heart button set 12 pt in from the edge (clear of the back swipe).
struct LifeTab: View {
    var petalFalling = false
    let onShow: () -> Void

    var body: some View {
        Button(action: onShow) {
            VStack(spacing: 4) {
                Image(systemName: "heart.fill").font(.system(size: 22, weight: .semibold)).foregroundStyle(LifePalette.heart)
                Text(LifeStats.title).font(Theme.font(.caption, weight: .heavy)).foregroundStyle(Color.appPrimaryText)
            }
            .frame(minWidth: 48, minHeight: 92)
            .background(LifePalette.glass, in: RoundedRectangle(cornerRadius: 24))
            .overlay(RoundedRectangle(cornerRadius: 24).stroke(LifePalette.line))
            .overlay(alignment: .topTrailing) {
                if petalFalling {
                    Circle().fill(LifePalette.petal).overlay(Circle().stroke(LifePalette.petalEdge, lineWidth: 1.5))
                        .frame(width: 11, height: 11).padding(8)
                }
            }
            .shadow(color: .black.opacity(0.1), radius: 8, y: 3)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(LifeStats.showLabel)
        .accessibilityIdentifier("life-show")
    }
}

/// At accessibility text sizes the panel is a sheet under the plant; it collapses to its header.
struct LifeSheet: View {
    let snapshot: LifeStats.Snapshot
    let collapsed: Bool
    let onToggle: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Capsule().fill(LifePalette.line).frame(width: 44, height: 5).frame(maxWidth: .infinity)
            HStack {
                Text(LifeStats.title).font(Theme.font(.title2, weight: .heavy)).foregroundStyle(Color.appPrimaryText)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                Button(action: onToggle) {
                    Image(systemName: "chevron.down").font(.system(size: 22, weight: .bold)).foregroundStyle(Color.appPrimaryText)
                        .rotationEffect(.degrees(collapsed ? 180 : 0))
                        .frame(width: Theme.minTap, height: Theme.minTap).contentShape(Rectangle())
                }
                .accessibilityLabel(collapsed ? LifeStats.showLabel : LifeStats.hideLabel)
                .accessibilityIdentifier(collapsed ? "life-show" : "life-hide")
            }
            if !collapsed { LifePanelContent(snapshot: snapshot, large: true).transition(.opacity) }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(LifeStats.title)
    }
}
