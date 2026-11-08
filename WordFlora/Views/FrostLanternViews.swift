import SwiftUI

// Frost & Lantern's full pack on screen (G5): the snowy lantern scene behind Home and Garden, the scrim that keeps
// text readable over it, the glasshouse plants in My Garden, the winter friends in the album and the pack's contents
// on the Seasons page. The art doc's rules: decorative art is hidden from VoiceOver, text over the scene sits on a
// card or on `appBackground` at 60 % (never on the bare dark snow bank), and the scene is never darkened.

private struct WinterSceneOnKey: EnvironmentKey { static let defaultValue = false }

extension EnvironmentValues {
    /// True on a screen drawn over the snowy lantern scene, so loose text puts its scrim behind it.
    var winterSceneOn: Bool {
        get { self[WinterSceneOnKey.self] }
        set { self[WinterSceneOnKey.self] = newValue }
    }
}

extension View {
    /// The screen's background: the snowy lantern scene for Frost & Lantern owners, else the plain `appBackground`.
    func frostLanternBackground(_ on: Bool) -> some View {
        modifier(FrostLanternBackground(on: on))
    }

    /// Text that sits straight on the screen (not on a card): over the scene it gets the 60 % `appBackground` scrim
    /// with the card's corners. Off the scene nothing changes.
    func sceneScrim() -> some View { modifier(SceneScrim()) }
}

private struct FrostLanternBackground: ViewModifier {
    let on: Bool
    func body(content: Content) -> some View {
        content
            .environment(\.winterSceneOn, on)
            .background {
                if on { WinterSceneBackdrop().ignoresSafeArea() } else { Color.appBackground.ignoresSafeArea() }
            }
    }
}

private struct SceneScrim: ViewModifier {
    @Environment(\.winterSceneOn) private var on
    func body(content: Content) -> some View {
        if on {
            content
                .padding(.horizontal, Space.s).padding(.vertical, 4)
                .background(Color.appBackground.opacity(FrostLanternScene.scrimOpacity),
                            in: RoundedRectangle(cornerRadius: Theme.cardRadius))
        } else {
            content
        }
    }
}

/// The scene art (light and dark from one imageset), aspect-filled and anchored to the bottom so the snow bank, fence
/// and lanterns always show; the sky takes the crop. Gentle snow falls over it (not in Quiet Garden; Calm halves it;
/// Reduce Motion, the app's switch or Low Power Mode: one still frame; paused when the app is not active).
struct WinterSceneBackdrop: View {
    @Environment(AppModel.self) private var app
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var lowPower = LowPowerWatch()
    @State private var visible = false

    var body: some View {
        let calm = app.settings.calmMode
        GeometryReader { geo in
            let f = FrostLanternScene.frame(in: geo.size)
            ZStack(alignment: .topLeading) {
                Color.appBackground
                Image(FrostLanternScene.imageName).resizable()
                    .frame(width: f.width, height: f.height)
                    .offset(x: f.minX, y: f.minY)
                if FrostLanternScene.snows(quietGarden: app.settings.quietGarden) {
                    SnowfallView(count: Snowfall.count(base: FrostLanternScene.snowCount, calm: calm), calm: calm,
                                 still: reduceMotion || app.settings.reduceMotionOverride || lowPower.isOn,
                                 paused: !visible || scenePhase != .active)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
            .clipped()
        }
        .onAppear { visible = true }
        .onDisappear { visible = false }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .accessibilityIdentifier("winter.scene")
    }
}

/// My Garden's glasshouse shelf: the pack's winter plants, outside the levels. Each opens its plant page.
struct GlasshouseSection: View {
    let rows: [PlantCollectible]
    let open: (String) -> Void
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        if !rows.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(FrostLanternCopy.glasshouseTitle).font(Theme.font(.headline)).foregroundStyle(Color.appPrimaryText)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                    Text(FrostLanternCopy.glasshouseLine).font(Theme.font(.subheadline)).foregroundStyle(Color.appPrimaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .sceneScrim()
                let columns = GridColumns.count(.garden, for: typeSize)
                Grid(horizontalSpacing: GridColumns.spacing(.garden), verticalSpacing: Space.m) {
                    ForEach(Array(GridColumns.rows(rows, .garden, for: typeSize).enumerated()), id: \.offset) { _, row in
                        GridRow {
                            ForEach(row) { plant in
                                Button { open(plant.plantId) } label: { PlantCard(plant: plant, fillsHeight: true) }
                                    .buttonStyle(.plain)
                                    .accessibilityHint(FrostLanternCopy.glasshouseCardHint)
                                    .accessibilityIdentifier("glasshouse.\(plant.plantId)")
                            }
                            ForEach(0..<(columns - row.count), id: \.self) { _ in Color.clear.gridCellUnsizedAxes([.horizontal, .vertical]) }
                        }
                    }
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("garden.glasshouse")
        }
    }
}

/// The album's winter friends, under the twelve: shown while the pack is live (offered or owned) or once met.
/// Met: the full sticker. Not met: the album's soft outline, with "Say hello in the game" for owners or the pack pots'
/// "A grown-up can find this in Settings." for everyone else (no price, no lock, no buy button).
struct SeasonFriendsSection: View {
    let album: StickerAlbum
    let owned: Bool
    let live: Bool
    let columns: Int
    let open: (VisitorSpecies) -> Void

    static func shownFriends(album: StickerAlbum, live: Bool) -> [VisitorSpecies] {
        VisitorCatalog.season.filter { live || album.count(of: $0.id) > 0 }
    }

    var body: some View {
        let friends = Self.shownFriends(album: album, live: live)
        if !friends.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(FrostLanternCopy.seasonFriendsTitle.uppercased()).font(Theme.font(.footnote, weight: .heavy)).tracking(1.2)
                        .foregroundStyle(Color.secondaryText)
                        .accessibilityLabel(FrostLanternCopy.seasonFriendsTitle).accessibilityAddTraits(.isHeader)
                    Text(FrostLanternCopy.seasonFriendsLine).font(Theme.font(.footnote)).foregroundStyle(Color.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                let rows = stride(from: 0, to: friends.count, by: columns).map { Array(friends[$0 ..< min($0 + columns, friends.count)]) }
                VStack(spacing: 12) {
                    ForEach(rows, id: \.first!.id) { row in
                        HStack(spacing: 12) {
                            ForEach(row, id: \.id) { card($0) }
                            if row.count < columns { Color.clear.frame(maxWidth: .infinity) }
                        }
                        .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(.top, 4)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("visitors.winterFriends")
        }
    }

    private func card(_ v: VisitorSpecies) -> some View {
        let count = album.count(of: v.id)
        let met = count > 0
        let shape = RoundedRectangle(cornerRadius: Theme.cardRadius)
        let hint = owned ? FrostLanternCopy.seasonHintOwned : FrostLanternCopy.seasonHintNotOwned
        return Button { if met || owned { open(v) } } label: {
            VStack(spacing: 6) {
                VisitorSticker(id: v.id, met: met, size: 84)
                Text(met ? v.name : VisitorsCopy.notMet).font(Theme.font(.headline, weight: .bold))
                    .foregroundStyle(met ? Color.appPrimaryText : Color.secondaryText).multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                if met {
                    Text(VisitorsCopy.metCount(count)).font(Theme.font(.subheadline, weight: .semibold)).foregroundStyle(Color.successText)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text(hint).font(Theme.font(.caption)).foregroundStyle(Color.secondaryText)
                        .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(Space.m).frame(maxWidth: .infinity, minHeight: 170, maxHeight: .infinity, alignment: .top)
            .background(met ? Color.appSurface : Color.appSurface.opacity(0.5), in: shape)
            .overlay {
                if met { shape.stroke(Color.appPrimaryText.opacity(0.08)) }
                else { shape.strokeBorder(Color.appPrimaryText.opacity(PuzzleInk.blankOutline), style: StrokeStyle(lineWidth: 1.5, dash: [5, 4])) }
            }
            .contentShape(shape)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(met ? "\(FrostLanternCopy.stickerLabel(v.name, met: true)). \(VisitorsCopy.metCount(count))"
                                : "\(FrostLanternCopy.stickerLabel(v.name, met: false)). \(hint)")
        .accessibilityAddTraits(met || owned ? .isButton : [])
        .accessibilityIdentifier(met ? "visitor-\(v.id)" : "visitor-unmet-\(v.id)")
    }
}

/// The Seasons page: what the full pack holds besides its pots (a grown-up's view, behind the gate for young players).
struct PackHoldsList: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            row("leaf.fill", FrostLanternCopy.holdsPlants)
            row("bird.fill", FrostLanternCopy.holdsFriends)
            row("snowflake", FrostLanternCopy.holdsScene)
        }
    }

    private func row(_ symbol: String, _ text: String) -> some View {
        Label { Text(text).fixedSize(horizontal: false, vertical: true) } icon: { Image(systemName: symbol).accessibilityHidden(true) }
            .font(Theme.font(.callout, weight: .semibold)).foregroundStyle(Color.appPrimaryText)
            .accessibilityElement(children: .combine)
    }
}
