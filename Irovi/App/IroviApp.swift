import SwiftData
import SwiftUI

@main
struct IroviApp: App {
    private let container = IroviApp.makeContainer()

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
    }

    /// On-device store. Falls back to memory so the app never fails to launch.
    static func makeContainer() -> ModelContainer {
        let schema = Schema([DayLog.self, LabResult.self, Medicine.self])
        // The store lives in Application Support, which doesn't exist on first launch.
        try? FileManager.default.createDirectory(at: .applicationSupportDirectory, withIntermediateDirectories: true)
        if let container = try? ModelContainer(for: schema) { return container }
        do {
            return try ModelContainer(for: schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        } catch {
            fatalError("Could not create the data store: \(error)")
        }
    }
}
