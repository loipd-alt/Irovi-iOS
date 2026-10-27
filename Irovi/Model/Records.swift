import Foundation
import SwiftData

/// One calendar day of the checklist. `dayKey` ("yyyy-MM-dd" in the user's
/// time zone) keeps exactly one log per day.
@Model
final class DayLog {
    @Attribute(.unique) var dayKey: String
    var date: Date
    var foodRaw: [String]
    var habitRaw: [String]
    /// Medicine ids marked as taken on this day.
    var takenMedicineIDs: [String]

    init(date: Date) {
        self.dayKey = DayKey.make(date)
        self.date = Calendar.current.startOfDay(for: date)
        self.foodRaw = []
        self.habitRaw = []
        self.takenMedicineIDs = []
    }

    var foods: Set<FoodGroup> { Set(foodRaw.compactMap(FoodGroup.init(rawValue:))) }
    var habits: Set<IronHabit> { Set(habitRaw.compactMap(IronHabit.init(rawValue:))) }

    func toggle(_ food: FoodGroup) {
        if foodRaw.contains(food.rawValue) { foodRaw.removeAll { $0 == food.rawValue } } else { foodRaw.append(food.rawValue) }
    }

    func toggle(_ habit: IronHabit) {
        if habitRaw.contains(habit.rawValue) { habitRaw.removeAll { $0 == habit.rawValue } } else { habitRaw.append(habit.rawValue) }
    }

    func toggleMedicine(_ id: UUID) {
        let key = id.uuidString
        if takenMedicineIDs.contains(key) { takenMedicineIDs.removeAll { $0 == key } } else { takenMedicineIDs.append(key) }
    }
}

/// A blood test result the user typed in. Hemoglobin is stored in g/dL,
/// ferritin in ng/mL (the same number as µg/L). Either may be missing.
@Model
final class LabResult {
    var id: UUID
    var date: Date
    var hemoglobin: Double?
    var ferritin: Double?
    var note: String?

    init(date: Date, hemoglobin: Double?, ferritin: Double?, note: String? = nil) {
        self.id = UUID()
        self.date = date
        self.hemoglobin = hemoglobin
        self.ferritin = ferritin
        self.note = note
    }
}

/// A medicine the user added themselves (e.g. what their doctor prescribed),
/// only for reminders and a daily "taken" tick. Irovi never suggests medicines
/// or doses.
@Model
final class Medicine {
    var id: UUID
    var name: String
    /// Reminder times as minutes after midnight, sorted.
    var reminderMinutes: [Int]
    var isActive: Bool
    var createdAt: Date

    init(name: String, reminderMinutes: [Int]) {
        self.id = UUID()
        self.name = name
        self.reminderMinutes = reminderMinutes.sorted()
        self.isActive = true
        self.createdAt = .now
    }
}

enum DayKey {
    static func make(_ date: Date, calendar: Calendar = .current) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }
}
