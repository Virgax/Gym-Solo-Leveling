import Foundation

/// Persists user-built Gates (custom routines).
final class RoutineStore {
    private let key = "custom.routines.v1"
    private let defaults = UserDefaults.standard

    func load() -> [Routine] {
        guard let data = defaults.data(forKey: key),
              let routines = try? JSONDecoder().decode([Routine].self, from: data)
        else { return [] }
        return routines
    }

    func save(_ routines: [Routine]) {
        if let data = try? JSONEncoder().encode(routines) { defaults.set(data, forKey: key) }
    }

    func reset() { defaults.removeObject(forKey: key) }
}
