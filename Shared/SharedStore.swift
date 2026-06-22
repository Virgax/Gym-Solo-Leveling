import Foundation

enum AppGroup {
    /// Must match the App Group capability on BOTH the app and widget targets.
    static let id = "group.com.virgax.arise"
}

/// Reads/writes the shared progression snapshot via the App Group. Falls back to
/// standard defaults if the group isn't provisioned yet (so nothing crashes).
final class SharedStore {
    static let shared = SharedStore()
    private let key = "shared.snapshot.v1"

    private var defaults: UserDefaults {
        UserDefaults(suiteName: AppGroup.id) ?? .standard
    }

    func save(_ snapshot: SharedSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults.set(data, forKey: key)
    }

    func load() -> SharedSnapshot {
        guard let data = defaults.data(forKey: key),
              let snapshot = try? JSONDecoder().decode(SharedSnapshot.self, from: data)
        else { return .placeholder }
        return snapshot
    }
}
