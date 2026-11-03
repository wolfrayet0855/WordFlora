import WidgetKit
import SwiftUI

@main
struct WordFloraWidgetBundle: WidgetBundle {
    var body: some Widget {
        GardenWidget()
        if #available(iOS 18.0, *) { WaterControl() }
    }
}
