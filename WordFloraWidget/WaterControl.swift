import WidgetKit
import SwiftUI
import AppIntents

@available(iOS 18.0, *)
struct WaterControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "WaterControl") {
            ControlWidgetButton(action: WaterGardenIntent()) {
                Label("Water garden", systemImage: "drop.fill")
            }
        }
        .displayName("Water my garden")
        .description("Give your garden a drink.")
    }
}
