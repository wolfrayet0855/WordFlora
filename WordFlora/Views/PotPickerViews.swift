import SwiftUI
import UIKit

/// Colours for the pot tiles (design-preview/pots/index.html): the in-use ring and the amber Plus tag.
enum PotPalette {
    private static func dyn(_ light: UInt32, _ dark: UInt32) -> Color {
        Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light) })
    }
    static let ring = dyn(0x3E7A22, 0xA8D84A)
    static let plus = dyn(0xE8A838, 0xF0C060)
    static let plusInk = dyn(0x2C3E2C, 0x1A2E1A)
    static let ok = dyn(0x3E7A22, 0xA8D84A)
}

/// The small amber "Plus" tag with a sparkle. No lock, no price.
struct PotPlusTag: View {
    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: "sparkle").font(.system(size: 8, weight: .heavy))
            Text(PotCatalog.Copy.plusTag).font(Theme.font(.caption2, weight: .heavy))
        }
        .foregroundStyle(PotPalette.plusInk)
        .padding(.horizontal, 6).padding(.vertical, 1)
        .background(PotPalette.plus, in: Capsule())
        .accessibilityHidden(true)
    }
}

/// The check badge on the pot in use (a shape, not only a colour).
struct PotCheckBadge: View {
    var size: CGFloat = 22
    var body: some View {
        Image(systemName: "checkmark").font(.system(size: size * 0.5, weight: .black))
            .foregroundStyle(Color.appSurface)
            .frame(width: size, height: size)
            .background(PotPalette.ring, in: Circle())
            .overlay(Circle().stroke(Color.appSurface, lineWidth: 2))
            .accessibilityHidden(true)
    }
}

// MARK: Repot sheet: Pick a pot

/// "Pick a pot" (design-preview/pots, section 2): all ten pots in a 5 x 2 grid (4 columns at accessibility text
/// sizes), above the soil choices. The picked pot has a ring and a check. Pots to earn are soft outlines and say how
/// to earn them when tapped; Plus pots are in full colour with a "Plus" tag and say where Plus lives.
struct PotPickGrid: View {
    let currentId: String
    @Binding var picked: String
    let stats: PotCatalog.Stats
    let hasPlus: Bool

    @State private var hinted: String?
    @Environment(\.dynamicTypeSize) private var typeSize

    private func state(_ pot: Pot) -> PotState {
        PotCatalog.state(of: pot, plantsGrown: stats.plantsGrown, finishedLevels: stats.finishedLevels, hasPlus: hasPlus)
    }

    var body: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 6, alignment: .top), count: typeSize.isAccessibilitySize ? 4 : 5)
        VStack(alignment: .leading, spacing: 8) {
            Text(PotCatalog.Copy.pickTitle).font(Theme.font(.headline, weight: .bold)).foregroundStyle(Color.appPrimaryText)
                .accessibilityAddTraits(.isHeader)
            Text(PotCatalog.Copy.pickSub).font(Theme.font(.callout)).foregroundStyle(Color.secondaryText)
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(PotCatalog.all) { tile($0) }
            }
            .padding(.top, 6)
            if let hinted { hint(PotCatalog.pot(id: hinted)).transition(.opacity) }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func tile(_ pot: Pot) -> some View {
        let s = state(pot)
        let isCurrent = pot.id == PotCatalog.pot(id: currentId).id
        let isPicked = pot.id == PotCatalog.pot(id: picked).id
        let choosable = PotCatalog.canChoose(pot, currentId: currentId, plantsGrown: stats.plantsGrown,
                                             finishedLevels: stats.finishedLevels, hasPlus: hasPlus)
        let toEarn: Bool = { if case .toEarn = s { return !isCurrent }; return false }()
        let plusTag: Bool = { if case .plus = s { return !isCurrent }; return false }()
        return Button {
            if choosable { picked = pot.id; hinted = nil } else { hinted = hinted == pot.id ? nil : pot.id }
        } label: {
            VStack(spacing: 3) {
                PotArtView(pot: pot, style: toEarn ? .toEarn : .full, width: 50)
                Text(pot.name).font(Theme.font(.caption, weight: .heavy))
                    .foregroundStyle(toEarn ? Color.secondaryText : Color.appPrimaryText)
                    // Wraps only at spaces: a one-word name shrinks a little instead of breaking inside the word.
                    .multilineTextAlignment(.center).lineLimit(pot.name.contains(" ") ? 2 : 1).minimumScaleFactor(0.7)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 9).padding(.bottom, 6).padding(.horizontal, 2)
            .frame(maxWidth: .infinity, minHeight: 86, alignment: .top)
            .background(Color.appBackground, in: RoundedRectangle(cornerRadius: 16))
            .overlay {
                if isPicked {
                    RoundedRectangle(cornerRadius: 16).strokeBorder(PotPalette.ring, lineWidth: 3)
                } else if hinted == pot.id {
                    RoundedRectangle(cornerRadius: 16).strokeBorder(Color.appPrimaryText, lineWidth: 2)
                }
            }
            .overlay(alignment: .topTrailing) { if isPicked { PotCheckBadge().offset(x: 3, y: -5) } }
            .overlay(alignment: .top) { if plusTag { PotPlusTag().offset(y: -7) } }
            .contentShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(PotCatalog.tileLabel(pot, state: isCurrent ? .owned : s, inUse: isCurrent))
        .accessibilityAddTraits(isPicked ? .isSelected : [])
        .accessibilityIdentifier("pot-tile-\(pot.id)")
    }

    @ViewBuilder private func hint(_ pot: Pot) -> some View {
        let s = state(pot)
        let lines: (String, String) = {
            switch s {
            case .plus: return (PotCatalog.plusLine(pot), PotCatalog.Copy.plusSettings)
            case .toEarn(let h): return (h, PotCatalog.tipLine(pot, plantsGrown: stats.plantsGrown, finishedLevels: stats.finishedLevels))
            case .owned: return (PotCatalog.Copy.earned, "")
            }
        }()
        HStack(alignment: .center, spacing: 10) {
            if case .plus = s {
                PotArtView(pot: pot, width: 30)
            } else {
                Image(systemName: "leaf.fill").font(.system(size: 18, weight: .bold)).accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(lines.0).font(Theme.font(.subheadline, weight: .bold))
                if !lines.1.isEmpty { Text(lines.1).font(Theme.font(.footnote, weight: .semibold)).opacity(0.92) }
            }
            .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .foregroundStyle(Color.appBackground)
        .padding(12)
        .background(Color.appPrimaryText, in: RoundedRectangle(cornerRadius: 14))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("pot-hint")
        .onAppear { AccessibilityNotification.Announcement("\(lines.0) \(lines.1)").post() }
        .id(pot.id)
    }
}

// MARK: Shed: Pots

/// The Shed's "Pots" grid below Tools (design-preview/pots, section 3): three columns of cards (two at accessibility
/// text sizes). Earned pots carry a check and "Yours to use" or who uses them; pots to earn show the goal and a
/// gentle progress bar; Plus pots show the tag. Nothing is locked or for sale here.
struct ShedPotsSection: View {
    let stats: PotCatalog.Stats
    let hasPlus: Bool
    /// The names of found plants sitting in a pot.
    let users: (Pot) -> [String]

    @State private var message: String?
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 8, alignment: .top), count: typeSize.isAccessibilitySize ? 2 : 3)
        VStack(alignment: .leading, spacing: 8) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline) { title; Spacer(minLength: 8); sub }
                VStack(alignment: .leading, spacing: 2) { title; sub }
            }
            .padding(.top, 8)
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(PotCatalog.all) { card($0) }
            }
            if let message {
                Text(message).font(Theme.font(.callout, weight: .semibold)).foregroundStyle(Color.appPrimaryText)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("shed-pot-hint")
            }
            Text(PotCatalog.Copy.shedFooter).font(Theme.font(.footnote)).foregroundStyle(Color.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onChange(of: message) { _, new in if let new { AccessibilityNotification.Announcement(new).post() } }
    }

    private var title: some View {
        Text(PotCatalog.Copy.shedTitle).font(Theme.font(.title3, weight: .bold)).foregroundStyle(Color.appPrimaryText)
            .accessibilityAddTraits(.isHeader)
    }
    private var sub: some View {
        Text(PotCatalog.Copy.shedSub).font(Theme.font(.footnote, weight: .bold)).foregroundStyle(Color.secondaryText)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func useLine(_ names: [String]) -> String {
        switch names.count {
        case 0: return PotCatalog.Copy.yours
        case 1: return "In use by \(names[0])"
        default: return "In use by \(names.count) plants"
        }
    }

    private func card(_ pot: Pot) -> some View {
        let s = PotCatalog.state(of: pot, plantsGrown: stats.plantsGrown, finishedLevels: stats.finishedLevels, hasPlus: hasPlus)
        let progress = PotCatalog.progress(pot, plantsGrown: stats.plantsGrown, finishedLevels: stats.finishedLevels)
        let progressText = PotCatalog.progressLine(pot, plantsGrown: stats.plantsGrown, finishedLevels: stats.finishedLevels)
        let toEarn: Bool = { if case .toEarn = s { return true }; return false }()
        let names = users(pot)
        let label: String = {
            switch s {
            case .owned: return "\(pot.name) pot. \(useLine(names))"
            case .plus: return "\(pot.name) pot, Plus. \(PotCatalog.Copy.plusCard)"
            case .toEarn: return "\(pot.name) pot, not earned yet. \(PotCatalog.goalLine(pot)). \(progressText)"
            }
        }()
        return Button { message = tapLine(pot, s) } label: {
            VStack(spacing: 4) {
                PotArtView(pot: pot, style: toEarn ? .toEarn : .full, width: 76)
                Text(pot.name).font(Theme.font(.subheadline, weight: .heavy)).foregroundStyle(Color.appPrimaryText)
                    .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                switch s {
                case .owned:
                    Text(useLine(names)).font(Theme.font(.caption, weight: .bold)).foregroundStyle(PotPalette.ok)
                        .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                case .plus:
                    Text(PotCatalog.Copy.plusCard).font(Theme.font(.caption, weight: .bold)).foregroundStyle(Color.secondaryText)
                        .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                case .toEarn:
                    Text(PotCatalog.goalLine(pot)).font(Theme.font(.caption, weight: .bold)).foregroundStyle(Color.secondaryText)
                        .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                    ProgressView(value: progress?.fraction ?? 0).tint(PotPalette.ok).frame(maxWidth: 90)
                    Text(progressText).font(Theme.font(.caption2, weight: .bold)).foregroundStyle(Color.secondaryText)
                        .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, 6).padding(.top, 10).padding(.bottom, 9)
            .frame(maxWidth: .infinity, minHeight: 150, alignment: .top)
            .background(toEarn ? Color.appSurface.opacity(0.55) : Color.appSurface, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
            .overlay(RoundedRectangle(cornerRadius: Theme.cardRadius).stroke(Color.appPrimaryText.opacity(toEarn ? 0.14 : 0.08), lineWidth: toEarn ? 1.5 : 1))
            .overlay(alignment: .topTrailing) {
                switch s {
                case .owned: PotCheckBadge(size: 20).padding(7)
                case .plus: PotPlusTag().padding(7)
                case .toEarn: EmptyView()
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: Theme.cardRadius))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier("shed-pot-\(pot.id)")
    }

    private func tapLine(_ pot: Pot, _ s: PotState) -> String {
        switch s {
        case .owned: return pot.unlock == .free ? pot.hint : PotCatalog.Copy.earned
        case .plus: return "\(PotCatalog.plusLine(pot)) \(PotCatalog.Copy.plusSettings)"
        case .toEarn(let h): return "\(h) \(PotCatalog.tipLine(pot, plantsGrown: stats.plantsGrown, finishedLevels: stats.finishedLevels))"
        }
    }
}
