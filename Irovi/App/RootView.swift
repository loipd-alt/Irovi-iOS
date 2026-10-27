import SwiftData
import SwiftUI

enum AppTab: String {
    case today, blood, learn
}

/// Onboarding gate, then the three tabs.
struct RootView: View {
    @Environment(\.modelContext) private var context
    @AppStorage(Prefs.onboarded) private var onboarded = false
    @AppStorage(Prefs.selectedTab) private var tab = AppTab.today.rawValue

    var body: some View {
        Group {
            if onboarded {
                TabView(selection: $tab) {
                    TodayView()
                        .tabItem { Label("Today", systemImage: "sun.max") }
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
        .task {
            #if DEBUG
            DemoData.seedIfRequested(context)
            #endif
        }
    }
}
