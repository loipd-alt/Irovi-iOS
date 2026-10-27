import Foundation

/// The small summary the app writes for the widget, through the App Group.
/// The widget never opens the app's database; it only reads this.
struct WidgetSnapshot: Codable, Equatable {
    static let appGroup = "group.com.irovi.app"
    private static let key = "widgetSnapshot"

    var dayKey: String
    var eaten: [String]
    var goal: Int
    var streak: Int

    static var placeholder: WidgetSnapshot {
        WidgetSnapshot(dayKey: DayKey.make(.now), eaten: [FoodGroup.redMeat.rawValue, FoodGroup.greens.rawValue],
                       goal: 3, streak: 5)
    }

    static func load(defaults: UserDefaults? = UserDefaults(suiteName: appGroup)) -> WidgetSnapshot? {
        guard let data = defaults?.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
    }

    func save(defaults: UserDefaults? = UserDefaults(suiteName: WidgetSnapshot.appGroup)) {
        guard let data = try? JSONEncoder().encode(self) else { return }
        defaults?.set(data, forKey: WidgetSnapshot.key)
    }

    /// What to show on `date`. A snapshot from an earlier day means nothing is
    /// logged yet today; the streak survives one night (it counts back from
    /// yesterday until today's goal is met) and is reset after that.
    func resolved(on date: Date = .now, calendar: Calendar = .current) -> (eaten: Set<FoodGroup>, goal: Int, streak: Int) {
        let today = DayKey.make(date, calendar: calendar)
        if dayKey == today {
            return (Set(eaten.compactMap(FoodGroup.init(rawValue:))), goal, streak)
        }
        let yesterday = calendar.date(byAdding: .day, value: -1, to: date).map { DayKey.make($0, calendar: calendar) }
        let carried = dayKey == yesterday && eaten.count >= goal ? streak : 0
        return ([], goal, carried)
    }
}
