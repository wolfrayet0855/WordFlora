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

/// The small amber "Plus" tag with a sparkle. No lock, no price. It grows with the text; at the accessibility sizes it
/// is not drawn (it would cover the pot), and the card's own line says "A Plus pot" instead.
struct PotPlusTag: View {
    @Environment(\.dynamicTypeSize) private var typeSize
    var body: some View {
        if !typeSize.isAccessibilitySize {
            HStack(spacing: 2) {
                Image(systemName: "sparkle").imageScale(.small)
                Text(PotCatalog.Copy.plusTag)
            }
            .font(Theme.font(.caption2, weight: .heavy))
            .foregroundStyle(PotPalette.plusInk)
            .padding(.horizontal, 6).padding(.vertical, 1)
            .background(PotPalette.plus, in: Capsule())
            .accessibilityHidden(true)
        }
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

/// "New pots in your shed!" in the Shed: one calm line, shown on the one opening that recorded newly earned pots.
/// (The repot sheet shows it as a closable pill, `PotNewPill`.)
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

/// Reduce Motion inside the repot sheet: the system setting or the app's own switch (Settings). Opacity changes only.
private struct RepotReduceMotionKey: EnvironmentKey { static let defaultValue = false }
extension EnvironmentValues {
    var repotReduceMotion: Bool {
        get { self[RepotReduceMotionKey.self] }
        set { self[RepotReduceMotionKey.self] = newValue }
    }
}

// MARK: Repot sheet v2 (design-preview/repot-sheet/notes.md)

/// The repot sheet: one compact header (the plant standing in the picked pot), the "New pots" pill once, a 4 x 4 grid
/// of fixed-height tiles, the soil chips, and a pinned footer (what the repot will do, or the hint for a pot that
/// cannot be picked, then one button). The footer is a `safeAreaInset`, so its whole height (fade included) is the
/// scroll view's bottom inset and nothing is ever hidden under it. Only pots the player has (or the pot already on
/// the plant) can be picked; the others say how to earn them, or where Plus lives.
struct RepotSheet: View {
    let plantName: String
    /// The plant's art (`PlantCollectible.imageName`) for the header thumb.
    let imageName: String
    let currentId: String
    let stats: PotCatalog.Stats
    let hasPlus: Bool
    /// Records the pots earned by play; the ids that were new, which shows the pill and the "New" tags this once.
    var record: () -> [String] = { [] }
    var go: (Pot, SoilType) -> Void

    @State private var picked: String
    @State private var pickedSoil: SoilType
    @State private var hinted: String?
    @State private var newIds: Set<String> = []
    @State private var showNewPill = false
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize
    /// The in-app Reduce Motion switch (Settings), on top of the system one.
    var reduceMotionOverride = false
    private var reduceMotion: Bool { systemReduceMotion || reduceMotionOverride }

    /// A live seasonal pack's pots, in their own row under the sixteen.
    var packPots: [Pot] = []

    init(plantName: String, imageName: String, currentId: String, soil: SoilType, stats: PotCatalog.Stats, hasPlus: Bool,
         packPots: [Pot] = [], reduceMotionOverride: Bool = false, record: @escaping () -> [String] = { [] },
         go: @escaping (Pot, SoilType) -> Void) {
        self.plantName = plantName; self.imageName = imageName; self.currentId = currentId
        self.packPots = packPots
        self.reduceMotionOverride = reduceMotionOverride
        self.stats = stats; self.hasPlus = hasPlus; self.record = record; self.go = go
        _picked = State(initialValue: PotCatalog.pot(id: currentId).id)
        _pickedSoil = State(initialValue: soil)
    }

    var body: some View {
        let pot = PotCatalog.pot(id: picked)
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                RepotHeader(plantName: plantName, imageName: imageName, pot: pot)
                if showNewPill {
                    PotNewPill { closePill() }
                        .padding(.top, 12)
                        .transition(reduceMotion ? .opacity : .opacity.combined(with: .offset(y: 6)))
                }
                PotPickGrid(currentId: currentId, picked: $picked, hinted: $hinted, newIds: newIds, stats: stats, hasPlus: hasPlus,
                            packPots: packPots)
                    .padding(.top, 14)
                SoilPicker(picked: $pickedSoil).padding(.top, 20)
                // At accessibility sizes the summary scrolls with the sheet, so the pinned footer is only the button
                // (and a tapped pot's hint) and the first pots show on the first screen.
                if typeSize.isAccessibilitySize { RepotSummary(pot: pot, soil: pickedSoil).padding(.top, 16) }
            }
            .padding(.horizontal, Space.gutter).padding(.top, Space.section).padding(.bottom, Space.card)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollIndicators(.visible)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            RepotFooter(picked: pot, soil: pickedSoil, hinted: hinted, currentId: currentId, stats: stats, hasPlus: hasPlus) {
                go(pot, pickedSoil)
            }
        }
        .background(Color.appBackground)
        .environment(\.repotReduceMotion, reduceMotion)
        .onAppear {
            let ids = record()
            guard !ids.isEmpty else { return }
            newIds = Set(ids)
            withAnimation(reduceMotion ? .easeOut(duration: 0.15) : .easeOut(duration: 0.25)) { showNewPill = true }
        }
    }

    /// Closing the pill clears the "New" tags too; the pots were recorded, so neither comes back.
    private func closePill() {
        withAnimation(.easeOut(duration: reduceMotion ? 0.15 : 0.2)) { showNewPill = false; newIds = [] }
    }
}

/// The plant standing in a pot, drawn as on the plant page (the plant box is 220 wide, the pot at `potRect`), scaled
/// down to fit `height`. The pot cross-fades when it changes (it just swaps with Reduce Motion).
struct PlantInPotThumb: View {
    let imageName: String
    let pot: Pot
    var height: CGFloat
    @Environment(\.repotReduceMotion) private var reduceMotion

    var body: some View {
        let r = TendAnimationView.potRect
        // The plant art leaves room above it; the box runs from the top of the plant to the foot of the pot.
        let top: CGFloat = 40, bottom = r.maxY
        let k = height / (bottom - top)
        ZStack(alignment: .topLeading) {
            PotArtView(pot: pot, width: r.width * k, soil: true)
                .id(pot.id)
                .transition(.opacity)
                .offset(x: r.minX * k, y: (r.minY - top) * k)
            Image(imageName).resizable().scaledToFit()
                .frame(width: 220 * k, height: 220 * k)
                .offset(y: -top * k)
        }
        .frame(width: 220 * k, height: height, alignment: .topLeading)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: pot.id)
        .accessibilityHidden(true)
    }
}

/// "Repot Daisy" with its thumb and one line ("Pick a pot. Changing pots is free."). The words grow with every text
/// size (the accessibility audit asks for it); the thumb stops at 76pt.
struct RepotHeader: View {
    let plantName: String
    let imageName: String
    let pot: Pot
    @ScaledMetric(relativeTo: .title3) private var thumb: CGFloat = 60

    var body: some View {
        let side = min(thumb, 76)
        let shape = RoundedRectangle(cornerRadius: 16, style: .continuous)
        HStack(spacing: 12) {
            PlantInPotThumb(imageName: imageName, pot: pot, height: side - 8)
                .frame(width: side, height: side)
                .background(Color.tileGardenFill, in: shape)
                .overlay(shape.stroke(Color.appPrimaryText.opacity(0.12)))
                .clipShape(shape)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text("Repot \(plantName)").font(Theme.font(.title3, weight: .bold)).foregroundStyle(Color.appPrimaryText)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                Text(PotCatalog.Copy.repotSub).font(Theme.font(.callout, weight: .medium)).foregroundStyle(Color.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
    }
}

/// "New pots in your shed!" as a small pill with a close button, shown on the one opening that recorded new pots.
struct PotNewPill: View {
    var close: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "sparkles").foregroundStyle(Color.successText).accessibilityHidden(true)
            Text(PotCatalog.Copy.newPots).font(Theme.font(.subheadline, weight: .heavy))
                .fixedSize(horizontal: false, vertical: true)
            Button(action: close) {
                Image(systemName: "xmark").font(.system(size: 11, weight: .heavy))
                    .frame(width: 28, height: 28)
                    .background(Color.appPrimaryText.opacity(0.1), in: Circle())
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close")
            .accessibilityIdentifier("pot-new-close")
        }
        .padding(.leading, 12).padding(.trailing, 0)
        .frame(minHeight: 34)
        .foregroundStyle(Color.appPrimaryText)
        .background(Color.tileGardenFill, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .accessibilityElement(children: .contain)
        .accessibilityLabel(PotCatalog.Copy.newPots)
        .accessibilityIdentifier("pot-new-line")
        .onAppear { AccessibilityNotification.Announcement(PotCatalog.Copy.newPots).post() }
    }
}

/// The tiny "New" tag on a pot that is new on this opening. VoiceOver hears ", new" in the tile's label instead.
struct PotNewTag: View {
    var body: some View {
        Text(PotCatalog.Copy.newTag).font(Theme.font(.caption2, weight: .black)).foregroundStyle(Color.appPrimaryText)
            .padding(.horizontal, 6).padding(.vertical, 1)
            .background(Color.tileGardenFill, in: Capsule())
            .accessibilityHidden(true)
    }
}

/// "✦ Plus" on line 2 of a Plus tile (the Shed v2 pill colours). No price. Part of the tile's button, whose label
/// says "Plus" already; not hidden, so the audit never sees drawn words that VoiceOver cannot reach.
struct PotPlusPill: View {
    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "sparkle").imageScale(.small)
            Text(PotCatalog.Copy.plusTag)
        }
        .font(Theme.font(.caption2, weight: .heavy))
        .foregroundStyle(Color.accentText)
        .padding(.horizontal, 7).padding(.vertical, 1)
        .background(Color.tileBadgesFill, in: Capsule())
        .overlay(Capsule().strokeBorder(Color.accentText.opacity(0.55), lineWidth: 1.2))
    }
}

/// "✓ In use" on line 2 of the pot on the plant: an outlined pill, so it never reads as a goal.
struct PotInUsePill: View {
    var body: some View {
        Label(PotCatalog.Copy.current, systemImage: "checkmark")
            .labelStyle(InUseLabelStyle())
            .font(Theme.font(.caption2, weight: .heavy)).foregroundStyle(Color.successText)
            .padding(.horizontal, 7)
            .overlay(Capsule().strokeBorder(Color.successText, lineWidth: 1.2))
    }

    private struct InUseLabelStyle: LabelStyle {
        func makeBody(configuration: Configuration) -> some View {
            HStack(spacing: 3) { configuration.icon.imageScale(.small); configuration.title }
        }
    }
}

/// The sixteen pots: four a row up to Large, two above, and at the accessibility sizes one a row with the pot beside its
/// words (GridColumns), so every name keeps whole words at every text size. The tiles in a row share one height (at
/// least `tileHeight`): the name, then line 2 says the state (the goal for a pot to earn, "Plus", "In use", or nothing).
/// The picked pot has a green ring and a check; a tapped pot that cannot be picked gets a double ink outline.
struct PotPickGrid: View {
    let currentId: String
    @Binding var picked: String
    @Binding var hinted: String?
    var newIds: Set<String> = []
    let stats: PotCatalog.Stats
    let hasPlus: Bool
    /// The live pack's pots (`AppModel.visiblePackPots`); empty while the store has no pack.
    var packPots: [Pot] = []

    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.repotReduceMotion) private var reduceMotion

    static let tileHeight: CGFloat = 108
    /// A one-a-row tile (accessibility sizes) is at least this tall.
    static let rowHeight: CGFloat = 64

    var body: some View {
        // An eager grid (not lazy): all the tiles are always laid out, so the grid checks see every row even when the
        // header takes the first screen at the largest text sizes.
        let columns = GridColumns.count(.repotTiles, for: typeSize)
        Grid(horizontalSpacing: GridColumns.spacing(.repotTiles), verticalSpacing: 8) {
            ForEach(GridColumns.rows(PotCatalog.all, .repotTiles, for: typeSize), id: \.first?.id) { row in
                GridRow { ForEach(row) { tile($0) } }
            }
            // A live seasonal pack: its own rows under the ladder, with the pack's name (no price, no lock).
            if !packPots.isEmpty {
                GridRow {
                    PackRowTitle(name: PackCatalog.frostLantern.name).gridCellColumns(columns)
                }
                ForEach(GridColumns.rows(packPots, .repotTiles, for: typeSize), id: \.first?.id) { row in
                    GridRow {
                        ForEach(row) { tile($0) }
                        ForEach(0..<max(0, columns - row.count), id: \.self) { _ in
                            Color.clear.gridCellUnsizedAxes([.horizontal, .vertical])
                        }
                    }
                }
            }
        }
        .animation(reduceMotion ? .easeInOut(duration: 0.15) : .spring(response: 0.25, dampingFraction: 0.8), value: picked)
        .animation(.easeInOut(duration: reduceMotion ? 0.15 : 0.2), value: hinted)
    }

    private func tile(_ pot: Pot) -> some View {
        let s = PotCatalog.state(of: pot, stats: stats, hasPlus: hasPlus)
        let isCurrent = pot.id == PotCatalog.pot(id: currentId).id
        let isPicked = pot.id == PotCatalog.pot(id: picked).id
        let isHinted = hinted == pot.id
        let isNew = newIds.contains(pot.id)
        let choosable = PotCatalog.canChoose(pot, currentId: currentId, stats: stats, hasPlus: hasPlus)
        // A pack pot not owned looks like a pot to earn (the soft outline, no lock, no price), with no line 2.
        let packSoft: Bool = { if case .pack = s { return !isCurrent }; return false }()
        let toEarn: Bool = { if case .toEarn = s { return !isCurrent }; return packSoft }()
        let plus: Bool = { if case .plus = s { return !isCurrent }; return false }()
        let row = GridColumns.isRow(.repotTiles, for: typeSize)
        let shape = RoundedRectangle(cornerRadius: 16, style: .continuous)
        let art = PotArtView(pot: pot, style: toEarn ? .toEarn : .full, width: 48).frame(height: 42, alignment: .bottom)
        let words = VStack(alignment: row ? .leading : .center, spacing: 3) {
            Text(pot.name)
                .font(Theme.font(.caption, weight: .heavy)).foregroundStyle(Color.appPrimaryText)
                .multilineTextAlignment(row ? .leading : .center)
                .fixedSize(horizontal: false, vertical: true)
            if isCurrent {
                PotInUsePill()
            } else if plus {
                PotPlusPill()
            } else if toEarn && !packSoft {
                Text(PotCatalog.goalLine(pot)).font(Theme.font(.caption2, weight: .bold)).foregroundStyle(Color.secondaryText)
                    .multilineTextAlignment(row ? .leading : .center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        return Button {
            if choosable { picked = pot.id; hinted = nil } else { hinted = isHinted ? nil : pot.id }
        } label: {
            Group {
                if row {
                    HStack(spacing: GridColumns.rowGap) {
                        art.frame(width: GridColumns.rowArt(.repotTiles))
                        words.frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.leading, GridColumns.rowPadding).padding(.trailing, GridColumns.rowPadding + GridColumns.rowBadge)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity, minHeight: Self.rowHeight, maxHeight: .infinity, alignment: .leading)
                } else {
                    VStack(spacing: 0) {
                        art
                        words.padding(.top, 7)
                        Spacer(minLength: 0)
                    }
                    .padding(.top, 13).padding(.bottom, 8).padding(.horizontal, GridColumns.cellPadding(.repotTiles))
                    .frame(maxWidth: .infinity, minHeight: Self.tileHeight, maxHeight: .infinity, alignment: .top)
                }
            }
            .background {
                if toEarn && !isHinted {
                    // The soft tile: ink at 6% over the sheet's background (no colorset of its own).
                    shape.fill(Color.appBackground).overlay(shape.fill(Color.appPrimaryText.opacity(0.06)))
                } else {
                    shape.fill(Color.appSurface)
                }
            }
            .overlay {
                if isPicked {
                    shape.strokeBorder(PotPalette.ring, lineWidth: 3)
                } else if isHinted {
                    ZStack {
                        shape.strokeBorder(Color.appPrimaryText, lineWidth: 2)
                        RoundedRectangle(cornerRadius: 12, style: .continuous).inset(by: 4)
                            .strokeBorder(Color.appPrimaryText.opacity(0.35), lineWidth: 1)
                    }
                } else if toEarn {
                    shape.strokeBorder(Color.appPrimaryText.opacity(0.32), style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                } else {
                    shape.strokeBorder(Color.appPrimaryText.opacity(0.12), lineWidth: 1)
                }
            }
            .overlay(alignment: .topTrailing) {
                if isPicked {
                    PotCheckBadge(size: 22).padding(4)
                        .transition(reduceMotion ? .opacity : .scale(scale: 0.6).combined(with: .opacity))
                }
            }
            .overlay(alignment: .topLeading) { if isNew { PotNewTag().padding(5).transition(.opacity) } }
            .contentShape(shape)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(PotCatalog.tileLabel(pot, state: isCurrent ? .owned : s, inUse: isCurrent, isNew: isNew))
        .accessibilityValue(toEarn && !packSoft ? PotCatalog.goalLine(pot) : "")
        .accessibilityHint(packSoft ? PotCatalog.Copy.hintPack : toEarn ? PotCatalog.Copy.hintToEarn : plus ? PotCatalog.Copy.hintPlus : "")
        .accessibilityAddTraits(isPicked ? .isSelected : [])
        .accessibilityIdentifier("pot-tile-\(pot.id)")
    }
}

/// The name over a seasonal pack's row of pots ("Frost & Lantern"), with the Seasons glyph. Grows with every text size.
struct PackRowTitle: View {
    let name: String
    var body: some View {
        Label { Text(name) } icon: {
            Image("seasons-row-glyph").renderingMode(.template).resizable().scaledToFit().frame(width: 18, height: 18)
                .accessibilityHidden(true)
        }
        .font(Theme.font(.subheadline, weight: .heavy)).foregroundStyle(Color.appPrimaryText)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 6)
        .accessibilityAddTraits(.isHeader)
        .accessibilityIdentifier("pot-pack-title")
    }
}

/// "Soil" and "Plants have favorite soils.", then four chips in a row (2 x 2 at accessibility sizes).
struct SoilPicker: View {
    @Binding var picked: SoilType
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.repotReduceMotion) private var reduceMotion

    /// Art colours for the dots (each clearly different from the others).
    static func dot(_ soil: SoilType) -> Color {
        switch soil {
        case .loam: return Color(UIColor(hex: 0x9A6B43))
        case .sandy: return Color(UIColor(hex: 0xE6CB8E))
        case .peaty: return Color(UIColor(hex: 0x2E211A))
        case .compost: return Color(UIColor(hex: 0x6E8A3E))
        }
    }

    var body: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: GridColumns.spacing(.soilChips)),
                            count: GridColumns.count(.soilChips, for: typeSize))
        // The heading and its line side by side, stacked at the accessibility sizes (chosen from the size, not measured).
        let header = typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 2)) : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: 8))
        VStack(alignment: .leading, spacing: 10) {
            header { title; sub }
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(SoilType.allCases, id: \.self) { chip($0) }
            }
            .animation(reduceMotion ? .easeInOut(duration: 0.15) : .spring(response: 0.25, dampingFraction: 0.8), value: picked)
        }
    }

    private var title: some View {
        Text(PotCatalog.Copy.soilTitle).font(Theme.font(.headline, weight: .heavy)).foregroundStyle(Color.appPrimaryText)
            .accessibilityAddTraits(.isHeader)
    }
    private var sub: some View {
        Text(PotCatalog.Copy.soilSub).font(Theme.font(.subheadline)).foregroundStyle(Color.secondaryText)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func chip(_ soil: SoilType) -> some View {
        let shape = RoundedRectangle(cornerRadius: 14, style: .continuous)
        let isPicked = picked == soil
        return Button { picked = soil } label: {
            HStack(spacing: GridColumns.soilDotGap) {
                Circle().fill(Self.dot(soil)).frame(width: GridColumns.soilDot, height: GridColumns.soilDot)
                    .overlay(Circle().stroke(Color.appPrimaryText.opacity(0.35), lineWidth: 1))
                Text(soil.rawValue.capitalized).font(Theme.font(.subheadline, weight: .bold)).foregroundStyle(Color.appPrimaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, GridColumns.cellPadding(.soilChips)).padding(.vertical, 6)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(Color.appSurface, in: shape)
            .overlay {
                if isPicked { shape.strokeBorder(PotPalette.ring, lineWidth: 3) }
                else { shape.strokeBorder(Color.appPrimaryText.opacity(0.12), lineWidth: 1) }
            }
            .contentShape(shape)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(soil.rawValue.capitalized)
        .accessibilityAddTraits(isPicked ? [.isButton, .isSelected] : .isButton)
        .accessibilityIdentifier("repot-soil-\(soil.rawValue)")
    }
}

/// The pinned footer: what the repot will do ("Rose pink pot, fresh loam soil"), or the hint for a tapped pot that
/// cannot be picked, then the one-line button. A 28pt fade above it lets the soil row scroll in softly.
struct RepotFooter: View {
    let picked: Pot
    let soil: SoilType
    let hinted: String?
    let currentId: String
    let stats: PotCatalog.Stats
    let hasPlus: Bool
    var go: () -> Void
    @Environment(\.repotReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize

    static let fade: CGFloat = 28

    var body: some View {
        VStack(spacing: 10) {
            Group {
                if let hinted {
                    PotHintCard(pot: PotCatalog.pot(id: hinted), stats: stats, hasPlus: hasPlus).id(hinted)
                } else if !typeSize.isAccessibilitySize {
                    RepotSummary(pot: picked, soil: soil)
                }
            }
            .transition(.opacity)
            Button(action: go) {
                // One line at the default sizes; at accessibility sizes a longer title wraps rather than clips.
                Text(PotCatalog.repotTitle(picked: picked, currentId: currentId))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 16).padding(.vertical, 6)
            }
            .buttonStyle(RepotButtonStyle())
            .accessibilityIdentifier("repot-go")
        }
        .animation(.easeInOut(duration: reduceMotion ? 0.15 : 0.2), value: hinted)
        .padding(.horizontal, Space.gutter).padding(.top, Space.s).padding(.bottom, Space.s)
        .background(alignment: .top) {
            Color.appBackground
                .overlay(alignment: .top) { Rectangle().fill(Color.appPrimaryText.opacity(0.12)).frame(height: 1) }
                .overlay(alignment: .top) {
                    LinearGradient(colors: [Color.appBackground.opacity(0), Color.appBackground], startPoint: .top, endPoint: .bottom)
                        .frame(height: Self.fade).offset(y: -Self.fade)
                }
                .ignoresSafeArea(edges: .bottom)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }
}

/// "Rose pink pot, fresh loam soil" with a mini pot.
struct RepotSummary: View {
    let pot: Pot
    let soil: SoilType

    var body: some View {
        HStack(spacing: 10) {
            PotArtView(pot: pot, width: 30)
            Text("\(Text("\(pot.name) pot").bold())\(Text(", fresh \(soil.rawValue) soil").foregroundStyle(Color.secondaryText))")
                .font(Theme.font(.subheadline)).foregroundStyle(Color.appPrimaryText)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .frame(minHeight: 44)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(PotCatalog.summaryLine(pot: pot, soil: soil))
        .accessibilityIdentifier("repot-summary")
    }
}

/// The hint for a tapped pot that cannot be picked: the goal and how far along, or where Plus lives. The same pot art
/// as the tile (ghost or full) ties the two together.
struct PotHintCard: View {
    let pot: Pot
    let stats: PotCatalog.Stats
    let hasPlus: Bool

    var body: some View {
        let s = PotCatalog.state(of: pot, stats: stats, hasPlus: hasPlus)
        let lines = PotCatalog.hintLines(pot, state: s, stats: stats)
        let toEarn: Bool = { switch s { case .toEarn, .pack: return true; default: return false } }()
        HStack(alignment: .center, spacing: 12) {
            PotArtView(pot: pot, style: toEarn ? .toEarn : .full, width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(lines.title).font(Theme.font(.subheadline, weight: .heavy)).foregroundStyle(Color.appPrimaryText)
                if !lines.detail.isEmpty {
                    Text(lines.detail).font(Theme.font(.footnote, weight: .semibold)).foregroundStyle(Color.secondaryText)
                }
            }
            .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12).padding(.vertical, 9)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Color.appPrimaryText.opacity(0.12), lineWidth: 1))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("pot-hint")
        .onAppear { AccessibilityNotification.Announcement("\(lines.title) \(lines.detail)").post() }
    }
}

/// The repot button: one line, 52pt, the accent fill (the shared `PrimaryButtonStyle` is untouched).
struct RepotButtonStyle: ButtonStyle {
    @Environment(\.repotReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.font(.headline, weight: .heavy))
            .foregroundStyle(Color.ink)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(Color.appAccent, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: Shed: Pots

/// The Shed's "Pots" grid below Tools (design-preview/pots, sections 3 and 6): sixteen cards, four a row up to Large,
/// two above, one a row (the pot beside its words) at the accessibility sizes (GridColumns), so every word stays whole.
/// Earned pots carry a check and "Yours to use" or who uses them; pots to earn show the goal and a gentle progress bar;
/// Plus pots show the tag. Nothing is locked or for sale here.
struct ShedPotsSection: View {
    let stats: PotCatalog.Stats
    let hasPlus: Bool
    /// The names of found plants sitting in a pot.
    let users: (Pot) -> [String]
    /// Records the pots earned by play; true when some were new, which shows "New pots in your shed!" this once.
    var record: () -> Bool = { false }
    /// A live seasonal pack's pots, in their own row under the sixteen.
    var packPots: [Pot] = []

    @State private var message: String?
    @State private var newPots = false
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        // The heading and its line side by side, stacked at the accessibility sizes (chosen from the size, not measured).
        let header = typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 2)) : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: 8))
        VStack(alignment: .leading, spacing: 8) {
            header { title; if !typeSize.isAccessibilitySize { Spacer(minLength: 8) }; sub }
            .padding(.top, 8)
            if newPots { PotNewLine() }
            grid(PotCatalog.all)
            if !packPots.isEmpty {
                PackRowTitle(name: PackCatalog.frostLantern.name)
                grid(packPots)
            }
            if let message {
                Text(message).font(Theme.font(.callout, weight: .semibold)).foregroundStyle(Color.appPrimaryText)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("shed-pot-hint")
            }
            Text(PotCatalog.Copy.shedFooter).font(Theme.font(.footnote)).foregroundStyle(Color.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("shed-pots-footer")
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

    /// The cards in an eager grid, so the cards in a row share one height.
    private func grid(_ pots: [Pot]) -> some View {
        let columns = GridColumns.count(.shedPots, for: typeSize)
        return Grid(horizontalSpacing: GridColumns.spacing(.shedPots), verticalSpacing: 8) {
            ForEach(GridColumns.rows(pots, .shedPots, for: typeSize), id: \.first?.id) { row in
                GridRow {
                    ForEach(row) { card($0) }
                    ForEach(0..<max(0, columns - row.count), id: \.self) { _ in
                        Color.clear.gridCellUnsizedAxes([.horizontal, .vertical])
                    }
                }
            }
        }
    }

    /// Who uses the pot, as VoiceOver hears it ("In use by Passionflower").
    private func useLine(_ names: [String]) -> String {
        switch names.count {
        case 0: return PotCatalog.Copy.yours
        case 1: return "In use by \(names[0])"
        default: return "In use by \(names.count) plants"
        }
    }

    /// The same on the card, except four a row: a plant's name does not fit a quarter of the row ("Passionflower"),
    /// so one plant reads "In use" there (VoiceOver still names it).
    private func cardUseLine(_ names: [String]) -> String {
        names.count == 1 && GridColumns.count(.shedPots, for: typeSize) == 4 ? PotCatalog.Copy.current : useLine(names)
    }

    private func card(_ pot: Pot) -> some View {
        let s = PotCatalog.state(of: pot, stats: stats, hasPlus: hasPlus)
        let progress = PotCatalog.progress(pot, stats: stats)
        let progressText = PotCatalog.progressLine(pot, stats: stats)
        let toEarn: Bool = { switch s { case .toEarn, .pack: return true; default: return false } }()
        let names = users(pot)
        let label: String = {
            switch s {
            case .owned: return "\(pot.voiceName) pot. \(useLine(names))"
            case .plus: return "\(pot.voiceName) pot, Plus. \(PotCatalog.Copy.plusCard)"
            case .pack: return "\(pot.voiceName) pot. \(PotCatalog.packLine(pot))"
            case .toEarn: return "\(pot.voiceName) pot, not earned yet. \(PotCatalog.goalLine(pot)). \(progressText)"
            }
        }()
        let row = GridColumns.isRow(.shedPots, for: typeSize)
        let words = VStack(alignment: row ? .leading : .center, spacing: 3) {
            Text(pot.name).font(Theme.font(.footnote, weight: .heavy)).foregroundStyle(Color.appPrimaryText)
                .multilineTextAlignment(row ? .leading : .center)
                .fixedSize(horizontal: false, vertical: true)
            switch s {
            case .owned:
                cardLine(cardUseLine(names), color: PotPalette.ok, leading: row)
            case .plus:
                cardLine(typeSize.isAccessibilitySize ? PotCatalog.Copy.plusCardShort : PotCatalog.Copy.plusCard,
                         color: Color.secondaryText, leading: row)
            case .pack:
                cardLine(PackCatalog.Copy.seasonsTitle, color: Color.secondaryText, leading: row)
            case .toEarn:
                cardLine(PotCatalog.goalLine(pot), color: Color.secondaryText, leading: row)
                ProgressView(value: progress?.fraction ?? 0).tint(PotPalette.ok).frame(maxWidth: row ? 140 : 70)
                cardLine(progressText, color: Color.secondaryText, small: true, leading: row)
            }
        }
        let art = PotArtView(pot: pot, style: toEarn ? .toEarn : .full, width: 60)
        return Button { message = tapLine(pot, s) } label: {
            Group {
                if row {
                    HStack(spacing: GridColumns.rowGap) {
                        art.frame(width: GridColumns.rowArt(.shedPots))
                        words.frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.leading, GridColumns.rowPadding).padding(.trailing, GridColumns.rowPadding + GridColumns.rowBadge)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                } else {
                    VStack(spacing: 3) {
                        art.padding(.top, 10)         // clears the check badge and Plus tag in the corner
                        words
                    }
                    .padding(.horizontal, GridColumns.cellPadding(.shedPots)).padding(.top, 8).padding(.bottom, 8)
                    .frame(maxWidth: .infinity, minHeight: 132, maxHeight: .infinity, alignment: .top)
                }
            }
            .background(toEarn ? Color.appSurface.opacity(0.55) : Color.appSurface, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
            .overlay(RoundedRectangle(cornerRadius: Theme.cardRadius).stroke(Color.appPrimaryText.opacity(toEarn ? 0.14 : 0.08), lineWidth: toEarn ? 1.5 : 1))
            .overlay(alignment: .topTrailing) {
                switch s {
                case .owned: PotCheckBadge(size: 20).padding(4)
                case .plus: PotPlusTag().padding(4)
                case .toEarn, .pack: EmptyView()
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

    private func cardLine(_ text: String, color: Color, small: Bool = false, leading: Bool = false) -> some View {
        Text(text).font(Theme.font(small ? .caption2 : .caption, weight: .bold)).foregroundStyle(color)
            .multilineTextAlignment(leading ? .leading : .center).fixedSize(horizontal: false, vertical: true)
    }

    private func tapLine(_ pot: Pot, _ s: PotState) -> String {
        switch s {
        case .owned: return pot.unlock == .free ? pot.hint : PotCatalog.Copy.earned
        case .plus: return "\(PotCatalog.plusLine(pot)) \(PotCatalog.Copy.plusSettings)"
        case .pack: return "\(PotCatalog.packLine(pot)) \(PotCatalog.packHint)"
        case .toEarn(let h): return "\(h) \(PotCatalog.tipLine(pot, stats: stats))"
        }
    }
}
