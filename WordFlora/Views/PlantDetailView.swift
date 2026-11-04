import SwiftUI
import TipKit
import SwiftData

/// The plant's page: the plant in the centre (drawn from its layered art at its love petal count), the love petal
/// row under it, rain and gentle thunder after a day with no love, the seed pot when it rests, and the Life panel
/// at the left edge (a sheet at accessibility text sizes). Under the plant sits the fact card; the tend buttons are
/// pinned at the bottom and show each action's state; a tap plays that action's effect over the plant.
/// Approved designs: design-preview/tending/lifestats.html (option B petal row), design-preview/tending/actions.html
/// (button states and the four effects), design-preview/fact-card (card placement).
struct PlantDetailView: View {
    let plantId: String

    @Environment(AppModel.self) private var app
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("lifePanelHidden") private var panelHidden = false
    @AccessibilityFocusState private var focus: PanelFocus?
    @State private var toast: ToastItem?
    @State private var toastCount = 0
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
    @State private var tends = TendSequencer()
    @State private var tendTaps = 0
    @State private var nudges: [TendKind: Int] = [:]
    @State private var pickedPot = ""        // the pot picked in the repot sheet (PotCatalog id)
    @State private var pickedSoil: SoilType = .loam

    private enum PanelFocus: Hashable { case show, hide }

    struct ToastItem: Equatable {
        let text: String
        let ok: Bool
        let id: Int
    }

    private var plant: PlantCollectible? { app.plants().first { $0.plantId == plantId } }
    private var large: Bool { typeSize.isAccessibilitySize }
    /// Reduce Motion and Low Power Mode both get the short fade instead of the travelling effects.
    private var calm: Bool { reduceMotion || lowPower.isOn }

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
                          dark: colorScheme == .dark, haptics: app.settings.hapticsOn, sound: app.settings.soundOn, flash: $flash,
                          lastRoll: { app.lastThunderRoll }, roll: { app.rollThunder() })
        }
        .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.6), trigger: tendTaps) { _, _ in app.settings.hapticsOn }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { draftName = plant.nickname; renaming = true } label: { Image(systemName: "pencil") }
                    .accessibilityLabel(PlantDetailCopy.rename)
                    .accessibilityHint(PlantDetailCopy.renameHint)
            }
        }
        .sheet(isPresented: $showRepot) { repotSheet(plant).presentationDetents([.large]).presentationDragIndicator(.visible) }
        .sheet(isPresented: $showWake) { WakeSheet(plant: plant).environment(app) }   // Wake the seed
        .alert("Name your plant", isPresented: $renaming) {
            TextField("Name", text: $draftName)
            Button("Save") { plant.nickname = String(draftName.prefix(16)); try? app.context.save() }
            Button("Cancel", role: .cancel) {}
        }
    }

    // MARK: Layouts

    /// The tend buttons sit below the scroll view (not over it), so nothing scrolls behind them.
    private func standardLayout(_ plant: PlantCollectible, _ snap: LifeStats.Snapshot) -> some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 16) {
                    ZStack(alignment: .topLeading) {
                        stage(plant, snap, plantSize: 220, plantTop: 92, cloudTop: 4)
                        panel(snap)
                    }
                    VStack(spacing: 16) {
                        below(plant, snap)
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 20)
            }
            actionBar(plant)
        }
    }

    private func largeLayout(_ plant: PlantCollectible, _ snap: LifeStats.Snapshot) -> some View {
        VStack(spacing: 0) {
            stage(plant, snap, plantSize: 132, plantTop: 52, cloudTop: 0)
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    LifeSheet(snapshot: snap, collapsed: panelHidden) { togglePanel() }
                    below(plant, snap)
                }
                .padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 20)
            }
            .background(LifePalette.glass, in: UnevenRoundedRectangle(topLeadingRadius: 30, topTrailingRadius: 30))
            .overlay(UnevenRoundedRectangle(topLeadingRadius: 30, topTrailingRadius: 30).stroke(LifePalette.line))
            actionBar(plant)
        }
    }

    // MARK: Stage: weather, plant, love petal row

    private func stage(_ plant: PlantCollectible, _ snap: LifeStats.Snapshot, plantSize s: CGFloat, plantTop: CGFloat, cloudTop: CGFloat) -> some View {
        let raining = snap.rainDay > 0
        let weather = LifeStats.weather(day: snap.rainDay)
        let k = s / 220
        let potBottom = plantTop + TendAnimationView.potRect.maxY * k     // the plant's pot stands on the floor here
        let groundY = potBottom - 6 * k
        let rowTop = potBottom + (large ? 6 : 8)
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
                .frame(height: s * 0.5).padding(.top, potBottom - s * 0.25).allowsHitTesting(false).accessibilityHidden(true)

            if raining && !reduceMotion {
                RainCanvas(drops: weather.drops, layers: [0], geometry: geo, paused: paused).frame(height: rowTop)
            }

            // The plant's pot stands behind it (the seed pot draws its own). The repot effect brings its own pots.
            if !showPot {
                stagePot(plant, size: s)
                    .opacity(tends.current?.effect == .repot && !calm ? 0 : 1)
                    .padding(.top, plantTop)
            }

            plantView(plant, snap, size: s, showPot: showPot, thirsty: thirsty, name: name)
                .padding(.top, plantTop)

            // The tend effect plays over the plant; taps pass through to it.
            TendAnimationView(play: tends.current, size: s, calm: calm)
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

    /// The plant's chosen pot at the stage spot (design-preview/pots, section 4), with its floor shadow.
    private func stagePot(_ plant: PlantCollectible, size s: CGFloat) -> some View {
        let k = s / 220
        let r = TendAnimationView.potRect, f = TendAnimationView.floorShadowRect
        return ZStack(alignment: .topLeading) {
            Ellipse().fill(colorScheme == .dark ? Color.black.opacity(0.35) : Color(UIColor(hex: 0x2C3E2C)).opacity(0.18))
                .frame(width: f.width * k, height: f.height * k)
                .offset(x: f.minX * k, y: f.minY * k)
            PotArtView(pot: PotCatalog.pot(id: plant.potId), width: r.width * k, soil: true)
                .offset(x: r.minX * k, y: r.minY * k)
        }
        .frame(width: s, height: f.maxY * k, alignment: .topLeading)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func plantView(_ plant: PlantCollectible, _ snap: LifeStats.Snapshot, size s: CGFloat, showPot: Bool, thirsty: Bool, name: String) -> some View {
        ZStack {
            if showPot {
                // The seed pot's pot box lines up with the stage pot, so the seed rests in the plant's own pot.
                let k = s / 220, r = TendAnimationView.potRect, u = r.width * k / 120
                SeedPotView(pot: PotCatalog.pot(id: plant.potId), width: 140 * u)
                    .offset(x: r.minX * k - SeedPotView.potOrigin.x * u, y: r.minY * k - SeedPotView.potOrigin.y * u)
                    .frame(width: s, height: s, alignment: .topLeading).transition(.opacity)
            } else {
                let k = s / 220, soil = TendAnimationView.soilRect
                LayeredPlantView(imageName: plant.imageName, pips: snap.pips, shownPips: plant.lastShownPips, size: s,
                                 onShown: { n in app.markPetalsShown(plant, pips: n) },
                                 groundClip: CGRect(x: soil.minX * k, y: soil.minY * k, width: soil.width * k, height: soil.height * k))
                .rotationEffect(.degrees(thirsty ? 5 : sway), anchor: .bottom)
                .transition(.opacity)
            }
        }
        .frame(width: s, height: s)
        .tendMotion(tends.current, size: s, calm: calm)
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

    // MARK: Below the stage: the seed card, the fact card, the plant's line, supplies

    @ViewBuilder private func below(_ plant: PlantCollectible, _ snap: LifeStats.Snapshot) -> some View {
        let quiet = app.settings.quietGarden

        // MARK: Wake the seed (begin). Kept to this one block for the planned redesign of this screen.
        if app.showsWakeCard(plant) { WakeSeedCard(plant: plant, isPresented: $showWake) }
        // MARK: Wake the seed (end)

        NameStoryCard(name: plant.name, botanicalName: plant.botanicalName, fact: plant.botanicalFact,
                      story: PlantCatalog.nameStory(for: plant.plantId))

        statusBlock(plant, snap)

        if !quiet { resources }

        if large && showsPrune {
            tendButton(.prune, plant)
        }

        if quiet {
            Text(PlantDetailCopy.quiet).font(Theme.font(.footnote)).foregroundStyle(Color.secondaryText)
                .frame(maxWidth: .infinity).multilineTextAlignment(.center)
        }

        if app.canOfferRewarded && !quiet && (app.profile?.water ?? 0) == 0 {
            Button { Task { if await app.watchRewardedAd() { run(.water, kind: .water, plant) } } } label: {
                Label("Watch a short video for 2 drops", systemImage: "play.rectangle.fill")
            }.buttonStyle(SecondaryButtonStyle())
        }

        if GardenAIProvider.isModelBacked() {
            if let aiText {
                Card {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(aiText).font(Theme.font(.callout)).foregroundStyle(Color.appPrimaryText)
                        Label("Written by on-device AI", systemImage: "sparkles").font(Theme.font(.caption)).foregroundStyle(Color.secondaryText)
                    }
                }
            } else {
                Button { Task { await tellMore(plant) } } label: { Label(aiBusy ? "Thinking…" : PlantDetailCopy.askAI, systemImage: "sparkles") }
                    .buttonStyle(SecondaryButtonStyle()).disabled(aiBusy)
            }
        }
    }

    /// The plant's line today (stage, thirsty or rain) and the hello hint.
    private func statusBlock(_ plant: PlantCollectible, _ snap: LifeStats.Snapshot) -> some View {
        let thirsty = TendingEngine.isThirsty(plant, now: .now, calm: app.settings.calmMode)
        let name = displayName(plant)
        let line = snap.rainDay > 0 ? LoveEngine.rainLine(name: name)
            : (thirsty ? PlantDetailCopy.thirsty : LifeStats.stageWord(snap.stage, seed: snap.isSeed))
        return VStack(spacing: 4) {
            Text(line).font(Theme.font(.callout, weight: .semibold)).foregroundStyle(Color.successText).multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            if !snap.isSeed {
                Label(LifeStats.hint(name: name), systemImage: "heart")
                    .font(Theme.font(.footnote, weight: .bold)).foregroundStyle(Color.appPrimaryText)
                    .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var resources: some View {
        let p = app.profile
        return ViewThatFits {
            HStack(spacing: 10) { chips(p) }
            VStack(spacing: 8) { chips(p) }
        }
        .frame(maxWidth: .infinity)
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

    // MARK: Tend buttons (pinned at the bottom; each shows its own state from AppModel.actionState)

    private var showsPrune: Bool { app.inventory.tier(of: .shears) > 0 || app.settings.showEverything }

    private func action(for kind: TendKind) -> AppModel.TendAction {
        switch kind {
        case .water: return .water
        case .feed: return .feed
        case .sun: return .sun
        case .prune: return .prune
        case .repot: return .repot(.loam)       // the soil is picked in the sheet; the state does not depend on it
        }
    }

    private func actionBar(_ plant: PlantCollectible) -> some View {
        Group {
            if large {
                Grid(horizontalSpacing: 8, verticalSpacing: 8) {
                    GridRow { tendButton(.water, plant); tendButton(.feed, plant) }
                    GridRow { tendButton(.sun, plant); tendButton(.repot, plant) }
                }
            } else {
                HStack(spacing: 8) {
                    ForEach([TendKind.water, .feed, .sun] + (showsPrune ? [.prune] : []) + [.repot], id: \.self) { tendButton($0, plant) }
                }
                .fixedSize(horizontal: false, vertical: true)       // every tile as tall as the tallest
            }
        }
        .padding(.horizontal, 14).padding(.top, 10).padding(.bottom, 6)
        .background(Color.appBackground.ignoresSafeArea(edges: .bottom))
        .overlay(alignment: .top) { Rectangle().fill(LifePalette.line).frame(height: 1) }
        .overlay(alignment: .top) {
            toastView.padding(.horizontal, 16)
                .alignmentGuide(.top) { d in d[.bottom] + 10 }
        }
    }

    private func tendButton(_ kind: TendKind, _ plant: PlantCollectible) -> some View {
        let state = app.actionState(action(for: kind), plant: plant)
        return TendActionButton(kind: kind, look: TendButtonLook(kind: kind, state: state), large: large, nudge: nudges[kind, default: 0]) {
            tap(kind, plant)
        }
    }

    private func tap(_ kind: TendKind, _ plant: PlantCollectible) {
        if kind == .repot {
            let state = app.actionState(.repot(.loam), plant: plant)
            if state.isReady {
                pickedPot = PotCatalog.pot(id: plant.potId).id
                pickedSoil = SoilType(rawValue: plant.soilType) ?? .loam
                showRepot = true
            } else { refuse(kind, state.line ?? TendKind.repot.supplyCaption) }
            return
        }
        run(action(for: kind), kind: kind, plant)
    }

    /// The repot sheet (design-preview/pots, section 2): pick a pot (free to change), pick a soil (a scoop, as
    /// before), then one button that names the new pot. Only pots the player has (or the pot already on the plant)
    /// can be picked; the others say how to earn them.
    private func repotSheet(_ plant: PlantCollectible) -> some View {
        let picked = PotCatalog.pot(id: pickedPot)
        return ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Repot \(displayName(plant))").font(Theme.font(.title3, weight: .bold)).foregroundStyle(Color.appPrimaryText)
                    .accessibilityAddTraits(.isHeader)
                PotPickGrid(currentId: plant.potId, picked: $pickedPot, stats: app.potStats, hasPlus: app.hasPlusForPots)
                VStack(alignment: .leading, spacing: 6) {
                    Text("Choose a soil").font(Theme.font(.headline, weight: .bold)).foregroundStyle(Color.appPrimaryText)
                        .accessibilityAddTraits(.isHeader)
                    Text("Plants have favorite soils. Try one and see how it reacts.").font(Theme.font(.callout)).foregroundStyle(Color.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(SoilType.allCases, id: \.self) { soil in
                        Button { pickedSoil = soil } label: { Text(soil.rawValue.capitalized) }
                            .buttonStyle(SecondaryButtonStyle())
                            .overlay {
                                if pickedSoil == soil { RoundedRectangle(cornerRadius: Theme.cornerRadius).strokeBorder(PotPalette.ring, lineWidth: 3) }
                            }
                            .accessibilityAddTraits(pickedSoil == soil ? .isSelected : [])
                    }
                }
            }
            .padding(24)
        }
        .safeAreaInset(edge: .bottom) {
            Button {
                showRepot = false
                run(.repot(pickedSoil), kind: .repot, plant, pot: picked)
            } label: { Text(PotCatalog.repotTitle(picked: picked, currentId: plant.potId)) }
                .buttonStyle(PrimaryButtonStyle())
                .accessibilityIdentifier("repot-go")
                .padding(.horizontal, 24).padding(.top, 10).padding(.bottom, 8)
                .background(Color.appBackground)
        }
        .background(Color.appBackground)
    }

    @ViewBuilder private var toastView: some View {
        if let toast {
            HStack(spacing: 10) {
                Image(systemName: toast.ok ? "checkmark.circle.fill" : "moon.fill")
                    .foregroundStyle(toast.ok ? LifePalette.leafBright : Color.appBackground.opacity(0.85))
                    .accessibilityHidden(true)
                Text(toast.text).font(Theme.font(.subheadline, weight: .semibold)).foregroundStyle(Color.appBackground)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.appPrimaryText, in: RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.15), radius: 6, y: 2)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.updatesFrequently)
            .accessibilityIdentifier("tend-toast")
            .id(toast.id)
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

    /// A tap: on success the effect plays once (replacing any effect still playing), with its sound and one soft
    /// haptic, and the toast follows the pour; a refused tap gets a soft nudge and the kind reason at once.
    /// A repot carries the picked pot, which is saved once the repot goes through (changing pots is free).
    private func run(_ action: AppModel.TendAction, kind: TendKind, _ plant: PlantCollectible, pot: Pot? = nil) {
        let from = TendPot(id: plant.potId)
        let outcome = app.tend(action, plant: plant)
        guard outcome.applied else { refuse(kind, outcome.message); return }
        if let pot { app.choosePot(pot, for: plant) }
        tendTaps += 1
        if let effect = TendEffect(action) {
            app.play(effect.sound)
            let play = tends.start(effect, pot: TendPot(id: plant.potId), from: from, at: .now)
            let life = TendMotion.lifetime(effect, calm: calm, hold: TendMotion.uiTestHold)
            DispatchQueue.main.asyncAfter(deadline: .now() + life) { tends.finish(id: play.id) }
        } else {
            app.play(.snip)
        }
        let delay = TendEffect(action) == nil ? 0 : (calm ? 0.4 : 0.9)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { if outcome.stageUp { bump.toggle() } }
        show(outcome.message, ok: true, after: delay)
    }

    private func refuse(_ kind: TendKind, _ line: String) {
        nudges[kind, default: 0] += 1
        show(line, ok: false, after: 0)
    }

    private func show(_ text: String, ok: Bool, after delay: Double) {
        toastCount += 1
        let item = ToastItem(text: text, ok: ok, id: toastCount)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            guard toastCount == item.id else { return }          // a newer tap took over
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { toast = item }
            AccessibilityNotification.Announcement(text).post()
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { if toast?.id == item.id { withAnimation { toast = nil } } }
        }
    }
}

/// Words that appear only on the plant page (checked by the copy tests).
enum PlantDetailCopy {
    static let rename = "Rename"
    static let renameHint = "Give your plant a name"
    static let quiet = "Take your time. Plants grow at their own pace."
    static let thirsty = "Thirsty. A drink will perk it right up."
    static let askAI = "Ask for a fun fact"
    static var all: [String] { [rename, renameHint, quiet, thirsty, askAI] }
}

/// The "tap your plant" hint is hidden while VoiceOver runs, since VoiceOver users get the plant's own hint.
private struct HelloTipModifier: ViewModifier {
    func body(content: Content) -> some View {
        if UIAccessibility.isVoiceOverRunning { content } else { content.popoverTip(PlantHelloTip(), arrowEdge: .bottom) }
    }
}
