import SwiftData
import SwiftUI

/// Add or edit one blood test result. Either number may be left empty.
/// Ranges only catch typos; they are not medical ranges.
struct LabResultEditor: View {
    let existing: LabResult?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var date: Date
    @State private var hbText: String
    @State private var ferritinText: String
    @State private var note: String
    @State private var confirmDelete = false

    private let unit: HemoglobinUnit

    init(existing: LabResult?) {
        self.existing = existing
        let unit = HemoglobinUnit(rawValue: UserDefaults.standard.string(forKey: Prefs.hbUnit) ?? "") ?? .gPerDL
        self.unit = unit
        _date = State(initialValue: existing?.date ?? .now)
        _hbText = State(initialValue: existing?.hemoglobin.map { unit.format($0) } ?? "")
        _ferritinText = State(initialValue: existing?.ferritin.map(Ferritin.format) ?? "")
        _note = State(initialValue: existing?.note ?? "")
    }

    private var hb: Double? { NumberInput.parse(hbText) }
    private var ferritin: Double? { NumberInput.parse(ferritinText) }
    private var hbError: Bool { !hbText.isEmpty && !(hb.map(unit.entryRange.contains) ?? false) }
    private var ferritinError: Bool { !ferritinText.isEmpty && !(ferritin.map(Ferritin.entryRange.contains) ?? false) }
    private var canSave: Bool { (hb != nil || ferritin != nil) && !hbError && !ferritinError }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("Test date", selection: $date, in: ...Date.now, displayedComponents: .date)
                }
                Section {
                    valueRow("Hemoglobin", text: $hbText, symbol: unit.symbol, isError: hbError, identifier: "hemoglobinField")
                    valueRow("Ferritin", text: $ferritinText, symbol: Ferritin.symbol, isError: ferritinError, identifier: "ferritinField")
                } header: {
                    Text("Results")
                } footer: {
                    Text("Copy the numbers from your lab report. Leave a field empty if it wasn't tested.")
                }
                Section("Note") {
                    TextField("Optional, e.g. lab name", text: $note, axis: .vertical)
                        .lineLimit(1...3)
                }
                if existing != nil {
                    Section {
                        Button("Delete result", role: .destructive) { confirmDelete = true }
                    }
                }
            }
            .navigationTitle(existing == nil ? "New result" : "Edit result")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save", action: save).disabled(!canSave) }
            }
            .confirmationDialog("Delete this result?", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    if let existing { context.delete(existing) }
                    try? context.save()
                    dismiss()
                }
            }
        }
    }

    private func valueRow(_ title: LocalizedStringKey, text: Binding<String>, symbol: String, isError: Bool,
                          identifier: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                Spacer()
                TextField(text: text, prompt: Text(verbatim: "—")) { Text(title) }
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 100)
                    .accessibilityLabel(Text(title))
                    .accessibilityValue(Text(verbatim: text.wrappedValue.isEmpty ? "" : "\(text.wrappedValue) \(symbol)"))
                    .accessibilityIdentifier(identifier)
                Text(verbatim: symbol)
                    .foregroundStyle(.secondary)
                    .frame(width: 56, alignment: .leading)
            }
            if isError {
                Text("Check this number")
                    .font(.footnote)
                    .foregroundStyle(Palette.iron)
            }
        }
    }

    private func save() {
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let storedHb = hb.map(unit.stored)
        if let existing {
            existing.date = date
            existing.hemoglobin = storedHb
            existing.ferritin = ferritin
            existing.note = trimmedNote.isEmpty ? nil : trimmedNote
        } else {
            context.insert(LabResult(date: date, hemoglobin: storedHb, ferritin: ferritin,
                                     note: trimmedNote.isEmpty ? nil : trimmedNote))
        }
        try? context.save()
        dismiss()
    }
}
