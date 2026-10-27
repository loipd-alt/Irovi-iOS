import CoreTransferable
import Foundation
import UniformTypeIdentifiers

/// A CSV of everything the user logged, shared through the system share sheet.
struct CSVExport: Transferable {
    let text: String

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .commaSeparatedText) { Data($0.text.utf8) }
            .suggestedFileName("irovi-export.csv")
    }
}

enum CSVBuilder {
    static func make(logs: [DayLog], labs: [LabResult], unit: HemoglobinUnit) -> String {
        var lines = ["section,date,items,hemoglobin_\(unit.symbol),ferritin_\(Ferritin.symbol),note"]
        for log in logs.sorted(by: { $0.date < $1.date }) {
            let items = (log.foods.map(\.rawValue).sorted() + log.habits.map(\.rawValue).sorted()).joined(separator: " ")
            lines.append(row(["checklist", log.dayKey, items, "", "", ""]))
        }
        for lab in labs.sorted(by: { $0.date < $1.date }) {
            lines.append(row([
                "blood_test",
                DayKey.make(lab.date),
                "",
                // Machine-readable numbers: always "." as the decimal separator,
                // whatever the phone's language (a "," would split the CSV column).
                lab.hemoglobin.map { String(format: unit == .gPerDL ? "%.1f" : "%.0f", unit.display($0)) } ?? "",
                lab.ferritin.map { String(format: "%.0f", $0) } ?? "",
                lab.note ?? "",
            ]))
        }
        return lines.joined(separator: "\n") + "\n"
    }

    private static func row(_ fields: [String]) -> String {
        fields.map { field in
            field.contains(where: { $0 == "," || $0 == "\"" || $0 == "\n" })
                ? "\"" + field.replacingOccurrences(of: "\"", with: "\"\"") + "\""
                : field
        }.joined(separator: ",")
    }
}
