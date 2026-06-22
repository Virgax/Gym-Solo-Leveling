#if canImport(ActivityKit)
import ActivityKit
import WidgetKit
import SwiftUI

/// Lock-screen + Dynamic Island presentation of an in-progress Gate.
struct GateLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: GateActivityAttributes.self) { context in
            lockScreen(context)
                .containerBackground(WidgetTheme.background.opacity(0.92), for: .widget)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label(context.attributes.gateRank, systemImage: "shield.lefthalf.filled")
                        .font(.caption.weight(.bold)).foregroundStyle(WidgetTheme.accent)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("\(context.state.setsDone)/\(context.state.totalSets)")
                        .font(.system(.body, design: .monospaced).weight(.bold)).foregroundStyle(WidgetTheme.accent)
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.attributes.routineName).font(.caption).foregroundStyle(WidgetTheme.textSecondary)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 6) {
                        ProgressView(value: context.state.fraction).tint(WidgetTheme.accent)
                        Text(context.state.resting ? "Rest · \(context.state.restRemaining)s" : context.state.exerciseName)
                            .font(.caption2).foregroundStyle(WidgetTheme.textPrimary)
                    }
                }
            } compactLeading: {
                Image(systemName: "dumbbell.fill").foregroundStyle(WidgetTheme.accent)
            } compactTrailing: {
                Text(context.state.resting ? "\(context.state.restRemaining)s" : "\(context.state.setsDone)/\(context.state.totalSets)")
                    .font(.system(.caption2, design: .monospaced).weight(.bold))
                    .foregroundStyle(context.state.resting ? WidgetTheme.gold : WidgetTheme.accent)
            } minimal: {
                Image(systemName: "dumbbell.fill").foregroundStyle(WidgetTheme.accent)
            }
            .keylineTint(WidgetTheme.accent)
        }
    }

    private func lockScreen(_ context: ActivityViewContext<GateActivityAttributes>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(context.attributes.routineName, systemImage: "shield.lefthalf.filled")
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                    .foregroundStyle(WidgetTheme.textPrimary)
                Spacer()
                Text("\(context.state.setsDone)/\(context.state.totalSets) sets")
                    .font(.system(.subheadline, design: .monospaced).weight(.bold))
                    .foregroundStyle(WidgetTheme.accent)
            }
            ProgressView(value: context.state.fraction).tint(WidgetTheme.accent)
            HStack {
                Image(systemName: context.state.resting ? "timer" : "figure.strengthtraining.traditional")
                    .foregroundStyle(context.state.resting ? WidgetTheme.gold : WidgetTheme.accent)
                Text(context.state.resting ? "Rest — \(context.state.restRemaining)s" : context.state.exerciseName)
                    .font(.system(.caption, design: .rounded)).foregroundStyle(WidgetTheme.textSecondary)
                Spacer()
            }
        }
        .padding()
    }
}
#endif
