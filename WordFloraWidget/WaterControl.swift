import WidgetKit
import SwiftUI
import AppIntents

@available(iOS 18.0, *)
struct WaterControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "WaterControl") {
            ControlWidgetButton(action: WaterGardenIntent()) {
                Label(WidgetCopy.controlLabel, systemImage: "drop.fill")
            } actionLabel: { isActive in
                // A control cannot show a dialog, so the tap is answered with "Watering" while it runs.
                Label(isActive ? WidgetCopy.watering : WidgetCopy.controlLabel, systemImage: "drop.fill")
            }
        }
        // Literals (control metadata); WidgetCopy.titles repeats them for the copy test.
        .displayName("Water my garden")
        .description("Give your garden a drink.")
    }
}
