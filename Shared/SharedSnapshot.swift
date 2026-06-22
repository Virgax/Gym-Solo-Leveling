import Foundation

/// Compact progression summary the main app writes to the App Group so the
/// home/lock-screen widget can render it. Shared by both targets.
struct SharedSnapshot: Codable {
    var name: String
    var level: Int
    var rankRaw: String
    var xpInto: Int
    var xpSpan: Int
    var streak: Int
    var questsDone: Int
    var questsTotal: Int
    var updated: Date

    var xpFraction: Double { xpSpan <= 0 ? 1 : min(1, Double(xpInto) / Double(xpSpan)) }
    var questFraction: Double { questsTotal <= 0 ? 0 : Double(questsDone) / Double(questsTotal) }

    static let placeholder = SharedSnapshot(
        name: "Hunter", level: 12, rankRaw: "D", xpInto: 80, xpSpan: 140,
        streak: 4, questsDone: 3, questsTotal: 7, updated: .now)
}
