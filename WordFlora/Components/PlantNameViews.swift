import SwiftUI

/// Make it yours, B1: "Give it a name" on the win card for a new plant with no name yet. It opens the "Name your plant"
/// box; after Save the plant says hello by its new name. Never a second prompt, never a reward for naming.
/// Hardware-keyboard letters cannot reach the round while the box is up: the win card is modal (GameView.cardIsModal).
struct NameOnArrivalRow: View {
    let plant: PlantCollectible

    @Environment(AppModel.self) private var app
    @State private var naming = false
    @State private var draft = ""
    @State private var savedName: String?

    var body: some View {
        Group {
            if let savedName {
                Text(PlantNameCopy.saved(savedName))
                    .font(Theme.font(.callout, weight: .semibold)).foregroundStyle(Color.successText)
                    .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("plantName.hello")
            } else if plant.nickname.isEmpty {
                Button { draft = ""; naming = true } label: {
                    Label(PlantNameCopy.giveName, systemImage: "pencil")
                        .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                }
                .buttonStyle(SecondaryButtonStyle())
                .accessibilityHint(PlantNameCopy.giveNameHint)
                .accessibilityIdentifier("plantName.give")
            }
        }
        .alert(PlantNameCopy.alertTitle, isPresented: $naming) {
            TextField(plant.name, text: $draft)
            Button(PlantNameCopy.save) {
                let name = app.rename(plant, to: draft)
                guard !name.isEmpty else { return }
                savedName = name
                AccessibilityNotification.Announcement(PlantNameCopy.saved(name)).post()
            }
            Button(PlantNameCopy.notNow, role: .cancel) {}
        }
    }
}

/// Make it yours, B2: the plant page row that puts this plant on the Home Screen widget (`PlayerProfile.widgetPlantID`).
/// Once pinned it reads "On your widget" with a check and is not a button. Shown for seeds too (the widget draws them).
struct WidgetPinRow: View {
    let plant: PlantCollectible

    @Environment(AppModel.self) private var app
    @State private var line: String?

    var body: some View {
        let name = PlantName.display(nickname: plant.nickname, species: plant.name)
        VStack(spacing: 6) {
            if app.isOnWidget(plant) {
                Label {
                    Text(PlantNameCopy.onWidget)
                } icon: {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.successText)
                }
                .font(Theme.font(.body, weight: .semibold)).foregroundStyle(Color.appPrimaryText)
                .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, minHeight: Theme.minTap)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(PlantNameCopy.onWidget)
                .accessibilityIdentifier("plant.onWidget")
            } else {
                Button { pin(name) } label: {
                    Label(PlantNameCopy.showOnWidget, systemImage: "apps.iphone")
                        .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                }
                .buttonStyle(SecondaryButtonStyle())
                .accessibilityHint(PlantNameCopy.showOnWidgetHint)
                .accessibilityIdentifier("plant.showOnWidget")
            }
            if let line {
                Text(line)
                    .font(Theme.font(.footnote)).foregroundStyle(Color.appPrimaryText)
                    .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity)
                    .accessibilityIdentifier("plant.widgetLine")
            }
        }
    }

    private func pin(_ name: String) {
        app.pinToWidget(plant)
        Task {
            let text = await app.hasGardenWidget() ? PlantNameCopy.widgetWillShow(name) : PlantNameCopy.addWidget(name)
            line = text
            AccessibilityNotification.Announcement(text).post()
        }
    }
}
