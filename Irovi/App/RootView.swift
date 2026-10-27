import SwiftData
import SwiftUI

enum AppTab: String {
    case today, blood, learn
}

/// Splash, then onboarding (first launch) or the three tabs. The UI is rebuilt
/// when the in-app language changes, so every string follows at once.
struct RootView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage(Prefs.onboarded) private var onboarded = false
    @AppStorage(Prefs.selectedTab) private var tab = AppTab.today.rawValue
    @AppStorage(AppLanguage.key, store: AppLanguage.store) private var languageRaw = AppLanguage.system.rawValue
    @State private var router = AppRouter()
    /// UI tests launch with `-IroviNoSplash YES` so the splash never covers a tap.
    @State private var showSplash = !UserDefaults.standard.bool(forKey: "IroviNoSplash")

    private var language: AppLanguage { AppLanguage(rawValue: languageRaw) ?? .system }

    var body: some View {
        ZStack {
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
            .id(languageRaw)

            if showSplash {
                SplashView()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .environment(\.locale, language.locale)
        .tint(Palette.iron)
        .environment(router)
        .onOpenURL { url in
            if router.handle(url) { tab = AppTab.today.rawValue }
        }
        .onChange(of: scenePhase) { _, phase in
            // Keeps the widget right after midnight and when leaving the app.
            if phase != .inactive { WidgetSync.refresh(context) }
        }
        .onChange(of: languageRaw) { _, _ in
            // Notification texts and the widget follow the new language.
            Task { await Reminders.sync(context) }
            WidgetSync.reloadWidget()
        }
        .task {
            #if DEBUG
            DemoData.seedIfRequested(context)
            #endif
            WidgetSync.refresh(context)
            try? await Task.sleep(for: .seconds(1.1))
            withAnimation(.easeOut(duration: 0.35)) { showSplash = false }
        }
    }
}
