import SwiftUI

// The Garden Shed v2 pieces (design-preview/shed-visitors/shed-v2/notes.md, direction B):
// the shed header with the points bar, the tool tiles, the tool sheet and the "got better" card.

/// Per-tool colours from the existing tile colorsets. `fill` is the tile background; `icon` the pips, bar and border.
struct ToolTint {
    let fill: Color
    let icon: Color

    static func of(_ tool: ToolID) -> ToolTint {
        switch tool {
        case .can: return ToolTint(fill: .tileLevelsFill, icon: .tileLevelsIcon)
        case .trowel: return ToolTint(fill: .tileShedFill, icon: .tileShedIcon)
        case .net: return ToolTint(fill: .tileVisitorsFill, icon: .tileVisitorsIcon)
        case .mister: return ToolTint(fill: .tileGardenFill, icon: .successText)
        case .shears: return ToolTint(fill: .bloomFill, icon: .bloomIcon)
        case .lamp: return ToolTint(fill: .tileBadgesFill, icon: .accentText)
        }
    }
}

/// Shed tools in screen order.
enum ShedTool {
    static let order: [ToolID] = [.can, .trowel, .net, .mister, .shears, .lamp]
}

struct ShedToolPick: Identifiable, Equatable {
    let tool: ToolID
    var id: String { tool.rawValue }
}

struct TierPips: View {
    let tier: Int
    let tint: Color
    @ScaledMetric(relativeTo: .body) private var size: CGFloat = 11

    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...3, id: \.self) { i in
                if i <= tier { Circle().fill(tint).frame(width: size, height: size) }
                else { Circle().strokeBorder(tint, lineWidth: 2).frame(width: size, height: size) }
            }
        }
        .accessibilityHidden(true)
    }
}

/// One card: the shed scene on top and the points bar below (or the Quiet Garden line, with no numbers).
struct ShedHeader: View {
    let points: Int
    let quiet: Bool
    let play: () -> Void
    @Environment(\.dynamicTypeSize) private var typeSize
    @ScaledMetric(relativeTo: .callout) private var stickerSize: CGFloat = 22

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 22, style: .continuous)
        VStack(spacing: 0) {
            Image(quiet ? "ShedSceneQuiet" : "ShedScene").resizable().scaledToFit()
                .frame(maxWidth: .infinity)
                .accessibilityLabel(ShedCopy.sceneLabel)
            bar
                .overlay(alignment: .top) { Rectangle().fill(Color.accentText.opacity(0.25)).frame(height: 1) }
        }
        .background(quiet ? Color.tileGardenFill : Color.tileBadgesFill)
        .clipShape(shape)
        .overlay(shape.stroke(Color.tileShedIcon.opacity(0.3), lineWidth: 1.5))
        .shadow(color: .black.opacity(0.06), radius: 2, y: 1)
    }

    @ViewBuilder private var bar: some View {
        if quiet {
            VStack(alignment: .leading, spacing: 2) {
                Text(ShedCopy.quietTitle).font(Theme.font(.headline, weight: .heavy)).foregroundStyle(Color.appPrimaryText)
                Text(ShedCopy.quietReady).font(Theme.font(.subheadline)).foregroundStyle(Color.secondaryText)
            }
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16).padding(.vertical, 12)
            .accessibilityElement(children: .combine)
        } else {
            let layout = typeSize.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: 10)) : AnyLayout(HStackLayout(spacing: 10))
            layout {
                VStack(alignment: .leading, spacing: 2) {
                    Text(ShedCopy.points(points)).font(Theme.font(.headline, weight: .heavy)).foregroundStyle(Color.appPrimaryText)
                    Text(ShedCopy.pointsHow).font(Theme.font(.subheadline)).foregroundStyle(Color.secondaryText)
                }
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(ShedCopy.points(points) + ". " + ShedCopy.pointsHow)
                .accessibilityIdentifier("shed.points")
                Button(action: play) {
                    HStack(spacing: 8) {
                        Image("visitor_monarch_sticker").resizable().scaledToFit().frame(width: stickerSize, height: stickerSize)
                            .accessibilityHidden(true)
                        Text(ShedCopy.play).font(Theme.font(.callout, weight: .heavy)).foregroundStyle(Color.appPrimaryText)
                    }
                    .padding(.horizontal, 16)
                    .frame(maxWidth: typeSize.isAccessibilitySize ? .infinity : nil, minHeight: 44)
                    .background(Color.tileVisitorsFill, in: Capsule())
                    .overlay(Capsule().stroke(Color.tileVisitorsIcon.opacity(0.55), lineWidth: 1.5))
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(ShedCopy.playLabel)
                .accessibilityIdentifier("shed.playButton")
            }
            .padding(.leading, 16).padding(.trailing, 12).padding(.vertical, 11)
        }
    }
}

/// A tool in the grid. A tap opens the tool sheet.
struct ToolTile: View {
    let tool: ToolID
    let tier: Int
    let points: Int
    let quiet: Bool
    let open: () -> Void
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.colorScheme) private var scheme
    @ScaledMetric(relativeTo: .body) private var artW: CGFloat = 58
    @ScaledMetric(relativeTo: .body) private var circle: CGFloat = 66

    private var tint: ToolTint { .of(tool) }
    private var owned: Bool { tier > 0 }
    private var ready: Bool {
        guard owned, ShedPolicy.showsUpgrades(quietGarden: quiet), let cost = ToolInventory.upgradeCost(toTier: tier + 1) else { return false }
        return points >= cost
    }
    private var line: String {
        guard owned else { return ShedCopy.toFind(tool) }
        return quiet ? ShedCopy.quietLine(tool) : ShedCopy.effect(tool, tier: tier)
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 20, style: .continuous)
        Button(action: open) {
            Group {
                if typeSize.isAccessibilitySize {
                    HStack(alignment: .center, spacing: 12) { art; text(alignment: .leading) }
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    VStack(spacing: 4) { art; text(alignment: .center) }.frame(maxWidth: .infinity)
                }
            }
            .padding(.vertical, 12).padding(.horizontal, 8)
            .frame(maxHeight: .infinity, alignment: .top)
            .background(owned ? tint.fill : findFill, in: shape)
            .overlay {
                if owned { shape.stroke(tint.icon.opacity(0.3), lineWidth: 1.5) }
                else { shape.strokeBorder(Color.appPrimaryText.opacity(0.6), style: StrokeStyle(lineWidth: 1.5, dash: [5, 4])) }
            }
            .contentShape(shape)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(ShedCopy.tileLabel(tool, tier: tier, quiet: quiet, ready: ready))
        .accessibilityHint(ShedCopy.toolHint)
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier("shed.tool.\(tool.rawValue)")
    }

    /// A tool to find: its colour mixed softly into the plain card colour.
    private var findFill: Color {
        tint.fill.opacity(0.45)
    }

    private var art: some View {
        ZStack {
            Circle().fill(Color.appSurface.opacity(0.72)).frame(width: circle, height: circle)
            if owned {
                Image("tool_\(tool.rawValue)_t\(tier)").resizable().scaledToFit().frame(width: artW, height: artW * 62 / 58)
            } else {
                Image("tool_\(tool.rawValue)_t1").renderingMode(.template).resizable().scaledToFit()
                    .frame(width: artW, height: artW * 62 / 58)
                    .foregroundStyle(Color.appPrimaryText.opacity(scheme == .dark ? 0.5 : 0.38))
            }
        }
        .accessibilityHidden(true)
    }

    private func text(alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 4) {
            Text(ShedCopy.name(tool)).font(Theme.font(.headline, weight: .heavy)).foregroundStyle(Color.appPrimaryText)
            if owned && !quiet { TierPips(tier: tier, tint: tint.icon) }
            Text(line).font(Theme.font(.footnote, weight: .bold))
                .foregroundStyle(owned ? Color.appPrimaryText : Color.secondaryText)
                .lineLimit(typeSize.isAccessibilitySize ? nil : 2)
            if ready {
                Label(ShedCopy.upgradeReady, systemImage: "arrow.up").font(Theme.font(.caption, weight: .heavy)).foregroundStyle(Color.ink)
                    .padding(.horizontal, 10).padding(.vertical, 3).background(Color.appAccent, in: Capsule())
            }
        }
        .multilineTextAlignment(alignment == .center ? .center : .leading)
        .fixedSize(horizontal: false, vertical: true)
    }
}

/// What a tool does now and next, with the upgrade button (enough points) or a progress bar (not yet).
/// Quiet Garden: the Now line only, with no tiers, costs or bar.
struct ToolSheet: View {
    let tool: ToolID
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    let upgraded: (ToolID, Int) -> Void
    @ScaledMetric(relativeTo: .body) private var circle: CGFloat = 76

    var body: some View {
        let tier = app.inventory.tier(of: tool)
        let quiet = !ShedPolicy.showsUpgrades(quietGarden: app.settings.quietGarden)
        let points = app.profile?.shedPoints ?? 0
        let tint = ToolTint.of(tool)
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 16) {
                    ZStack {
                        Circle().fill(Color.appSurface.opacity(0.85)).frame(width: circle, height: circle)
                        Image("tool_\(tool.rawValue)_t\(max(1, tier))").resizable().scaledToFit().frame(width: circle * 0.8, height: circle * 0.8)
                            .saturation(tier > 0 ? 1 : 0).opacity(tier > 0 ? 1 : 0.45)
                    }
                    .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(ShedCopy.name(tool)).font(Theme.font(.title3, weight: .heavy)).foregroundStyle(Color.appPrimaryText)
                            .accessibilityAddTraits(.isHeader)
                        if tier > 0 && !quiet {
                            TierPips(tier: tier, tint: tint.icon)
                            Text(ShedCopy.tier(tier)).font(Theme.font(.caption, weight: .bold)).foregroundStyle(Color.secondaryText)
                        }
                    }
                    Spacer(minLength: 0)
                }
                .padding(16)
                .background(tint.fill, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(tint.icon.opacity(0.3), lineWidth: 1.5))

                if tier == 0 {
                    row(ShedCopy.nowLabel, ShedCopy.toFind(tool))
                } else if quiet {
                    row(ShedCopy.nowLabel, ShedCopy.quietLine(tool))
                } else {
                    row(ShedCopy.nowLabel, ShedCopy.effect(tool, tier: tier))
                    if let cost = ToolInventory.upgradeCost(toTier: tier + 1) {
                        row(ShedCopy.nextLabel, ShedCopy.effect(tool, tier: tier + 1))
                        if points >= cost {
                            Button(ShedCopy.upgradeButton(cost: cost)) {
                                if app.upgradeTool(tool) { dismiss(); upgraded(tool, tier + 1) }
                            }
                            .buttonStyle(PrimaryButtonStyle())
                            .accessibilityIdentifier("shed.upgradeButton")
                        } else {
                            VStack(alignment: .leading, spacing: 6) {
                                // A drawn bar, not a ProgressView: the line under it already says the same in words,
                                // so VoiceOver reads it once, and a 4 pt bar is not offered as something to touch.
                                Capsule().fill(tint.icon.opacity(0.2)).frame(height: 4)
                                    .overlay(alignment: .leading) {
                                        GeometryReader { g in
                                            Capsule().fill(tint.icon).frame(width: g.size.width * min(1, Double(points) / Double(max(1, cost))))
                                        }
                                    }
                                    .accessibilityHidden(true)
                                HStack {
                                    Text(ShedCopy.progress(have: points, cost: cost)).font(Theme.font(.subheadline, weight: .bold))
                                    Spacer(minLength: 8)
                                    Text(ShedCopy.toGo(have: points, cost: cost)).font(Theme.font(.subheadline, weight: .semibold))
                                }
                                .foregroundStyle(Color.appPrimaryText)
                                .accessibilityElement(children: .combine)
                                Text(ShedCopy.pointsHow).font(Theme.font(.subheadline)).foregroundStyle(Color.secondaryText)
                            }
                            .fixedSize(horizontal: false, vertical: true)
                        }
                    } else {
                        Text(ShedCopy.fullyUpgraded).font(Theme.font(.headline, weight: .bold)).foregroundStyle(Color.appPrimaryText)
                    }
                }
            }
            .padding(20)
        }
        .scrollBounceBehavior(.basedOnSize)
        .background(Color.appBackground.ignoresSafeArea())
        // Full height: a medium sheet floats and is drawn about 4% smaller, which shrinks its text below the size the
        // reader chose (the accessibility audit reports it as clipped).
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private func row(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label.uppercased()).font(Theme.font(.caption, weight: .heavy)).tracking(1.2).foregroundStyle(Color.secondaryText)
                .accessibilityLabel(label)
            Text(value).font(Theme.font(.body, weight: .bold)).foregroundStyle(Color.appPrimaryText)
        }
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityElement(children: .combine)
    }
}

/// "Your trowel got better!" over a soft dim. Springs in; fades only with Reduce Motion.
struct UpgradeCard: View {
    let tool: ToolID
    let tier: Int
    let reduceMotion: Bool
    let done: () -> Void
    @State private var shown = false

    var body: some View {
        let tint = ToolTint.of(tool)
        ZStack {
            Color.black.opacity(0.32).ignoresSafeArea().onTapGesture(perform: done).accessibilityHidden(true)
            VStack(spacing: 10) {
                ZStack {
                    Circle().fill(tint.fill).frame(width: 96, height: 96)
                    Image("tool_\(tool.rawValue)_t\(tier)").resizable().scaledToFit().frame(width: 76, height: 76)
                }
                .accessibilityHidden(true)
                Text(ShedCopy.upgradedTitle(tool)).font(Theme.font(.title3, weight: .heavy)).foregroundStyle(Color.appPrimaryText)
                    .multilineTextAlignment(.center).accessibilityAddTraits(.isHeader)
                TierPips(tier: tier, tint: tint.icon)
                Text(ShedCopy.upgradedLine(tool, tier: tier)).font(Theme.font(.callout)).foregroundStyle(Color.secondaryText)
                    .multilineTextAlignment(.center)
                Button(ShedCopy.yay, action: done).buttonStyle(PrimaryButtonStyle()).padding(.top, 4)
            }
            .fixedSize(horizontal: false, vertical: true)
            .padding(Space.card)
            .background(Color.appBackground, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .padding(32)
            .scaleEffect(reduceMotion || shown ? 1 : 0.9)
            .opacity(shown ? 1 : 0)
        }
        .onAppear {
            withAnimation(reduceMotion ? .easeOut(duration: 0.2) : .spring(response: 0.35, dampingFraction: 0.7)) { shown = true }
            AccessibilityNotification.Announcement("\(ShedCopy.name(tool)) got better. \(ShedCopy.upgradedLine(tool, tier: tier))").post()
        }
    }
}
