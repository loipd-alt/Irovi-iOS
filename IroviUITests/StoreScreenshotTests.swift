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
        capture("1-home", launch(tab: "today"))

        let home = launch(tab: "today")
        home.buttons["Log food"].firstMatch.tap()
        _ = home.buttons["Shellfish & fish"].waitForExistence(timeout: 5)
        capture("2-log", home)

        capture("3-blood", launch(tab: "blood"))

        let history = launch(tab: "today")
        history.buttons["History"].firstMatch.tap()
        _ = history.navigationBars["History"].waitForExistence(timeout: 5)
        capture("4-history", history)

        capture("5-learn", launch(tab: "learn"))
        capture("6-welcome", launch(tab: "today", onboarded: false))
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
