import Foundation
import SwiftData
import WidgetKit

/// Keeps the widget's snapshot in step with the app. Called after logging,
/// when the goal changes, and when the app goes to the background.
enum WidgetSync {
    @MainActor
    static func refresh(_ context: ModelContext, defaults: UserDefaults = .standard) {
        let logs = (try? context.fetch(FetchDescriptor<DayLog>())) ?? []
        let goal = defaults.object(forKey: Prefs.dailyGoal) as? Int ?? Prefs.defaultGoal
        let todayKey = DayKey.make(.now)
        let counts = Dictionary(logs.map { ($0.dayKey, $0.foods.count) }, uniquingKeysWith: max)
        let today = logs.first { $0.dayKey == todayKey }
        let snapshot = WidgetSnapshot(
            dayKey: todayKey,
            eaten: today.map { FoodGroup.allCases.filter($0.foods.contains).map(\.rawValue) } ?? [],
            goal: goal,
            streak: ChecklistProgress.streak(foodCountsByDay: counts, goal: goal)
        )
        guard snapshot != WidgetSnapshot.load() else { return }
        snapshot.save()
        WidgetCenter.shared.reloadAllTimelines()
    }
}

/// Opens screens from outside (the widget's link). Lives in the environment.
@Observable
final class AppRouter {
    var openFoodLog = false

    static let foodLogURL = URL(string: "irovi://log")!

    func handle(_ url: URL) -> Bool {
        guard url.scheme == "irovi", url.host == "log" else { return false }
        openFoodLog = true
        return true
    }
}
