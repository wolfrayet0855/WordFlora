import SwiftUI

enum GameRoute: Hashable {
    case game(daily: Bool)
    case garden
    case plant(String)          // plantId
    case levelMap
    case settings
    case shed
    case butterfly
    case badges
    case plus
}

@Observable
final class GameRouter {
    var path: [GameRoute] = []
    func go(_ route: GameRoute) { path.append(route) }
    func home() { path.removeAll() }
    func back() { if !path.isEmpty { path.removeLast() } }
}
