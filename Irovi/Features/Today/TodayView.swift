import SwiftData
import SwiftUI

/// The daily checklist: which iron-rich food groups made it onto today's plate,
/// two absorption habits, the user's own medicines, and a tip.
struct TodayView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \DayLog.date, order: .reverse) private var logs: [DayLog]
    @Query(filter: #Predicate<Medicine> { $0.isActive }, sort: \Medicine.createdAt) private var medicines: [Medicine]

    @AppStorage(Prefs.dailyGoal) private var goal = Prefs.defaultGoal
    @AppStorage(Prefs.nextTestDate) private var nextTestInterval: Double = 0

    @State private var showSettings = false

    private var todayKey: String { DayKey.make(.now) }
    private var todayLog: DayLog? { logs.first { $0.dayKey == todayKey } }
    private var checked: Set<FoodGroup> { todayLog?.foods ?? [] }

    private var streak: Int {
        var counts: [String: Int] = [:]
        for log in logs { counts[log.dayKey] = log.foods.count }
        return ChecklistProgress.streak(foodCountsByDay: counts, goal: goal)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Palette.Space.xl) {
                    ProgressHero(checked: checked.count, goal: goal, streak: streak)

                    VStack(alignment: .leading, spacing: Palette.Space.m) {
                        SectionTitle("Iron-rich foods today")
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: Palette.Space.m),
                                            GridItem(.flexible(), spacing: Palette.Space.m)],
                                  spacing: Palette.Space.m) {
                            ForEach(FoodGroup.allCases) { food in
                                FoodTile(food: food, isOn: checked.contains(food)) {
                                    edit { $0.toggle(food) }
                                }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: Palette.Space.m) {
                        SectionTitle("Help your body absorb it")
                        ForEach(IronHabit.allCases) { habit in
                            CheckRow(emoji: habit.emoji, title: habit.name, detail: habit.detail,
                                     isOn: todayLog?.habits.contains(habit) ?? false) {
                                edit { $0.toggle(habit) }
                            }
                        }
                    }

                    if !medicines.isEmpty {
                        VStack(alignment: .leading, spacing: Palette.Space.m) {
                            SectionTitle("Your medicines")
                            ForEach(medicines) { medicine in
                                CheckRow(emoji: "💊", title: medicine.name,
                                         detail: medicine.reminderMinutes.map(\.clockText).joined(separator: " · "),
                                         isOn: todayLog?.takenMedicineIDs.contains(medicine.id.uuidString) ?? false) {
                                    edit { $0.toggleMedicine(medicine.id) }
                                }
                            }
                        }
                    }

                    if let next = nextTest {
                        NextTestCard(date: next)
                    }

                    TipCard(article: Article.tipOfTheDay)
                }
                .padding(.horizontal, Palette.Space.gutter)
                .padding(.vertical, Palette.Space.l)
            }
            .background(Palette.background)
            .navigationTitle("Today")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Settings")
                }
            }
            .sheet(isPresented: $showSettings) { SettingsView() }
        }
    }

    private var nextTest: Date? {
        guard nextTestInterval > 0 else { return nil }
        let date = Date(timeIntervalSince1970: nextTestInterval)
        return date >= Calendar.current.startOfDay(for: .now) ? date : nil
    }

    /// Changes today's log, creating it on first use.
    private func edit(_ change: (DayLog) -> Void) {
        let log: DayLog
        if let existing = todayLog {
            log = existing
        } else {
            log = DayLog(date: .now)
            context.insert(log)
        }
        withAnimation(.snappy) { change(log) }
        try? context.save()
    }
}

/// Ring with today's count, plus the streak.
private struct ProgressHero: View {
    let checked: Int
    let goal: Int
    let streak: Int

    private var done: Bool { checked >= goal }

    var body: some View {
        Panel(padding: Palette.Space.xl) {
            HStack(spacing: Palette.Space.xl) {
                ZStack {
                    Circle()
                        .stroke(Palette.ironSoft, lineWidth: 14)
                    Circle()
                        .trim(from: 0, to: ChecklistProgress.fraction(checked: checked, goal: goal))
                        .stroke(done ? Palette.leaf : Palette.iron, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.snappy, value: checked)
                    Text(done ? "✓" : "\(checked)")
                        .font(Palette.display(.largeTitle))
                        .foregroundStyle(done ? Palette.leaf : Palette.iron)
                        .contentTransition(.numericText())
                }
                .frame(width: 96, height: 96)
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: Palette.Space.s) {
                    Text(Date.now, format: .dateTime.weekday(.wide).day().month(.wide))
                        .font(.subheadline)
                        .foregroundStyle(Palette.textSecondary)
                    Text(done ? "Goal reached today" : "\(checked) of \(goal) food groups")
                        .font(Palette.display(.title2))
                        .foregroundStyle(Palette.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    if streak > 0 {
                        Text(streak == 1 ? "🔥 1 day in a row" : "🔥 \(streak) days in a row")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Palette.onLeafSoft)
                            .padding(.horizontal, Palette.Space.m)
                            .padding(.vertical, Palette.Space.xs)
                            .background(Palette.leafSoft, in: Capsule())
                    }
                }
                Spacer(minLength: 0)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

/// One food group; tap to mark it eaten today.
private struct FoodTile: View {
    let food: FoodGroup
    let isOn: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: Palette.Space.s) {
                HStack(alignment: .top) {
                    Text(food.emoji)
                        .font(.system(size: 34))
                        .accessibilityHidden(true)
                    Spacer()
                    Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(isOn ? Palette.iron : Palette.border)
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
            .background(isOn ? Palette.ironSoft : Palette.surface,
                        in: RoundedRectangle(cornerRadius: Palette.Radius.tile, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Palette.Radius.tile, style: .continuous)
                    .strokeBorder(isOn ? Palette.iron : Palette.border, lineWidth: isOn ? 2 : 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(food.name))
        .accessibilityHint(Text(food.examples))
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }
}

/// A habit or medicine row with a green tick.
struct CheckRow: View {
    let emoji: String
    let title: String
    let detail: String
    let isOn: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Palette.Space.m) {
                Text(emoji)
                    .font(.title2)
                    .frame(width: 44, height: 44)
                    .background(isOn ? Palette.leafSoft : Palette.surfaceAlt, in: Circle())
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Palette.textPrimary)
                    if !detail.isEmpty {
                        Text(detail)
                            .font(.footnote)
                            .foregroundStyle(Palette.textSecondary)
                    }
                }
                Spacer(minLength: 0)
                Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isOn ? Palette.leaf : Palette.border)
                    .accessibilityHidden(true)
            }
            .padding(Palette.Space.m)
            .background(Palette.surface, in: RoundedRectangle(cornerRadius: Palette.Radius.tile, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }
}

private struct NextTestCard: View {
    let date: Date

    private var days: Int {
        Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: .now),
                                        to: Calendar.current.startOfDay(for: date)).day ?? 0
    }

    var body: some View {
        Panel {
            HStack(spacing: Palette.Space.m) {
                Image(systemName: "calendar")
                    .font(.title2)
                    .foregroundStyle(Palette.iron)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Next blood test")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Palette.textSecondary)
                    Text(date, format: .dateTime.weekday(.abbreviated).day().month(.abbreviated))
                        .font(Palette.display(.title3))
                        .foregroundStyle(Palette.textPrimary)
                }
                Spacer()
                Text(days == 0 ? "Today" : (days == 1 ? "Tomorrow" : "In \(days) days"))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Palette.onIronSoft)
                    .padding(.horizontal, Palette.Space.m)
                    .padding(.vertical, Palette.Space.xs)
                    .background(Palette.ironSoft, in: Capsule())
            }
        }
        .accessibilityElement(children: .combine)
    }
}

private struct TipCard: View {
    let article: Article

    var body: some View {
        NavigationLink { ArticleView(article: article) } label: {
            Panel {
                VStack(alignment: .leading, spacing: Palette.Space.s) {
                    Label("Tip of the day", systemImage: "lightbulb")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Palette.leaf)
                    Text(article.title)
                        .font(Palette.display(.title3))
                        .foregroundStyle(Palette.textPrimary)
                        .multilineTextAlignment(.leading)
                    Text(article.summary)
                        .font(.subheadline)
                        .foregroundStyle(Palette.textSecondary)
                        .multilineTextAlignment(.leading)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
