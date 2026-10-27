import Charts
import SwiftData
import SwiftUI

/// Sheets Home can open. `add` is the chooser behind the floating + button.
enum HomeRoute: String, Identifiable {
    case add, food, lab, medicine, settings
    var id: String { rawValue }
}

/// The overview: today's plate, the week, latest blood results, medicines,
/// the next test and a tip. Logging happens through the + button.
struct HomeView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \DayLog.date, order: .reverse) private var logs: [DayLog]
    @Query(sort: \LabResult.date) private var labs: [LabResult]
    @Query(filter: #Predicate<Medicine> { $0.isActive }, sort: \Medicine.createdAt) private var medicines: [Medicine]

    @AppStorage(Prefs.dailyGoal) private var goal = Prefs.defaultGoal
    @AppStorage(Prefs.nextTestDate) private var nextTestInterval: Double = 0
    @AppStorage(Prefs.hbUnit) private var unitRaw = HemoglobinUnit.gPerDL.rawValue
    @AppStorage(Prefs.selectedTab) private var tab = AppTab.today.rawValue

    @Environment(AppRouter.self) private var router
    @State private var route: HomeRoute?
    @State private var pendingRoute: HomeRoute?

    private var todayLog: DayLog? { logs.first { $0.dayKey == DayKey.make(.now) } }
    private var countsByDay: [String: Int] {
        Dictionary(logs.map { ($0.dayKey, $0.foods.count) }, uniquingKeysWith: max)
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                ScrollView {
                    VStack(alignment: .leading, spacing: Palette.Space.xl) {
                        PlateHero(eaten: todayLog?.foods ?? [], goal: goal,
                                  streak: ChecklistProgress.streak(foodCountsByDay: countsByDay, goal: goal)) {
                            route = .food
                        }

                        WeekCard(countsByDay: countsByDay, goal: goal)

                        VStack(alignment: .leading, spacing: Palette.Space.m) {
                            SectionTitle(title: "Blood results") {
                                if !labs.isEmpty {
                                    Button("See all") { tab = AppTab.blood.rawValue }
                                        .font(.subheadline.weight(.semibold))
                                }
                            }
                            BloodSummary(labs: labs, unit: HemoglobinUnit(rawValue: unitRaw) ?? .gPerDL,
                                         onOpen: { tab = AppTab.blood.rawValue }, onAdd: { route = .lab })
                        }

                        if !medicines.isEmpty {
                            VStack(alignment: .leading, spacing: Palette.Space.m) {
                                SectionTitle("Today's medicines")
                                ForEach(medicines) { medicine in
                                    CheckRow(emoji: "💊", title: medicine.name,
                                             detail: medicine.reminderMinutes.map(\.clockText).joined(separator: " · "),
                                             isOn: todayLog?.takenMedicineIDs.contains(medicine.id.uuidString) ?? false) {
                                        toggleMedicine(medicine)
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
                    .padding(.top, Palette.Space.s)
                    .padding(.bottom, 96)
                }
                .background(Palette.background)

                AddButton { route = .add }
                    .padding(.trailing, Palette.Space.gutter)
                    .padding(.bottom, Palette.Space.l)
            }
            .navigationTitle(greeting)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { route = .settings } label: { Image(systemName: "gearshape") }
                        .accessibilityLabel("Settings")
                }
            }
            .onChange(of: router.openFoodLog, initial: true) { _, open in
                guard open else { return }
                router.openFoodLog = false
                route = .food
            }
            .sheet(item: $route, onDismiss: openPending) { destination in
                switch destination {
                case .add:
                    AddSheet { picked in
                        pendingRoute = picked
                        route = nil
                    }
                case .food: LogFoodView()
                case .lab: LabResultEditor(existing: nil)
                case .medicine: MedicineEditor(existing: nil)
                case .settings: SettingsView()
                }
            }
        }
    }

    private var greeting: String {
        switch Calendar.current.component(.hour, from: .now) {
        case 5..<12: String(localized: "Good morning")
        case 12..<18: String(localized: "Good afternoon")
        default: String(localized: "Good evening")
        }
    }

    private var nextTest: Date? {
        guard nextTestInterval > 0 else { return nil }
        let date = Date(timeIntervalSince1970: nextTestInterval)
        return date >= Calendar.current.startOfDay(for: .now) ? date : nil
    }

    private func openPending() {
        if let next = pendingRoute {
            pendingRoute = nil
            route = next
        }
    }

    private func toggleMedicine(_ medicine: Medicine) {
        let log = todayLog ?? {
            let created = DayLog(date: .now)
            context.insert(created)
            return created
        }()
        withAnimation(.snappy) { log.toggleMedicine(medicine.id) }
        try? context.save()
    }
}

// MARK: - Hero

private struct PlateHero: View {
    let eaten: Set<FoodGroup>
    let goal: Int
    let streak: Int
    let onLog: () -> Void

    private var done: Bool { eaten.count >= goal }

    var body: some View {
        VStack(alignment: .leading, spacing: Palette.Space.l) {
            HStack(alignment: .top) {
                Text("Today's iron plate")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.92))
                Spacer()
                if streak > 0 {
                    Text(streak == 1 ? "🔥 1 day in a row" : "🔥 \(streak) days in a row")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, Palette.Space.m)
                        .padding(.vertical, Palette.Space.xs)
                        .background(.white.opacity(0.2), in: Capsule())
                }
            }

            HStack(spacing: Palette.Space.xl) {
                ZStack {
                    Circle().stroke(.white.opacity(0.25), lineWidth: 12)
                    Circle()
                        .trim(from: 0, to: ChecklistProgress.fraction(checked: eaten.count, goal: goal))
                        .stroke(.white, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.snappy, value: eaten.count)
                    Text(done ? "✓" : "\(eaten.count)")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .contentTransition(.numericText())
                }
                .frame(width: 92, height: 92)
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: Palette.Space.s) {
                    Text(done ? "Goal reached today" : "\(eaten.count) of \(goal) food groups")
                        .font(Palette.display(.title2))
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)
                    if eaten.isEmpty {
                        Text("Nothing logged yet")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.9))
                    } else {
                        Text(FoodGroup.allCases.filter(eaten.contains).map(\.emoji).joined(separator: " "))
                            .font(.title3)
                            .accessibilityHidden(true)
                    }
                }
                Spacer(minLength: 0)
            }

            Button(action: onLog) {
                Label("Log food", systemImage: "plus")
                    .font(.headline)
                    .foregroundStyle(Palette.iron)
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .background(.white, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(Palette.Space.xl)
        .background(Palette.heroGradient, in: RoundedRectangle(cornerRadius: Palette.Radius.card, style: .continuous))
        .shadow(color: Palette.ironDeep.opacity(0.28), radius: 18, y: 10)
    }
}

// MARK: - Week

private struct WeekCard: View {
    let countsByDay: [String: Int]
    let goal: Int

    private var days: [Date] {
        let today = Calendar.current.startOfDay(for: .now)
        return (0..<7).reversed().compactMap { Calendar.current.date(byAdding: .day, value: -$0, to: today) }
    }

    private func count(_ day: Date) -> Int { countsByDay[DayKey.make(day)] ?? 0 }

    var body: some View {
        let met = days.filter { count($0) >= goal }.count
        Panel {
            VStack(alignment: .leading, spacing: Palette.Space.l) {
                HStack(alignment: .firstTextBaseline) {
                    Text("This week")
                        .font(Palette.display(.title3))
                        .foregroundStyle(Palette.textPrimary)
                    Spacer()
                    NavigationLink { HistoryView() } label: {
                        HStack(spacing: 2) {
                            Text("History")
                            Image(systemName: "chevron.right").font(.footnote.weight(.semibold))
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Palette.iron)
                    }
                }
                HStack(alignment: .bottom, spacing: Palette.Space.s) {
                    ForEach(days, id: \.self) { day in
                        let value = count(day)
                        let isToday = Calendar.current.isDateInToday(day)
                        VStack(spacing: Palette.Space.s) {
                            ZStack(alignment: .bottom) {
                                Capsule().fill(Palette.surfaceAlt)
                                Capsule()
                                    .fill(value >= goal ? Palette.leaf : Palette.iron)
                                    .frame(height: value == 0 ? 0 : max(12, 76 * ChecklistProgress.fraction(checked: value, goal: goal)))
                            }
                            .frame(height: 76)
                            .frame(maxWidth: 28)
                            Text(day, format: .dateTime.weekday(.narrow))
                                .font(.caption.weight(isToday ? .bold : .regular))
                                .foregroundStyle(isToday ? Palette.iron : Palette.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text("This week"))
                .accessibilityValue(Text("\(met) of 7 days on goal"))
                Text("\(met) of 7 days on goal")
                    .font(.subheadline)
                    .foregroundStyle(Palette.textSecondary)
                    .accessibilityHidden(true)
            }
        }
    }
}

// MARK: - Blood

private struct BloodSummary: View {
    let labs: [LabResult]
    let unit: HemoglobinUnit
    let onOpen: () -> Void
    let onAdd: () -> Void

    var body: some View {
        let hb = labs.compactMap { lab in lab.hemoglobin.map { (lab.date, unit.display($0)) } }
        let ferritin = labs.compactMap { lab in lab.ferritin.map { (lab.date, $0) } }
        if hb.isEmpty && ferritin.isEmpty {
            Panel {
                VStack(alignment: .leading, spacing: Palette.Space.m) {
                    Text("No blood results yet")
                        .font(.headline)
                        .foregroundStyle(Palette.textPrimary)
                    Text("Add your hemoglobin and ferritin to see them here.")
                        .font(.subheadline)
                        .foregroundStyle(Palette.textSecondary)
                    Button("Add a result", action: onAdd)
                        .buttonStyle(.tinted)
                }
            }
        } else {
            Button(action: onOpen) {
                HStack(spacing: Palette.Space.m) {
                    MetricMini(title: "Hemoglobin", unit: unit.symbol, series: hb,
                               format: { unit.format(unit.stored($0)) }, tint: Palette.iron, soft: Palette.ironSoft)
                    MetricMini(title: "Ferritin", unit: Ferritin.symbol, series: ferritin,
                               format: Ferritin.format, tint: Palette.amber, soft: Palette.amberSoft)
                }
            }
            .buttonStyle(.plain)
        }
    }
}

private struct MetricMini: View {
    let title: LocalizedStringKey
    let unit: String
    let series: [(Date, Double)]
    let format: (Double) -> String
    let tint: Color
    let soft: Color

    var body: some View {
        VStack(alignment: .leading, spacing: Palette.Space.s) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Palette.textSecondary)
            if let last = series.last {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(format(last.1))
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(Palette.textPrimary)
                    Text(verbatim: unit)
                        .font(.caption)
                        .foregroundStyle(Palette.textSecondary)
                }
                if series.count >= 2 {
                    Chart {
                        ForEach(Array(series.enumerated()), id: \.offset) { index, point in
                            LineMark(x: .value("Index", index), y: .value("Value", point.1))
                                .interpolationMethod(.monotone)
                                .foregroundStyle(tint)
                                .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
                        }
                    }
                    .chartXAxis(.hidden)
                    .chartYAxis(.hidden)
                    .chartYScale(domain: .automatic(includesZero: false))
                    .frame(height: 34)
                    .accessibilityHidden(true)
                }
                Text(last.0, format: .dateTime.day().month(.abbreviated).year())
                    .font(.caption)
                    .foregroundStyle(Palette.textSecondary)
            } else {
                Text(verbatim: "—")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(Palette.textSecondary)
                Text("No data")
                    .font(.caption)
                    .foregroundStyle(Palette.textSecondary)
            }
        }
        .padding(Palette.Space.l)
        .frame(maxWidth: .infinity, minHeight: 150, alignment: .topLeading)
        .background(soft, in: RoundedRectangle(cornerRadius: Palette.Radius.tile, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Shared pieces

/// Floating + that opens the add chooser.
private struct AddButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: Palette.Size.fab, height: Palette.Size.fab)
                .background(Palette.actionGradient, in: Circle())
                .shadow(color: Palette.ironDeep.opacity(0.35), radius: 12, y: 6)
        }
        .accessibilityLabel("Add")
    }
}

/// Chooser behind the + button.
struct AddSheet: View {
    let onPick: (HomeRoute) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Palette.Space.m) {
            Text("What would you like to add?")
                .font(Palette.display(.title3))
                .foregroundStyle(Palette.textPrimary)
                .padding(.bottom, Palette.Space.xs)
            option("🥬", "Iron-rich food", "Tick what you ate today", Palette.leafSoft) { onPick(.food) }
            option("🩸", "Blood test result", "Hemoglobin and ferritin", Palette.ironSoft) { onPick(.lab) }
            option("💊", "Medicine reminder", "A medicine your doctor prescribed", Palette.amberSoft) { onPick(.medicine) }
        }
        .padding(Palette.Space.gutter)
        .padding(.top, Palette.Space.s)
        .presentationDetents([.height(380)])
        .presentationDragIndicator(.visible)
    }

    private func option(_ emoji: String, _ title: LocalizedStringKey, _ detail: LocalizedStringKey,
                        _ tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: Palette.Space.m) {
                Text(emoji)
                    .font(.title2)
                    .frame(width: 52, height: 52)
                    .background(tint, in: RoundedRectangle(cornerRadius: Palette.Radius.control, style: .continuous))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.headline).foregroundStyle(Palette.textPrimary)
                    Text(detail).font(.subheadline).foregroundStyle(Palette.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Palette.textSecondary)
                    .accessibilityHidden(true)
            }
            .padding(Palette.Space.m)
            .background(Palette.surface, in: RoundedRectangle(cornerRadius: Palette.Radius.tile, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: Palette.Radius.tile, style: .continuous).strokeBorder(Palette.border))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
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
                    .frame(width: 44, height: 44)
                    .background(Palette.ironSoft, in: Circle())
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
            HStack(alignment: .top, spacing: Palette.Space.m) {
                Text(article.emoji)
                    .font(.title)
                    .frame(width: 52, height: 52)
                    .background(.white.opacity(0.7), in: RoundedRectangle(cornerRadius: Palette.Radius.control, style: .continuous))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: Palette.Space.xs) {
                    Label("Tip of the day", systemImage: "lightbulb")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Palette.onLeafSoft)
                    Text(article.title)
                        .font(.headline)
                        .foregroundStyle(Palette.textPrimary)
                        .multilineTextAlignment(.leading)
                    Text(article.summary)
                        .font(.subheadline)
                        .foregroundStyle(Palette.textSecondary)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
            }
            .padding(Palette.Space.l)
            .background(Palette.leafSoft, in: RoundedRectangle(cornerRadius: Palette.Radius.card, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
