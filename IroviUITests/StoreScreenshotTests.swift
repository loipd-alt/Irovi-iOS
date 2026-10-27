import XCTest

/// Captures the raw App Store screens with the DEBUG demo data. Run through
/// `scripts/store_screenshots.sh`; skipped in normal test runs.
final class StoreScreenshotTests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
        try XCTSkipUnless(ProcessInfo.processInfo.environment["STORE_SCREENSHOTS"] == "1",
                          "Only runs from scripts/store_screenshots.sh")
    }

    func testCaptureStoreScreens() {
        capture("1-today", launch(tab: "today"))
        capture("2-blood", launch(tab: "blood"))

        let today = launch(tab: "today")
        today.swipeUp()
        capture("3-absorb", today)

        capture("4-learn", launch(tab: "learn"))
        capture("5-welcome", launch(tab: "today", onboarded: false))
    }

    private func launch(tab: String, onboarded: Bool = true) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "-onboarded", onboarded ? "YES" : "NO", "-IroviDemoData", "YES", "-selectedTab", tab,
            "-AppleLanguages", "(en)", "-AppleLocale", "en_US",
        ]
        app.launch()
        return app
    }

    private func capture(_ name: String, _ app: XCUIApplication) {
        sleep(2) // let the ring, chart and shadows settle
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = "en-\(name)"
        shot.lifetime = .keepAlways
        add(shot)
    }
}
