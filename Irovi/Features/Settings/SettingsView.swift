import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var logs: [DayLog]
    @Query private var labs: [LabResult]
    @Query private var medicines: [Medicine]

    @AppStorage(Prefs.dailyGoal) private var goal = Prefs.defaultGoal
    @AppStorage(Prefs.hbUnit) private var unitRaw = HemoglobinUnit.gPerDL.rawValue
    @AppStorage(Prefs.foodReminderOn) private var foodReminderOn = false
    @AppStorage(Prefs.foodReminderMinutes) private var foodMinutes = Prefs.defaultFoodReminderMinutes

    @State private var permissionDenied = false
    @State private var confirmDelete = false

    private var unit: HemoglobinUnit { HemoglobinUnit(rawValue: unitRaw) ?? .gPerDL }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Stepper(value: $goal, in: 1...FoodGroup.allCases.count) {
                        HStack {
                            Text("Food groups per day")
                            Spacer()
                            Text(verbatim: "\(goal)").foregroundStyle(Palette.iron).fontWeight(.semibold)
                        }
                    }
                } header: {
                    Text("Daily goal")
                }

                Section {
                    Toggle("Iron-rich food reminder", isOn: foodReminder)
                    if foodReminderOn {
                        DatePicker("Time", selection: foodTime, displayedComponents: .hourAndMinute)
                    }
                    NavigationLink {
                        MedicinesView()
                    } label: {
                        HStack {
                            Text("My medicines")
                            Spacer()
                            Text(verbatim: "\(medicines.filter(\.isActive).count)").foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Reminders")
                } footer: {
                    Text("The next blood test reminder is on the Blood tab.")
                }

                Section("Units") {
                    Picker("Hemoglobin", selection: $unitRaw) {
                        ForEach(HemoglobinUnit.allCases) { Text(verbatim: $0.symbol).tag($0.rawValue) }
                    }
                }

                Section {
                    Button("Language") {
                        if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
                    }
                } footer: {
                    Text("Irovi follows your iPhone's language. You can pick a different one for Irovi in the Settings app.")
                }

                Section {
                    ShareLink(item: CSVExport(text: CSVBuilder.make(logs: logs, labs: labs, unit: unit)),
                              preview: SharePreview("Irovi data")) {
                        Label("Export my data (CSV)", systemImage: "square.and.arrow.up")
                    }
                    Button("Delete all data", role: .destructive) { confirmDelete = true }
                } header: {
                    Text("Your data")
                } footer: {
                    Text("Everything stays on this iPhone. There is no account and nothing is uploaded.")
                }

                Section("About") {
                    NavigationLink("Privacy") { PrivacyView() }
                    NavigationLink("Health information") { HealthNoteView() }
                    LabeledContent("Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
            .onChange(of: foodMinutes) { _, _ in resync() }
            .onChange(of: goal) { _, _ in WidgetSync.refresh(context) }
            .alert("Notifications are off", isPresented: $permissionDenied) {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
                }
                Button("OK", role: .cancel) {}
            } message: {
                Text("Turn on notifications for Irovi in Settings to get reminders.")
            }
            .confirmationDialog("Delete all data?", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("Delete everything", role: .destructive, action: deleteAll)
            } message: {
                Text("Your checklist, blood results and medicines will be removed from this iPhone. This can't be undone.")
            }
        }
    }

    private var foodReminder: Binding<Bool> {
        Binding(get: { foodReminderOn }, set: { isOn in
            Task {
                foodReminderOn = isOn ? await Reminders.requestPermission() : false
                permissionDenied = isOn && !foodReminderOn
                await Reminders.sync(context)
            }
        })
    }

    private var foodTime: Binding<Date> {
        Binding(get: { .todayAt(minutes: foodMinutes) }, set: { foodMinutes = $0.minutesAfterMidnight })
    }

    private func resync() {
        Task { await Reminders.sync(context) }
    }

    private func deleteAll() {
        try? context.delete(model: DayLog.self)
        try? context.delete(model: LabResult.self)
        try? context.delete(model: Medicine.self)
        try? context.save()
        let defaults = UserDefaults.standard
        for key in [Prefs.nextTestDate, Prefs.testReminderOn, Prefs.hbTarget, Prefs.ferritinTarget, Prefs.foodReminderOn] {
            defaults.removeObject(forKey: key)
        }
        resync()
        WidgetSync.refresh(context)
    }
}

struct PrivacyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Palette.Space.l) {
                Text("Your privacy")
                    .font(Palette.display(.title2))
                Text("Everything you enter in Irovi (your checklist, blood test results and medicines) is stored only on this iPhone.")
                Text("Irovi has no account, no servers, no ads, no analytics and no tracking. Nothing you enter is uploaded or shared.")
                Text("Reminders are local notifications created on your iPhone. You can export your data as a CSV file or delete it all in Settings.")
            }
            .foregroundStyle(Palette.textPrimary)
            .padding(Palette.Space.gutter)
        }
        .background(Palette.background)
        .navigationTitle("Privacy")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct HealthNoteView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Palette.Space.l) {
                Text("Health information")
                    .font(Palette.display(.title2))
                Text("Irovi is a wellness diary. It is not a medical device and does not diagnose, treat or prevent any condition.")
                Text("Irovi does not recommend medicines, supplements or doses. Medicines you add are only used for your own reminders.")
                Text("Nutrition information in Irovi is general and comes from public sources such as the US National Institutes of Health and the World Health Organization.")
                Text("Always talk to a doctor or pharmacist about your blood test results, symptoms and any treatment.")
            }
            .foregroundStyle(Palette.textPrimary)
            .padding(Palette.Space.gutter)
        }
        .background(Palette.background)
        .navigationTitle("Health information")
        .navigationBarTitleDisplayMode(.inline)
    }
}
