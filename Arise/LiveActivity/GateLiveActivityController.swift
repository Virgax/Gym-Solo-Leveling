import Foundation
#if canImport(ActivityKit)
import ActivityKit

/// Starts / updates / ends the Gate Live Activity from the running app.
/// Deployment target is iOS 17, so ActivityKit is always present.
@MainActor
final class GateLiveActivityController {
    private var activity: Activity<GateActivityAttributes>?

    func start(routine: Routine, state: GateActivityAttributes.ContentState) {
        guard activity == nil, ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let attributes = GateActivityAttributes(routineName: routine.name, gateRank: routine.gateRank.rawValue)
        activity = try? Activity.request(
            attributes: attributes,
            content: .init(state: state, staleDate: nil)
        )
    }

    func update(_ state: GateActivityAttributes.ContentState) {
        guard let activity else { return }
        Task { await activity.update(.init(state: state, staleDate: nil)) }
    }

    func end() {
        guard let activity else { return }
        self.activity = nil
        Task { await activity.end(nil, dismissalPolicy: .immediate) }
    }
}
#endif
