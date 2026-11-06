import SwiftUI

/// The butterfly game itself. It starts as soon as it opens (the Visitors page is its front door).
/// Calm mode: no time bar, slower visitors, and the round ends after 5 hellos or a tap on Done.
struct ButterflyView: View {
    @Environment(AppModel.self) private var app
    @Environment(GameRouter.self) private var router
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion

    @State private var game: ButterflyGameModel?
    @State private var summary: ButterflyRewards.Summary?
    @State private var swoosh: [CGPoint] = []
    @State private var popups: [Popup] = []
    @State private var newFriend: String?
    @State private var metThisRound: Set<String> = []
    @State private var lastTick = Date()
    private let ticker = Timer.publish(every: 1.0 / 30.0, on: .main, in: .common).autoconnect()

    struct Popup: Identifiable { let id = UUID(); var species: String; var at: CGPoint }

    private var reduceMotion: Bool { systemReduceMotion || app.settings.reduceMotionOverride }
    private var evening: Bool { VisitorSpawner.isEvening(.now, calendar: .current) }
    private var onSky: Color { evening ? .white : Color.ink }

    var body: some View {
        ZStack {
            background.ignoresSafeArea()
            if let game, summary == nil { scene(game) }
            if let summary { summaryCard(summary) }
        }
        .navigationTitle("Butterfly game")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if let game, game.calm, summary == nil {
                ToolbarItem(placement: .confirmationAction) {
                    Button(VisitorsCopy.done) { endNow() }.accessibilityIdentifier("calm-done")
                }
            }
        }
        .onAppear { if game == nil && summary == nil { start() } }
        .sensoryFeedback(.success, trigger: summary != nil) { _, ended in ended && app.settings.hapticsOn }
        .onReceive(ticker) { now in
            guard var g = game, summary == nil else { lastTick = now; return }
            // Real elapsed time, so a busy screen can never slow the game down; capped so a long pause isn't a jump.
            let dt = min(0.1, max(0, now.timeIntervalSince(lastTick)))
            lastTick = now
            g.tick(dt)
            game = g
            if g.isFinished { finish(g) }
        }
    }

    // MARK: Pieces

    private var background: some View {
        LinearGradient(colors: evening ? [Color(hex: 0x1F2A4A), Color(hex: 0x3A3F6B)] : [Color(hex: 0xBFE6F5), Color(hex: 0xE9F6E0)],
                       startPoint: .top, endPoint: .bottom)
            .overlay(alignment: .bottom) {
                ZStack(alignment: .bottom) {
                    Rectangle().fill(Color(hex: 0x4E9A55).opacity(0.85)).frame(height: 120)
                    // The player's own plants line the garden bed; flowering ones are what attract visitors.
                    HStack(spacing: -6) {
                        ForEach(app.plants().filter { $0.earnedCount > 0 }.prefix(6), id: \.plantId) { p in
                            Image(p.imageName).resizable().scaledToFit().frame(height: 74).accessibilityHidden(true)
                        }
                    }.padding(.bottom, 30)
                }
            }
    }

    private func scene(_ g: ButterflyGameModel) -> some View {
        GeometryReader { geo in
            ZStack {
                ForEach(g.visitors) { v in
                    Image(frame(for: v, elapsed: g.elapsed)).resizable().scaledToFit().frame(width: 64, height: 64)
                        .scaleEffect(x: v.vx < 0 ? -1 : 1, y: 1)
                        .position(x: v.x * geo.size.width, y: v.y * geo.size.height)
                        .accessibilityElement().accessibilityLabel(VisitorCatalog.species(v.speciesId)?.name ?? "Visitor")
                        .accessibilityAddTraits(.isButton)
                        .accessibilityAction { catchAt(CGPoint(x: v.x * geo.size.width, y: v.y * geo.size.height), in: geo.size) }
                }
                swooshPath
                ForEach(popups) { p in
                    VStack(spacing: 6) {
                        Image("visitor_\(p.species)_sticker").resizable().scaledToFit().frame(width: 72, height: 72)
                        Text(VisitorsCopy.caughtPill(VisitorCatalog.species(p.species)?.name ?? "Visitor"))
                            .font(Theme.font(.headline, weight: .bold)).foregroundStyle(Color.ink)
                            .padding(.horizontal, 14).padding(.vertical, 6)
                            .background(Color.white, in: Capsule()).shadow(color: .black.opacity(0.12), radius: 3, y: 1)
                    }
                    .position(x: min(max(p.at.x, 90), geo.size.width - 90), y: max(p.at.y, 70))
                    .transition(reduceMotion ? .opacity : .scale.combined(with: .opacity))
                    .accessibilityHidden(true)
                }
                VStack(spacing: 10) {
                    if g.showsTimeBar {
                        ProgressView(value: g.elapsed, total: ButterflyGameModel.duration).tint(Color.appAccent).padding(.horizontal, 24)
                            .accessibilityLabel("Game progress")
                    }
                    Spacer()
                    if let newFriend, let v = VisitorCatalog.species(newFriend) { newFriendCard(v) }
                    HStack {
                        Spacer()
                        Label(VisitorsCopy.saidHello(g.caught.count), systemImage: "hand.wave.fill")
                            .font(Theme.font(.headline, weight: .bold)).foregroundStyle(Color.ink)
                            .padding(.horizontal, 14).padding(.vertical, 8)
                            .background(Color.white.opacity(0.92), in: Capsule())
                            .accessibilityAddTraits(.updatesFrequently)
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.top, 8).padding(.bottom, 136)
            }
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0)
                .onChanged { value in
                    if !reduceMotion { swoosh.append(value.location); if swoosh.count > 14 { swoosh.removeFirst() } }
                    catchAt(value.location, in: geo.size)
                }
                .onEnded { _ in withAnimation(reduceMotion ? nil : .easeOut(duration: 0.25)) { swoosh.removeAll() } })
        }
    }

    private func newFriendCard(_ v: VisitorSpecies) -> some View {
        HStack(spacing: 14) {
            Image("visitor_\(v.id)_sticker").resizable().scaledToFit().frame(width: 52, height: 52).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(VisitorsCopy.newFriendTitle(v.name)).font(Theme.font(.headline, weight: .bold)).foregroundStyle(Color.ink)
                Text(VisitorsCopy.newFriendLine(v.rarity)).font(Theme.font(.subheadline)).foregroundStyle(Color.ink.opacity(0.85))
            }
            .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(Space.card)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 22))
        .shadow(color: .black.opacity(0.12), radius: 6, y: 2)
        .padding(.horizontal, 16)
        .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
        .accessibilityElement(children: .combine)
    }

    private var swooshPath: some View {
        Path { p in
            guard let first = swoosh.first else { return }
            p.move(to: first); swoosh.dropFirst().forEach { p.addLine(to: $0) }
        }
        .stroke(Color.white.opacity(0.75), style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round))
        .allowsHitTesting(false)
    }

    private func summaryCard(_ s: ButterflyRewards.Summary) -> some View {
        ZStack {
            Color.black.opacity(0.45).ignoresSafeArea()
            CelebrationBurst(requested: [.medium], origin: .fromTop(ScreenInsets.top + 80))     // petals behind the card
            ScrollView {
                VStack(spacing: 12) {
                    Text(VisitorsCopy.summaryTitle(friends: s.newStickerIds.count))
                        .font(Theme.font(.title2, weight: .bold)).foregroundStyle(Color.appPrimaryText).multilineTextAlignment(.center)
                        .accessibilityAddTraits(.isHeader)
                    if !s.newFriendIds.isEmpty {
                        Text(VisitorsCopy.newInAlbum(s.newFriendIds.count))
                            .font(Theme.font(.callout, weight: .semibold)).foregroundStyle(Color.successText).multilineTextAlignment(.center)
                    }
                    if !s.newStickerIds.isEmpty {
                        // Wraps into rows, so a big round (5 or more friends) never runs past the card.
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 84), spacing: 8)], spacing: 10) {
                            ForEach(s.newStickerIds, id: \.self) { id in
                                VStack(spacing: 2) {
                                    Image("visitor_\(id)_sticker").resizable().scaledToFit().frame(width: 60, height: 60).accessibilityHidden(true)
                                    Text(VisitorCatalog.species(id)?.name ?? "").font(Theme.font(.caption, weight: .semibold))
                                        .foregroundStyle(Color.appPrimaryText).multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                        if let fact = (s.newFriendIds + s.newStickerIds).compactMap({ VisitorCatalog.species($0)?.fact }).first {
                            Text(fact).font(Theme.font(.callout)).multilineTextAlignment(.center).foregroundStyle(Color.secondaryText)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    if !app.settings.quietGarden && (s.water + s.shedPoints + s.scoops) > 0 {
                        HStack(spacing: 14) {
                            if s.water > 0 { Label("\(s.water)", systemImage: "drop.fill").accessibilityLabel("\(s.water) water") }
                            if s.shedPoints > 0 { Label("\(s.shedPoints)", systemImage: "star.fill").accessibilityLabel(ShedCopy.points(s.shedPoints)) }
                            if s.scoops > 0 { Label("\(s.scoops)", systemImage: "shippingbox.fill").accessibilityLabel("\(s.scoops) soil") }
                        }.font(Theme.font(.headline)).foregroundStyle(Color.appPrimaryText)
                    }
                    Button("Play again") { summary = nil; game = nil; start() }.buttonStyle(PrimaryButtonStyle())
                    Button(VisitorsCopy.done) { router.back() }.buttonStyle(SecondaryButtonStyle())
                }
                .padding(20).background(Color.appBackground, in: RoundedRectangle(cornerRadius: 24)).padding(24)
            }.scrollBounceBehavior(.basedOnSize)
        }
    }

    // MARK: Actions

    private func frame(for v: ButterflyGameModel.Visitor, elapsed: Double) -> String {
        if v.resting { return "visitor_\(v.speciesId)_idle" }
        return "visitor_\(v.speciesId)_\(Int(elapsed * 4) % 2 == 0 ? "a" : "b")"
    }

    private func start() {
        game = app.startButterflyGame(reduceMotion: reduceMotion)
        lastTick = Date()
        summary = nil
        metThisRound = []
        newFriend = nil
    }

    private func catchAt(_ point: CGPoint, in size: CGSize) {
        guard var g = game, size.width > 0, size.height > 0 else { return }
        // The net tier sets the catch circle (48/64/80 pt); the model works in normalised coordinates.
        let radius = ToolEngine.netCatchRadius(tier: app.inventory.tier(of: .net)) / size.width
        guard let species = g.catchAt(x: point.x / size.width, y: point.y / size.height, radius: max(0.08, radius)) else { return }
        game = g
        app.play(.butterfly)
        let name = VisitorCatalog.species(species)?.name ?? "Visitor"
        let popup = Popup(species: species, at: point)
        withAnimation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.55)) { popups.append(popup) }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) { withAnimation { popups.removeAll { $0.id == popup.id } } }
        let isNew = app.album.count(of: species) == 0 && !metThisRound.contains(species)
        metThisRound.insert(species)
        if isNew {
            withAnimation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.8)) { newFriend = species }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) { if newFriend == species { withAnimation { newFriend = nil } } }
            AccessibilityNotification.Announcement("\(VisitorsCopy.newFriendTitle(name)). \(name) says hello").post()
        } else {
            AccessibilityNotification.Announcement("\(name) says hello").post()
        }
    }

    private func endNow() {
        guard var g = game, summary == nil else { return }
        g.finishNow()
        game = g
        finish(g)
    }

    private func finish(_ g: ButterflyGameModel) {
        guard summary == nil else { return }
        summary = app.finishButterflyGame(g)
        app.play(.earned)
        app.markPeakDismissed()
    }
}

// MARK: Visitors page

/// The Visitors page: friends met, a big "Say hello" card that starts the game, and the album right there.
/// Friends not met yet are soft outlines (never locks). A tap on a card opens it with a fun fact.
struct VisitorsView: View {
    @Environment(AppModel.self) private var app
    @Environment(GameRouter.self) private var router
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var detail: VisitorSpecies?

    /// Two cards a row, one at accessibility text sizes.
    private var albumColumns: Int { typeSize.isAccessibilitySize ? 1 : 2 }
    private var albumRows: [[VisitorSpecies]] {
        stride(from: 0, to: VisitorCatalog.all.count, by: albumColumns).map {
            Array(VisitorCatalog.all[$0 ..< min($0 + albumColumns, VisitorCatalog.all.count)])
        }
    }

    var body: some View {
        let album = app.album
        let total = VisitorCatalog.all.count
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                metCard(met: album.species, total: total)
                playCard
                infoRow
                Button { router.go(.visitorsBook) } label: { Label(EndgameCopy.visitorsBook, systemImage: "book.fill") }
                    .buttonStyle(SecondaryButtonStyle())
                    .accessibilityIdentifier("visitors.book")
                Text(VisitorsCopy.album.uppercased()).font(Theme.font(.footnote, weight: .heavy)).tracking(1.5)
                    .foregroundStyle(Color.secondaryText).padding(.top, 4).accessibilityAddTraits(.isHeader)
                    .accessibilityLabel(VisitorsCopy.album)
                // Twelve cards, laid out eagerly (not a lazy grid): every card stays measurable when large text pushes
                // it below the fold, which the Dynamic Type audit relies on.
                VStack(spacing: 12) {
                    ForEach(albumRows, id: \.first!.id) { row in
                        HStack(spacing: 12) {
                            ForEach(row, id: \.id) { v in albumCard(v, album: album) }
                            if row.count < albumColumns { Color.clear.frame(maxWidth: .infinity) }
                        }
                        .fixedSize(horizontal: false, vertical: true)     // both cards take the taller one's height
                    }
                }
            }
            .padding(.horizontal, Space.gutter).padding(.vertical, Space.card)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle(VisitorsCopy.title)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $detail) { v in VisitorDetailSheet(visitor: v).environment(app) }
    }

    private func metCard(met: Int, total: Int) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle().stroke(Color.tileVisitorsIcon.opacity(0.25), lineWidth: 9)
                Circle().trim(from: 0, to: CGFloat(met) / CGFloat(max(1, total)))
                    .stroke(Color.tileVisitorsIcon, style: StrokeStyle(lineWidth: 9, lineCap: .round)).rotationEffect(.degrees(-90))
            }
            .frame(width: 62, height: 62)
            // The number sits over the ring as its own text, so its contrast is judged against the card behind it,
            // not against the ring. The line beside it says the same, so VoiceOver skips it.
            .overlay { Text("\(met)").font(Theme.font(.title3, weight: .bold)).foregroundStyle(Color.appPrimaryText).accessibilityHidden(true) }
            VStack(alignment: .leading, spacing: 4) {
                Text(VisitorsCopy.friendsMet(met, of: total)).font(Theme.font(.title3, weight: .bold)).foregroundStyle(Color.appPrimaryText)
                Text(VisitorsCopy.moreFlowers).font(Theme.font(.subheadline)).foregroundStyle(Color.secondaryText)
            }
            .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(Space.card)
        .background(Color.tileVisitorsFill, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
        .overlay(RoundedRectangle(cornerRadius: Theme.cardRadius).stroke(Color.tileVisitorsIcon.opacity(0.3)))
        .accessibilityElement(children: .combine)
    }

    private var playCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 14) {
                    Image("visitor_monarch_a").resizable().scaledToFit().frame(width: 60, height: 60).accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(VisitorsCopy.playTitle).font(Theme.font(.title3, weight: .bold)).foregroundStyle(Color.appPrimaryText)
                        Text(app.settings.calmMode ? VisitorsCopy.playBlurbCalm : VisitorsCopy.playBlurb)
                            .font(Theme.font(.subheadline)).foregroundStyle(Color.secondaryText)
                    }
                    .fixedSize(horizontal: false, vertical: true)
                }
                Button(VisitorsCopy.sayHello) { router.go(.butterfly) }.buttonStyle(PrimaryButtonStyle())
            }
        }
    }

    private var infoRow: some View {
        let tier = app.inventory.tier(of: .net)
        let row = typeSize.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: 10)) : AnyLayout(HStackLayout(alignment: .top, spacing: 12))
        return row {
            mini("visitor_firefly_idle", VisitorsCopy.eveningTitle, VisitorsCopy.eveningTimes)
            mini("tool_net_t\(max(1, tier))", VisitorsCopy.netTitle(tier: tier), tier >= 3 ? VisitorsCopy.netFull : VisitorsCopy.netGrows)
        }
    }

    private func mini(_ image: String, _ title: String, _ line: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(image).resizable().scaledToFit().frame(width: 40, height: 40).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(Theme.font(.subheadline, weight: .bold)).foregroundStyle(Color.appPrimaryText)
                Text(line).font(Theme.font(.footnote)).foregroundStyle(Color.secondaryText)
            }
            .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private func albumCard(_ v: VisitorSpecies, album: StickerAlbum) -> some View {
        let count = album.count(of: v.id)
        let met = count > 0
        let seen = album.lastSeen(of: v.id).map { VisitorsCopy.seen($0, now: .now, calendar: .current) }
        let shape = RoundedRectangle(cornerRadius: Theme.cardRadius)
        return Button { detail = v } label: {
            VStack(spacing: 6) {
                VisitorSticker(id: v.id, met: met, size: 84)
                Text(met ? v.name : VisitorsCopy.notMet).font(Theme.font(.headline, weight: .bold))
                    .foregroundStyle(met ? Color.appPrimaryText : Color.secondaryText).multilineTextAlignment(.center)
                RarityChip(rarity: v.rarity)
                if met {
                    Text(VisitorsCopy.metCount(count)).font(Theme.font(.subheadline, weight: .semibold)).foregroundStyle(Color.successText)
                    if let seen { Text(seen).font(Theme.font(.caption)).foregroundStyle(Color.secondaryText) }
                } else {
                    Text(VisitorsCopy.notMetHint(nightOnly: v.nightOnly)).font(Theme.font(.caption)).foregroundStyle(Color.secondaryText)
                        .multilineTextAlignment(.center)
                }
            }
            .fixedSize(horizontal: false, vertical: true)
            .padding(Space.m).frame(maxWidth: .infinity, minHeight: 190, maxHeight: .infinity, alignment: .top)
            .background(met ? Color.appSurface : Color.appSurface.opacity(0.5), in: shape)
            .overlay {
                if met { shape.stroke(Color.appPrimaryText.opacity(0.08)) }
                else { shape.strokeBorder(Color.appPrimaryText.opacity(0.3), style: StrokeStyle(lineWidth: 1.5, dash: [5, 4])) }
            }
            .contentShape(shape)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(VisitorsCopy.cardLabel(name: v.name, rarity: v.rarity, met: count, seen: seen))
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier(met ? "visitor-\(v.id)" : "visitor-unmet-\(v.id)")
    }
}

/// A visitor's round sticker. Friends not met yet are a soft, pale outline of the same shape (no lock, no dark disc).
struct VisitorSticker: View {
    let id: String
    let met: Bool
    var size: CGFloat = 84

    var body: some View {
        Image("visitor_\(id)_sticker").resizable().scaledToFit().frame(width: size, height: size)
            .saturation(met ? 1 : 0)
            .opacity(met ? 1 : 0.32)
            .accessibilityHidden(true)
    }
}

struct RarityChip: View {
    let rarity: VisitorCatalog.Rarity

    private var tint: Color {
        switch rarity {
        case .common: return Color.successText
        case .uncommon: return Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: 0x9CC8F0) : UIColor(hex: 0x2D5F8F) })
        case .rare: return Color.tileVisitorsIcon
        }
    }

    var body: some View {
        Text(rarity.label).font(Theme.font(.caption, weight: .bold)).foregroundStyle(tint)
            .padding(.horizontal, 10).padding(.vertical, 3)
            .background(tint.opacity(0.14), in: Capsule())
            .fixedSize(horizontal: false, vertical: true)
            .multilineTextAlignment(.center)
    }
}

extension VisitorSpecies: Identifiable {}

/// A tap on an album card: the big sticker, how often it comes, how many times you met it, and its fun fact.
struct VisitorDetailSheet: View {
    let visitor: VisitorSpecies
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let count = app.album.count(of: visitor.id)
        let met = count > 0
        ScrollView {
            VStack(spacing: 12) {
                VisitorSticker(id: visitor.id, met: met, size: 150)
                Text(met ? visitor.name : VisitorsCopy.notMet).font(Theme.font(.title, weight: .bold)).foregroundStyle(Color.appPrimaryText)
                    .accessibilityAddTraits(.isHeader)
                RarityChip(rarity: visitor.rarity)
                if met {
                    Text(VisitorsCopy.metSentence(count)).font(Theme.font(.headline, weight: .semibold)).foregroundStyle(Color.successText)
                        .multilineTextAlignment(.center)
                } else {
                    Text(visitor.nightOnly ? VisitorsCopy.notMetHint(nightOnly: true) : VisitorsCopy.notMetDetail)
                        .font(Theme.font(.callout)).foregroundStyle(Color.secondaryText).multilineTextAlignment(.center)
                }
                if met, let fact = visitor.fact {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(VisitorsCopy.funFact.uppercased()).font(Theme.font(.caption, weight: .heavy)).tracking(1.2)
                            .foregroundStyle(Color.accentText).accessibilityLabel(VisitorsCopy.funFact)
                        Text(fact).font(Theme.font(.body)).foregroundStyle(Color.appPrimaryText)
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(16).frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.appSurface, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
                    .accessibilityElement(children: .combine)
                }
                Button(VisitorsCopy.done) { dismiss() }.buttonStyle(PrimaryButtonStyle()).padding(.top, 6)
            }
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 24).padding(.top, 28).padding(.bottom, 20)
        }
        .scrollBounceBehavior(.basedOnSize)
        .background(Color.appBackground.ignoresSafeArea())
        // Full height: a medium sheet floats and is drawn about 4% smaller, which shrinks its text below the size the
        // reader chose (the accessibility audit reports it as clipped).
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}
