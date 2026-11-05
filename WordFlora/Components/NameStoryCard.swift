import SwiftUI

/// The plant-page fact card (design-preview/fact-card): how a plant got its name, or a plain "Did you know?" fact
/// when the plant has no verified name story. Placement on the plant page belongs to PlantDetailView.
struct NameStoryCard: View {
    /// Everything the card shows, worked out once so tests can check the words without rendering.
    struct Content: Equatable {
        struct Chip: Equatable {
            let meaning: String
            let name: String
            let symbol: String
        }

        /// What VoiceOver and the speaker say ("How Daisy got its name").
        let title: String
        /// The small caps line over the big name ("How it got its name"); the name is right under it.
        let eyebrow: String
        let name: String
        let botanicalName: String
        let chip: Chip?
        let lines: [String]
        let more: String?

        init(name: String, botanicalName: String, fact: String, story: NameStory?) {
            self.name = name
            self.botanicalName = botanicalName
            if let story {
                title = "How \(name) got its name"
                eyebrow = "How it got its name"
                chip = Chip(meaning: story.meaning, name: name, symbol: story.symbol ?? "text.book.closed.fill")
                lines = [story.line, story.funFact]
                more = "In \(story.language), it was \u{201C}\(story.origin).\u{201D} That means \u{201C}\(story.meaning).\u{201D}"
            } else {
                title = "Did you know?"
                eyebrow = title
                chip = nil
                lines = [fact]
                more = nil
            }
        }

        init(plant: PlantInfo) {
            self.init(name: plant.name, botanicalName: plant.botanicalName, fact: plant.botanicalFact, story: plant.nameStory)
        }

        /// What the speaker button reads and what Share sends.
        var spoken: String { ([title + "."] + lines + [more].compactMap { $0 }).joined(separator: " ") }
        var shareText: String { "\(name) (\(botanicalName)). " + lines.joined(separator: " ") + " Found in WordFlora." }
    }

    let content: Content
    @State private var expanded = false
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOver

    init(content: Content) { self.content = content }
    init(plant: PlantInfo) { self.content = Content(plant: plant) }
    init(name: String, botanicalName: String, fact: String, story: NameStory?) {
        self.content = Content(name: name, botanicalName: botanicalName, fact: fact, story: story)
    }

    private var shape: RoundedRectangle { RoundedRectangle(cornerRadius: 24, style: .continuous) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center) {
                Text(content.eyebrow)
                    .textCase(.uppercase).kerning(0.8)
                    .font(Theme.font(.caption, weight: .heavy)).foregroundStyle(Color.appPrimaryText)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityLabel(content.title)
                    .accessibilityAddTraits(.isHeader)
                Spacer(minLength: 8)
                if ReadAloud.shouldOffer(voiceOverRunning: voiceOver) {
                    Button { ReadAloud.shared.speak(hint: content.spoken, extra: nil, simpler: nil) } label: {
                        Image(systemName: "speaker.wave.2.fill").font(.body.weight(.semibold))
                            .foregroundStyle(Color.appPrimaryText)
                            .frame(width: Theme.minTap, height: Theme.minTap)
                            .background(Color.successText.opacity(0.14), in: Circle())
                    }
                    .accessibilityLabel("Read aloud")
                }
            }

            storyText

            HStack {
                if content.more != nil {
                    Button { withAnimation(.easeInOut(duration: 0.25)) { expanded.toggle() } } label: {
                        HStack(spacing: 4) {
                            Text(expanded ? "Show less" : "Tell me more")
                                .underline(color: Color.appAccent)
                            Image(systemName: expanded ? "chevron.up" : "chevron.down").font(.caption.weight(.bold))
                        }
                        .font(Theme.font(.subheadline, weight: .heavy)).foregroundStyle(Color.appPrimaryText)
                        .frame(minHeight: Theme.minTap)
                    }
                    .accessibilityLabel(expanded ? "Show less" : "Tell me more")
                }
                Spacer(minLength: 8)
                ShareLink(item: content.shareText) {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .font(Theme.font(.subheadline, weight: .heavy)).foregroundStyle(Color.appPrimaryText)
                        .frame(minHeight: Theme.minTap)
                }
                .accessibilityLabel("Share this fact")
            }
            .padding(.top, 8)
        }
        .padding(.horizontal, 18).padding(.top, 16).padding(.bottom, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(alignment: .topTrailing) {
            Circle()
                .fill(RadialGradient(colors: [Color.appAccent.opacity(0.35), .clear], center: .center, startRadius: 0, endRadius: 60))
                .frame(width: 120, height: 120).offset(x: 30, y: -30)
                .accessibilityHidden(true)
        }
        .background(Color.appSurface, in: shape)
        .clipShape(shape)
        .overlay(shape.stroke(Color.appPrimaryText.opacity(0.14), lineWidth: 1.5))
        .accessibilityIdentifier("name-story-card")
    }

    /// Name, botanical name, origin chip and lines read as one VoiceOver element.
    private var storyText: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(content.name)
                .font(.system(.largeTitle, design: .serif, weight: .bold))
                .foregroundStyle(Color.appPrimaryText)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 2)
            Text(content.botanicalName)
                .font(.system(.subheadline, design: .serif).italic())
                .foregroundStyle(Color.appPrimaryText)
                .padding(.top, 2).padding(.bottom, 10)

            if let chip = content.chip {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 8) { chipViews(chip) }
                    VStack(alignment: .leading, spacing: 6) { chipViews(chip) }
                }
                .padding(.bottom, 10)
            }

            VStack(alignment: .leading, spacing: 2) {
                ForEach(content.lines, id: \.self) { line in
                    Text(line).font(Theme.font(.body)).foregroundStyle(Color.appPrimaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if expanded, let more = content.more {
                VStack(alignment: .leading, spacing: 8) {
                    Line().stroke(Color.appPrimaryText.opacity(0.2), style: StrokeStyle(lineWidth: 1.5, dash: [5, 4])).frame(height: 1.5)
                    Text(more).font(Theme.font(.subheadline)).foregroundStyle(Color.appPrimaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 8)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    @ViewBuilder private func chipViews(_ chip: Content.Chip) -> some View {
        Label(chip.meaning, systemImage: chip.symbol)
            .font(Theme.font(.subheadline, weight: .heavy)).foregroundStyle(Color.appPrimaryText)
            .padding(.horizontal, 12).padding(.vertical, 6)
            .background(Color.appAccent.opacity(0.2), in: Capsule())
        Image(systemName: "arrow.right").font(.subheadline.weight(.heavy)).foregroundStyle(Color.secondaryText)
        Text(chip.name)
            .font(Theme.font(.subheadline, weight: .heavy)).foregroundStyle(Color.ink)
            .padding(.horizontal, 12).padding(.vertical, 6)
            .background(Color.appAccent, in: Capsule())
    }

    private var accessibilityText: String {
        var parts = [content.title, "\(content.name), \(content.botanicalName)"]
        if let chip = content.chip { parts.append("\(chip.meaning) became \(chip.name)") }
        parts += content.lines
        if expanded, let more = content.more { parts.append(more) }
        return parts.joined(separator: ". ")
    }
}

private struct Line: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path(); p.move(to: CGPoint(x: rect.minX, y: rect.midY)); p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY)); return p
    }
}

#Preview("Daisy story") {
    ScrollView {
        VStack(spacing: 16) {
            NameStoryCard(name: "Daisy", botanicalName: "Bellis perennis",
                          fact: "Its name comes from 'day's eye': petals close at night.",
                          story: NameStory(origin: "dæges ēage", language: "Old English", meaning: "day's eye",
                                           line: "Daisy comes from \u{201C}day's eye.\u{201D}",
                                           funFact: "Its petals close at night and open with the morning sun, like an eye waking up.",
                                           symbol: "sun.max.fill"))
            NameStoryCard(name: "Rose", botanicalName: "Rosa gallica",
                          fact: "Its fruits, called rose hips, are rich in vitamin C.", story: nil)
        }
        .padding(16)
    }
    .background(Color.appBackground)
}
