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
    /// The Life panel starts closed and opens itself on a visit where the weather slot, hearts or seed state changed
    /// since the last visit (`AppModel.lifePanelVisit`). The player's own open/close lasts for the visit.
    @State private var panelHidden = true
    @State private var visited = false
    @State private var weatherPuzzle = false
    @AccessibilityFocusState private var focus: PanelFocus?
    @State private var toast: ToastItem?
    @State private var toastCount = 0
    @State private var sway = 0.0
    @State private var hellos = 0
    @State private var petalNotes = 0
    @State private var lean = 0.0                         // Living Touch: the plant leans with a stroking finger
    @State private var strokes = LivingTouch.Strokes()
    @State private var lastTouchTap: Date?
    @State private var touchTaps = 0
    @State private var showRepot = false
    @State private var renaming = false
    @State private var draftName = ""
    @State private var bump = false
    @State private var stagePuff = 0          // a small puff of petals at the plant's head when it grows a stage
    @State private var aiText: String?
    @State private var aiBusy = false
    @State private var showWake = false      // Wake the seed (see the marked block below)
    @State private var flash = 0.0
    @State private var stageVisible = true
    @State private var lowPower = LowPowerWatch()
    @State private var tends = TendSequencer()
    @State private var tendTaps = 0
    @State private var nudges: [TendKind: Int] = [:]
    @State private var snips = 0              // Pruning Pro: a tidy trim drops one dry petal
    @State private var mists = 0              // Mist Maker: each mist plays the spray once
    @State private var showMistTip = false    // "Some plants love a little mist on their leaves.", the first time only

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
        .onAppear {
            // Mist Maker's tip, once: the first visit on which the Mist button shows.
            if app.showsMist && !app.settings.mistTipShown { showMistTip = true; app.settings.mistTipShown = true }
        }
    }

    private func displayName(_ plant: PlantCollectible) -> String { plant.nickname.isEmpty ? plant.name : plant.nickname }

    private func snapshot(_ plant: PlantCollectible) -> LifeStats.Snapshot {
        var inputs = LifeStats.Inputs(plant: plant, now: .now, calendar: .current, exempt: app.loveExempt)
        inputs.weather = app.weatherInputs()[plant.plantId]       // empty in Calm, Quiet Garden or with weather off
        return LifeStats.snapshot(inputs)
    }

    @ViewBuilder private func content(_ plant: PlantCollectible) -> some View {
        let snap = snapshot(plant)
        let wx = app.plantWeather(plant)
        let lifeKey = LifePanelVisit.key(weather: app.weatherChangeKey(for: plant), hearts: snap.hearts, isSeed: snap.isSeed)
        Group {
            if large { largeLayout(plant, snap, wx) } else { standardLayout(plant, snap, wx) }
        }
        .onAppear {
            guard !visited else { return }
            visited = true
            panelHidden = !app.lifePanelVisit(plant, hearts: snap.hearts, isSeed: snap.isSeed)
        }
        // A change that happens on this page (a hello, a tend, care mending the weather) has been seen.
        .onChange(of: lifeKey) { _, _ in app.markLifeSeen(plant, hearts: snap.hearts, isSeed: snap.isSeed) }
        .fullScreenCover(isPresented: $weatherPuzzle) { WeatherPuzzleSheet { weatherPuzzle = false }.environment(app) }
        // Garden weather: the day's bed and arrival sound while the stage is on screen (silent with Sound off, Calm,
        // Quiet Garden; see WeatherSoundGate). When care mends the look on this page, the relief chime ends the bed.
        .weatherSoundscape(wx?.kind, active: stageVisible)
        .onChange(of: wx?.kind) { old, new in
            if old != nil && new == nil && stageVisible {
                app.playWeather(.reliefChime, systemReduceMotion: reduceMotion, stopsBed: true)
            }
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
        .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.35), trigger: petalNotes)
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
    private func standardLayout(_ plant: PlantCollectible, _ snap: LifeStats.Snapshot, _ wx: PlantWeatherScene?) -> some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 16) {
                    ZStack(alignment: .topLeading) {
                        stage(plant, snap, wx, plantSize: 220, plantTop: 92, cloudTop: 4)
                        panel(snap)
                    }
                    VStack(spacing: 16) {
                        below(plant, snap)
                    }
                    .padding(.horizontal, Space.gutter)
                }
                .padding(.bottom, 20)
            }
            actionBar(plant)
        }
    }

    private func largeLayout(_ plant: PlantCollectible, _ snap: LifeStats.Snapshot, _ wx: PlantWeatherScene?) -> some View {
        VStack(spacing: 0) {
            stage(plant, snap, wx, plantSize: 132, plantTop: 52, cloudTop: 0)
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Accessibility sizes: the tend buttons are full-width tiles at the top of the page, so every
                    // word keeps a whole line at every size (TendRowLayout); the toast stays pinned at the bottom.
                    VStack(spacing: 8) { ForEach(tendKinds, id: \.self) { tendButton($0, plant) } }
                    LifeSheet(snapshot: snap, collapsed: panelHidden) { togglePanel() }
                    below(plant, snap)
                }
                .padding(.horizontal, Space.gutter).padding(.top, 8).padding(.bottom, 20)
            }
            .background(LifePalette.glass, in: UnevenRoundedRectangle(topLeadingRadius: 30, topTrailingRadius: 30))
            .overlay(UnevenRoundedRectangle(topLeadingRadius: 30, topTrailingRadius: 30).stroke(LifePalette.line))
            actionBar(plant)
        }
    }

    // MARK: Stage: weather, plant, love petal row

    private func stage(_ plant: PlantCollectible, _ snap: LifeStats.Snapshot, _ wx: PlantWeatherScene?, plantSize s: CGFloat, plantTop: CGFloat, cloudTop: CGFloat) -> some View {
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
        // Garden weather art: Reduce Motion (system or the app's switch) and Low Power hold one still frame.
        let weatherStill = reduceMotion || app.settings.reduceMotionOverride || lowPower.isOn
        let weatherSpec = wx.map { WeatherArt.spec($0.kind, look: $0.look) }

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

            if let wx {
                WeatherOverlay(kind: wx.kind, look: wx.look, layer: .back, size: s, still: weatherStill, paused: paused)
                    .padding(.top, plantTop)
            }

            // The plant's pot stands behind it (the seed pot draws its own). The repot effect brings its own pots.
            if !showPot {
                stagePot(plant, size: s)
                    .opacity(tends.current?.effect == .repot && !calm ? 0 : 1)
                    .padding(.top, plantTop)
            }

            if let weatherSpec, let wx {
                // The weather poses the plant only (never the pot); its line is the plant's VoiceOver value.
                plantView(plant, snap, size: s, showPot: showPot, thirsty: thirsty, name: name)
                    .accessibilityValue(wx.line)
                    .weatherPose(weatherSpec, still: weatherStill, paused: paused)
                    .frame(width: s, height: s)
                    .padding(.top, plantTop)
            } else {
                plantView(plant, snap, size: s, showPot: showPot, thirsty: thirsty, name: name)
                    .padding(.top, plantTop)
            }

            // The tend effect plays over the plant; taps pass through to it.
            TendAnimationView(play: tends.current, size: s, calm: calm)
                .padding(.top, plantTop)
            // Mist Maker's spray (Calm: half the droplets; Reduce Motion or Low Power: the dew cross-fade only).
            MistSprayView(trigger: mists, size: s, calm: app.settings.calmMode,
                          reduceMotion: calm || app.settings.reduceMotionOverride)
                .padding(.top, plantTop)

            if let wx {
                WeatherOverlay(kind: wx.kind, look: wx.look, layer: .front, size: s, still: weatherStill, paused: paused)
                    .padding(.top, plantTop)
            }

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
                    // The petal sound toy: tap a petal for its note, the love flower for all five (tap the plant for hello).
                    PetalPipRow(count: snap.pips, large: large, onPetal: playPetal).frame(minHeight: rowHeight)
                }
                if raining && reduceMotion {
                    Label(LifeStats.badge(thunder: weather.thunder), systemImage: "drop.fill")
                        .font(Theme.font(.footnote, weight: .heavy)).foregroundStyle(Color.appPrimaryText)
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(LifePalette.glass, in: Capsule()).overlay(Capsule().stroke(LifePalette.line))
                        .accessibilityHidden(true)
                        .allowsHitTesting(false)
                }
            }
            .padding(.top, rowTop)
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
                .goldenBloom(app.isGolden(plant))
                // Wild Weather's shown-stage dip: the plant looks one stage smaller for now (display only).
                .scaleEffect(Self.dipScale(snap), anchor: UnitPoint(x: 0.5, y: 188.0 / 220))
                .rotationEffect(.degrees(thirsty ? 5 : sway + lean), anchor: .bottom)
                .transition(.opacity)
                // Pruning Pro: one faded bloom on a cue day, the fresh bud on later visits after a tidy trim.
                FadedBloomOverlay(size: s, spot: app.fadedBloomSpot(plant), showsBloom: app.showsFadedBloom(plant),
                                  showsBud: app.showsFreshBud(plant), snips: snips,
                                  reduceMotion: reduceMotion || app.settings.reduceMotionOverride, calm: app.settings.calmMode)
                    .rotationEffect(.degrees(thirsty ? 5 : sway + lean), anchor: .bottom)
            }
        }
        .frame(width: s, height: s)
        .tendMotion(tends.current, size: s, calm: calm)
        .animation(.easeInOut(duration: reduceMotion ? 0.3 : 1.2), value: showPot)
        .contentShape(Rectangle())
        .onTapGesture { hello(plant) }
        // Living Touch: stroke the plant (not the petal row, which plays notes) and it leans with the finger; a seed in
        // its pot keeps the tap only. Simultaneous, so the page still scrolls.
        .simultaneousGesture(livingTouch(plant, width: s), including: showPot ? .subviews : .all)
        .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.5), trigger: hellos)
        .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.3), trigger: touchTaps) { _, _ in app.settings.hapticsOn }
        .modifier(HelloTipModifier())
        .scaleEffect(bump ? 1.06 : 1)
        .animation(.spring(response: 0.4, dampingFraction: 0.45), value: bump)
        .overlay { TapBurst(trigger: hellos) }
        .overlay(alignment: .top) {
            PetalPuff(trigger: stagePuff, level: app.celebrationLevel(.small, systemReduceMotion: reduceMotion)).frame(width: 240, height: 240).offset(y: -80)
        }
        .overlay(alignment: .topTrailing) {
            if thirsty {
                Image(systemName: "drop.fill").foregroundStyle(Color.successText).padding(10)
                    .background(Color.appSurface, in: Circle()).accessibilityLabel("Thirsty")
                    .offset(x: 12)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(showPot ? LifeStats.seedLabel(name: name) : plantLabel(plant, name: name, pips: snap.pips))
        .accessibilityAddTraits(.isButton)
        .accessibilityHint(snap.isSeed ? WakeCopy.wakeButton(name: name) : LifeStats.hint(name: name))
        .accessibilityAction { hello(plant) }
        .accessibilityIdentifier("plant-love")
    }

    /// The plant's VoiceOver label, ending with "ready for a trim" while a faded bloom shows.
    private func plantLabel(_ plant: PlantCollectible, name: String, pips: Int) -> String {
        let base = LifeStats.plantLabel(name: name, pips: pips)
        return app.showsFadedBloom(plant) ? PruningProCopy.plantLabel(base) : base
    }

    /// Wild Weather draws a dipped plant at the size of its shown stage relative to its stored one (1 = unchanged).
    static func dipScale(_ snap: LifeStats.Snapshot) -> CGFloat {
        guard snap.dipped else { return 1 }
        return GrandGardenArt.stageScale(snap.shownStage) / GrandGardenArt.stageScale(snap.stage)
    }

    /// The petal sound toy (PetalNotes): gentle notes and a light tap, never a hello and never counted.
    private func playPetal(_ petal: Int?) {
        PetalSynth.shared.play(tap: petal, volume: PetalNotes.volume(soundOn: app.settings.soundOn, calm: app.settings.calmMode))
        if PetalNotes.haptic(hapticsOn: app.settings.hapticsOn) { petalNotes += 1 }
    }

    /// Living Touch (light): the plant leans with the finger (none under Reduce Motion, half as far in Calm), a soft tap
    /// at most every 0.3 s, and every third stroke is one hello (the tap hello's path: its line, love, hearts).
    /// VoiceOver keeps the plant's own action (a hello).
    private func livingTouch(_ plant: PlantCollectible, width: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 12)
            .onChanged { v in
                let dx = v.translation.width, dy = v.translation.height
                guard abs(dx) > abs(dy) else { return }
                let motion = LivingTouch.motion(reduceMotion: reduceMotion, appReduceMotion: app.settings.reduceMotionOverride,
                                                calm: app.settings.calmMode)
                withAnimation(.interactiveSpring(response: 0.25, dampingFraction: 0.7)) {
                    lean = LivingTouch.lean(translationX: dx, width: width, motion: motion)
                }
                let now = Date()
                if LivingTouch.mayTap(last: lastTouchTap, now: now) { lastTouchTap = now; touchTaps += 1 }
            }
            .onEnded { v in
                withAnimation(.interpolatingSpring(stiffness: 90, damping: 6)) { lean = 0 }
                guard LivingTouch.isStroke(dx: v.translation.width, dy: v.translation.height) else { return }
                if strokes.stroke(at: Date()) { hello(plant) }
            }
    }

    /// A small hello: the plant sways back and settles, hearts float up, it counts as love, and the plant answers
    /// with a short line in the same toast (and VoiceOver announcement) the tend lines use.
    private func hello(_ plant: PlantCollectible) {
        if app.showsWakeCard(plant) { showWake = true; return }   // Wake the seed: a tap on a seed offers the wake sheet
        hellos += 1
        app.love(plant)
        show(app.helloLine(plant, tap: hellos), ok: true, after: 0)
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
        .padding(.leading, Space.gutter)
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
        GoldenProgressCard(plant: plant)

        // The weather puzzle, from a weathered plant's page while it is open (never in Calm or Quiet Garden).
        if app.weatherPuzzleOpen && (app.plantWeather(plant) != nil || snap.dipped) {
            Button(WeatherPuzzleCopy.bannerButton) { weatherPuzzle = true }
                .buttonStyle(SecondaryButtonStyle())
                .accessibilityIdentifier("plant.weatherPuzzle")
        }

        NameStoryCard(name: plant.name, botanicalName: plant.botanicalName, fact: plant.botanicalFact,
                      story: PlantCatalog.nameStory(for: plant.plantId))
            .onAppear { if plant.earnedCount > 0 { app.noteFactCardRead(plantId: plant.plantId) } }     // Wild Discovery badge

        statusBlock(plant, snap)

        if !quiet { resources }

        if showMistTip {
            Text(MistMakerCopy.tip).font(Theme.font(.footnote)).foregroundStyle(Color.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityIdentifier("mist-tip")
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
            : (thirsty ? PlantDetailCopy.thirsty : LifeStats.stageWord(snap.shownStage, seed: snap.isSeed))
        return VStack(spacing: 4) {
            Text(line).font(Theme.font(.callout, weight: .semibold)).foregroundStyle(Color.successText).multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            if app.showsFadedBloom(plant) {
                Label(PruningProCopy.cue, systemImage: "scissors")
                    .font(Theme.font(.callout, weight: .semibold)).foregroundStyle(Color.appPrimaryText)
                    .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("plant.tidyCue")
            } else if app.showsFreshBud(plant) {
                Text(PruningProCopy.freshBud).font(Theme.font(.callout, weight: .semibold)).foregroundStyle(Color.appPrimaryText)
                    .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("plant.freshBudLine")
            }
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
        case .mist: return .mist
        case .repot: return .repot(.loam)       // the soil is picked in the sheet; the state does not depend on it
        }
    }

    /// The tend buttons in order: Water, Feed, Sun, then Prune and Mist once their tools are in the Shed, then Repot.
    private var tendKinds: [TendKind] {
        [TendKind.water, .feed, .sun] + (showsPrune ? [.prune] : []) + (app.showsMist ? [.mist] : []) + [.repot]
    }

    private func actionBar(_ plant: PlantCollectible) -> some View {
        Group {
            if large {
                // The tiles live in the page at accessibility sizes; the pinned strip only carries the toast.
                Color.clear.frame(height: 1).accessibilityHidden(true)
            } else {
                let kinds = tendKinds
                let columns = TendRowLayout.columns(buttons: kinds.count, typeSize: typeSize)
                let gap = TendRowLayout.spacing(columns: columns)
                if columns >= kinds.count {
                    HStack(spacing: gap) { ForEach(kinds, id: \.self) { tendButton($0, plant) } }
                        .fixedSize(horizontal: false, vertical: true)       // every tile as tall as the tallest
                } else {
                    // Rows of three (or two): every word keeps a whole line (TendRowLayout).
                    Grid(horizontalSpacing: gap, verticalSpacing: gap) {
                        ForEach(Array(stride(from: 0, to: kinds.count, by: columns)), id: \.self) { i in
                            GridRow { ForEach(kinds[i..<min(i + columns, kinds.count)], id: \.self) { tendButton($0, plant) } }
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, Space.gutter).padding(.top, 10).padding(.bottom, 6)
        .background(Color.appBackground.ignoresSafeArea(edges: .bottom))
        .overlay(alignment: .top) { Rectangle().fill(LifePalette.line).frame(height: 1) }
        .overlay(alignment: .top) {
            toastView.padding(.horizontal, Space.gutter)
                .alignmentGuide(.top) { d in d[.bottom] + 10 }
        }
    }

    private func tendButton(_ kind: TendKind, _ plant: PlantCollectible) -> some View {
        let state = app.actionState(action(for: kind), plant: plant)
        let hint = kind == .prune && app.showsFadedBloom(plant) ? PruningProCopy.pruneHint : nil
        return TendActionButton(kind: kind, look: TendButtonLook(kind: kind, state: state, name: displayName(plant)), large: large, nudge: nudges[kind, default: 0],
                                hintOverride: hint) {
            tap(kind, plant)
        }
    }

    private func tap(_ kind: TendKind, _ plant: PlantCollectible) {
        if kind == .repot {
            let state = app.actionState(.repot(.loam), plant: plant)
            if state.isReady {
                showRepot = true
            } else { refuse(kind, state.line ?? TendKind.repot.supplyCaption) }
            return
        }
        run(action(for: kind), kind: kind, plant)
    }

    /// The repot sheet (design-preview/repot-sheet): pick a pot (free to change), pick a soil (a scoop, as before),
    /// then one button that names the new pot. The picked pot and soil start from the plant's own each time it opens.
    private func repotSheet(_ plant: PlantCollectible) -> some View {
        RepotSheet(plantName: displayName(plant), imageName: plant.imageName, currentId: plant.potId,
                   soil: SoilType(rawValue: plant.soilType) ?? .loam, stats: app.potStats, hasPlus: app.hasPlusForPots,
                   packPots: app.visiblePackPots(currentId: plant.potId),
                   reduceMotionOverride: app.settings.reduceMotionOverride,
                   record: { app.recordEarnedPots() }) { pot, soil in
            showRepot = false
            run(.repot(soil), kind: .repot, plant, pot: pot)
        }
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
        if outcome.tidy { snips += 1 }
        if let effect = TendEffect(action) {
            app.play(effect.sound)
            let play = tends.start(effect, pot: TendPot(id: plant.potId), from: from, at: .now)
            let life = TendMotion.lifetime(effect, calm: calm, hold: TendMotion.uiTestHold)
            DispatchQueue.main.asyncAfter(deadline: .now() + life) { tends.finish(id: play.id) }
        } else if action == .mist {
            mists += 1
            // The soft mist hiss (wf-mist-hiss) on the ambient session; Calm has no sound. The soft haptic stays.
            if !app.settings.calmMode { app.play(.mist) }
        } else {
            app.play(.snip)
        }
        let delay = TendEffect(action) == nil ? 0 : (calm ? 0.4 : 0.9)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { if outcome.stageUp { bump.toggle(); stagePuff += 1 } }
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
            // A UI test hold (`-uitest-tend-hold`) keeps the toast up as long as it holds the effect.
            let stay = 3 + (TendMotion.uiTestHold ? TendMotion.holdSeconds : 0)
            DispatchQueue.main.asyncAfter(deadline: .now() + stay) { if toast?.id == item.id { withAnimation { toast = nil } } }
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
