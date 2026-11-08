import Foundation
import CloudKit
import CoreData

/// What WordFlora Settings says about iCloud sync, from facts the app has (docs/pm/plus-flow-fable-review.md N4).
/// Shown to everyone: free players see that sync comes with Plus, which answers the question before they buy.
enum CloudSyncStatus: Equatable {
    case needsPlus, startsNextLaunch, on, needsSignIn, unavailable

    /// `launchedWithCloud`: this launch opened the store with CloudKit. `cloudOpenFailed`: it wanted to and could not.
    /// `account`: the iCloud account status, when it has been read (nil before, or without Plus).
    static func status(hasPlus: Bool, launchedWithCloud: Bool, cloudOpenFailed: Bool, account: CKAccountStatus?) -> CloudSyncStatus {
        guard hasPlus else { return .needsPlus }
        // The account first: a player who signed out of iCloud after this launch opened the CloudKit store is not syncing.
        if account == .noAccount { return .needsSignIn }
        if account == .restricted { return .unavailable }
        if launchedWithCloud { return .on }
        if cloudOpenFailed { return .unavailable }
        return .startsNextLaunch
    }

    var title: String {
        switch self {
        case .needsPlus: return Copy.needsPlus
        case .startsNextLaunch: return Copy.startsNextLaunch
        case .on: return Copy.on
        case .needsSignIn: return Copy.needsSignIn
        case .unavailable: return Copy.unavailable
        }
    }

    var footnote: String? {
        switch self {
        case .on: return Copy.onFootnote
        case .needsSignIn: return Copy.needsSignInFootnote
        case .unavailable: return Copy.unavailableFootnote
        case .needsPlus, .startsNextLaunch: return nil
        }
    }

    var symbol: String {
        switch self {
        case .on: return "icloud.fill"
        case .needsPlus, .startsNextLaunch: return "icloud"
        case .needsSignIn, .unavailable: return "icloud.slash"
        }
    }

    enum Copy {
        static let needsPlus = "iCloud sync comes with Plus"
        static let startsNextLaunch = "iCloud sync starts next time you open WordFlora"
        static let on = "iCloud sync is on"
        static let needsSignIn = "iCloud sync needs an iCloud sign-in"
        static let unavailable = "iCloud sync isn't available on this device"
        static let onFootnote = "Your garden shows up on any iPhone signed in to the same iCloud account."
        static let needsSignInFootnote = "Sign in to iCloud in the Settings app, then reopen WordFlora."
        static let unavailableFootnote = "Check that WordFlora may use iCloud in the Settings app (Apple Account > iCloud), then reopen WordFlora."
        /// "Synced 5 minutes ago", "Synced 1 week ago": numeric, because the named style says "last week" (CopySafety
        /// bans "last"), as would "Last synced".
        static func synced(_ date: Date, now: Date = .now) -> String {
            let f = RelativeDateTimeFormatter()
            f.dateTimeStyle = .numeric
            f.unitsStyle = .full
            return "Synced \(f.localizedString(for: min(date, now), relativeTo: now))"
        }
        static var all: [String] {
            [needsPlus, startsNextLaunch, on, needsSignIn, unavailable, onFootnote, needsSignInFootnote, unavailableFootnote,
             synced(Date.now.addingTimeInterval(-300))]
        }
    }
}

/// Listens for the CloudKit mirroring events under SwiftData's store and keeps the time of the latest successful import
/// or export, for the "Synced 5 minutes ago" line. Apple documents the event for NSPersistentCloudKitContainer, not for
/// SwiftData: when no event ever comes, the line simply never shows (never an invented time). The time is a
/// UserDefaults value in the App Group, not a SwiftData field.
@Observable
@MainActor
final class CloudSyncMonitor {
    static let key = "cloudSyncedAt"
    private(set) var syncedAt: Date?
    private(set) var lastFailed = false
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored nonisolated(unsafe) private var token: NSObjectProtocol?
    @ObservationIgnored nonisolated(unsafe) private let center: NotificationCenter

    init(center: NotificationCenter = .default, defaults: UserDefaults = SharedDefaults.store, listen: Bool = true) {
        self.defaults = defaults
        self.center = center
        syncedAt = defaults.object(forKey: Self.key) as? Date
        guard listen else { return }
        token = center.addObserver(forName: NSPersistentCloudKitContainer.eventChangedNotification, object: nil, queue: .main) { [weak self] n in
            guard let e = n.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey] as? NSPersistentCloudKitContainer.Event,
                  let end = e.endDate, e.type != .setup else { return }
            let ok = e.succeeded
            Task { @MainActor in self?.record(end: end, ok: ok) }
        }
    }

    deinit { if let token { center.removeObserver(token) } }

    /// A finished import or export: a success moves the time on; a failure changes nothing on screen (it retries).
    func record(end: Date, ok: Bool) {
        lastFailed = !ok
        guard ok else { return }
        syncedAt = end
        defaults.set(end, forKey: Self.key)
    }
}
