import SwiftUI

/// The butterfly game itself. It starts as soon as it opens (the Visitors page is its front door).
/// The player holds a net (docs/pm/butterfly-net-spec.md): the hoop follows the finger with a soft lag and says hello to
/// visitors it sweeps over; every hello is a hello, not a capture, and the visitor always flies free.
/// Calm mode: no time bar, slower visitors, and the round ends after 5 hellos or a tap on Done.
/// Quick wings (13 and up, unless Easier butterflies is on): a little quicker visitors, a smaller hoop, a longer round.
/// Gentle Net: a visitor that lands on a flower can get a gentle hello.
struct ButterflyView: View {
    @Environment(AppModel.self) private var app
    @Environment(GameRouter.self) private var router
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOver
    @Environment(\.accessibilitySwitchControlEnabled) private var switchControl
    @Environment(\.colorScheme) private var colorScheme

    @State private var game: ButterflyGameModel?
    @State private var summary: ButterflyRewards.Summary?
    @State private var net = ButterflyNet(restPoint: .zero)
    @State private var finger: CGPoint?
    @State private var sceneSize: CGSize = .zero
    @State private var bottomInset: CGFloat = 0
    @State private var pillTop: CGFloat?
    @State private var popups: [Popup] = []
    @State private var ghosts: [Ghost] = []
    @State private var netLift: CGFloat = 0
    @State private var netDrop: CGFloat = 0
    @State private var pocket = false
    @State private var newFriend: String?
    @State private var metThisRound: Set<String> = []
    @State private var gentleThisRound: Set<String> = []
    @State private var showTip = false
    @State private var lastTick = Date()
    private let ticker = Timer.publish(every: 1.0 / 30.0, on: .main, in: .common).autoconnect()

    struct Popup: Identifiable { let id = UUID(); var species: String; var at: CGPoint; var gentle: Bool; var risen = false }
    /// The visitor's soft fold into the mesh and its flight out again (view only; it left the game at once).
    struct Ghost: Identifiable { let id = UUID(); var species: String; var at: CGPoint; var folded = false; var freed = false }

    private var reduceMotion: Bool { systemReduceMotion || app.settings.reduceMotionOverride }
    private var evening: Bool { VisitorSpawner.isEvening(.now, calendar: .current) }
    private var onSky: Color { evening ? .white : Color.ink }
    private var tier: Int { app.inventory.tier(of: .net) }
    private func radius(_ g: ButterflyGameModel) -> Double { g.pace.netRadius(tier: tier) }
    /// The garden bed's plants (the flowering ones are what attract visitors); landed visitors rest on them.
    private var bedPlants: [PlantCollectible] { Array(app.plants().filter { $0.earnedCount > 0 }.prefix(6)) }

    var body: some View {
        ZStack {
            background.ignoresSafeArea()
            if let game, summary == nil { scene(game) }
            if let summary { summaryCard(summary) }
        }
        .navigationTitle("Butterfly game")
        .navigationBarTitleDisplayMode(.inline)
        // The bar is solid in the app's own scheme: in dark mode the system title is white, so it gets the evening sky's
        // navy behind it instead of the pale day sky (white on pale blue failed the contrast audit).
        // On the evening sky the bar is navy in light mode too, with the dark bar's white title (a near-black title on
        // navy was about 2:1).
        .toolbarBackground(colorScheme == .dark || evening ? Color(hex: 0x1F2A4A) : Color(hex: 0xBFE6F5), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(evening ? .dark : nil, for: .navigationBar)
        .toolbar {
            if let game, game.calm, summary == nil {
                ToolbarItem(placement: .confirmationAction) {
                    Button(VisitorsCopy.done) { endNow() }.accessibilityIdentifier("calm-done")
                }
            }
        }
        .onAppear { if game == nil && summary == nil { start() } }
        .sensoryFeedback(.success, trigger: summary != nil) { _, ended in ended && app.settings.hapticsOn }
        .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.6), trigger: game?.caught.count ?? 0) { old, new in
            new > old && app.settings.hapticsOn
        }
        .onReceive(ticker) { now in
            guard var g = game, summary == nil else { lastTick = now; return }
            // Real elapsed time, so a busy screen can never slow the game down; capped so a long pause isn't a jump.
            let dt = min(0.1, max(0, now.timeIntervalSince(lastTick)))
            lastTick = now
            g.tick(dt)
            game = g
            if let swept = net.step(dt, reduceMotion: reduceMotion) { sweep(from: swept.from, to: swept.to) }
            if let g = game {
                maybeShowTip(g)
                if g.isFinished { finish(g) }
            }
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
                        ForEach(bedPlants, id: \.plantId) { p in
                            Image(p.imageName).resizable().scaledToFit().frame(height: 74).accessibilityHidden(true)
                        }
                    }.padding(.bottom, 30)
                }
            }
    }

    private func scene(_ g: ButterflyGameModel) -> some View {
        GeometryReader { geo in
            ZStack {
                // A soft halo under each resting visitor, so a child can see "this one is resting".
                ForEach(g.visitors.filter(\.resting)) { v in
                    RestingHalo(breathing: !reduceMotion)
                        .position(x: v.x * geo.size.width, y: v.y * geo.size.height + 22)
                }
                ForEach(g.visitors) { v in visitor(v, g: g, size: geo.size) }
                ForEach(ghosts) { ghost in
                    Image("visitor_\(ghost.species)_idle").resizable().scaledToFit().frame(width: 64, height: 64)
                        .scaleEffect(ghost.folded && !ghost.freed ? 0.45 : (ghost.freed ? 0.6 : 1))
                        .opacity(ghost.freed ? 0 : 1)
                        .position(ghost.at)
                        .allowsHitTesting(false).accessibilityHidden(true)
                }
                if let g = game {
                    let r = radius(g)
                    ButterflyNetCanvas(center: net.position, radius: r, tier: tier, evening: evening,
                                       handleRight: ButterflyNet.handlePointsRight(hoopX: net.position.x, sceneWidth: geo.size.width),
                                       handleScale: tier <= 1 && g.pace == .quickWings ? 0.9 : 1.1, pocket: pocket)
                        .offset(y: netLift + netDrop)
                        .opacity(net.isDown ? 1 : ButterflyNet.restingOpacity)
                        .shadow(color: .black.opacity(net.isDown ? 0 : 0.12), radius: 3)
                }
                ForEach(popups) { p in popup(p, size: geo.size) }
                VStack(spacing: 10) {
                    if g.showsTimeBar {
                        // The bar is 4 pt tall; its accessibility frame is 44 pt (the hit area check), and the negative
                        // padding keeps the layout where it was.
                        let done = min(g.elapsed, g.roundSeconds) / g.roundSeconds
                        Color.clear.frame(height: 44)
                            .overlay { ProgressView(value: done).tint(Color.appAccent).accessibilityHidden(true) }
                            .padding(.vertical, -20).padding(.horizontal, 24)
                            .accessibilityElement()
                            .accessibilityLabel("Game progress")
                            .accessibilityValue("\(Int((done * 100).rounded())) percent")
                            .accessibilityAddTraits(.updatesFrequently)
                            .accessibilityIdentifier("butterfly.progress")
                    }
                    if showTip {
                        Text(GentleNetCopy.tip).font(Theme.font(.subheadline, weight: .semibold)).foregroundStyle(Color.ink)
                            .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal, 14).padding(.vertical, 8)
                            .background(Color.white.opacity(0.92), in: Capsule())
                            .padding(.horizontal, 24)
                            .transition(.opacity)
                            .accessibilityIdentifier("butterfly.gentleTip")
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
                            .onGeometryChange(for: CGFloat.self) { $0.frame(in: .named("butterflyScene")).minY } action: { top in
                                pillTop = top; placeRest()
                            }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.top, 8).padding(.bottom, 136)
            }
            .coordinateSpace(name: "butterflyScene")
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0)
                .onChanged { value in
                    finger = value.location
                    if !net.isDown {
                        let s = net.touchDown(at: value.location)      // a scoop: the hoop jumps under the finger
                        sweep(from: s.from, to: s.to)
                    } else {
                        net.drag(to: value.location)
                        // The gentle game also tests every finger sample with today's area, so no catch that worked
                        // before can fail now. Quick wings tests the hoop's sweep on each tick only.
                        if game?.pace != .quickWings { sweep(from: net.position, to: net.position) }
                    }
                }
                .onEnded { _ in net.lift(); finger = nil; placeRest() })
            .accessibilityElement(children: .contain)
            .accessibilityLabel(VisitorsCopy.sceneLabel)
            .accessibilityIdentifier("butterfly.scene.\(g.pace.rawValue)")
            .accessibilityAction(named: VisitorsCopy.swingAction) { swingToNearest() }
            .onAppear { configure(geo) }
            .onChange(of: geo.size) { configure(geo) }
        }
    }

    private func visitor(_ v: ButterflyGameModel.Visitor, g: ButterflyGameModel, size: CGSize) -> some View {
        let name = VisitorCatalog.species(v.speciesId)?.name ?? "Visitor"
        return Image(frame(for: v, elapsed: g.elapsed)).resizable().scaledToFit().frame(width: 64, height: 64)
            .scaleEffect(x: v.vx < 0 ? -1 : 1, y: 1)
            .position(x: v.x * size.width, y: v.y * size.height)
            .accessibilityElement()
            .accessibilityLabel(v.resting ? GentleNetCopy.restingLabel(name: name) : VisitorsCopy.flyingLabel(name))
            .accessibilityHint(v.resting ? GentleNetCopy.restingHint : VisitorsCopy.netHint)
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { helloTo(v.id) }
    }

    @ViewBuilder
    private func popup(_ p: Popup, size: CGSize) -> some View {
        VStack(spacing: 6) {
            Image("visitor_\(p.species)_sticker").resizable().scaledToFit().frame(width: 72, height: 72)
                .overlay(alignment: .topTrailing) { if p.gentle { GentleHeart(size: 26).offset(x: 6, y: -4) } }
            if p.gentle {
                GentleHelloPill()
            } else {
                Text(VisitorsCopy.caughtPill(VisitorCatalog.species(p.species)?.name ?? "Visitor"))
                    .font(Theme.font(.headline, weight: .bold)).foregroundStyle(Color.ink)
                    .padding(.horizontal, 14).padding(.vertical, 6)
                    .background(Color.white, in: Capsule()).shadow(color: .black.opacity(0.12), radius: 3, y: 1)
            }
        }
        .offset(y: p.risen ? -24 : 0)
        // Inside the scene: never under the bar, never down on the garden bed.
        .position(x: min(max(p.at.x, 100), size.width - 100), y: min(max(p.at.y, 90), size.height - 150))
        .transition(reduceMotion ? .opacity : .scale.combined(with: .opacity))
        .allowsHitTesting(false)
        .accessibilityHidden(true)
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
                    // Gentle Net: not shown at 0, and never in Quiet Garden (the summary's count is 0 there).
                    if s.gentleHellos > 0 {
                        Text(GentleNetCopy.summary(s.gentleHellos))
                            .font(Theme.font(.callout, weight: .semibold)).foregroundStyle(Color.appPrimaryText).multilineTextAlignment(.center)
                            .accessibilityIdentifier("butterfly.summary.gentle")
                    }
                    if !s.newStickerIds.isEmpty {
                        // Wraps into rows, so a big round (5 or more friends) never runs past the card.
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 84), spacing: 8)], spacing: 10) {
                            ForEach(s.newStickerIds, id: \.self) { id in
                                let name = VisitorCatalog.species(id)?.name ?? ""
                                let gentle = gentleThisRound.contains(id)
                                VStack(spacing: 2) {
                                    Image("visitor_\(id)_sticker").resizable().scaledToFit().frame(width: 60, height: 60).accessibilityHidden(true)
                                        .overlay(alignment: .topTrailing) { if gentle { GentleHeart(size: 24).offset(x: 6, y: -4) } }
                                    Text(name).font(Theme.font(.caption, weight: .semibold))
                                        .foregroundStyle(Color.appPrimaryText).multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                                }
                                .accessibilityElement(children: .ignore)
                                .accessibilityLabel(gentle ? "\(name), \(GentleNetCopy.heartLabel)" : name)
                            }
                        }
                        if let fact = (s.newFriendIds + s.newStickerIds).compactMap({ VisitorCatalog.species($0)?.fact }).first {
                            Text(fact).font(Theme.font(.callout)).multilineTextAlignment(.center).foregroundStyle(Color.secondaryText)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    if !app.settings.quietGarden && (s.water + s.shedPoints + s.scoops) > 0 {
                        // In words ("1 water · 6 shed points · 1 soil"), not bare icons and numbers.
                        Text([s.water > 0 ? "\(s.water) water" : nil, s.shedPoints > 0 ? ShedCopy.points(s.shedPoints) : nil,
                              s.scoops > 0 ? "\(s.scoops) soil" : nil].compactMap { $0 }.joined(separator: " · "))
                            .font(Theme.font(.footnote, weight: .semibold)).foregroundStyle(Color.appPrimaryText)
                            .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                            .accessibilityIdentifier("butterfly.summary.rewards")
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
        if v.showsIdle { return "visitor_\(v.speciesId)_idle" }
        return "visitor_\(v.speciesId)_\(Int(elapsed * 4) % 2 == 0 ? "a" : "b")"
    }

    private func start() {
        game = app.startButterflyGame(reduceMotion: reduceMotion, voiceOver: voiceOver, switchControl: switchControl)
        lastTick = Date()
        summary = nil
        metThisRound = []
        gentleThisRound = []
        newFriend = nil
        ghosts = []
        showTip = false
        if sceneSize != .zero { tellGameTheScene() }
    }

    /// The scene's size, its flowers and where landed visitors sit, and the net's rest point.
    private func configure(_ geo: GeometryProxy) {
        sceneSize = geo.size
        bottomInset = geo.safeAreaInsets.bottom
        tellGameTheScene()
        placeRest()
    }

    private func tellGameTheScene() {
        guard sceneSize.width > 0, sceneSize.height > 0 else { return }
        // Bed plants are 74 pt tall, 30 pt above the screen's bottom edge; a landed visitor sits on top of them.
        let perchY = Double((sceneSize.height + bottomInset - 90) / sceneSize.height)
        game?.setScene(size: sceneSize, perchSpots: ButterflyNet.flowerSpots(count: bedPlants.count, sceneWidth: Double(sceneSize.width)),
                       perchY: perchY)
    }

    private func placeRest() {
        guard let g = game, sceneSize.width > 0 else { return }
        let rest = ButterflyNet.restPoint(scene: sceneSize, radius: radius(g), pillTop: pillTop.map { Double($0) }, lastLift: net.lastLift)
        let first = net.restPoint == .zero
        net.restPoint = rest
        if first || reduceMotion { if !net.isDown { net.position = rest; net.target = rest } }
    }

    private func sweep(from a: CGPoint, to b: CGPoint) {
        guard var g = game, sceneSize.width > 0 else { return }
        let hellos = g.catchSwept(from: a, to: b, finger: finger, scene: sceneSize, radius: radius(g))
        guard !hellos.isEmpty else { return }
        game = g
        for h in hellos { greet(h, hoop: net.position) }
    }

    /// VoiceOver (and any assistive tap): the net swings to this visitor and says hello. No aiming needed.
    private func helloTo(_ id: Int) {
        guard var g = game, let h = g.sayHello(toVisitor: id) else { return }
        game = g
        let p = CGPoint(x: h.x * sceneSize.width, y: h.y * sceneSize.height)
        if !reduceMotion { net.position = p }
        greet(h, hoop: p)
        if !reduceMotion { DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) { placeRest(); if !net.isDown { net.target = net.restPoint } } }
    }

    /// Switch Control's "Swing the net": a hello to the visitor nearest the net's rest point.
    private func swingToNearest() {
        guard let g = game, sceneSize.width > 0 else { return }
        let rx = Double(net.restPoint.x), ry = Double(net.restPoint.y), w = Double(sceneSize.width), h = Double(sceneSize.height)
        func away(_ v: ButterflyGameModel.Visitor) -> Double { hypot(v.x * w - rx, v.y * h - ry) }
        let nearest = g.visitors.min { away($0) < away($1) }
        if let nearest { helloTo(nearest.id) }
    }

    private func greet(_ h: ButterflyGameModel.Hello, hoop: CGPoint) {
        let species = h.speciesId
        app.play(.butterfly, volume: h.gentle ? 0.7 : 1)
        if h.gentle { gentleThisRound.insert(species) }
        let name = VisitorCatalog.species(species)?.name ?? "Visitor"
        let at = CGPoint(x: h.x * sceneSize.width, y: h.y * sceneSize.height)
        let popup = Popup(species: species, at: at, gentle: h.gentle)
        withAnimation(reduceMotion ? .easeInOut(duration: 0.25) : .spring(response: 0.3, dampingFraction: 0.55)) { popups.append(popup) }
        if h.gentle && !reduceMotion {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                withAnimation(.easeOut(duration: 1.2)) { if let i = popups.firstIndex(where: { $0.id == popup.id }) { popups[i].risen = true } }
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + (h.gentle ? 1.6 : 1.3)) {
            withAnimation(.easeOut(duration: h.gentle ? 0.4 : 0.3)) { popups.removeAll { $0.id == popup.id } }
        }
        if !reduceMotion { foldAndFree(species, from: at, hoop: hoop, gentle: h.gentle) }
        let isNew = app.album.count(of: species) == 0 && !metThisRound.contains(species)
        metThisRound.insert(species)
        if isNew {
            withAnimation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.8)) { newFriend = species }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) { if newFriend == species { withAnimation { newFriend = nil } } }
        }
        let line = h.gentle ? GentleNetCopy.announcement(name: name) : "\(name) says hello"
        AccessibilityNotification.Announcement(isNew ? "\(VisitorsCopy.newFriendTitle(name)). \(line)" : line).post()
    }

    /// Fold (0.25 s), lift (0.2 s), free (0.5 s). A gentle hello first lowers the net softly onto the flower.
    private func foldAndFree(_ species: String, from at: CGPoint, hoop: CGPoint, gentle: Bool) {
        if gentle {
            netDrop = -28
            withAnimation(.easeOut(duration: 0.35)) { netDrop = 0 }
        }
        let ghost = Ghost(species: species, at: at)
        ghosts.append(ghost)
        DispatchQueue.main.async {
            withAnimation(.easeIn(duration: 0.25)) {
                pocket = true
                if let i = ghosts.firstIndex(where: { $0.id == ghost.id }) { ghosts[i].at = hoop; ghosts[i].folded = true }
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            pocket = false
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) { netLift = -12 }
            withAnimation(.easeOut(duration: 0.5)) {
                if let i = ghosts.firstIndex(where: { $0.id == ghost.id }) { ghosts[i].freed = true; ghosts[i].at.y -= 70 }
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) { netLift = 0 } }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { ghosts.removeAll { $0.id == ghost.id } }
    }

    /// The first time any visitor rests, a small tip under the sky for 4 s (once per device).
    private func maybeShowTip(_ g: ButterflyGameModel) {
        guard !app.settings.gentleNetTipShown, g.visitors.contains(where: \.resting) else { return }
        app.settings.gentleNetTipShown = true
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.3)) { showTip = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) { withAnimation(.easeInOut(duration: 0.3)) { showTip = false } }
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
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOver
    @Environment(\.accessibilitySwitchControlEnabled) private var switchControl
    @State private var detail: VisitorSpecies?

    /// Two cards a row, one at accessibility text sizes.
    /// The count ring grows with its number, so "12" stays inside it at every text size.
    @ScaledMetric(relativeTo: .title3) private var ring: CGFloat = 62
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
                Text(VisitorsCopy.album.uppercased()).font(Theme.font(.footnote, weight: .heavy)).tracking(1.2)
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
                // Frost & Lantern's winter friends, after the twelve (never part of the count above).
                SeasonFriendsSection(album: album, owned: app.ownedPacks.contains(PackCatalog.frostLanternId),
                                     live: app.entitlements.packIsLive(PackCatalog.frostLanternId), columns: albumColumns) { detail = $0 }
            }
            .padding(.horizontal, Space.gutter).padding(.vertical, Space.card)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle(VisitorsCopy.title)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $detail) { v in VisitorDetailSheet(visitor: v).environment(app) }
        .onAppear { app.recordQuest(.visitedVisitors) }
    }

    private func metCard(met: Int, total: Int) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle().stroke(Color.tileVisitorsIcon.opacity(0.25), lineWidth: 9)
                Circle().trim(from: 0, to: CGFloat(met) / CGFloat(max(1, total)))
                    .stroke(Color.tileVisitorsIcon, style: StrokeStyle(lineWidth: 9, lineCap: .round)).rotationEffect(.degrees(-90))
            }
            .frame(width: ring, height: ring)
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

    /// The pace the next round would have (the chip and blurb say what it will be like).
    private var pace: ButterflyPace {
        app.butterflyPace(reduceMotion: systemReduceMotion || app.settings.reduceMotionOverride, voiceOver: voiceOver, switchControl: switchControl)
    }

    private var playBlurb: String {
        switch pace {
        case .calm: return VisitorsCopy.playBlurbCalm
        case .quickWings: return VisitorsCopy.playBlurbQuick
        case .gentle: return VisitorsCopy.playBlurb
        }
    }

    private var playCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 14) {
                // The monarch beside the words, above them at the accessibility sizes so the words get the card's
                // whole width ("Hummingbird" broke beside it at AX4 and AX5).
                let imageRow = typeSize.isAccessibilitySize
                    ? AnyLayout(VStackLayout(alignment: .leading, spacing: 10)) : AnyLayout(HStackLayout(alignment: .top, spacing: 14))
                imageRow {
                    Image("visitor_monarch_a").resizable().scaledToFit().frame(width: 60, height: 60).accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 4) {
                        // The Quick wings chip sits beside the title, and under it at accessibility text sizes.
                        let titleRow = typeSize.isAccessibilitySize
                            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 6)) : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: 8))
                        titleRow {
                            Text(VisitorsCopy.playTitle).font(Theme.font(.title3, weight: .bold)).foregroundStyle(Color.appPrimaryText)
                            if pace == .quickWings { QuickWingsChip() }
                        }
                        // Easier butterflies, right by the chip: 13 and up with Calm off (under 13 never sees it). It
                        // stays shown while on, so the gentle game can be switched back to Quick wings here too.
                        if ButterflyPace.offersEasierSwitch(ageBand: app.settings.ageBand, calmMode: app.settings.calmMode) {
                            easierSwitch
                        }
                        Text(playBlurb)
                            .font(Theme.font(.subheadline)).foregroundStyle(Color.secondaryText)
                        // Friend of the day: a suggestion only, hidden in Quiet Garden.
                        if !app.settings.quietGarden {
                            let friend = VisitorSpawner.friendOfTheDay(seed: app.profile?.weatherSeed ?? 0, day: app.weatherToday)
                            Text(VisitorsCopy.friendOfTheDay(friend.name))
                                .font(Theme.font(.subheadline, weight: .semibold)).foregroundStyle(Color.appPrimaryText)
                                .fixedSize(horizontal: false, vertical: true)
                                .accessibilityIdentifier("visitors.friendOfTheDay")
                        }
                    }
                    .fixedSize(horizontal: false, vertical: true)
                }
                Button(VisitorsCopy.sayHello) { router.go(.butterfly) }.buttonStyle(PrimaryButtonStyle())
            }
        }
    }

    /// The switch row, then its note; both use text styles and wrap. At the accessibility sizes the words take their own
    /// line and the switch sits under them (beside a switch "butterflies" broke from AX3).
    private var easierSwitch: some View {
        @Bindable var s = app.settings
        let label = Text(VisitorsCopy.easierToggle).font(Theme.font(.subheadline, weight: .semibold)).foregroundStyle(Color.appPrimaryText)
            .fixedSize(horizontal: false, vertical: true)
        return VStack(alignment: .leading, spacing: 4) {
            if typeSize.isAccessibilitySize {
                label
                Toggle(VisitorsCopy.easierToggle, isOn: $s.easierButterflies)
                    .labelsHidden()
                    .accessibilityLabel(VisitorsCopy.easierToggle)
                    .tint(Color.successText)
                    .accessibilityIdentifier("visitors.easierButterflies")
            } else {
                Toggle(isOn: $s.easierButterflies) { label }
                    .tint(Color.successText)
                    .accessibilityIdentifier("visitors.easierButterflies")
            }
            Text(VisitorsCopy.easierFootnote).font(Theme.font(.footnote)).foregroundStyle(Color.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("visitors.easierButterfliesNote")
        }
        .padding(.top, 4)
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
                else { shape.strokeBorder(Color.appPrimaryText.opacity(PuzzleInk.blankOutline), style: StrokeStyle(lineWidth: 1.5, dash: [5, 4])) }
            }
            .contentShape(shape)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(VisitorsCopy.cardLabel(name: v.name, rarity: v.rarity, met: count, seen: seen, nightOnly: v.nightOnly))
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
            .background(tint.opacity(0.06), in: Capsule())      // a light wash keeps "Often seen" above 4.5:1
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
    @Environment(\.dynamicTypeSize) private var typeSize

    /// The title a step smaller only at AX5 (title3 there is still larger than title at AX4, so the text never shrinks as
    /// the size grows, which the audit reads as Dynamic Type unsupported), and the sides tighter at the accessibility
    /// sizes, so "Hummingbird" stays whole.
    static func titleStyle(_ size: DynamicTypeSize) -> Font.TextStyle { size >= .accessibility5 ? .title3 : .title }
    static func sidePadding(_ size: DynamicTypeSize) -> CGFloat { size.isAccessibilitySize ? 12 : 24 }

    var body: some View {
        let count = app.album.count(of: visitor.id)
        let met = count > 0
        ScrollView {
            VStack(spacing: 12) {
                VisitorSticker(id: visitor.id, met: met, size: 150)
                Text(met ? visitor.name : VisitorsCopy.notMet).font(Theme.font(Self.titleStyle(typeSize), weight: .bold))
                    .foregroundStyle(Color.appPrimaryText).multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
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
            .padding(.horizontal, Self.sidePadding(typeSize)).padding(.top, 28).padding(.bottom, 20)
        }
        .scrollBounceBehavior(.basedOnSize)
        .background(Color.appBackground.ignoresSafeArea())
        // Full height: a medium sheet floats and is drawn about 4% smaller, which shrinks its text below the size the
        // reader chose (the accessibility audit reports it as clipped).
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}
