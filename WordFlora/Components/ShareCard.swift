import SwiftUI

/// The picture people share. A fixed warm palette in both appearances, because it leaves the app as an image.
struct PlantShareCard: View {
    let plantName: String
    let botanicalName: String
    let imageName: String
    let fact: String

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "leaf.circle.fill").foregroundStyle(Color(hex: 0x2E7D32))
                Text("WordFlora").font(.system(.subheadline, design: .rounded, weight: .heavy)).foregroundStyle(Color(hex: 0x2C3E2C))
            }
            Image(imageName).resizable().scaledToFit().frame(height: 120)
            Text(plantName).font(.system(.title2, design: .rounded, weight: .bold)).foregroundStyle(Color(hex: 0x2C3E2C))
            Text(botanicalName).font(.system(.footnote, design: .rounded)).italic().foregroundStyle(Color(hex: 0x4A5C4A))
            Text(fact).font(.system(.callout, design: .rounded)).multilineTextAlignment(.center).foregroundStyle(Color(hex: 0x2C3E2C))
            Text("Guess words. Grow a garden.").font(.system(.caption, design: .rounded, weight: .semibold)).foregroundStyle(Color(hex: 0x8A5A00))
        }
        .padding(24)
        .frame(width: 320)
        .background(LinearGradient(colors: [Color(hex: 0xFFF4D6), Color(hex: 0xFAF7F0)], startPoint: .top, endPoint: .bottom))
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    @MainActor
    func rendered() -> Image? {
        let r = ImageRenderer(content: self)
        r.scale = 3
        return r.uiImage.map { Image(uiImage: $0) }
    }
}

/// The weekly note's share picture (13 and up): the PlantShareCard pattern, a fixed warm palette and 320 pt wide.
/// Only the week's rows (species names, never typed names), no date, no player name.
struct WeekShareCard: View {
    let rows: [String]

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "leaf.circle.fill").foregroundStyle(Color(hex: 0x2E7D32))
                Text(WeeklyNoteCopy.shareHeader).font(.system(.subheadline, design: .rounded, weight: .heavy)).foregroundStyle(Color(hex: 0x2C3E2C))
            }
            Text(WeeklyNoteCopy.title).font(.system(.title3, design: .rounded, weight: .bold)).foregroundStyle(Color(hex: 0x2C3E2C))
                .multilineTextAlignment(.center)
            VStack(alignment: .leading, spacing: 8) {
                ForEach(rows, id: \.self) { row in
                    Label {
                        Text(row).font(.system(.callout, design: .rounded)).foregroundStyle(Color(hex: 0x2C3E2C))
                            .fixedSize(horizontal: false, vertical: true)
                    } icon: {
                        Image(systemName: "leaf.fill").foregroundStyle(Color(hex: 0x2E7D32))
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Text(WeeklyNoteCopy.tagline).font(.system(.caption, design: .rounded, weight: .semibold)).foregroundStyle(Color(hex: 0x8A5A00))
        }
        .padding(24)
        .frame(width: 320)
        .background(LinearGradient(colors: [Color(hex: 0xFFF4D6), Color(hex: 0xFAF7F0)], startPoint: .top, endPoint: .bottom))
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    @MainActor
    func rendered() -> Image? {
        let r = ImageRenderer(content: self)
        r.scale = 3
        return r.uiImage.map { Image(uiImage: $0) }
    }
}
