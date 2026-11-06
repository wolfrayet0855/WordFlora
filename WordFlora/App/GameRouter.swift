import SwiftUI

enum GameRoute: Hashable {
    case game(daily: Bool, level: Int?)
    case garden
    case plant(String)          // plantId
    case levelMap
    case settings
    case shed
    case butterfly
    case visitors
    case badges
    case plus
    case visitorsBook
}

@Observable
final class GameRouter {
    var path: [GameRoute] = []
    func go(_ route: GameRoute) { path.append(route) }
    func home() { path.removeAll() }
    func back() { if !path.isEmpty { path.removeLast() } }
}

extension GameRouter {
    /// Deep links from the widget: wordflora://plant/<plantId> and wordflora://play
    func open(_ url: URL) {
        guard url.scheme == "wordflora" else { return }
        home()
        switch url.host {
        case "plant":
            let id = url.pathComponents.dropFirst().first ?? ""
            go(.garden)
            if !id.isEmpty { go(.plant(id)) }
        case "play": go(.game(daily: false, level: nil))
        default: break
        }
    }
}

