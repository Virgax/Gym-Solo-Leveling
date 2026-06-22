import Foundation

/// Source-agnostic provider of fitness data. iOS uses `HealthKitSource`
/// (which includes RingConn + Eufy data synced into Apple Health). A future
/// Android build adds `HealthConnectSource` (Fitbit + Google Health) behind the
/// same protocol — the engine and UI never change.
protocol HealthSource {
    /// Whether the platform can provide data at all (e.g. HealthKit available).
    var isAvailable: Bool { get }

    /// Request read authorization. Returns true if the user granted (or the
    /// platform reports sharing-authorized).
    func requestAuthorization() async -> Bool

    /// Read a full snapshot (today + rolling windows + latest readings).
    func snapshot() async -> HealthSnapshot
}

/// Fallback source for Simulator / previews / unsupported platforms.
struct MockHealthSource: HealthSource {
    var isAvailable: Bool { true }
    func requestAuthorization() async -> Bool { true }
    func snapshot() async -> HealthSnapshot { .sample }
}
