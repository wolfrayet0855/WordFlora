import SwiftUI

struct ButterflyView: View {
    @Environment(AppModel.self) private var app
    @Environment(GameRouter.self) private var router
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var game: ButterflyGameModel?
    @State private var summary: ButterflyRewards.Summary?
    @State private var swoosh: [CGPoint] = []
    @State private var popups: [Popup] = []
    @State private var useLantern = false
    @State private var showAlbum = false
    @State private var lastTick = Date()
    private let ticker = Timer.publish(every: 1.0 / 30.0, on: .main, in: .common).autoconnect()

    struct Popup: Identifiable { let id = UUID(); var species: String; var at: CGPoint }

    private var evening: Bool { VisitorSpawner.isEvening(.now, calendar: .current) }

    var body: some View {
        ZStack {
            background.ignoresSafeArea()
            if let game, summary == nil { scene(game) } else if summary == nil { intro }
            if let summary { summaryCard(summary) }
        }
        .navigationTitle("Butterfly game")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAlbum) { AlbumView().environment(app) }
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
        LinearGradient(colors: evening || useLantern ? [Color(hex: 0x1F2A4A), Color(hex: 0x3A3F6B)] : [Color(hex: 0xBFE6F5), Color(hex: 0xE9F6E0)],
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

    private var intro: some View {
        VStack(spacing: 16) {
            Image("tool_net_t\(max(1, app.inventory.tier(of: .net)))").resizable().scaledToFit().frame(height: 110).accessibilityHidden(true)
            Text("Meet your garden visitors").font(Theme.font(.title2, weight: .bold)).foregroundStyle(evening ? .white : Color.ink)
            Text(reduceMotion ? "Tap the visitors resting on the flowers. Every visit is a good one." : "Swipe the net across the visitors to say hello. Every visit is a good one.")
                .font(Theme.font(.callout)).multilineTextAlignment(.center).foregroundStyle(evening ? .white.opacity(0.85) : Color.ink.opacity(0.8))
            if (app.profile?.glowLanterns ?? 0) > 0 && !evening {
                Toggle("Use a Glow Lantern for night visitors", isOn: $useLantern).tint(Color.appAccent).padding(.horizontal, 8)
            }
            Button("Start") { start() }.buttonStyle(PrimaryButtonStyle())
            Button { showAlbum = true } label: { Label("Visitor album", systemImage: "book.fill") }.buttonStyle(SecondaryButtonStyle())
        }
        .padding(24)
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
                    Image("visitor_\(p.species)_sticker").resizable().scaledToFit().frame(width: 72, height: 72)
                        .position(p.at).transition(.scale.combined(with: .opacity))
                }
                VStack {
                    ProgressView(value: g.elapsed, total: ButterflyGameModel.duration).tint(Color.appAccent).padding(.horizontal, 24)
                        .accessibilityLabel("Game progress")
                    Spacer()
                }.padding(.top, 8)
            }
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0)
                .onChanged { value in
                    swoosh.append(value.location); if swoosh.count > 14 { swoosh.removeFirst() }
                    catchAt(value.location, in: geo.size)
                }
                .onEnded { _ in withAnimation(.easeOut(duration: 0.25)) { swoosh.removeAll() } })
        }
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
            ScrollView {
                VStack(spacing: 12) {
                    Text(s.newStickerIds.isEmpty ? "Thanks for visiting the garden" : "You met \(s.newStickerIds.count) visitor\(s.newStickerIds.count == 1 ? "" : "s")")
                        .font(Theme.font(.title2, weight: .bold)).multilineTextAlignment(.center)
                    if !s.newStickerIds.isEmpty {
                        HStack { ForEach(s.newStickerIds, id: \.self) { id in
                            VStack(spacing: 2) {
                                Image("visitor_\(id)_sticker").resizable().scaledToFit().frame(width: 64, height: 64)
                                Text(VisitorCatalog.species(id)?.name ?? "").font(Theme.font(.caption2))
                            }
                        } }
                        if let fact = s.newStickerIds.compactMap({ VisitorCatalog.species($0)?.fact }).first {
                            Text(fact).font(Theme.font(.callout)).multilineTextAlignment(.center).foregroundStyle(Color.appPrimaryText.opacity(0.85))
                        }
                    }
                    if !app.settings.quietGarden && (s.water + s.shedPoints + s.scoops) > 0 {
                        HStack(spacing: 14) {
                            if s.water > 0 { Label("\(s.water)", systemImage: "drop.fill") }
                            if s.shedPoints > 0 { Label("\(s.shedPoints)", systemImage: "star.fill") }
                            if s.scoops > 0 { Label("\(s.scoops)", systemImage: "shippingbox.fill") }
                        }.font(Theme.font(.headline)).foregroundStyle(Color.appPrimaryText)
                    }
                    Button("Play again") { summary = nil; game = nil; start() }.buttonStyle(PrimaryButtonStyle())
                    Button { showAlbum = true } label: { Label("Visitor album", systemImage: "book.fill") }.buttonStyle(SecondaryButtonStyle())
                    Button("Done") { router.back() }.frame(minHeight: Theme.minTap)
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
        game = app.startButterflyGame(useLantern: useLantern, reduceMotion: reduceMotion)
        lastTick = Date()
        summary = nil
    }

    private func catchAt(_ point: CGPoint, in size: CGSize) {
        guard var g = game, size.width > 0, size.height > 0 else { return }
        // radius is in width units; the model works in normalised coordinates
        let radius = 48 / size.width
        guard let species = g.catchAt(x: point.x / size.width, y: point.y / size.height, radius: max(0.08, radius)) else { return }
        game = g
        app.play(.butterfly)
        let popup = Popup(species: species, at: point)
        withAnimation(.spring(response: 0.3, dampingFraction: 0.55)) { popups.append(popup) }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) { withAnimation { popups.removeAll { $0.id == popup.id } } }
        AccessibilityNotification.Announcement("\(VisitorCatalog.species(species)?.name ?? "Visitor") says hello").post()
    }

    private func finish(_ g: ButterflyGameModel) {
        summary = app.finishButterflyGame(g)
        app.play(.earned)
        app.markPeakDismissed()
    }
}

struct AlbumView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 12)]

    var body: some View {
        let album = app.album
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(VisitorCatalog.all, id: \.id) { v in
                        let met = album.count(of: v.id) > 0
                        VStack(spacing: 6) {
                            Image("visitor_\(v.id)_sticker").resizable().scaledToFit().frame(height: 80)
                                .saturation(met ? 1 : 0).brightness(met ? 0 : -0.5).opacity(met ? 1 : 0.5).accessibilityHidden(true)
                            Text(met ? v.name : "Not met yet").font(Theme.font(.subheadline, weight: .bold)).foregroundStyle(Color.appPrimaryText)
                            if met, let fact = v.fact { Text(fact).font(Theme.font(.caption2)).multilineTextAlignment(.center).foregroundStyle(Color.appPrimaryText.opacity(0.75)) }
                            if !met && v.nightOnly { Text("Comes out in the evening").font(Theme.font(.caption2)).foregroundStyle(Color.appPrimaryText.opacity(0.6)) }
                        }
                        .padding(12).frame(maxWidth: .infinity, minHeight: 150)
                        .background(Color.appSurface, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(met ? "\(v.name), met \(album.count(of: v.id)) times" : "Visitor not met yet")
                    }
                }.padding(20)
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("Visitor album").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }
}
