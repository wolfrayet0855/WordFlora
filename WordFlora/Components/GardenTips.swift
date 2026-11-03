import SwiftUI
import TipKit

/// One-time, gentle hints that surface gestures players might not find on their own (TipKit, on device only).
struct PlantHelloTip: Tip {
    var title: Text { Text("Say hello") }
    var message: Text? { Text("Tap your plant. It likes company.") }
    var image: Image? { Image(systemName: "hand.tap.fill") }
}
