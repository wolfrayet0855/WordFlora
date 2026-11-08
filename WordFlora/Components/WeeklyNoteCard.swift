import SwiftUI

/// The weekly garden note on Home (WeeklyNote), in Home's note card style: leaf icon, title, the week's rows as
/// wrapping lines, a closing line, then "Lovely" and "Visit my garden" (side by side, stacked at accessibility sizes)
/// and, for 13 and up outside Quiet Garden, "Share my week". VoiceOver reads the words as one element, then the buttons.
struct WeeklyNoteCard: View {
    let summary: WeeklyNote.Summary
    let quiet: Bool
    let canShare: Bool
    let onLovely: () -> Void
    let onVisit: () -> Void

    @Environment(\.dynamicTypeSize) private var typeSize
    @ScaledMetric(relativeTo: .title3) private var iconSize: CGFloat = 22
    @State private var shareImage: Image?

    private var shape: RoundedRectangle { RoundedRectangle(cornerRadius: 20, style: .continuous) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            words
            buttons
            if canShare, let shareImage {
                ShareLink(item: shareImage, message: Text(WeeklyNoteCopy.caption),
                          preview: SharePreview(WeeklyNoteCopy.caption, image: shareImage)) {
                    Label(WeeklyNoteCopy.share, systemImage: "square.and.arrow.up")
                        .underline()
                        .font(Theme.font(.callout, weight: .bold)).foregroundStyle(Color.accentText)
                        .multilineTextAlignment(.leading).fixedSize(horizontal: false, vertical: true)
                        .frame(minHeight: Theme.minTap)
                }
                .accessibilityHint(WeeklyNoteCopy.shareHint)
                .accessibilityIdentifier("weeklyNote.share")
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.appSurface, in: shape)
        .overlay(shape.stroke(Color.appPrimaryText.opacity(0.12)))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("weeklyNote")
        .onAppear {
            guard canShare, shareImage == nil else { return }
            shareImage = WeekShareCard(rows: WeeklyNoteCopy.rows(summary, quiet: false)).rendered()
        }
    }

    private var words: some View {
        HStack(alignment: .top, spacing: 10) {
            // At accessibility sizes the leaf would take a column of its own beside the words.
            if !typeSize.isAccessibilitySize {
                Image(systemName: "leaf.fill").font(.system(size: iconSize)).foregroundStyle(Color.accentText)
                    .padding(.top, 2).accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: 6) {
                // The title alone is the VoiceOver header; the rows and closing line read next as one element.
                Text(WeeklyNoteCopy.title).font(Theme.font(.headline)).foregroundStyle(Color.appPrimaryText)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier("weeklyNote.title")
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(WeeklyNoteCopy.rows(summary, quiet: quiet), id: \.self) { row in
                        Text(row).font(Theme.font(.subheadline)).foregroundStyle(Color.appPrimaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Text(WeeklyNoteCopy.closing(weekKey: summary.weekKey))
                        .font(Theme.font(.subheadline, weight: .semibold)).foregroundStyle(Color.successText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(WeeklyNoteCopy.bodyLabel(summary, quiet: quiet))
                .accessibilityIdentifier("weeklyNote.text")
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .contain)
    }

    private var buttons: some View {
        let layout = typeSize.isAccessibilitySize ? AnyLayout(VStackLayout(spacing: 10)) : AnyLayout(HStackLayout(spacing: 10))
        return layout {
            Button(action: onLovely) {
                Text(WeeklyNoteCopy.lovely).multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
            }
            .buttonStyle(SecondaryButtonStyle())
            .accessibilityIdentifier("weeklyNote.lovely")
            Button(action: onVisit) {
                Text(WeeklyNoteCopy.visit).multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
            }
            .buttonStyle(SecondaryButtonStyle())
            .accessibilityIdentifier("weeklyNote.visit")
        }
    }
}
