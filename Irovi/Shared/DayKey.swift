import Foundation

/// "yyyy-MM-dd" in the user's time zone. One checklist entry per key.
/// Shared by the app and the widget.
enum DayKey {
    static func make(_ date: Date, calendar: Calendar = .current) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }
}
