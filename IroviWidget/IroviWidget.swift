import SwiftUI
import WidgetKit

@main
struct IroviWidgetBundle: WidgetBundle {
    var body: some Widget {
        PlateWidget()
    }
}

/// Today's iron plate: progress toward the daily goal and the streak, on the
/// Home Screen and the Lock Screen. Reads the snapshot the app writes; tapping
/// opens the food log.
struct PlateWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "PlateWidget", provider: PlateProvider()) { entry in
            PlateWidgetView(entry: entry)
                .environment(\.locale, AppLanguage.current.locale)
                .widgetURL(URL(string: "irovi://log"))
        }
        .configurationDisplayName("Iron plate")
        .description("Today's progress and your streak.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular])
    }
}

struct PlateProvider: TimelineProvider {
    func placeholder(in context: Context) -> PlateEntry {
        entry(from: .placeholder, at: .now)
    }

    func getSnapshot(in context: Context, completion: @escaping (PlateEntry) -> Void) {
        completion(entry(from: context.isPreview ? .placeholder : (WidgetSnapshot.load() ?? .placeholder), at: .now))
    }

    /// One entry now and one at midnight, when the day's count resets.
    func getTimeline(in context: Context, completion: @escaping (Timeline<PlateEntry>) -> Void) {
        let snapshot = WidgetSnapshot.load() ?? WidgetSnapshot(dayKey: DayKey.make(.now), eaten: [], goal: Prefs.defaultGoal, streak: 0)
        let midnight = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: .now)) ?? .now
        let entries = [entry(from: snapshot, at: .now), entry(from: snapshot, at: midnight)]
        completion(Timeline(entries: entries, policy: .after(midnight)))
    }

    private func entry(from snapshot: WidgetSnapshot, at date: Date) -> PlateEntry {
        let resolved = snapshot.resolved(on: date)
        return PlateEntry(date: date, eaten: resolved.eaten, goal: resolved.goal, streak: resolved.streak)
    }
}
