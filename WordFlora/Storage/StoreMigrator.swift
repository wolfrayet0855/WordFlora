import Foundation

/// Moves the SwiftData store into the App Group container without ever risking the original
/// (spec section 4; widget and iCloud both need the shared location). Copy, verify, rename; the old file stays.
enum StoreMigrator {
    enum Result: Equatable { case notNeeded, migrated, failed(String) }

    private static let sidecars = ["", "-wal", "-shm"]

    static func migrateIfNeeded(from old: URL, to new: URL, fileManager fm: FileManager = .default) -> Result {
        guard !fm.fileExists(atPath: new.path) else { return .notNeeded }
        guard fm.fileExists(atPath: old.path) else { return .notNeeded }

        func temp(_ suffix: String) -> URL { URL(fileURLWithPath: new.path + suffix + ".migrating") }

        // Clean up anything a crashed earlier attempt left behind.
        for s in sidecars { try? fm.removeItem(at: temp(s)) }

        do {
            try fm.createDirectory(at: new.deletingLastPathComponent(), withIntermediateDirectories: true)
            for s in sidecars {
                let source = URL(fileURLWithPath: old.path + s)
                if fm.fileExists(atPath: source.path) { try fm.copyItem(at: source, to: temp(s)) }
            }
            // Sidecars first, the main file last, so the "new store exists" check only flips once everything is in place.
            for s in sidecars.reversed() where fm.fileExists(atPath: temp(s).path) {
                try fm.moveItem(at: temp(s), to: URL(fileURLWithPath: new.path + s))
            }
            return .migrated
        } catch {
            for s in sidecars {
                try? fm.removeItem(at: temp(s))
                if s != "" { try? fm.removeItem(at: URL(fileURLWithPath: new.path + s)) }
            }
            try? fm.removeItem(at: new)
            return .failed(error.localizedDescription)
        }
    }
}
