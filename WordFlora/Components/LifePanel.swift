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
                            if snapshot.dipped && i > snapshot.shownStage && i <= snapshot.stage {
                                // Wild Weather: the earned stage the plant is resting back to, as a dashed gold ring.
                                Circle().fill(Color.appSurface)
                                Circle().stroke(LifePalette.sun, style: StrokeStyle(lineWidth: large ? 3 : 2, dash: [large ? 5 : 3, large ? 4 : 2.5]))
                            } else if i < snapshot.shownStage {
                                Circle().fill(LifePalette.leafBright)
                                Image(systemName: "checkmark").font(.system(size: dot * 0.5, weight: .heavy)).foregroundStyle(LifePalette.leafInk)
                            } else if i == snapshot.shownStage {
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
            Text(LifeStats.stageWord(snapshot.shownStage, seed: snapshot.isSeed)).font(smallFont).foregroundStyle(Color.appPrimaryText)
                .fixedSize(horizontal: false, vertical: true)
            if snapshot.dipped {
                Text(LifeStats.mendingNote).font(smallFont).foregroundStyle(Color.appPrimaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(snapshot.stageLabel + (snapshot.isSeed ? ", kept safe" : ""))
    }

    private var love: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(LifeStats.energyTitle).font(nameFont).foregroundStyle(Color.appPrimaryText)
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

// MARK: Tend buttons (design-preview/tending/actions.html, section 1)

/// The plant page's tend buttons.
enum TendKind: String, CaseIterable, Equatable {
    case water, feed, sun, prune, repot

    var title: String {
        switch self {
        case .water: return "Water"
        case .feed: return "Feed"
        case .sun: return "Sun"
        case .prune: return "Prune"
        case .repot: return "Repot"
        }
    }

    var icon: String {
        switch self {
        case .water: return "drop.fill"
        case .feed: return "leaf.fill"
        case .sun: return "sun.max.fill"
        case .prune: return "scissors"
        case .repot: return "shippingbox.fill"
        }
    }

    var tint: Color {
        switch self {
        case .water: return LifePalette.water
        case .feed: return LifePalette.soil
        case .sun: return LifePalette.sun
        case .prune: return LifePalette.leaf
        case .repot: return LifePalette.clay
        }
    }

    /// Ready: what the tap will do.
    var readyCaption: String {
        switch self {
        case .water: return "Give a drink"
        case .feed: return "Add soil"
        case .sun: return "Let it shine"
        case .prune: return "Give a trim"
        case .repot: return "Pick a pot"
        }
    }

    /// Needs a supply: the short reason (the tap says the next step).
    var supplyCaption: String {
        switch self {
        case .water: return "Can is dry"
        case .feed, .repot: return "Need scoops"
        case .prune: return "Need shears"
        case .sun: return "Let it shine"
        }
    }

    static let wakeFirst = "Wake first"
    static let wakeCaption = "Tap the seed"
    static let moreTomorrow = "More tomorrow"
    static let trimLater = "Trim in 2 days"
    static let trimmed = "Trimmed"
}

/// What one tend button shows for its action state: lit when ready, softly checked when done for today,
/// a small plus when a supply is needed, a moon while the plant rests as a seed. Never colour alone.
struct TendButtonLook: Equatable {
    enum Badge: Equatable { case none, check, supply, rest }

    let title: String
    let caption: String
    let badge: Badge
    let lit: Bool
    let accessibilityLabel: String
    let accessibilityValue: String
    /// What a tap will do, or the kind reason and next step when it will not.
    let hint: String

    init(kind: TendKind, state: AppModel.ActionState) {
        accessibilityLabel = kind.title
        switch state.status {
        case .ready:
            title = kind.title; caption = kind.readyCaption; badge = .none; lit = true
            accessibilityValue = kind.readyCaption
            hint = kind.readyCaption
        case .done:
            title = kind == .prune ? TendKind.trimmed : state.label
            caption = kind == .prune ? TendKind.trimLater : TendKind.moreTomorrow
            badge = .check; lit = false
            accessibilityValue = "\(title), \(caption.lowercased())"
            hint = state.line ?? caption
        case .needsSupply:
            title = kind.title; caption = kind.supplyCaption; badge = .supply; lit = false
            accessibilityValue = kind.supplyCaption
            hint = state.line ?? kind.supplyCaption
        case .seed:
            title = state.label; caption = TendKind.wakeCaption; badge = .rest; lit = false
            accessibilityValue = state.label
            hint = state.line ?? TendKind.wakeCaption
        }
    }
}

/// A tend button. `large` is the accessibility-size row (icon beside the words); otherwise the icon sits on top.
/// `nudge` gives a soft press when a tap is refused (no shake).
struct TendActionButton: View {
    let kind: TendKind
    let look: TendButtonLook
    var large = false
    var nudge = 0
    let action: () -> Void

    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var squeeze = false

    /// From accessibility size 3 up, a 2 x 2 tile has no room for the icon beside two lines of words: the icon goes on
    /// top and only the title shows, shrinking to fit one line (the caption is still the VoiceOver value).
    private var compact: Bool { large && typeSize >= .accessibility3 }

    var body: some View {
        Button(action: action) {
            Group {
                if compact {
                    VStack(spacing: 4) {
                        dot(34)
                        Text(look.title).font(Theme.font(.body, weight: .heavy)).foregroundStyle(Color.appPrimaryText)
                            .lineLimit(1).minimumScaleFactor(0.4)
                    }
                    .frame(maxWidth: .infinity, minHeight: 64)
                    .padding(.vertical, 6).padding(.horizontal, 6)
                } else if large {
                    HStack(spacing: 10) { dot(40); words(alignment: .leading) }
                        .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
                        .padding(.horizontal, 10)
                } else {
                    VStack(spacing: 4) { dot(44); words(alignment: .center); Spacer(minLength: 0) }
                        .frame(maxWidth: .infinity, minHeight: 64, maxHeight: .infinity)
                        .padding(.vertical, 8).padding(.horizontal, 2)
                }
            }
            .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(LifePalette.line))
            .scaleEffect(squeeze ? 0.93 : 1)
        }
        .buttonStyle(TendPressStyle(reduceMotion: reduceMotion))
        .accessibilityLabel(look.accessibilityLabel)
        .accessibilityValue(look.accessibilityValue)
        .accessibilityHint(look.hint)
        .accessibilityIdentifier("tend-\(kind.rawValue)")
        .onChange(of: nudge) {
            guard !reduceMotion else { return }
            withAnimation(.spring(response: 0.16, dampingFraction: 0.6)) { squeeze = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) { withAnimation(.spring(response: 0.3, dampingFraction: 0.55)) { squeeze = false } }
        }
    }

    private func dot(_ d: CGFloat) -> some View {
        let restTint = LifePalette.ghost
        return ZStack {
            if look.lit {
                Circle().stroke(kind.tint.opacity(0.45), lineWidth: 3).frame(width: d + 8, height: d + 8)
                Circle().fill(kind.tint)
                Image(systemName: kind.icon).font(.system(size: d * 0.46, weight: .bold))
                    .foregroundStyle(scheme == .dark ? LifePalette.leafInk : Color.white)
            } else {
                Circle().fill((look.badge == .check ? kind.tint : restTint).opacity(look.badge == .check ? 0.2 : 0.16))
                Image(systemName: kind.icon).font(.system(size: d * 0.46, weight: .bold))
                    .foregroundStyle(look.badge == .check ? kind.tint : restTint)
            }
        }
        .frame(width: d, height: d)
        .overlay(alignment: .topTrailing) { badge(look.badge == .check ? kind.tint : restTint).offset(x: 5, y: -5) }
        .frame(width: d + 8, height: d + 8)
        .accessibilityHidden(true)
    }

    /// The badge is drawn, not a glyph, so it never reads as text that should scale.
    @ViewBuilder private func badge(_ tint: Color) -> some View {
        if look.badge != .none {
            BadgeMark(badge: look.badge).stroke(tint, style: StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round))
                .frame(width: 10, height: 10)
                .frame(width: 20, height: 20)
                .background(Color.appSurface, in: Circle())
                .overlay(Circle().stroke(tint, lineWidth: 2))
        }
    }

    private func words(alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 1) {
            Text(look.title).font(Theme.font(large ? .body : .footnote, weight: .heavy)).foregroundStyle(Color.appPrimaryText)
                .fixedSize(horizontal: false, vertical: true)
            Text(look.caption).font(Theme.font(large ? .footnote : .caption2, weight: .bold)).foregroundStyle(Color.appPrimaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .multilineTextAlignment(alignment == .leading ? .leading : .center)
    }
}

/// Check (done), plus (needs a supply) or crescent moon (resting seed), in a 10 point box.
private struct BadgeMark: Shape {
    let badge: TendButtonLook.Badge
    func path(in r: CGRect) -> Path {
        var p = Path()
        switch badge {
        case .none: break
        case .check:
            p.move(to: CGPoint(x: r.minX, y: r.midY + 0.5)); p.addLine(to: CGPoint(x: r.minX + r.width * 0.38, y: r.maxY - 1))
            p.addLine(to: CGPoint(x: r.maxX, y: r.minY + 1))
        case .supply:
            p.move(to: CGPoint(x: r.midX, y: r.minY)); p.addLine(to: CGPoint(x: r.midX, y: r.maxY))
            p.move(to: CGPoint(x: r.minX, y: r.midY)); p.addLine(to: CGPoint(x: r.maxX, y: r.midY))
        case .rest:
            p.addArc(center: CGPoint(x: r.midX, y: r.midY), radius: r.width / 2, startAngle: .degrees(-60), endAngle: .degrees(200), clockwise: false)
            p.addQuadCurve(to: CGPoint(x: r.midX + r.width * 0.25, y: r.minY + r.height * 0.07), control: CGPoint(x: r.midX + r.width * 0.05, y: r.midY + r.height * 0.1))
        }
        return p
    }
}

private struct TendPressStyle: ButtonStyle {
    let reduceMotion: Bool
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.95 : 1)
            .opacity(configuration.isPressed && reduceMotion ? 0.8 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
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
