import SwiftUI

/// The "DAILY QUEST" window — the System's to-do list with progress.
struct QuestWindowView: View {
    var title: String = "Daily Quest — Info"
    let quests: [Quest]

    private var allDone: Bool { !quests.isEmpty && quests.allSatisfy { $0.isComplete } }

    var body: some View {
        SystemPanel(title: title) {
            VStack(alignment: .leading, spacing: 14) {
                Text(allDone ? "ALL QUESTS CLEARED. Well done, Hunter."
                             : "Complete the daily training to grow stronger.")
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(allDone ? SystemTheme.accent : SystemTheme.textSecondary)

                ForEach(quests) { QuestRow(quest: $0) }
            }
        }
    }
}

private struct QuestRow: View {
    let quest: Quest

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: quest.isComplete ? "checkmark.seal.fill" : "circle.dashed")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(quest.isComplete ? SystemTheme.accent : SystemTheme.textSecondary)
                .systemGlow(quest.isComplete ? SystemTheme.accent : .clear, radius: quest.isComplete ? 4 : 0)

            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(quest.title)
                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                        .foregroundStyle(SystemTheme.textPrimary)
                    if quest.isMandatory {
                        Text("REQ")
                            .font(.system(size: 9, design: .monospaced).weight(.black))
                            .padding(.horizontal, 5).padding(.vertical, 1)
                            .background(SystemTheme.danger.opacity(0.25))
                            .foregroundStyle(SystemTheme.danger)
                            .clipShape(Capsule())
                    }
                    Spacer()
                    Text("+\(quest.xpReward) XP")
                        .font(.system(.caption2, design: .monospaced).weight(.bold))
                        .foregroundStyle(SystemTheme.gold)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.06))
                        Capsule().fill(SystemTheme.accent.opacity(quest.isComplete ? 1 : 0.7))
                            .frame(width: max(3, geo.size.width * quest.fraction))
                    }
                }
                .frame(height: 5)
                Text(quest.progressText)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(SystemTheme.textSecondary)
            }
        }
    }
}
