#if DEBUG
import Foundation
import SwiftData

/// Example data for store screenshots and UI tests only. Loaded when the app
/// is launched with `-IroviDemoData YES` and the store is empty; never in Release.
enum DemoData {
    static var isRequested: Bool { UserDefaults.standard.bool(forKey: "IroviDemoData") }

    @MainActor
    static func seedIfRequested(_ context: ModelContext) {
        guard isRequested, ((try? context.fetchCount(FetchDescriptor<DayLog>())) ?? 0) == 0 else { return }
        let calendar = Calendar.current
        let plan: [[FoodGroup]] = [
            [.redMeat, .greens, .fortified], [.legumes, .greens, .seafood], [.poultry, .greens, .legumes],
            [.redMeat, .seafood, .greens], [.fortified, .legumes, .greens], [.seafood, .poultry, .greens],
            [.redMeat, .legumes],
        ]
        for daysAgo in 1...27 {
            guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: .now) else { continue }
            let log = DayLog(date: date)
            let foods = daysAgo % 9 == 0 ? Array(plan[daysAgo % 7].prefix(1)) : plan[daysAgo % 7]
            foods.forEach(log.toggle)
            if daysAgo % 2 == 0 { log.toggle(.vitaminC) }
            if daysAgo % 3 != 0 { log.toggle(.teaApart) }
            context.insert(log)
        }
        let today = DayLog(date: .now)
        [FoodGroup.redMeat, .greens].forEach(today.toggle)
        today.toggle(.vitaminC)
        context.insert(today)

        let labs: [(Int, Double, Double)] = [(150, 10.8, 9), (95, 11.4, 18), (40, 12.1, 31)]
        for (daysAgo, hb, ferritin) in labs {
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: .now) ?? .now
            context.insert(LabResult(date: date, hemoglobin: hb, ferritin: ferritin))
        }
        try? context.save()
        WidgetSync.refresh(context)
    }
}
#endif
