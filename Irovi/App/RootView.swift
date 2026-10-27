import SwiftData
import SwiftUI

enum AppTab: String {
    case today, blood, learn
}

/// Onboarding gate, then the three tabs.
struct RootView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage(Prefs.onboarded) private var onboarded = false
    @AppStorage(Prefs.selectedTab) private var tab = AppTab.today.rawValue
    @State private var router = AppRouter()

    var body: some View {
        Group {
            if onboarded {
                TabView(selection: $tab) {
                    HomeView()
                        .tabItem { Label("Home", systemImage: "house") }
                        .tag(AppTab.today.rawValue)
                    BloodView()
                        .tabItem { Label("Blood", systemImage: "drop") }
                        .tag(AppTab.blood.rawValue)
                    LearnView()
                        .tabItem { Label("Learn", systemImage: "book") }
                        .tag(AppTab.learn.rawValue)
                }
            } else {
                OnboardingView()
            }
        }
        .tint(Palette.iron)
        .environment(router)
        .onOpenURL { url in
            if router.handle(url) { tab = AppTab.today.rawValue }
        }
        .onChange(of: scenePhase) { _, phase in
            // Keeps the widget right after midnight and when leaving the app.
            if phase != .inactive { WidgetSync.refresh(context) }
        }
        .task {
            #if DEBUG
            DemoData.seedIfRequested(context)
            #endif
            WidgetSync.refresh(context)
        }
    }
}
