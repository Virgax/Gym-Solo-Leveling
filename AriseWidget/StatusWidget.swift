import WidgetKit
import SwiftUI

struct StatusEntry: TimelineEntry {
    let date: Date
    let snapshot: SharedSnapshot
}

struct StatusProvider: TimelineProvider {
    func placeholder(in context: Context) -> StatusEntry {
        StatusEntry(date: .now, snapshot: .placeholder)
    }
    func getSnapshot(in context: Context, completion: @escaping (StatusEntry) -> Void) {
        completion(StatusEntry(date: .now, snapshot: SharedStore.shared.load()))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<StatusEntry>) -> Void) {
        let entry = StatusEntry(date: .now, snapshot: SharedStore.shared.load())
        // App pushes reloads on change; refresh hourly as a safety net.
        let next = Calendar.current.date(byAdding: .hour, value: 1, to: .now) ?? .now
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

struct StatusWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "AriseStatusWidget", provider: StatusProvider()) { entry in
            StatusWidgetView(snapshot: entry.snapshot)
                .containerBackground(WidgetTheme.background, for: .widget)
        }
        .configurationDisplayName("Hunter Status")
        .description("Your rank, level and XP at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular, .accessoryCircular])
    }
}

struct StatusWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let snapshot: SharedSnapshot

    var body: some View {
        switch family {
        case .accessoryCircular: circular
        case .accessoryRectangular: rectangular
        case .systemMedium: medium
        default: small
        }
    }

    private var rankColor: Color { WidgetTheme.rankColor(snapshot.rankRaw) }

    private var small: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(snapshot.rankRaw)
                    .font(.system(size: 26, weight: .black, design: .rounded))
                    .foregroundStyle(rankColor)
                Spacer()
                VStack(alignment: .trailing, spacing: 0) {
                    Text("LV").font(.system(size: 9, design: .monospaced)).foregroundStyle(WidgetTheme.textSecondary)
                    Text("\(snapshot.level)").font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundStyle(WidgetTheme.accent)
                }
            }
            Spacer()
            Text(snapshot.name).font(.system(.subheadline, design: .rounded).weight(.bold))
                .foregroundStyle(WidgetTheme.textPrimary).lineLimit(1)
            xpBar
            HStack(spacing: 4) {
                Image(systemName: "flame.fill").font(.system(size: 9)).foregroundStyle(WidgetTheme.gold)
                Text("\(snapshot.streak)d · \(snapshot.questsDone)/\(snapshot.questsTotal) quests")
                    .font(.system(size: 10, design: .monospaced)).foregroundStyle(WidgetTheme.textSecondary)
            }
        }
    }

    private var medium: some View {
        HStack(spacing: 16) {
            VStack {
                Text(snapshot.rankRaw).font(.system(size: 40, weight: .black, design: .rounded)).foregroundStyle(rankColor)
                Text("RANK").font(.system(size: 9, design: .monospaced)).foregroundStyle(WidgetTheme.textSecondary)
            }
            VStack(alignment: .leading, spacing: 8) {
                Text(snapshot.name).font(.system(.title3, design: .rounded).weight(.heavy)).foregroundStyle(WidgetTheme.textPrimary)
                Text("Level \(snapshot.level)").font(.subheadline).foregroundStyle(WidgetTheme.accent)
                xpBar
                HStack(spacing: 10) {
                    Label("\(snapshot.streak)-day", systemImage: "flame.fill").foregroundStyle(WidgetTheme.gold)
                    Label("\(snapshot.questsDone)/\(snapshot.questsTotal)", systemImage: "checklist").foregroundStyle(WidgetTheme.textSecondary)
                }
                .font(.system(.caption, design: .rounded))
            }
            Spacer()
        }
    }

    private var rectangular: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(snapshot.rankRaw) · Lv \(snapshot.level) · \(snapshot.name)")
                .font(.headline).widgetAccentable()
            Gauge(value: snapshot.xpFraction) { EmptyView() }
                .gaugeStyle(.accessoryLinearCapacity)
            Text("\(snapshot.streak)d streak · \(snapshot.questsDone)/\(snapshot.questsTotal) quests")
                .font(.caption2)
        }
    }

    private var circular: some View {
        Gauge(value: snapshot.xpFraction) {
            Text(snapshot.rankRaw)
        } currentValueLabel: {
            Text("\(snapshot.level)")
        }
        .gaugeStyle(.accessoryCircular)
    }

    private var xpBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.12))
                Capsule().fill(LinearGradient(colors: [WidgetTheme.accentDeep, WidgetTheme.accent],
                                              startPoint: .leading, endPoint: .trailing))
                    .frame(width: max(3, geo.size.width * snapshot.xpFraction))
            }
        }
        .frame(height: 6)
    }
}
