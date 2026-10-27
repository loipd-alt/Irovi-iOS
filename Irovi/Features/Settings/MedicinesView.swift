import SwiftData
import SwiftUI

/// Medicines the user adds for their own reminders and daily tick.
/// Irovi never suggests a medicine or a dose.
struct MedicinesView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Medicine.createdAt) private var medicines: [Medicine]
    @State private var editing: MedicineEditorItem?

    var body: some View {
        List {
            Section {
                ForEach(medicines) { medicine in
                    Button { editing = MedicineEditorItem(medicine: medicine) } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(medicine.name)
                                    .foregroundStyle(Palette.textPrimary)
                                Text(medicine.reminderMinutes.map(\.clockText).joined(separator: " · "))
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if !medicine.isActive {
                                Text("Paused").font(.footnote).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .onDelete { offsets in
                    offsets.map { medicines[$0] }.forEach(context.delete)
                    try? context.save()
                    Task { await Reminders.sync(context) }
                }
            } footer: {
                Text("Add only medicines a doctor or pharmacist told you to take. Irovi reminds you at the times you choose; it doesn't suggest medicines or doses.")
            }
        }
        .overlay {
            if medicines.isEmpty {
                ContentUnavailableView("No medicines", systemImage: "pills",
                                       description: Text("Add a medicine to get a reminder and tick it off each day."))
            }
        }
        .navigationTitle("My medicines")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { editing = MedicineEditorItem(medicine: nil) } label: { Image(systemName: "plus") }
                    .accessibilityLabel("Add a medicine")
            }
        }
        .sheet(item: $editing) { MedicineEditor(existing: $0.medicine) }
    }
}

struct MedicineEditorItem: Identifiable {
    let id = UUID()
    let medicine: Medicine?
}

private struct MedicineEditor: View {
    let existing: Medicine?
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var times: [Date]
    @State private var isActive: Bool
    @State private var permissionDenied = false

    init(existing: Medicine?) {
        self.existing = existing
        _name = State(initialValue: existing?.name ?? "")
        _times = State(initialValue: (existing?.reminderMinutes ?? [8 * 60]).map(Date.todayAt(minutes:)))
        _isActive = State(initialValue: existing?.isActive ?? true)
    }

    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name, as on the package", text: $name)
                        .textInputAutocapitalization(.sentences)
                }
                Section {
                    ForEach(times.indices, id: \.self) { index in
                        DatePicker("Reminder \(index + 1)", selection: $times[index], displayedComponents: .hourAndMinute)
                    }
                    .onDelete { times.remove(atOffsets: $0) }
                    if times.count < 4 {
                        Button("Add a time") { times.append(.todayAt(minutes: 20 * 60)) }
                    }
                } header: {
                    Text("Reminder times")
                }
                Section {
                    Toggle("Reminders on", isOn: $isActive)
                }
                if existing != nil {
                    Section {
                        Button("Delete medicine", role: .destructive) {
                            if let existing { context.delete(existing) }
                            try? context.save()
                            Task { await Reminders.sync(context) }
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle(existing == nil ? "New medicine" : "Edit medicine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save).disabled(trimmedName.isEmpty || times.isEmpty)
                }
            }
            .alert("Notifications are off", isPresented: $permissionDenied) {
                Button("OK") { dismiss() }
            } message: {
                Text("The medicine is saved. Turn on notifications for Irovi in Settings to get reminders.")
            }
        }
    }

    private func save() {
        let minutes = Array(Set(times.map(\.minutesAfterMidnight))).sorted()
        if let existing {
            existing.name = trimmedName
            existing.reminderMinutes = minutes
            existing.isActive = isActive
        } else {
            let medicine = Medicine(name: trimmedName, reminderMinutes: minutes)
            medicine.isActive = isActive
            context.insert(medicine)
        }
        try? context.save()
        Task {
            let allowed = isActive ? await Reminders.requestPermission() : true
            await Reminders.sync(context)
            if allowed { dismiss() } else { permissionDenied = true }
        }
    }
}
