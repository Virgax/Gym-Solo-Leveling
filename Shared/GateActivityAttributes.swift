#if canImport(ActivityKit)
import ActivityKit
import Foundation

/// Live Activity payload for an in-progress Gate (workout). Shared by the app
/// (which starts/updates it) and the widget extension (which renders it).
struct GateActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var exerciseName: String
        var setsDone: Int
        var totalSets: Int
        var resting: Bool
        var restRemaining: Int

        var fraction: Double { totalSets <= 0 ? 0 : Double(setsDone) / Double(totalSets) }
    }

    var routineName: String
    var gateRank: String
}
#endif
