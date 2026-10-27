import Foundation

/// Pure checklist maths, kept out of the views so it can be unit-tested.
enum ChecklistProgress {
    /// Fraction of today's goal reached, capped at 1.
    static func fraction(checked: Int, goal: Int) -> Double {
        guard goal > 0 else { return 0 }
        return min(Double(checked) / Double(goal), 1)
    }

    /// Consecutive days, ending today, on which the goal was met. If today is
    /// not done yet the streak counts back from yesterday, so it does not
    /// "break" in the morning.
    static func streak(foodCountsByDay: [String: Int], goal: Int, today: Date = .now,
                       calendar: Calendar = .current) -> Int {
        guard goal > 0 else { return 0 }
        func met(_ date: Date) -> Bool { (foodCountsByDay[DayKey.make(date, calendar: calendar)] ?? 0) >= goal }

        var day = calendar.startOfDay(for: today)
        if !met(day) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: day) else { return 0 }
            day = yesterday
        }
        var count = 0
        while met(day) {
            count += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }
        return count
    }
}

/// Hemoglobin unit shown to the user. Values are stored in g/dL.
enum HemoglobinUnit: String, CaseIterable, Identifiable {
    case gPerDL, gPerL

    var id: String { rawValue }
    var symbol: String { self == .gPerDL ? "g/dL" : "g/L" }

    func display(_ gPerDL: Double) -> Double { self == .gPerDL ? gPerDL : gPerDL * 10 }
    func stored(_ value: Double) -> Double { self == .gPerDL ? value : value / 10 }

    /// Plausible entry range in this unit, to catch typos (not a medical range).
    var entryRange: ClosedRange<Double> { self == .gPerDL ? 3...25 : 30...250 }

    func format(_ gPerDL: Double) -> String {
        let value = display(gPerDL)
        return self == .gPerDL ? value.formatted(.number.precision(.fractionLength(1))) : value.formatted(.number.precision(.fractionLength(0)).grouping(.never))
    }
}

enum Ferritin {
    static let symbol = "ng/mL"
    /// Plausible entry range, to catch typos (not a medical range).
    static let entryRange: ClosedRange<Double> = 0...3000

    static func format(_ value: Double) -> String { value.formatted(.number.precision(.fractionLength(0))) }
}

/// UserDefaults keys in one place.
enum Prefs {
    static let onboarded = "onboarded"
    static let onboardingStep = "onboardingStep"
    static let dailyGoal = "dailyGoal"
    static let hbUnit = "hbUnit"
    static let foodReminderOn = "foodReminderOn"
    static let foodReminderMinutes = "foodReminderMinutes"
    static let nextTestDate = "nextTestDate"
    static let testReminderOn = "testReminderOn"
    static let hbTarget = "hbTarget"
    static let ferritinTarget = "ferritinTarget"
    static let selectedTab = "selectedTab"

    static let defaultGoal = 3
    static let defaultFoodReminderMinutes = 11 * 60 + 30
}
