import Foundation

/// Petal thinning: as a plant's love pips fall (5 full ... 0 empty), its petals let go one evenly spread group
/// at a time, and plants with no petals droop instead. The data comes from `PlantThinning.json`, which
/// `tools/thin_svg.py` generates from the plant art together with the layer imagesets in
/// `Assets.xcassets/PlantLayers`. The rules below mirror that script (and the approved prototype in
/// design-preview/tending/parts/thinning.js) exactly, so the app can recompute any state on its own.
enum PetalThinning {
    /// Share of each ring kept at 0...5 pips, front-loaded so 4 pips already looks sparser.
    static let keptShare: [Double] = [0, 0.13, 0.27, 0.47, 0.72, 1]
    static let golden = 0.6180339887

    /// How many of a ring's `count` petals show at `pips`. Every pip drops at least one petal on rings of
    /// five or more, and a ring keeps its last petal until 0 pips, so only 0 pips is bare.
    static func keptCount(of count: Int, pips: Int) -> Int {
        if pips >= 5 { return count }
        if pips <= 0 || count <= 0 { return 0 }
        var kept = Int((Double(count) * keptShare[pips] + 0.5).rounded(.down))
        if count >= 5 { kept = min(max(kept, pips), count - (5 - pips)) }
        return max(kept, 1)
    }

    /// The nested keep order of a ring: walk the ring by the golden ratio so gaps never bunch on one side.
    /// The first `keptCount` entries are the petals still showing.
    static func keepOrder(count: Int) -> [Int] {
        guard count > 0 else { return [] }
        var used = [Bool](repeating: false, count: count), order: [Int] = []
        order.reserveCapacity(count)
        var step = 0
        while order.count < count {
            var i = Int(((Double(step) * golden).truncatingRemainder(dividingBy: 1) * Double(count)).rounded(.down))
            while used[i] { i = (i + 1) % count }
            used[i] = true
            order.append(i)
            step += 1
        }
        return order
    }
}

/// One petal of a plant: ring index and petal index within that ring.
struct PetalRef: Hashable, Codable {
    let ring: Int
    let petal: Int
}

/// How a droop plant (or a flower with `droop`) sits at a pip count: tilt about the stem base, squash and grey.
struct DroopPose: Equatable {
    var tiltDegrees: Double
    var scaleX: Double
    var scaleY: Double
    var saturation: Double
    var brightness: Double
    static let upright = DroopPose(tiltDegrees: 0, scaleX: 1, scaleY: 1, saturation: 1, brightness: 1)
}

struct PlantThinningManifest: Codable {
    var version: Int
    var frac: [Double]
    /// Path of the rose rule the build read, or "pending".
    var roseRule: String
    /// Keyed by plant image name (`plant_daisy`).
    var plants: [String: PlantThinning]

    enum LoadError: Error { case fileNotFound }

    static func load(bundle: Bundle = .main) throws -> PlantThinningManifest {
        guard let url = bundle.url(forResource: "PlantThinning", withExtension: "json") else { throw LoadError.fileNotFound }
        return try JSONDecoder().decode(PlantThinningManifest.self, from: Data(contentsOf: url))
    }
}

struct PlantThinning: Codable {
    enum Kind: String, Codable {
        /// Loses petals as pips fall.
        case petals
        /// No petals to speak of: the body tilts, squashes and greys (any small flower on it still sheds).
        case droop
        /// Never changes.
        case exempt
    }

    /// One layer of the plant, drawn bottom to top. All images share the plant's view box.
    struct Layer: Codable {
        enum Kind: String, Codable {
            /// The ground shadow: never tilts.
            case ground
            /// Static art (`back`, `midN`, `front`, or `body` for droop plants).
            case `static`
            /// A run of petals, in z-order, drawn from the rings' sprites.
            case petals
        }
        var kind: Kind
        var image: String?
        /// [ring, petal] pairs for a `petals` layer.
        var petals: [[Int]]?
        /// A part that moves on its own (the rose's sepals): what it is, how far it splays open at
        /// `Rule.splayAt` pips, and the point it turns about (view box units).
        var role: String?
        var splayDegrees: Double?
        var origin: [Double]?

        var petalRefs: [PetalRef] {
            (petals ?? []).compactMap { $0.count == 2 ? PetalRef(ring: $0[0], petal: $0[1]) : nil }
        }
    }

    struct Ring: Codable {
        struct Sprite: Codable {
            /// Imageset name in PlantLayers, drawn at the first petal that uses it.
            var image: String
            var fill: String?
        }
        struct Petal: Codable {
            /// Source element indices in the plant SVG.
            var elements: [Int]
            /// Index into `sprites`.
            var sprite: Int
            /// Degrees, clockwise from up, about the ring pivot.
            var angle: Double
            /// Furthest reach from the pivot, in view box units.
            var radius: Double
            var centre: [Double]
            /// Affine transform (a, b, c, d, tx, ty) in view box units that moves the sprite onto this petal.
            var transform: [Double]
            /// A dedicated falling sprite (the rose's curled petals); otherwise the petal's own sprite falls.
            var fallSprite: String?
            /// The peel unit this petal belongs to (rose rule).
            var unit: String?
        }
        /// rotated | circles | tagged | peel
        var type: String
        /// radial | spike | peel
        var layout: String
        var pivot: [Double]
        var radius: Double
        var sprites: [Sprite]
        var petals: [Petal]
        var keepOrder: [Int]
        /// A peel schedule: petals showing at 0...5 pips, replacing the even share (outer layers go first).
        var keptCounts: [Int]?
        /// Precomputed petals showing at "0"..."5" pips (the build's answer; the functions below recompute it).
        var visible: [String: [Int]]
        /// Precomputed petals lost going from "k" to k - 1 pips, in fall order.
        var fall: [String: [Int]]

        /// How many petals show at `pips`: the peel schedule if there is one, else the even share.
        func keptCount(pips: Int) -> Int {
            let p = min(max(pips, 0), 5)
            if let keptCounts, keptCounts.count == 6 { return min(max(keptCounts[p], 0), petals.count) }
            return PetalThinning.keptCount(of: petals.count, pips: p)
        }

        /// Petals showing at `pips`, sorted by petal index.
        func visiblePetals(pips: Int) -> [Int] {
            Array(keepOrder.prefix(keptCount(pips: pips))).sorted()
        }

        /// Petals that let go when the pips drop from `pips` to `pips - 1`, first to fall first.
        func fallOrder(fromPips pips: Int) -> [Int] {
            guard (1...5).contains(pips) else { return [] }
            let lo = keptCount(pips: pips - 1), hi = keptCount(pips: pips)
            return lo < hi ? Array(keepOrder[lo..<hi]) : []
        }
    }

    struct Head: Codable {
        var pivot: [Double]
        var rings: [Int]
    }

    struct Droop: Codable {
        struct PerPip: Codable, Equatable {
            var tiltDegrees: Double
            var squashX: Double
            var squashY: Double
            var saturation: Double
            var brightness: Double
        }
        /// Stem base in view box units: the body rotates and squashes about it.
        var pivot: [Double]
        var maxTiltDegrees: Double
        var perPip: PerPip
    }

    /// A per-plant special rule, such as the rose's "peel" (outer layers peel off first). The rings already
    /// carry its schedule; the rest is for the view: which petals leave together, where the curled fall
    /// sprites start, how the last bud settles into its sepals, and the motion notes.
    struct Rule: Codable {
        struct Unit: Codable {
            var id: String
            /// [ring, petal] pairs that leave together.
            var petals: [[Int]]
            var sprite: String?
            var fallImage: String?
            /// [radius, angle] about `centre` where each falling sprite starts.
            var drops: [[Double]]
            /// The pip count reached when this unit is lost.
            var lostAtPips: Int?
        }
        struct FallSprite: Codable {
            var image: String
            var scale: Double
            var viewBox: [Double]
        }
        struct Settle: Codable {
            /// [ring, petal] pairs that sink by (dx, dy) view box units at this pip count and below.
            var petals: [[Int]]
            var dx: Double
            var dy: Double
        }
        /// The rose's curl (design-preview/tending/parts/notes/rose-curl.md): petals that stay at low counts swap to a
        /// shorter, rolled-back sprite and droop by `rotate` degrees (clockwise) about `pivot`, their base.
        struct Curl: Codable {
            struct Entry: Codable, Equatable {
                /// [ring, petal] pairs this look applies to.
                var petals: [[Int]]
                /// Imageset in PlantLayers, drawn in place in the 200 box (no petal transform).
                var image: String
                /// View box units.
                var pivot: [Double]
                var rotate: Double
            }
            var sprites: [String]
            /// Keyed by pip count: applies at that count and below, the smallest matching key wins (as `settle`).
            var pips: [String: [Entry]]
        }
        var name: String
        /// applied | pending
        var status: String
        var source: String?
        var centre: [Double]?
        var units: [Unit]?
        var fallSprites: [String: FallSprite]?
        /// Keyed by pip count.
        var settle: [String: Settle]?
        /// Sepals splay open at this pip count.
        var splayAt: Int?
        /// Delay before crossfading to the seed pot at 0 pips.
        var seedAfterMs: Int?
        var curl: Curl?
        var motion: [String: String]?
    }

    var kind: Kind
    var viewBox: [Double]
    var layers: [Layer]
    var rings: [Ring]
    var heads: [Head]
    var petalCount: Int
    var maxFallPerPip: Int
    var droop: Droop?
    var rule: Rule?
    var note: String?
    var warnings: [String]?

    /// Every image this plant draws: layers, petal sprites, dedicated fall sprites and curled petals.
    var imageNames: [String] {
        layers.compactMap(\.image) + rings.flatMap { $0.sprites.map(\.image) }
            + rings.flatMap { $0.petals.compactMap(\.fallSprite) } + (rule?.fallSprites?.values.map(\.image) ?? [])
            + (rule?.curl?.sprites ?? [])
    }

    /// The curled look of a petal still showing at `pips` (rule `curl`): the smallest pip key at or above `pips`
    /// that lists the petal wins, as with settle. Nil for petals that are gone, fresh, or on plants without a curl.
    func curl(for ref: PetalRef, pips: Int) -> Rule.Curl.Entry? {
        guard let curl = rule?.curl, rings.indices.contains(ref.ring),
              rings[ref.ring].visiblePetals(pips: pips).contains(ref.petal) else { return nil }
        let pair = [ref.ring, ref.petal]
        return curl.pips.compactMap { key, entries -> (Int, Rule.Curl.Entry)? in
            guard let n = Int(key), n >= pips, let e = entries.first(where: { $0.petals.contains(pair) }) else { return nil }
            return (n, e)
        }.min { $0.0 < $1.0 }?.1
    }

    /// True when something besides petals is always drawn, so the plant never goes blank.
    var isNeverEmpty: Bool {
        layers.contains { $0.kind == .static && $0.image != nil }
    }

    /// Petals showing at `pips`, ring by ring.
    func visiblePetals(pips: Int) -> [PetalRef] {
        rings.enumerated().flatMap { r, ring in ring.visiblePetals(pips: pips).map { PetalRef(ring: r, petal: $0) } }
    }

    /// Petals lost going from `pips` to `pips - 1` across all rings, in the prototype's order: rings shed
    /// together (by keep order position), ties broken by angle. The first `maxFallPerPip` drift to the ground.
    func fallOrder(fromPips pips: Int) -> [PetalRef] {
        guard (1...5).contains(pips) else { return [] }
        var lost: [(ref: PetalRef, step: Int, angle: Double)] = []
        for (r, ring) in rings.enumerated() {
            let lo = ring.keptCount(pips: pips - 1)
            for (step, petal) in ring.fallOrder(fromPips: pips).enumerated() {
                lost.append((PetalRef(ring: r, petal: petal), lo + step, ring.petals[petal].angle))
            }
        }
        return lost.sorted { ($0.step, $0.angle, $0.ref.ring) < ($1.step, $1.angle, $1.ref.ring) }.map(\.ref)
    }

    /// The droop at `pips` (upright for plants without droop).
    func droopPose(pips: Int) -> DroopPose {
        guard let droop, kind != .exempt else { return .upright }
        let lost = Double(5 - min(max(pips, 0), 5)), p = droop.perPip
        return DroopPose(tiltDegrees: lost * p.tiltDegrees,
                         scaleX: 1 - lost * p.squashX,
                         scaleY: 1 - lost * p.squashY,
                         saturation: 1 - lost * p.saturation,
                         brightness: 1 - lost * p.brightness)
    }
}
