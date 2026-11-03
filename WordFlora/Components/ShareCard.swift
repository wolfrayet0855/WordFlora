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
