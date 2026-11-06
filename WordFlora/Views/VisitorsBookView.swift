import SwiftUI

/// The Visitors' book (G-5): a page for every visitor met, with the fact, plus the weather stickers. Friends not met
/// yet are soft outlines (no locks); stickers not earned yet are dashed. Laid out eagerly so every card stays measurable.
struct VisitorsBookView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        let album = app.album
        let met = VisitorCatalog.all.filter { album.count(of: $0.id) > 0 }
        let owned = WeatherSticker.owned(in: album)
        let showStickers = !owned.isEmpty || app.weatherNow.showsMechanics
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                header(EndgameCopy.bookFriends, EndgameCopy.bookFriendsCount(met.count, of: VisitorCatalog.all.count))
                VStack(spacing: 12) {
                    ForEach(VisitorCatalog.all, id: \.id) { v in page(v, met: album.count(of: v.id)) }
                }
                if showStickers {
                    header(EndgameCopy.bookStickers, EndgameCopy.bookStickersCount(owned.count, of: WeatherSticker.allCases.count))
                        .padding(.top, 8)
                    let cols = typeSize.isAccessibilitySize ? 2 : 4
                    Grid(horizontalSpacing: 12, verticalSpacing: 12) {
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
            .padding(20)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle(EndgameCopy.visitorsBook)
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("visitorsBook")
    }

    private func header(_ title: String, _ line: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title.uppercased()).font(Theme.font(.footnote, weight: .heavy)).tracking(1.4).foregroundStyle(Color.secondaryText)
                .accessibilityLabel(title).accessibilityAddTraits(.isHeader)
            Text(line).font(Theme.font(.subheadline, weight: .semibold)).foregroundStyle(Color.appPrimaryText)
        }
    }

    private func page(_ v: VisitorSpecies, met: Int) -> some View {
        let isMet = met > 0
        let layout = typeSize.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: 10)) : AnyLayout(HStackLayout(alignment: .top, spacing: 14))
        return layout {
            Image("visitor_\(v.id)_sticker").resizable().scaledToFit().frame(width: 64, height: 64)
                .saturation(isMet ? 1 : 0).opacity(isMet ? 1 : 0.3)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(v.name).font(Theme.font(.headline, weight: .bold)).foregroundStyle(Color.appPrimaryText)
                if isMet {
                    Text(VisitorsCopy.metCount(met)).font(Theme.font(.subheadline, weight: .semibold)).foregroundStyle(Color.secondaryText)
                    if let fact = v.fact {
                        Text(fact).font(Theme.font(.subheadline)).foregroundStyle(Color.appPrimaryText).fixedSize(horizontal: false, vertical: true)
                    }
                } else {
                    Text(EndgameCopy.bookNotYet).font(Theme.font(.subheadline)).foregroundStyle(Color.secondaryText)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isMet ? Color.appSurface : Color.clear, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
        .overlay(RoundedRectangle(cornerRadius: Theme.cardRadius)
            .strokeBorder(Color.appPrimaryText.opacity(isMet ? 0.08 : 0.25), style: StrokeStyle(lineWidth: 1.5, dash: isMet ? [] : [5, 4])))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("book.page.\(v.id)")
    }
}
