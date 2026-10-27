import Foundation
import SwiftData
import UserNotifications

/// What should be scheduled, built from settings and the medicine list.
struct ReminderPlan: Equatable {
    struct MedicineTimes: Equatable {
        let name: String
        let minutes: [Int]
    }

    var foodOn: Bool
    var foodMinutes: Int
    var medicines: [MedicineTimes]
    var testOn: Bool
    var testDate: Date?
}

/// Local notifications only. Everything is rebuilt from the plan each time,
/// so there is never a stale reminder. Texts never contain health values.
enum Reminders {
    static let prefix = "irovi."

    static func requests(for plan: ReminderPlan, now: Date = .now, calendar: Calendar = .current) -> [UNNotificationRequest] {
        var result: [UNNotificationRequest] = []

        if plan.foodOn {
            result.append(daily(id: "food", minutes: plan.foodMinutes,
                                body: String(localized: "Has your plate had something iron-rich today?")))
        }

        for (index, medicine) in plan.medicines.enumerated() {
            for minutes in medicine.minutes {
                result.append(daily(id: "med.\(index).\(minutes)", minutes: minutes,
                                    body: String(localized: "Reminder: \(medicine.name)")))
            }
        }

        if plan.testOn, let date = plan.testDate {
            var components = calendar.dateComponents([.year, .month, .day], from: date)
            components.hour = 9
            if let fire = calendar.date(from: components), fire > now {
                let content = makeContent(String(localized: "Your blood test is planned for today."))
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                result.append(UNNotificationRequest(identifier: prefix + "test", content: content, trigger: trigger))
            }
        }
        return result
    }

    static func apply(_ plan: ReminderPlan) async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests().map(\.identifier).filter { $0.hasPrefix(prefix) }
        center.removePendingNotificationRequests(withIdentifiers: pending)
        for request in requests(for: plan) {
            try? await center.add(request)
        }
    }

    /// Asks once; returns whether notifications are allowed.
    static func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral: return true
        case .denied: return false
        default: return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        }
    }

    /// Reads the current settings and medicines, then reschedules everything.
    @MainActor
    static func sync(_ context: ModelContext, defaults: UserDefaults = .standard) async {
        let medicines = (try? context.fetch(FetchDescriptor<Medicine>(sortBy: [SortDescriptor(\.createdAt)]))) ?? []
        let testInterval = defaults.double(forKey: Prefs.nextTestDate)
        let plan = ReminderPlan(
            foodOn: defaults.bool(forKey: Prefs.foodReminderOn),
            foodMinutes: defaults.object(forKey: Prefs.foodReminderMinutes) as? Int ?? Prefs.defaultFoodReminderMinutes,
            medicines: medicines.filter(\.isActive).map { .init(name: $0.name, minutes: $0.reminderMinutes) },
            testOn: defaults.bool(forKey: Prefs.testReminderOn),
            testDate: testInterval > 0 ? Date(timeIntervalSince1970: testInterval) : nil
        )
        await apply(plan)
    }

    private static func daily(id: String, minutes: Int, body: String) -> UNNotificationRequest {
        var components = DateComponents()
        components.hour = minutes / 60
        components.minute = minutes % 60
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        return UNNotificationRequest(identifier: prefix + id, content: makeContent(body), trigger: trigger)
    }

    private static func makeContent(_ body: String) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = "Irovi"
        content.body = body
        content.sound = .default
        return content
    }
}

extension Int {
    /// "11:30 AM" / "11:30" for minutes after midnight, in the user's locale.
    var clockText: String {
        var components = DateComponents()
        components.hour = self / 60
        components.minute = self % 60
        let date = Calendar.current.date(from: components) ?? .now
        return date.formatted(date: .omitted, time: .shortened)
    }
}

extension Date {
    var minutesAfterMidnight: Int {
        let c = Calendar.current.dateComponents([.hour, .minute], from: self)
        return (c.hour ?? 0) * 60 + (c.minute ?? 0)
    }

    static func todayAt(minutes: Int) -> Date {
        Calendar.current.date(bySettingHour: minutes / 60, minute: minutes % 60, second: 0, of: .now) ?? .now
    }
}
