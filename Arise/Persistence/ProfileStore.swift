import Foundation

/// Tiny Codable persistence for the Hunter profile. Good enough for Phase 1;
/// swap for SwiftData/CloudKit later without touching the engine.
final class ProfileStore {
    private let key = "hunter.profile.v1"
    private let defaults = UserDefaults.standard

    func load() -> HunterProfile {
        guard let data = defaults.data(forKey: key),
              let profile = try? JSONDecoder().decode(HunterProfile.self, from: data)
        else { return HunterProfile() }
        return profile
    }

    func save(_ profile: HunterProfile) {
        guard let data = try? JSONEncoder().encode(profile) else { return }
        defaults.set(data, forKey: key)
    }

    func reset() { defaults.removeObject(forKey: key) }
}

enum DayKey {
    static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.calendar = .current
        return f
    }()
    static func string(for date: Date = .now) -> String { formatter.string(from: date) }
}
