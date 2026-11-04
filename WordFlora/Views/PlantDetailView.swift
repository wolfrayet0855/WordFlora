import SwiftUI
import TipKit
import SwiftData

/// The plant's page: the plant in the centre (drawn from its layered art at its love petal count), the love petal
/// row under it, rain and gentle thunder after a day with no love, the seed pot when it rests, and the Life panel
/// at the left edge (a sheet with pinned actions at accessibility text sizes). Approved design:
/// design-preview/tending/lifestats.html (option B petal row).
struct PlantDetailView: View {
    let plantId: String

    @Environment(AppModel.self) private var app
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("lifePanelHidden") private var panelHidden = false
    @AccessibilityFocusState private var focus: PanelFocus?
    @State private var toast: String?
    @State private var sway = 0.0
    @State private var hellos = 0
    @State private var showRepot = false
    @State private var renaming = false
    @State private var draftName = ""
    @State private var bump = false
    @State private var aiText: String?
    @State private var aiBusy = false
    @State private var showWake = false      // Wake the seed (see the marked block below)
    @State private var flash = 0.0
    @State private var stageVisible = true
    @State private var lowPower = LowPowerWatch()

    private enum PanelFocus: Hashable { case show, hide }

    private var plant: PlantCollectible? { app.plants().first { $0.plantId == plantId } }
    private var large: Bool { typeSize.isAccessibilitySize }

    var body: some View {
        Group {
            if let plant { content(plant) } else { ComingSoonView(title: "Plant") }
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle(plant.map(displayName) ?? "Plant")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func displayName(_ plant: PlantCollectible) -> String { plant.nickname.isEmpty ? plant.name : plant.nickname }

    private func snapshot(_ plant: PlantCollectible) -> LifeStats.Snapshot {
        LifeStats.snapshot(.init(plant: plant, now: .now, calendar: .current, exempt: app.settings.quietGarden || app.settings.calmMode))
    }

    @ViewBuilder private func content(_ plant: PlantCollectible) -> some View {
        let snap = snapshot(plant)
        Group {
            if large { largeLayout(plant, snap) } else { standardLayout(plant, snap) }
        }
        .overlay {
            Color.white.opacity(flash).ignoresSafeArea().allowsHitTesting(false).accessibilityHidden(true)
        }
        .background {
            ThunderDriver(active: LifeStats.weather(day: snap.rainDay).thunder && !reduceMotion && stageVisible
                                  && scenePhase == .active && !lowPower.isOn,
                          dark: colorScheme == .dark, haptics: app.settings.hapticsOn, flash: $flash)
        }
        .overlay(alignment: .bottom) { toastView }
        .sheet(isPresented: $showRepot) { repotSheet(plant).presentationDetents([.medium]) }
        .sheet(isPresented: $showWake) { WakeSheet(plant: plant).environment(app) }   // Wake the seed
        .alert("Name your plant", isPresented: $renaming) {
            TextField("Name", text: $draftName)
            Button("Save") { plant.nickname = String(draftName.prefix(16)); try? app.context.save() }
            Button("Cancel", role: .cancel) {}
        }
    }

    // MARK: Layouts

    private func standardLayout(_ plant: PlantCollectible, _ snap: LifeStats.Snapshot) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                ZStack(alignment: .topLeading) {
                    stage(plant, snap, plantSize: 220, plantTop: 92, cloudTop: 4)
                    panel(snap)
                }
                VStack(spacing: 16) {
                    nameBlock(plant, snap)
                    details(plant, includeActions: true)
                }
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 20)
        }
    }

    private func largeLayout(_ plant: PlantCollectible, _ snap: LifeStats.Snapshot) -> some View {
        VStack(spacing: 0) {
            stage(plant, snap, plantSize: 132, plantTop: 52, cloudTop: 0)
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    LifeSheet(snapshot: snap, collapsed: panelHidden) { togglePanel() }
                    nameBlock(plant, snap).frame(maxWidth: .infinity)
                    details(plant, includeActions: false)
                }
                .padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 20)
            }
            .background(LifePalette.glass, in: UnevenRoundedRectangle(topLeadingRadius: 30, topTrailingRadius: 30))
            .overlay(UnevenRoundedRectangle(topLeadingRadius: 30, topTrailingRadius: 30).stroke(LifePalette.line))
        }
        .safeAreaInset(edge: .bottom) { pinnedActions(plant) }
    }

    // MARK: Stage: weather, plant, love petal row

    private func stage(_ plant: PlantCollectible, _ snap: LifeStats.Snapshot, plantSize s: CGFloat, plantTop: CGFloat, cloudTop: CGFloat) -> some View {
        let raining = snap.rainDay > 0
        let weather = LifeStats.weather(day: snap.rainDay)
        let groundY = plantTop + s * 171 / 200
        let rowTop = plantTop + s + (large ? 6 : 8)
        let rowHeight: CGFloat = large ? 40 : 30
        let geo = RainGeometry(cloudTop: cloudTop, groundY: groundY)
        let paused = !stageVisible || scenePhase != .active || lowPower.isOn
        let showPot = snap.isSeed && plant.lastShownPips == 0
        let thirsty = TendingEngine.isThirsty(plant, now: .now, calm: app.settings.calmMode)
        let name = displayName(plant)
        let height = rowTop + rowHeight + (large ? 34 : 44)

        return ZStack(alignment: .top) {
            if raining {
                LinearGradient(colors: [Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: 0x2A3D55, alpha: 0.4) : UIColor(hex: 0x9FB8C8, alpha: 0.3) }), .clear],
                               startPoint: .top, endPoint: .bottom)
                    .frame(height: groundY).allowsHitTesting(false).accessibilityHidden(true)
            }
            LinearGradient(stops: [.init(color: .clear, location: 0), .init(color: LifePalette.soil.opacity(0.18), location: 0.45), .init(color: .clear, location: 1)],
                           startPoint: .top, endPoint: .bottom)
                .frame(height: s * 0.5).padding(.top, plantTop + s * 0.77).allowsHitTesting(false).accessibilityHidden(true)

            if raining && !reduceMotion {
                RainCanvas(drops: weather.drops, layers: [0], geometry: geo, paused: paused).frame(height: rowTop)
            }

            plantView(plant, snap, size: s, showPot: showPot, thirsty: thirsty, name: name)
                .padding(.top, plantTop)

            if raining && !reduceMotion {
                RainCanvas(drops: weather.drops, layers: [1, 2], geometry: geo, paused: paused).frame(height: rowTop)
            }
            if raining {
                CloudView(storm: weather.thunder, glow: flash).padding(.top, cloudTop)
            }

            VStack(spacing: 8) {
                if showPot {
                    Color.clear.frame(height: rowHeight)
                } else {
                    PetalPipRow(count: snap.pips, large: large).frame(height: rowHeight)
                }
                if raining && reduceMotion {
                    Label(LifeStats.badge(thunder: weather.thunder), systemImage: "drop.fill")
                        .font(Theme.font(.footnote, weight: .heavy)).foregroundStyle(Color.appPrimaryText)
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(LifePalette.glass, in: Capsule()).overlay(Capsule().stroke(LifePalette.line))
                        .accessibilityHidden(true)
                }
            }
            .padding(.top, rowTop)
            .allowsHitTesting(false)
        }
        .frame(maxWidth: .infinity, minHeight: height, alignment: .top)
        .background {
            GeometryReader { g in
                Color.clear.onChange(of: g.frame(in: .global).maxY > 60, initial: true) { _, v in stageVisible = v }
            }
        }
    }

    @ViewBuilder
    private func plantView(_ plant: PlantCollectible, _ snap: LifeStats.Snapshot, size s: CGFloat, showPot: Bool, thirsty: Bool, name: String) -> some View {
        ZStack {
            if showPot {
                SeedPotView(width: s * 0.78).frame(width: s, height: s, alignment: .bottom).transition(.opacity)
            } else {
                LayeredPlantView(imageName: plant.imageName, pips: snap.pips, shownPips: plant.lastShownPips, size: s) { n in
                    app.markPetalsShown(plant, pips: n)
                }
                .rotationEffect(.degrees(thirsty ? 5 : sway), anchor: .bottom)
                .transition(.opacity)
            }
        }
        .frame(width: s, height: s)
        .animation(.easeInOut(duration: reduceMotion ? 0.3 : 1.2), value: showPot)
        .contentShape(Rectangle())
        .onTapGesture { hello(plant) }
        .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.5), trigger: hellos)
        .modifier(HelloTipModifier())
        .scaleEffect(bump ? 1.06 : 1)
        .animation(.spring(response: 0.4, dampingFraction: 0.45), value: bump)
        .overlay { TapBurst(trigger: hellos) }
        .overlay(alignment: .topTrailing) {
            if thirsty {
                Image(systemName: "drop.fill").foregroundStyle(Color.successText).padding(10)
                    .background(Color.appSurface, in: Circle()).accessibilityLabel("Thirsty")
                    .offset(x: 12)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(showPot ? LifeStats.seedLabel(name: name) : LifeStats.plantLabel(name: name, pips: snap.pips))
        .accessibilityAddTraits(.isButton)
        .accessibilityHint(snap.isSeed ? WakeCopy.wakeButton(name: name) : LifeStats.hint(name: name))
        .accessibilityAction { hello(plant) }
        .accessibilityIdentifier("plant-love")
    }

    /// A small hello: the plant sways back and settles, hearts float up, and it counts as love.
    private func hello(_ plant: PlantCollectible) {
        if app.showsWakeCard(plant) { showWake = true; return }   // Wake the seed: a tap on a seed offers the wake sheet
        hellos += 1
        app.love(plant)
        guard !reduceMotion else { return }
        withAnimation(.interpolatingSpring(stiffness: 90, damping: 5)) { sway = 7 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { withAnimation(.interpolatingSpring(stiffness: 90, damping: 5)) { sway = 0 } }
    }

    // MARK: Life panel

    @ViewBuilder private func panel(_ snap: LifeStats.Snapshot) -> some View {
        let transition: AnyTransition = reduceMotion ? .opacity : .scale(scale: 0.2, anchor: .leading).combined(with: .opacity)
        Group {
            if panelHidden {
                LifeTab(petalFalling: snap.rainDay > 0) { togglePanel() }
                    .accessibilityFocused($focus, equals: .show)
                    .padding(.top, 150)
                    .transition(reduceMotion ? .opacity : .opacity.combined(with: .offset(x: -6)))
            } else {
                LifePanel(snapshot: snap) { togglePanel() }
                    .accessibilityFocused($focus, equals: .hide)
                    .padding(.top, 8)
                    .transition(transition)
            }
        }
        .padding(.leading, 12)
    }

    private func togglePanel() {
        withAnimation(reduceMotion ? .easeInOut(duration: 0.2) : .spring(response: 0.3, dampingFraction: 0.8)) { panelHidden.toggle() }
        let target: PanelFocus = panelHidden ? .show : .hide
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { focus = target }
    }

    // MARK: Below the stage

    private func nameBlock(_ plant: PlantCollectible, _ snap: LifeStats.Snapshot) -> some View {
        let thirsty = TendingEngine.isThirsty(plant, now: .now, calm: app.settings.calmMode)
        let name = displayName(plant)
        let line = snap.rainDay > 0 ? LoveEngine.rainLine(name: name)
            : (thirsty ? "Thirsty. A drink will perk it right up." : LifeStats.stageWord(snap.stage, seed: snap.isSeed))
        return VStack(spacing: 4) {
            Button { draftName = plant.nickname; renaming = true } label: {
                HStack(spacing: 6) {
                    Text(name).font(Theme.font(.title2, weight: .bold))
                    Image(systemName: "pencil").font(.footnote)
                }.foregroundStyle(Color.appPrimaryText)
            }
            .accessibilityHint("Give your plant a name")
            Text(plant.botanicalName).font(Theme.font(.subheadline)).italic().foregroundStyle(Color.secondaryText)
            Text(line).font(Theme.font(.callout, weight: .semibold)).foregroundStyle(Color.successText).multilineTextAlignment(.center)
            if !snap.isSeed {
                Label(LifeStats.hint(name: name), systemImage: "heart")
                    .font(Theme.font(.footnote, weight: .bold)).foregroundStyle(Color.appPrimaryText)
                    .padding(.top, 2)
            }
        }
    }

    @ViewBuilder private func details(_ plant: PlantCollectible, includeActions: Bool) -> some View {
        let quiet = app.settings.quietGarden
        if !quiet { resources }

        // MARK: Wake the seed (begin). Kept to this one block for the planned redesign of this screen.
        if app.showsWakeCard(plant) { WakeSeedCard(plant: plant, isPresented: $showWake) }
        // MARK: Wake the seed (end)

        if includeActions { actions(plant) } else if app.inventory.tier(of: .shears) > 0 || app.settings.showEverything {
            action("Prune", "scissors") { run(.prune, plant) }
        }

        if quiet {
            Text("Take your time. Plants grow at their own pace.").font(Theme.font(.footnote)).foregroundStyle(Color.secondaryText)
        } else {
            let cap = TendingEngine.capacityState(plant, now: .now, calendar: .current, economy: .default)
            Label(TendingEngine.capacityLine(cap, name: displayName(plant)), systemImage: cap == .plenty ? "checkmark.seal.fill" : "leaf.fill")
                .font(Theme.font(.footnote, weight: .semibold)).foregroundStyle(Color.secondaryText).multilineTextAlignment(.center)
        }

        if app.canOfferRewarded && !quiet && (app.profile?.water ?? 0) == 0 {
            Button { Task { if await app.watchRewardedAd() { run(.water, plant) } } } label: {
                Label("Watch a short video for 2 drops", systemImage: "play.rectangle.fill")
            }.buttonStyle(SecondaryButtonStyle())
        }

        Card { Text(plant.botanicalFact).font(Theme.font(.callout)).foregroundStyle(Color.appPrimaryText) }

        if GardenAIProvider.isModelBacked() {
            if let aiText {
                Card {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(aiText).font(Theme.font(.callout)).foregroundStyle(Color.appPrimaryText)
                        Label("Written by on-device AI", systemImage: "sparkles").font(Theme.font(.caption)).foregroundStyle(Color.secondaryText)
                    }
                }
            } else {
                Button { Task { await tellMore(plant) } } label: { Label(aiBusy ? "Thinking…" : "Tell me more", systemImage: "sparkles") }
                    .buttonStyle(SecondaryButtonStyle()).disabled(aiBusy)
            }
        }
    }

    private var resources: some View {
        let p = app.profile
        return ViewThatFits {
            HStack(spacing: 10) { chips(p) }
            VStack(spacing: 8) { chips(p) }
        }
    }

    @ViewBuilder private func chips(_ p: PlayerProfile?) -> some View {
        chip("drop.fill", p?.water ?? 0, "water drops")
        chip("shippingbox.fill", p?.soil ?? 0, "soil scoops")
        chip("star.fill", p?.shedPoints ?? 0, "shed points")
    }

    private func chip(_ icon: String, _ n: Int, _ label: String) -> some View {
        Label("\(n)", systemImage: icon).font(Theme.font(.subheadline, weight: .semibold))
            .padding(.horizontal, 12).frame(minHeight: 36).background(Color.appSurface, in: Capsule())
            .accessibilityLabel("\(n) \(label)")
    }

    private func actions(_ plant: PlantCollectible) -> some View {
        let owns = app.inventory
        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            action("Water", "drop.fill") { run(.water, plant) }
            action("Feed", "leaf.arrow.triangle.circlepath") { run(.feed, plant) }
            action("Sun", "sun.max.fill") { run(.sun, plant) }
            if owns.tier(of: .shears) > 0 || app.settings.showEverything { action("Prune", "scissors") { run(.prune, plant) } }
            action("Repot", "shippingbox") { showRepot = true }
        }
    }

    /// Accessibility text sizes: Water, Feed, Sun and Repot stay pinned under the Life sheet as a 2 by 2 bar.
    private func pinnedActions(_ plant: PlantCollectible) -> some View {
        Grid(horizontalSpacing: 8, verticalSpacing: 8) {
            GridRow {
                pinned("Water", "drop.fill", LifePalette.water) { run(.water, plant) }
                pinned("Feed", "leaf.fill", LifePalette.leaf) { run(.feed, plant) }
            }
            GridRow {
                pinned("Sun", "sun.max.fill", LifePalette.sun) { run(.sun, plant) }
                pinned("Repot", "shippingbox.fill", LifePalette.clay) { showRepot = true }
            }
        }
        .padding(.horizontal, 14).padding(.top, 10).padding(.bottom, 6)
        .background(Color.appBackground.ignoresSafeArea(edges: .bottom))
        .overlay(alignment: .top) { Rectangle().fill(LifePalette.line).frame(height: 1) }
    }

    private func pinned(_ title: String, _ icon: String, _ tint: Color, _ tap: @escaping () -> Void) -> some View {
        Button(action: tap) {
            HStack(spacing: 8) {
                Image(systemName: icon).foregroundStyle(tint)
                Text(title).foregroundStyle(Color.appPrimaryText).lineLimit(1).minimumScaleFactor(0.6)
            }
            .font(Theme.font(.body, weight: .heavy))
            .frame(maxWidth: .infinity, minHeight: 64)
            .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(LifePalette.line))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }

    private func action(_ title: String, _ icon: String, _ tap: @escaping () -> Void) -> some View {
        Button(action: tap) { Label(title, systemImage: icon) }.buttonStyle(SecondaryButtonStyle())
    }

    private func repotSheet(_ plant: PlantCollectible) -> some View {
        VStack(spacing: 14) {
            Text("Choose a soil").font(Theme.font(.title3, weight: .bold))
            Text("Plants have favorite soils. Try one and see how it reacts.").font(Theme.font(.callout)).foregroundStyle(Color.secondaryText).multilineTextAlignment(.center)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(SoilType.allCases, id: \.self) { soil in
                    Button { showRepot = false; run(.repot(soil), plant) } label: { Text(soil.rawValue.capitalized) }
                        .buttonStyle(SecondaryButtonStyle())
                }
            }
        }
        .padding(24)
    }

    @ViewBuilder private var toastView: some View {
        if let toast {
            Text(toast).font(Theme.font(.subheadline, weight: .semibold)).foregroundStyle(Color.appPrimaryText)
                .padding(.horizontal, 16).padding(.vertical, 12)
                .background(Color.appSurface, in: Capsule()).shadow(radius: 6, y: 2).padding(.bottom, 20)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .accessibilityAddTraits(.updatesFrequently)
        }
    }

    /// Grounded in the plant's reviewed fact; unsafe or empty output falls back to the fact itself (spec section 5).
    private func tellMore(_ plant: PlantCollectible) async {
        aiBusy = true
        let entry = WordEntry(id: plant.plantId, word: plant.name.uppercased().filter { $0.isLetter || $0 == " " }, display: plant.name, hint: "", hint2: nil,
                              fact: plant.botanicalFact, level: plant.level, kind: .vocab, plantId: nil, tags: [], minAge: 6, dailyEligible: false,
                              source: "bank", license: "proprietary", reviewedBy: nil)
        aiText = await GardenAIProvider.current().explain(entry: entry)
        aiBusy = false
    }

    private func run(_ action: AppModel.TendAction, _ plant: PlantCollectible) {
        let outcome = app.tend(action, plant: plant)
        if outcome.applied {
            switch action {
            case .water: app.play(.water)
            case .feed, .repot: app.play(.soil)
            case .sun: app.play(.sun)
            case .prune: app.play(.snip)
            }
        }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { toast = outcome.message }
        if outcome.stageUp { bump.toggle() }
        AccessibilityNotification.Announcement(outcome.message).post()
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { withAnimation { toast = nil } }
    }
}

/// The "tap your plant" hint is hidden while VoiceOver runs, since VoiceOver users get the plant's own hint.
private struct HelloTipModifier: ViewModifier {
    func body(content: Content) -> some View {
        if UIAccessibility.isVoiceOverRunning { content } else { content.popoverTip(PlantHelloTip(), arrowEdge: .bottom) }
    }
}
