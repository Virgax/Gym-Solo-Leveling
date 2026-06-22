import Foundation

/// Source-agnostic provider of fitness data. iOS uses `HealthKitSource`
/// (which includes RingConn + Eufy data synced into Apple Health). A future
/// Android build adds `HealthConnectSource` (Fitbit + Google Health) behind the
/// same protocol — the engine and UI never change.
/// Body metrics read from the platform to prefill onboarding. Any field may be
/// nil (no data) → the user fills it in manually.
struct BodyPrefill {
    var sex: Sex?
    var birthDate: Date?
    var heightCm: Double?
    var weightKg: Double?
}

/// An increment to mirror into the platform's nutrition store (write-through).
struct IntakeWrite {
    var waterMl: Double?
    var caffeineMg: Double?
    var energyKcal: Double?
    var proteinG: Double?
    var date: Date = .now
}

protocol HealthSource {
    /// Whether the platform can provide data at all (e.g. HealthKit available).
    var isAvailable: Bool { get }

    /// Request read authorization. Returns true if the user granted (or the
    /// platform reports sharing-authorized).
    func requestAuthorization() async -> Bool

    /// Read a full snapshot (today + rolling windows + latest readings).
    func snapshot() async -> HealthSnapshot

    /// Best-effort body metrics to prefill setup (sex, DOB, height, weight).
    func bodyPrefill() async -> BodyPrefill

    /// Mirror a logged intake increment into the platform (write-through).
    /// No-op where unsupported or unauthorized.
    func export(_ write: IntakeWrite) async
}

/// Fallback source for Simulator / previews / unsupported platforms.
struct MockHealthSource: HealthSource {
    var isAvailable: Bool { true }
    func requestAuthorization() async -> Bool { true }
    func snapshot() async -> HealthSnapshot { .sample }
    func bodyPrefill() async -> BodyPrefill { BodyPrefill() }
    func export(_ write: IntakeWrite) async {}
}
