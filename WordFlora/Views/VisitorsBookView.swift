import SwiftUI

/// The Visitors' book (G-5): a notebook page for every visitor (Field Notes), plus the weather stickers. Friends not met
/// yet are soft outlines (no locks); stickers not earned yet are dashed. Laid out eagerly so every card stays measurable.
/// Field Notes: a page is collected only when its fact is read aloud to the end or "I read it!" is tapped, never on
/// opening the book (docs/pm/badge-mechanics-art.md, section 1).
struct VisitorsBookView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOver
    @State private var listening = FieldNotes.Listening()
    @State private var justStamped: String?
    @State private var toast = 0
    @State private var toastShown = false
    @State private var stampTaps = 0

    private static let metFormat: DateFormatter = {
        let f = DateFormatter(); f.setLocalizedDateFormatFromTemplate("d MMM"); return f
    }()

    var body: some View {
        let album = app.album
        let met = VisitorCatalog.all.filter { album.count(of: $0.id) > 0 }
        let owned = WeatherSticker.owned(in: album)
        let showStickers = !owned.isEmpty || app.weatherNow.showsMechanics
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                header(EndgameCopy.bookFriends, EndgameCopy.bookFriendsCount(met.count, of: VisitorCatalog.all.count))
                if FieldNotes.showsPageCount(quiet: app.settings.quietGarden) {
                    Text(FieldNotesCopy.notebookTitle + ": " + FieldNotesCopy.pages(FieldNotes.collected(in: app.badges), of: VisitorCatalog.all.count))
                        .font(Theme.font(.subheadline, weight: .semibold)).foregroundStyle(Color.secondaryText)
                        .accessibilityIdentifier("book.notebookCount")
                }
                VStack(spacing: 18) {
                    ForEach(VisitorCatalog.all, id: \.id) { v in page(v, album: album) }
                }
                if showStickers {
                    header(EndgameCopy.bookStickers, EndgameCopy.bookStickersCount(owned.count, of: WeatherSticker.allCases.count))
                        .padding(.top, 8)
                    // Four a row, three from xLarge, two at AX1 to AX3, one from AX4, so every name stays whole
                    // ("Snowflake" broke from xLarge in four columns; GridColumns, TextFitLayoutTests).
                    let cols = GridColumns.count(.stickers, for: typeSize)
                    Grid(horizontalSpacing: GridColumns.spacing(.stickers), verticalSpacing: 12) {
                        ForEach(Array(stride(from: 0, to: WeatherSticker.allCases.count, by: cols)), id: \.self) { start in
                            GridRow {
                                ForEach(Array(WeatherSticker.allCases[start..<min(start + cols, WeatherSticker.allCases.count)])) { s in
                                    VStack(spacing: 6) {
                                        WeatherStickerImage(sticker: s, owned: owned.contains(s))
                                        Text(s.name).font(Theme.font(.footnote, weight: .semibold)).foregroundStyle(Color.appPrimaryText)
                                            .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                                            .accessibilityHidden(true)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .accessibilityElement(children: .combine)
                                    .accessibilityIdentifier("book.sticker.\(s.rawValue)")
                                }
                            }
                        }
                    }
                    if owned.count < WeatherSticker.allCases.count && app.weatherNow.showsMechanics {
                        Text(EndgameCopy.bookStickersHint).font(Theme.font(.subheadline)).foregroundStyle(Color.secondaryText)
                    }
                }
            }
            .padding(.horizontal, Space.gutter).padding(.vertical, Space.card)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle(EndgameCopy.visitorsBook)
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("visitorsBook")
        .overlay(alignment: .bottom) { if toastShown { toastView } }
        .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.6), trigger: stampTaps) { _, _ in app.settings.hapticsOn }
        // Leaving the book stops the voice; a page read only part way is not collected.
        .onDisappear { ReadAloud.shared.stop(); listening.cancel() }
    }

    private var stampMotion: FieldNotesPage.StampMotion {
        if reduceMotion || app.settings.reduceMotionOverride { return .fade }
        return app.settings.calmMode ? .calmPress : .press
    }

    private func listen(_ v: VisitorSpecies) {
        guard let fact = v.fact else { return }
        let token = listening.start(v.id)
        ReadAloud.shared.speak(hint: fact, extra: nil, simpler: nil) {
            if let page = listening.finish(token: token) { collect(page) }
        }
    }

    private func collect(_ id: String) {
        guard app.collectFieldNote(id) else { return }
        justStamped = id
        stampTaps += 1
        if !app.settings.calmMode { app.play(.button, volume: 0.5) }
        toast += 1
        let mine = toast
        withAnimation(.easeOut(duration: 0.25)) { toastShown = true }
        AccessibilityNotification.Announcement(FieldNotesCopy.pageAdded).post()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            if toast == mine { withAnimation(.easeIn(duration: 0.25)) { toastShown = false } }
        }
    }

    private var toastView: some View {
        HStack(spacing: 10) {
            LeafStampView().frame(width: 22, height: 22)
            Text(FieldNotesCopy.pageAdded).font(Theme.font(.subheadline, weight: .semibold)).foregroundStyle(Color.appBackground)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
        .background(Color.appPrimaryText, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, Space.gutter).padding(.bottom, 12)
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("book.toast")
    }

    private func header(_ title: String, _ line: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title.uppercased()).font(Theme.font(.footnote, weight: .heavy)).tracking(1.2).foregroundStyle(Color.secondaryText)
                .accessibilityLabel(title).accessibilityAddTraits(.isHeader)
            Text(line).font(Theme.font(.subheadline, weight: .semibold)).foregroundStyle(Color.appPrimaryText)
        }
    }

    private func page(_ v: VisitorSpecies, album: StickerAlbum) -> some View {
        let isMet = album.count(of: v.id) > 0
        let stamped = isMet && app.isFieldNoteStamped(v.id)
        return FieldNotesPage(
            visitor: v, met: isMet, metOn: album.lastSeen(of: v.id).map { Self.metFormat.string(from: $0) },
            stamped: stamped, justStamped: justStamped == v.id,
            readIt: FieldNotes.readItButton(stamped: stamped, quiet: app.settings.quietGarden),
            showsListen: v.fact != nil && FieldNotes.showsListen(voiceOverRunning: voiceOver),
            reading: listening.page == v.id, motion: stampMotion,
            onListen: { listen(v) }, onReadIt: { listening.cancel(); ReadAloud.shared.stop(); collect(v.id) })
    }
}
