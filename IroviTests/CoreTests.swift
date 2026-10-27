import UserNotifications
import XCTest
@testable import Irovi

final class ProgressTests: XCTestCase {
    private var calendar: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh")!
        return c
    }

    private func day(_ offset: Int, from base: Date) -> String {
        DayKey.make(calendar.date(byAdding: .day, value: offset, to: base)!, calendar: calendar)
    }

    func testFractionIsCappedAndSafe() {
        XCTAssertEqual(ChecklistProgress.fraction(checked: 2, goal: 4), 0.5)
        XCTAssertEqual(ChecklistProgress.fraction(checked: 6, goal: 3), 1)
        XCTAssertEqual(ChecklistProgress.fraction(checked: 1, goal: 0), 0)
    }

    func testStreakCountsBackFromTodayWhenMet() {
        let today = calendar.date(from: DateComponents(year: 2026, month: 10, day: 27, hour: 20))!
        let counts = [day(0, from: today): 3, day(-1, from: today): 4, day(-2, from: today): 3, day(-4, from: today): 3]
        XCTAssertEqual(ChecklistProgress.streak(foodCountsByDay: counts, goal: 3, today: today, calendar: calendar), 3)
    }

    func testStreakDoesNotBreakBeforeTodayIsDone() {
        let today = calendar.date(from: DateComponents(year: 2026, month: 10, day: 27, hour: 8))!
        let counts = [day(0, from: today): 1, day(-1, from: today): 3, day(-2, from: today): 3]
        XCTAssertEqual(ChecklistProgress.streak(foodCountsByDay: counts, goal: 3, today: today, calendar: calendar), 2)
    }

    func testNoStreakWithoutData() {
        XCTAssertEqual(ChecklistProgress.streak(foodCountsByDay: [:], goal: 3, calendar: calendar), 0)
    }
}

final class UnitTests: XCTestCase {
    func testHemoglobinConversionRoundTrips() {
        XCTAssertEqual(HemoglobinUnit.gPerL.display(12.3), 123, accuracy: 0.0001)
        XCTAssertEqual(HemoglobinUnit.gPerL.stored(123), 12.3, accuracy: 0.0001)
        XCTAssertEqual(HemoglobinUnit.gPerDL.display(12.3), 12.3)
    }

    func testNumberInputAcceptsCommaAndDot() {
        XCTAssertEqual(NumberInput.parse("12,5"), 12.5)
        XCTAssertEqual(NumberInput.parse(" 12.5 "), 12.5)
        XCTAssertNil(NumberInput.parse(""))
        XCTAssertNil(NumberInput.parse("abc"))
    }

    func testEntryRangesCatchTypos() {
        XCTAssertTrue(HemoglobinUnit.gPerDL.entryRange.contains(12))
        XCTAssertFalse(HemoglobinUnit.gPerDL.entryRange.contains(120))
        XCTAssertTrue(HemoglobinUnit.gPerL.entryRange.contains(120))
    }
}

final class ExportTests: XCTestCase {
    func testCSVEscapesNotesAndListsResults() {
        let lab = LabResult(date: Date(timeIntervalSince1970: 0), hemoglobin: 11.5, ferritin: 20, note: "Lab A, fasting")
        let csv = CSVBuilder.make(logs: [], labs: [lab], unit: .gPerDL)
        XCTAssertTrue(csv.hasPrefix("section,date,items,hemoglobin_g/dL,ferritin_ng/mL,note\n"))
        XCTAssertTrue(csv.contains("\"Lab A, fasting\""))
        XCTAssertTrue(csv.contains(",11.5,20,"))
    }
}

final class ReminderTests: XCTestCase {
    func testPlanBuildsOneRequestPerReminder() {
        let plan = ReminderPlan(foodOn: true, foodMinutes: 690,
                                medicines: [.init(name: "Tablet", minutes: [480, 1200])],
                                testOn: true, testDate: Date().addingTimeInterval(3 * 86_400))
        let requests = Reminders.requests(for: plan)
        XCTAssertEqual(requests.count, 4)
        XCTAssertTrue(requests.allSatisfy { $0.identifier.hasPrefix(Reminders.prefix) })
        XCTAssertEqual(Set(requests.map(\.identifier)).count, 4)
    }

    func testPastTestDateIsNotScheduled() {
        let plan = ReminderPlan(foodOn: false, foodMinutes: 0, medicines: [],
                                testOn: true, testDate: Date().addingTimeInterval(-86_400))
        XCTAssertTrue(Reminders.requests(for: plan).isEmpty)
    }

    func testNotificationTextHasNoHealthValues() {
        let plan = ReminderPlan(foodOn: true, foodMinutes: 690, medicines: [], testOn: false, testDate: nil)
        let body = Reminders.requests(for: plan).first?.content.body ?? ""
        XCTAssertFalse(body.contains(where: \.isNumber))
    }
}
