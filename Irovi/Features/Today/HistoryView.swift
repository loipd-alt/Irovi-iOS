import SwiftData
import SwiftUI

/// Month calendar of the checklist: which days reached the goal, which had
/// something logged, and a short month summary. Tap a past day to see or
/// edit what was logged.
struct HistoryView: View {
    @Query private var logs: [DayLog]
    @AppStorage(Prefs.dailyGoal) private var goal = Prefs.defaultGoal

    @State private var month = Calendar.current.dateInterval(of: .month, for: .now)?.start ?? .now
    @State private var openDay: DayItem?

    private let calendar = Calendar.current

    private var countsByDay: [String: Int] {
        Dictionary(logs.map { ($0.dayKey, $0.foods.count) }, uniquingKeysWith: max)
    }

    private var daysInMonth: [Date] {
        guard let range = calendar.range(of: .day, in: .month, for: month) else { return [] }
        return range.compactMap { calendar.date(byAdding: .day, value: $0 - 1, to: month) }
    }

    /// Empty cells before day 1, following the user's first weekday.
    private var leadingBlanks: Int {
        (calendar.component(.weekday, from: month) - calendar.firstWeekday + 7) % 7
    }

    private var weekdaySymbols: [String] {
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        let start = calendar.firstWeekday - 1
        return Array(symbols[start...] + symbols[..<start])
    }

    private var isCurrentMonth: Bool { calendar.isDate(month, equalTo: .now, toGranularity: .month) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Palette.Space.xl) {
                monthHeader
                calendarPanel
                summaryPanel
            }
            .padding(.horizontal, Palette.Space.gutter)
            .padding(.vertical, Palette.Space.l)
        }
        .background(Palette.background)
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $openDay) { LogFoodView(date: $0.date) }
    }

    private var monthHeader: some View {
        HStack {
            Button { shiftMonth(-1) } label: { Image(systemName: "chevron.left") }
                .accessibilityLabel("Previous month")
            Spacer()
            Text(month, format: .dateTime.month(.wide).year())
                .font(Palette.display(.title2))
                .foregroundStyle(Palette.textPrimary)
            Spacer()
            Button { shiftMonth(1) } label: { Image(systemName: "chevron.right") }
                .disabled(isCurrentMonth)
                .accessibilityLabel("Next month")
        }
        .font(.title3.weight(.semibold))
        .tint(Palette.iron)
    }

    private var calendarPanel: some View {
        Panel {
            VStack(spacing: Palette.Space.m) {
                let columns = Array(repeating: GridItem(.flexible(), spacing: Palette.Space.xs), count: 7)
                LazyVGrid(columns: columns, spacing: Palette.Space.xs) {
                    ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                        Text(symbol)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Palette.textSecondary)
                            .frame(height: 24)
                    }
                    ForEach(0..<leadingBlanks, id: \.self) { _ in Color.clear.frame(height: 42) }
                    ForEach(daysInMonth, id: \.self) { day in dayCell(day) }
                }
                HStack(spacing: Palette.Space.l) {
                    legend(Palette.leaf, "Goal reached")
                    legend(Palette.ironSoft, "Some food logged")
                    Spacer()
                }
                .font(.caption)
                .foregroundStyle(Palette.textSecondary)
            }
        }
    }

    private func dayCell(_ day: Date) -> some View {
        let count = countsByDay[DayKey.make(day)] ?? 0
        let met = count >= goal
        let isFuture = day > .now
        let isToday = calendar.isDateInToday(day)
        return Button { openDay = DayItem(date: day) } label: {
            ZStack {
                Circle().fill(met ? Palette.leaf : (count > 0 ? Palette.ironSoft : .clear))
                if isToday {
                    Circle().strokeBorder(Palette.iron, lineWidth: 2)
                }
                Text(day, format: .dateTime.day())
                    .font(.subheadline.weight(isToday ? .bold : .medium))
                    .foregroundStyle(met ? .white : (isFuture ? Palette.textSecondary.opacity(0.4) : Palette.textPrimary))
            }
            .frame(width: 40, height: 40)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .disabled(isFuture)
        .accessibilityLabel(Text(day, format: .dateTime.day().month(.wide)))
        .accessibilityValue(Text(met ? "Goal reached" : (count > 0 ? "Some food logged" : "Nothing logged yet")))
    }

    private var summaryPanel: some View {
        let keys = Set(daysInMonth.map { DayKey.make($0) })
        let monthLogs = logs.filter { keys.contains($0.dayKey) }
        let met = monthLogs.filter { $0.foods.count >= goal }.count
        var tally: [FoodGroup: Int] = [:]
        for log in monthLogs { for food in log.foods { tally[food, default: 0] += 1 } }
        let top = tally.max { a, b in a.value == b.value ? a.key.rawValue > b.key.rawValue : a.value < b.value }

        return HStack(spacing: Palette.Space.m) {
            summaryTile(value: "\(met)", title: "Days on goal", detail: nil, tint: Palette.leafSoft)
            summaryTile(value: top?.key.emoji ?? "—", title: "Most logged", detail: top?.key.name,
                        tint: top?.key.tint ?? Palette.surfaceAlt)
        }
    }

    private func summaryTile(value: String, title: LocalizedStringKey, detail: String?, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: Palette.Space.xs) {
            Text(verbatim: value)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(Palette.textPrimary)
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Palette.textSecondary)
            if let detail {
                Text(detail)
                    .font(.footnote)
                    .foregroundStyle(Palette.textSecondary)
                    .lineLimit(2)
            }
        }
        .padding(Palette.Space.l)
        .frame(maxWidth: .infinity, minHeight: 100, alignment: .topLeading)
        .background(tint, in: RoundedRectangle(cornerRadius: Palette.Radius.tile, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private func legend(_ color: Color, _ text: LocalizedStringKey) -> some View {
        HStack(spacing: Palette.Space.xs) {
            Circle().fill(color).frame(width: 10, height: 10)
            Text(text)
        }
    }

    private func shiftMonth(_ delta: Int) {
        if let next = calendar.date(byAdding: .month, value: delta, to: month) {
            withAnimation(.snappy) { month = next }
        }
    }
}

/// A day opened from the calendar.
struct DayItem: Identifiable {
    let date: Date
    var id: String { DayKey.make(date) }
}
