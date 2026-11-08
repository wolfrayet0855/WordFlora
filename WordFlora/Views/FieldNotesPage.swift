import SwiftUI

/// Field Notes art (design-preview/badge-mechanics: notebook-page.svg, leaf-stamp.svg). Drawn in SwiftUI from the
/// SVG coordinates; no bitmap files. The page stays paper in dark mode, a little dimmer so it does not glare.
enum FieldNotesPalette {
    static let paper = Color(hex: 0xF6EBD3)
    static let spine = Color(hex: 0xEADBB9)
    static let edge = Color(hex: 0xD9C29A)
    static let rule = Color(hex: 0xC9B48A)
    /// Text on the paper: about 7.9:1 on `paper`.
    static let ink = Color(hex: 0x5B4A32)
    static let stampInk = Color(hex: 0x3F8A4A)
    static let sepia = Color(hex: 0xF3E2C2)
}

/// The leaf stamp (leaf-stamp.svg, 120 x 120 box): an inked ring, a dashed inner ring, a leaf with paper-coloured veins
/// and knock-out specks for a rubber-stamp feel. The -12 degree tilt is part of the art.
struct LeafStampView: View {
    var body: some View {
        Canvas { ctx, size in
            let k = min(size.width, size.height) / 120
            func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * k, y: y * k) }
            ctx.translateBy(x: 60 * k, y: 60 * k); ctx.rotate(by: .degrees(-12)); ctx.translateBy(x: -60 * k, y: -60 * k)
            let ink = GraphicsContext.Shading.color(FieldNotesPalette.stampInk)
            let paper = GraphicsContext.Shading.color(FieldNotesPalette.paper)
            ctx.stroke(Path(ellipseIn: CGRect(x: 10 * k, y: 10 * k, width: 100 * k, height: 100 * k)), with: ink, lineWidth: 5 * k)
            ctx.stroke(Path(ellipseIn: CGRect(x: 18 * k, y: 18 * k, width: 84 * k, height: 84 * k)), with: ink,
                       style: StrokeStyle(lineWidth: 1.8 * k, lineCap: .round, dash: [3 * k, 4 * k]))
            var leaf = Path()
            leaf.move(to: p(60, 26))
            leaf.addCurve(to: p(60, 92), control1: p(84, 36), control2: p(88, 66))
            leaf.addCurve(to: p(60, 26), control1: p(32, 66), control2: p(36, 36))
            ctx.fill(leaf, with: ink)
            var mid = Path(); mid.move(to: p(60, 32)); mid.addLine(to: p(60, 92))
            ctx.stroke(mid, with: paper, style: StrokeStyle(lineWidth: 2.6 * k, lineCap: .round))
            var veins = Path()
            for (y0, y1, dx) in [(50.0, 42.0, 12.0), (64, 55, 15), (78, 70, 11)] {
                veins.move(to: p(60, y0)); veins.addLine(to: p(60 + dx, y1))
                veins.move(to: p(60, y0)); veins.addLine(to: p(60 - dx, y1))
            }
            ctx.stroke(veins, with: paper, style: StrokeStyle(lineWidth: 1.8 * k, lineCap: .round))
            var stem = Path(); stem.move(to: p(60, 92)); stem.addQuadCurve(to: p(55, 104), control: p(60, 100))
            ctx.stroke(stem, with: ink, style: StrokeStyle(lineWidth: 3.2 * k, lineCap: .round))
            // The specks are cut out of the ink, so whatever is under the stamp shows through.
            ctx.blendMode = .destinationOut
            for (x, y, r) in [(31.0, 38.0, 1.6), (88, 30, 1.2), (96, 71, 1.8), (70, 98, 1.3), (24, 78, 1.1),
                              (52, 18, 1.0), (64, 58, 1.2), (55, 74, 0.9), (43, 95, 1.4)] {
                ctx.fill(Path(ellipseIn: CGRect(x: (x - r) * k, y: (y - r) * k, width: 2 * r * k, height: 2 * r * k)), with: .color(.black))
            }
        }
        .compositingGroup()
        .opacity(0.9)
        .accessibilityHidden(true)
    }
}

/// The paper behind a page (notebook-page.svg): parchment with a darker spine and five binding holes on the leading
/// edge, faint rules, and two strips of tape at the top corners.
struct NotebookPaper: View {
    var body: some View {
        Canvas { ctx, size in
            let page = Path(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 14)
            ctx.fill(page, with: .color(FieldNotesPalette.paper))
            let spineW: CGFloat = 18
            ctx.fill(Path(CGRect(x: 0, y: 0, width: spineW, height: size.height)).intersection(page), with: .color(FieldNotesPalette.spine))
            for i in 0..<5 {
                let y = size.height * (CGFloat(i) + 0.5) / 5
                ctx.fill(Path(ellipseIn: CGRect(x: spineW / 2 - 3.5, y: y - 3.5, width: 7, height: 7)), with: .color(FieldNotesPalette.edge))
            }
            var rules = Path()
            var y: CGFloat = 120
            while y < size.height - 12 { rules.move(to: CGPoint(x: spineW + 14, y: y)); rules.addLine(to: CGPoint(x: size.width - 14, y: y)); y += 28 }
            ctx.stroke(rules, with: .color(FieldNotesPalette.rule.opacity(0.45)), lineWidth: 1)
            ctx.stroke(page, with: .color(FieldNotesPalette.edge), lineWidth: 1.5)
            for (x, angle) in [(size.width * 0.22, -8.0), (size.width * 0.78, 7.0)] {
                var tape = ctx
                tape.translateBy(x: x, y: 2); tape.rotate(by: .degrees(angle))
                tape.fill(Path(CGRect(x: -22, y: -7, width: 44, height: 14)), with: .color(Color.white.opacity(0.5)))
            }
        }
        .accessibilityHidden(true)
    }
}

/// One friend's page in the Visitors' book. A met friend: sepia sticker, name, "Seen on <date>", the fact, then Listen and
/// "I read it!" (or "Stamped"). Not met: a faint outline and "Meet this friend to fill this page." with no buttons.
struct FieldNotesPage: View {
    let visitor: VisitorSpecies
    let met: Bool
    let metOn: String?
    let stamped: Bool
    /// The stamp just landed on this page (plays the press once).
    let justStamped: Bool
    let readIt: FieldNotes.ReadItButton
    let showsListen: Bool
    let reading: Bool
    let motion: StampMotion
    let onListen: () -> Void
    let onReadIt: () -> Void

    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.colorScheme) private var scheme
    @State private var pressed = false

    /// The stamp press: default, Reduce Motion (a fade) or Calm (the press at half speed).
    enum StampMotion { case press, fade, calmPress }

    private var large: Bool { typeSize.isAccessibilitySize }

    /// The page's side padding: it clears the 18 pt spine and its holes; tighter at the accessibility sizes.
    /// (The spine is 18 pt with its holes inside it, so 24 still leaves 6 pt of paper before the words.)
    static func leading(_ size: DynamicTypeSize) -> CGFloat { size.isAccessibilitySize ? 24 : 34 }
    static func trailing(_ size: DynamicTypeSize) -> CGFloat { size.isAccessibilitySize ? 8 : 18 }
    /// Subheadline only at AX5 (the same size as title3 at AX4), so the name never shrinks as the text grows.
    static func nameStyle(_ size: DynamicTypeSize) -> Font.TextStyle { size >= .accessibility5 ? .subheadline : .title3 }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            paperPage
            if met { buttons }
        }
        .onAppear { pressed = !justStamped }
        .onChange(of: justStamped) { _, now in if now { land() } }
    }

    private var paperPage: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Spacer(minLength: 0)
                Image("visitor_\(visitor.id)_sticker").resizable().scaledToFit()
                    .frame(width: large ? 96 : 108, height: large ? 96 : 108)
                    .modifier(StickerLook(met: met))
                    .frame(maxWidth: .infinity, minHeight: large ? 104 : 124)
                    .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(FieldNotesPalette.rule, style: StrokeStyle(lineWidth: 1.5, dash: [5, 4])))
                    .frame(maxWidth: 220)
                Spacer(minLength: 0)
            }
            // A step smaller at the accessibility sizes, so "Hummingbird" stays whole (TextFitLayoutTests); still bold
            // and first on the page.
            Text(met ? visitor.name : FieldNotesCopy.unmetTitle)
                .font(.system(Self.nameStyle(typeSize), design: .rounded, weight: .bold)).foregroundStyle(FieldNotesPalette.ink)
                .fixedSize(horizontal: false, vertical: true)
            if met {
                if let metOn {
                    Text(FieldNotesCopy.metOn(metOn)).font(.system(.footnote, design: .rounded, weight: .semibold))
                        .foregroundStyle(FieldNotesPalette.ink.opacity(0.85))
                }
                if let fact = visitor.fact {
                    Text(fact).font(.system(.body, design: .rounded)).foregroundStyle(FieldNotesPalette.ink)
                        .lineSpacing(6).fixedSize(horizontal: false, vertical: true)
                }
                if stamped {
                    // The stamp sits on its own line after the fact (trailing), so it never covers words.
                    HStack { Spacer(); stamp }
                }
            } else {
                Text(FieldNotesCopy.unmetPage).font(.system(.body, design: .rounded)).foregroundStyle(FieldNotesPalette.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.leading, Self.leading(typeSize)).padding(.trailing, Self.trailing(typeSize)).padding(.vertical, 18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(NotebookPaper())
        .brightness(scheme == .dark ? -0.06 : 0)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(met ? FieldNotesCopy.pageLabel(name: visitor.name, met: metOn, fact: visitor.fact ?? "", stamped: stamped)
                                : FieldNotesCopy.unmetLabel)
        .accessibilityIdentifier("book.page.\(visitor.id)")
    }

    private var stamp: some View {
        let size: CGFloat = large ? 64 : 84
        return LeafStampView().frame(width: size, height: size)
            .scaleEffect(pressed ? 1 : (motion == .fade ? 1 : 1.35))
            .opacity(pressed ? 1 : 0)
            .offset(y: pressed || motion == .fade ? 0 : -10)
            .accessibilityIdentifier("book.stamp.\(visitor.id)")
    }

    /// The press: from 1.35 and clear to 0.96, then settles to 1 (0.28 s + 0.12 s; twice as slow in Calm). Reduce Motion
    /// fades it in over 0.3 s at full size.
    private func land() {
        pressed = false
        DispatchQueue.main.async {
            switch motion {
            case .fade:
                withAnimation(.easeInOut(duration: 0.3)) { pressed = true }
            case .press, .calmPress:
                let slow = motion == .calmPress ? 2.0 : 1.0
                withAnimation(.easeIn(duration: 0.28 * slow)) { pressed = true }
            }
        }
    }

    @ViewBuilder private var buttons: some View {
        let layout = large ? AnyLayout(VStackLayout(spacing: 8)) : AnyLayout(HStackLayout(spacing: 10))
        layout {
            if showsListen {
                Button(action: onListen) {
                    Label(FieldNotesCopy.listen, systemImage: reading ? "speaker.wave.3.fill" : "speaker.wave.2.fill")
                }
                .buttonStyle(SecondaryButtonStyle())
                .accessibilityHint(FieldNotesCopy.listenHint)
                .accessibilityIdentifier("book.listen.\(visitor.id)")
            }
            switch readIt {
            case .readIt:
                Button(action: onReadIt) { Label(FieldNotesCopy.readIt, systemImage: "checkmark.circle") }
                    .buttonStyle(SecondaryButtonStyle())
                    .accessibilityHint(FieldNotesCopy.readItHint)
                    .accessibilityIdentifier("book.readIt.\(visitor.id)")
            case .stamped:
                Label(FieldNotesCopy.stamped, systemImage: "leaf.fill")
                    .font(Theme.font(.body, weight: .semibold)).foregroundStyle(Color.successText)
                    .frame(maxWidth: .infinity, minHeight: Theme.minTap + 8)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(FieldNotesCopy.stamped)
                    .accessibilityAddTraits(.isStaticText)
                    .accessibilityIdentifier("book.stamped.\(visitor.id)")
            case .hidden:
                EmptyView()
            }
        }
    }
}

/// Met: a light sepia, so the friend still looks like itself. Not met: a faint grey outline.
private struct StickerLook: ViewModifier {
    let met: Bool
    func body(content: Content) -> some View {
        if met {
            content.grayscale(0.25).colorMultiply(FieldNotesPalette.sepia)
        } else {
            content.grayscale(1).opacity(0.35)
        }
    }
}
