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
        // A tag, not a label: at accessibility text sizes it would cover the pot and its name.
        .dynamicTypeSize(...DynamicTypeSize.large)
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
            .dynamicTypeSize(...DynamicTypeSize.large)
            .accessibilityHidden(true)
    }
}

/// "New pots in your shed!": one calm line, shown on the one opening that recorded newly earned pots.
struct PotNewLine: View {
    var body: some View {
        Label(PotCatalog.Copy.newPots, systemImage: "sparkles")
            .font(Theme.font(.subheadline, weight: .bold)).foregroundStyle(PotPalette.ok)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("pot-new-line")
            .onAppear { AccessibilityNotification.Announcement(PotCatalog.Copy.newPots).post() }
    }
}

// MARK: Repot sheet: Pick a pot

/// "Pick a pot" (design-preview/pots, sections 2 and 6): all sixteen pots in a 4 x 4 grid at every text size, above
/// the soil choices. The picked pot has a ring and a check. Pots to earn are soft outlines and say how
/// to earn them when tapped; Plus pots are in full colour with a "Plus" tag and say where Plus lives.
struct PotPickGrid: View {
    let currentId: String
    @Binding var picked: String
    let stats: PotCatalog.Stats
    let hasPlus: Bool
    /// Records the pots earned by play; true when some were new, which shows "New pots in your shed!" this once.
    var record: () -> Bool = { false }

    @State private var hinted: String?
    @State private var newPots = false

    private func state(_ pot: Pot) -> PotState {
        PotCatalog.state(of: pot, stats: stats, hasPlus: hasPlus)
    }

    var body: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 6, alignment: .top), count: PotCatalog.gridColumns)
        VStack(alignment: .leading, spacing: 8) {
            Text(PotCatalog.Copy.pickTitle).font(Theme.font(.headline, weight: .bold)).foregroundStyle(Color.appPrimaryText)
                .accessibilityAddTraits(.isHeader)
            Text(PotCatalog.Copy.pickSub).font(Theme.font(.callout)).foregroundStyle(Color.secondaryText)
            if newPots { PotNewLine() }
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(PotCatalog.all) { tile($0) }
            }
            .padding(.top, 6)
            if let hinted { hint(PotCatalog.pot(id: hinted)).transition(.opacity) }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear { if record() { newPots = true } }
    }

    private func tile(_ pot: Pot) -> some View {
        let s = state(pot)
        let isCurrent = pot.id == PotCatalog.pot(id: currentId).id
        let isPicked = pot.id == PotCatalog.pot(id: picked).id
        let choosable = PotCatalog.canChoose(pot, currentId: currentId, stats: stats, hasPlus: hasPlus)
        let toEarn: Bool = { if case .toEarn = s { return !isCurrent }; return false }()
        let plusTag: Bool = { if case .plus = s { return !isCurrent }; return false }()
        return Button {
            if choosable { picked = pot.id; hinted = nil } else { hinted = hinted == pot.id ? nil : pot.id }
        } label: {
            VStack(spacing: 3) {
                PotArtView(pot: pot, style: toEarn ? .toEarn : .full, width: 50)
                Text(pot.name).font(Theme.font(.caption, weight: .heavy))
                    .foregroundStyle(toEarn ? Color.secondaryText : Color.appPrimaryText)
                    // Wraps only at spaces: a one-word name shrinks instead of breaking inside the word or clipping.
                    // Capped so "Terracotta" still fits a tile at accessibility sizes; VoiceOver reads the full label.
                    .multilineTextAlignment(.center).lineLimit(pot.name.contains(" ") ? 2 : 1).minimumScaleFactor(0.5)
                    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                    .fixedSize(horizontal: false, vertical: true)
            }
            // Room above the pot for the Plus tag, and beside the name so it clears the 3pt picked ring.
            .padding(.top, 12).padding(.bottom, 6).padding(.horizontal, 5)
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
        .accessibilityHint(toEarn ? PotCatalog.Copy.hintToEarn : plusTag ? PotCatalog.Copy.hintPlus : "")
        .accessibilityAddTraits(isPicked ? .isSelected : [])
        .accessibilityIdentifier("pot-tile-\(pot.id)")
    }

    @ViewBuilder private func hint(_ pot: Pot) -> some View {
        let s = state(pot)
        let lines: (String, String) = {
            switch s {
            case .plus: return (PotCatalog.plusLine(pot), PotCatalog.Copy.plusSettings)
            case .toEarn(let h): return (h, PotCatalog.tipLine(pot, stats: stats))
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

/// The Shed's "Pots" grid below Tools (design-preview/pots, sections 3 and 6): sixteen cards, 4 x 4 at every text
/// size (the text stops growing at xxxLarge so a card stays readable; VoiceOver reads it all). Earned pots carry a check and "Yours to use" or who uses them; pots to earn show the goal and a
/// gentle progress bar; Plus pots show the tag. Nothing is locked or for sale here.
struct ShedPotsSection: View {
    let stats: PotCatalog.Stats
    let hasPlus: Bool
    /// The names of found plants sitting in a pot.
    let users: (Pot) -> [String]
    /// Records the pots earned by play; true when some were new, which shows "New pots in your shed!" this once.
    var record: () -> Bool = { false }

    @State private var message: String?
    @State private var newPots = false

    var body: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 6, alignment: .top), count: PotCatalog.gridColumns)
        VStack(alignment: .leading, spacing: 8) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline) { title; Spacer(minLength: 8); sub }
                VStack(alignment: .leading, spacing: 2) { title; sub }
            }
            .padding(.top, 8)
            if newPots { PotNewLine() }
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
        .onAppear { if record() { newPots = true } }
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
        let s = PotCatalog.state(of: pot, stats: stats, hasPlus: hasPlus)
        let progress = PotCatalog.progress(pot, stats: stats)
        let progressText = PotCatalog.progressLine(pot, stats: stats)
        let toEarn: Bool = { if case .toEarn = s { return true }; return false }()
        let names = users(pot)
        let label: String = {
            switch s {
            case .owned: return "\(pot.voiceName) pot. \(useLine(names))"
            case .plus: return "\(pot.voiceName) pot, Plus. \(PotCatalog.Copy.plusCard)"
            case .toEarn: return "\(pot.voiceName) pot, not earned yet. \(PotCatalog.goalLine(pot)). \(progressText)"
            }
        }()
        return Button { message = tapLine(pot, s) } label: {
            VStack(spacing: 3) {
                PotArtView(pot: pot, style: toEarn ? .toEarn : .full, width: 60)
                    .padding(.top, 10)         // clears the check badge and Plus tag in the corner
                Text(pot.name).font(Theme.font(.footnote, weight: .heavy)).foregroundStyle(Color.appPrimaryText)
                    // As on the pick tiles: a one-word name shrinks to fit instead of breaking inside the word.
                    .multilineTextAlignment(.center).lineLimit(pot.name.contains(" ") ? 2 : 1).minimumScaleFactor(0.5)
                    .fixedSize(horizontal: false, vertical: true)
                Group {
                    switch s {
                    case .owned:
                        cardLine(useLine(names), color: PotPalette.ok)
                    case .plus:
                        cardLine(PotCatalog.Copy.plusCard, color: Color.secondaryText)
                    case .toEarn:
                        cardLine(PotCatalog.goalLine(pot), color: Color.secondaryText)
                        ProgressView(value: progress?.fraction ?? 0).tint(PotPalette.ok).frame(maxWidth: 70)
                        cardLine(progressText, color: Color.secondaryText, small: true)
                    }
                }
            }
            // Four cards a row: the words stop growing at xxxLarge so they stay whole; VoiceOver reads the full card.
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            .padding(.horizontal, 4).padding(.top, 8).padding(.bottom, 8)
            .frame(maxWidth: .infinity, minHeight: 132, alignment: .top)
            .background(toEarn ? Color.appSurface.opacity(0.55) : Color.appSurface, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
            .overlay(RoundedRectangle(cornerRadius: Theme.cardRadius).stroke(Color.appPrimaryText.opacity(toEarn ? 0.14 : 0.08), lineWidth: toEarn ? 1.5 : 1))
            .overlay(alignment: .topTrailing) {
                switch s {
                case .owned: PotCheckBadge(size: 20).padding(4)
                case .plus: PotPlusTag().padding(4)
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

    private func cardLine(_ text: String, color: Color, small: Bool = false) -> some View {
        Text(text).font(Theme.font(small ? .caption2 : .caption, weight: .bold)).foregroundStyle(color)
            .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
    }

    private func tapLine(_ pot: Pot, _ s: PotState) -> String {
        switch s {
        case .owned: return pot.unlock == .free ? pot.hint : PotCatalog.Copy.earned
        case .plus: return "\(PotCatalog.plusLine(pot)) \(PotCatalog.Copy.plusSettings)"
        case .toEarn(let h): return "\(h) \(PotCatalog.tipLine(pot, stats: stats))"
        }
    }
}
