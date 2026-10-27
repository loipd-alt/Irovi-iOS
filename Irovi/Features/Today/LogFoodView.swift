import SwiftData
import SwiftUI

/// Log which iron-rich food groups (and absorption habits) made it onto the
/// plate — today or yesterday, or any past day opened from History.
struct LogFoodView: View {
    enum Day: Hashable { case today, yesterday }

    /// Set when opened from History; hides the Today/Yesterday switch.
    private let fixedDate: Date?

    init(date: Date? = nil) {
        fixedDate = date
    }

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \DayLog.date, order: .reverse) private var logs: [DayLog]
    @AppStorage(Prefs.dailyGoal) private var goal = Prefs.defaultGoal

    @State private var day: Day = .today

    private var date: Date {
        if let fixedDate { return fixedDate }
        return day == .today ? .now : (Calendar.current.date(byAdding: .day, value: -1, to: .now) ?? .now)
    }

    private var goalText: LocalizedStringKey {
        guard eaten.count >= goal else { return "\(eaten.count) of \(goal) food groups" }
        return Calendar.current.isDateInToday(date) ? "Goal reached today" : "Goal reached"
    }

    private var log: DayLog? { logs.first { $0.dayKey == DayKey.make(date) } }
    private var eaten: Set<FoodGroup> { log?.foods ?? [] }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Palette.Space.xl) {
                    if fixedDate == nil {
                        ChoiceTrack(options: [Day.today, .yesterday], selection: $day) { $0 == .today ? "Today" : "Yesterday" }
                    }

                    VStack(alignment: .leading, spacing: Palette.Space.s) {
                        Text(goalText)
                            .font(Palette.display(.title3))
                            .foregroundStyle(eaten.count >= goal ? Palette.leaf : Palette.textPrimary)
                        ProgressView(value: ChecklistProgress.fraction(checked: eaten.count, goal: goal))
                            .tint(eaten.count >= goal ? Palette.leaf : Palette.iron)
                            .animation(.snappy, value: eaten.count)
                    }

                    VStack(alignment: .leading, spacing: Palette.Space.m) {
                        SectionTitle("Iron-rich foods")
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: Palette.Space.m),
                                            GridItem(.flexible(), spacing: Palette.Space.m)],
                                  spacing: Palette.Space.m) {
                            ForEach(FoodGroup.allCases) { food in
                                FoodTile(food: food, isOn: eaten.contains(food)) { edit { $0.toggle(food) } }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: Palette.Space.m) {
                        SectionTitle("Help your body absorb it")
                        ForEach(IronHabit.allCases) { habit in
                            CheckRow(emoji: habit.emoji, title: habit.name, detail: habit.detail,
                                     isOn: log?.habits.contains(habit) ?? false) {
                                edit { $0.toggle(habit) }
                            }
                        }
                    }
                }
                .padding(.horizontal, Palette.Space.gutter)
                .padding(.vertical, Palette.Space.l)
            }
            .background(Palette.background)
            .navigationTitle(fixedDate.map { $0.formatted(.dateTime.weekday(.wide).day().month(.wide)) } ?? String(localized: "Log food"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
    }

    /// Changes the selected day's log, creating it on first use.
    private func edit(_ change: (DayLog) -> Void) {
        let target = log ?? {
            let created = DayLog(date: date)
            context.insert(created)
            return created
        }()
        withAnimation(.snappy) { change(target) }
        try? context.save()
        WidgetSync.refresh(context)
    }
}

/// One food group on its own pastel; tap to mark it eaten.
private struct FoodTile: View {
    let food: FoodGroup
    let isOn: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: Palette.Space.s) {
                HStack(alignment: .top) {
                    Text(food.emoji)
                        .font(.system(size: 28))
                        .frame(width: 50, height: 50)
                        .background(Palette.surface.opacity(0.85), in: Circle())
                        .accessibilityHidden(true)
                    Spacer()
                    Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundStyle(isOn ? Palette.iron : Palette.textSecondary.opacity(0.35))
                        .accessibilityHidden(true)
                }
                Text(food.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Palette.textPrimary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Text(food.examples)
                    .font(.caption)
                    .foregroundStyle(Palette.textSecondary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2, reservesSpace: true)
            }
            .padding(Palette.Space.l)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(food.tint, in: RoundedRectangle(cornerRadius: Palette.Radius.tile, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Palette.Radius.tile, style: .continuous)
                    .strokeBorder(isOn ? Palette.iron : .clear, lineWidth: 2.5)
            )
            .scaleEffect(isOn ? 1 : 0.98)
            .animation(.snappy, value: isOn)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(food.name))
        .accessibilityHint(Text(food.examples))
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }
}
