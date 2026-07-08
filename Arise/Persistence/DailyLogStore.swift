import Foundation

/// Persists per-day intake & training logs (water, caffeine, meals, Gates).
/// Keyed by yyyy-MM-dd. Simple Codable/UserDefaults store for Phase 1.
final class DailyLogStore {
    private let key = "daily.logs.v1"
    private let defaults = UserDefaults.standard

    private var all: [String: DailyLog] {
        get {
            guard let data = defaults.data(forKey: key),
                  let map = try? JSONDecoder().decode([String: DailyLog].self, from: data)
            else { return [:] }
            return map
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) { defaults.set(data, forKey: key) }
        }
    }

    func log(for dayKey: String) -> DailyLog {
        all[dayKey] ?? DailyLog(dayKey: dayKey)
    }

    func save(_ log: DailyLog) {
        var map = all
        map[log.dayKey] = log
        all = map
    }

    func reset() { defaults.removeObject(forKey: key) }
}
