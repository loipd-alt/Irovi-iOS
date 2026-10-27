import Charts
import SwiftData
import SwiftUI

enum BloodMetric: String, CaseIterable, Identifiable {
    case hemoglobin, ferritin
    var id: String { rawValue }

    var title: LocalizedStringKey { self == .hemoglobin ? "Hemoglobin" : "Ferritin" }
}

/// Blood test results the user typed in: a chart per metric, an optional
/// target from their doctor, the next test date, and the full list.
/// Irovi shows numbers only; it never labels a value as low, normal or high.
struct BloodView: View {
    @Environment(\.modelContext) private var context
    @Environment(AppRouter.self) private var router
    @Query(sort: \LabResult.date) private var results: [LabResult]

    @AppStorage(Prefs.hbUnit) private var unitRaw = HemoglobinUnit.gPerDL.rawValue
    @AppStorage(Prefs.hbTarget) private var hbTarget: Double = 0
    @AppStorage(Prefs.ferritinTarget) private var ferritinTarget: Double = 0

    @State private var metric: BloodMetric = .hemoglobin
    @State private var editorItem: EditorItem?
    @State private var showTarget = false

    private var unit: HemoglobinUnit { HemoglobinUnit(rawValue: unitRaw) ?? .gPerDL }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Palette.Space.xl) {
                    ChoiceTrack(options: BloodMetric.allCases, selection: $metric) { $0.title }

                    if points.isEmpty {
                        emptyState
                    } else {
                        chartPanel
                    }

                    targetRow
                    NextTestPanel()

                    if !results.isEmpty {
                        VStack(alignment: .leading, spacing: Palette.Space.m) {
                            SectionTitle("All results")
                            ForEach(results.reversed()) { result in
                                Button { editorItem = EditorItem(result: result) } label: {
                                    ResultRow(result: result, unit: unit)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    CareNote(text: "Irovi doesn't interpret results. Ask your doctor what your numbers mean for you.")
                }
                .padding(.horizontal, Palette.Space.gutter)
                .padding(.vertical, Palette.Space.l)
            }
            .background(Palette.background)
            .navigationTitle("Blood")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { editorItem = EditorItem(result: nil) } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add a result")
                }
            }
            .sheet(item: $editorItem) { item in LabResultEditor(existing: item.result) }
            .sheet(isPresented: $showTarget) { TargetEditor(metric: metric) }
            // The widget was tapped: make way for Home's food log.
            .onChange(of: router.openFoodLog) { _, open in
                if open { editorItem = nil; showTarget = false }
            }
        }
    }

    // MARK: - Data

    private struct Point: Identifiable {
        let id: PersistentIdentifier
        let date: Date
        let value: Double
    }

    private var points: [Point] {
        results.compactMap { result in
            switch metric {
            case .hemoglobin: result.hemoglobin.map { Point(id: result.persistentModelID, date: result.date, value: unit.display($0)) }
            case .ferritin: result.ferritin.map { Point(id: result.persistentModelID, date: result.date, value: $0) }
            }
        }
    }

    private var symbol: String { metric == .hemoglobin ? unit.symbol : Ferritin.symbol }

    private var target: Double? {
        switch metric {
        case .hemoglobin: hbTarget > 0 ? unit.display(hbTarget) : nil
        case .ferritin: ferritinTarget > 0 ? ferritinTarget : nil
        }
    }

    private func format(_ value: Double) -> String {
        metric == .hemoglobin ? unit.format(unit.stored(value)) : Ferritin.format(value)
    }

    // MARK: - Pieces

    private var chartPanel: some View {
        Panel {
            VStack(alignment: .leading, spacing: Palette.Space.l) {
                if let latest = points.last {
                    HStack(alignment: .firstTextBaseline, spacing: Palette.Space.s) {
                        Text(format(latest.value))
                            .font(.system(size: 44, weight: .bold, design: .rounded))
                            .foregroundStyle(Palette.textPrimary)
                        Text(symbol)
                            .font(.headline)
                            .foregroundStyle(Palette.textSecondary)
                    }
                    HStack(spacing: Palette.Space.s) {
                        Text("Latest · \(latest.date, format: .dateTime.day().month(.abbreviated).year())")
                        if points.count >= 2 {
                            let previous = points[points.count - 2]
                            let delta = latest.value - previous.value
                            Text(verbatim: "·")
                            Text(verbatim: (delta >= 0 ? "+" : "−") + format(abs(delta)))
                                .monospacedDigit()
                        }
                    }
                    .font(.subheadline)
                    .foregroundStyle(Palette.textSecondary)
                }
                Chart {
                    ForEach(points) { point in
                        LineMark(x: .value("Date", point.date), y: .value("Value", point.value))
                            .interpolationMethod(.monotone)
                            .foregroundStyle(Palette.iron)
                        PointMark(x: .value("Date", point.date), y: .value("Value", point.value))
                            .foregroundStyle(Palette.iron)
                            .symbolSize(70)
                    }
                    if let target {
                        RuleMark(y: .value("Target", target))
                            .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                            .foregroundStyle(Palette.leaf)
                            .annotation(position: .top, alignment: .leading) {
                                Text("Doctor's target")
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(Palette.leaf)
                            }
                    }
                }
                .chartYScale(domain: .automatic(includesZero: false))
                .frame(height: 200)
                .accessibilityLabel(Text(metric.title))
            }
        }
    }

    private var emptyState: some View {
        Panel(padding: Palette.Space.xl) {
            VStack(alignment: .leading, spacing: Palette.Space.m) {
                Text("🩸").font(.largeTitle).accessibilityHidden(true)
                Text("No results yet")
                    .font(Palette.display(.title3))
                    .foregroundStyle(Palette.textPrimary)
                Text("Add the hemoglobin and ferritin numbers from your lab report to see how they change over time.")
                    .font(.subheadline)
                    .foregroundStyle(Palette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                Button("Add a result") { editorItem = EditorItem(result: nil) }
                    .buttonStyle(.filled)
                    .padding(.top, Palette.Space.s)
            }
        }
    }

    private var targetRow: some View {
        Button { showTarget = true } label: {
            HStack {
                Label("Your doctor's target", systemImage: "scope")
                    .foregroundStyle(Palette.textPrimary)
                Spacer()
                if let target {
                    Text(verbatim: "\(format(target)) \(symbol)")
                        .foregroundStyle(Palette.leaf)
                        .fontWeight(.semibold)
                } else {
                    Text("Not set").foregroundStyle(Palette.textSecondary)
                }
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Palette.textSecondary)
                    .accessibilityHidden(true)
            }
            .padding(Palette.Space.l)
            .background(Palette.surface, in: RoundedRectangle(cornerRadius: Palette.Radius.tile, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

/// Wrapper so `.sheet(item:)` can open the editor for a new or existing result.
struct EditorItem: Identifiable {
    let id = UUID()
    let result: LabResult?
}

private struct ResultRow: View {
    let result: LabResult
    let unit: HemoglobinUnit

    var body: some View {
        HStack(alignment: .center, spacing: Palette.Space.m) {
            VStack(alignment: .leading, spacing: 2) {
                Text(result.date, format: .dateTime.day().month(.abbreviated).year())
                    .font(.headline)
                    .foregroundStyle(Palette.textPrimary)
                if let note = result.note, !note.isEmpty {
                    Text(note)
                        .font(.footnote)
                        .foregroundStyle(Palette.textSecondary)
                        .lineLimit(1)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                if let hb = result.hemoglobin {
                    Text(verbatim: "Hb \(unit.format(hb)) \(unit.symbol)")
                }
                if let ferritin = result.ferritin {
                    Text(verbatim: "\(localized("Ferritin")) \(Ferritin.format(ferritin)) \(Ferritin.symbol)")
                }
            }
            .font(.subheadline.monospacedDigit())
            .foregroundStyle(Palette.textPrimary)
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Palette.textSecondary)
                .accessibilityHidden(true)
        }
        .padding(Palette.Space.l)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: Palette.Radius.tile, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

/// Plan the next blood test and get a reminder that morning.
private struct NextTestPanel: View {
    @Environment(\.modelContext) private var context
    @AppStorage(Prefs.nextTestDate) private var nextTestInterval: Double = 0
    @AppStorage(Prefs.testReminderOn) private var reminderOn = false
    @State private var permissionDenied = false

    private var planned: Binding<Bool> {
        Binding(get: { nextTestInterval > 0 }, set: { isOn in
            nextTestInterval = isOn ? (Calendar.current.date(byAdding: .month, value: 3, to: .now) ?? .now).timeIntervalSince1970 : 0
            if !isOn { reminderOn = false }
            resync()
        })
    }

    private var date: Binding<Date> {
        Binding(get: { Date(timeIntervalSince1970: nextTestInterval) },
                set: { nextTestInterval = $0.timeIntervalSince1970; resync() })
    }

    private var reminder: Binding<Bool> {
        Binding(get: { reminderOn }, set: { isOn in
            Task {
                reminderOn = isOn ? await Reminders.requestPermission() : false
                permissionDenied = isOn && !reminderOn
                await Reminders.sync(context)
            }
        })
    }

    var body: some View {
        Panel {
            VStack(alignment: .leading, spacing: Palette.Space.m) {
                Toggle(isOn: planned) {
                    Label("Plan my next blood test", systemImage: "calendar")
                        .font(.headline)
                }
                if nextTestInterval > 0 {
                    DatePicker("Date", selection: date, in: Calendar.current.startOfDay(for: .now)..., displayedComponents: .date)
                    Toggle("Remind me that morning", isOn: reminder)
                }
            }
        }
        .alert("Notifications are off", isPresented: $permissionDenied) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
            }
            Button("OK", role: .cancel) {}
        } message: {
            Text("Turn on notifications for Irovi in Settings to get reminders.")
        }
    }

    private func resync() {
        Task { await Reminders.sync(context) }
    }
}

/// A target the user's doctor gave them; shown as a line on the chart.
private struct TargetEditor: View {
    let metric: BloodMetric
    @Environment(\.dismiss) private var dismiss
    @AppStorage(Prefs.hbUnit) private var unitRaw = HemoglobinUnit.gPerDL.rawValue
    @AppStorage(Prefs.hbTarget) private var hbTarget: Double = 0
    @AppStorage(Prefs.ferritinTarget) private var ferritinTarget: Double = 0
    @State private var text = ""

    private var unit: HemoglobinUnit { HemoglobinUnit(rawValue: unitRaw) ?? .gPerDL }
    private var symbol: String { metric == .hemoglobin ? unit.symbol : Ferritin.symbol }
    private var range: ClosedRange<Double> { metric == .hemoglobin ? unit.entryRange : Ferritin.entryRange }
    private var value: Double? { NumberInput.parse(text) }
    private var isValid: Bool { value.map(range.contains) ?? false }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text(metric.title)
                        Spacer()
                        TextField(text: $text, prompt: Text(verbatim: "—")) { Text(metric.title) }
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                            .accessibilityLabel(Text(metric.title))
                        Text(verbatim: symbol).foregroundStyle(.secondary)
                    }
                } footer: {
                    Text("Only enter a target your doctor gave you. Irovi doesn't suggest targets.")
                }
                if currentStored > 0 {
                    Section {
                        Button("Remove target", role: .destructive) { save(nil) }
                    }
                }
            }
            .navigationTitle("Doctor's target")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save(value) }.disabled(!isValid)
                }
            }
            .onAppear {
                if currentStored > 0 {
                    text = metric == .hemoglobin ? unit.format(currentStored) : Ferritin.format(currentStored)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private var currentStored: Double { metric == .hemoglobin ? hbTarget : ferritinTarget }

    private func save(_ value: Double?) {
        switch metric {
        case .hemoglobin: hbTarget = value.map(unit.stored) ?? 0
        case .ferritin: ferritinTarget = value ?? 0
        }
        dismiss()
    }
}

/// Decimal input that accepts both "12.5" and "12,5".
enum NumberInput {
    static func parse(_ text: String) -> Double? {
        let cleaned = text.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: ".")
        guard !cleaned.isEmpty else { return nil }
        return Double(cleaned)
    }
}
