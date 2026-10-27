import XCTest

/// Back works on every onboarding step, including the daily goal.
final class OnboardingBackTests: XCTestCase {
    func testBackFromGoalReturnsToLastIntroPage() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US", "-appLanguage", "en", "-IroviNoSplash", "YES"]
        app.launch()
        try XCTSkipUnless(app.buttons["Continue"].waitForExistence(timeout: 5), "Needs a fresh install")

        app.buttons["Continue"].tap()
        for _ in 1...3 { app.buttons["Next"].tap() }
        XCTAssertTrue(app.staticTexts["Your daily goal"].waitForExistence(timeout: 5))

        app.buttons["Back"].tap()
        XCTAssertTrue(app.staticTexts["Gentle reminders, fully private"].waitForExistence(timeout: 5))
        app.buttons["Back"].tap()
        XCTAssertTrue(app.staticTexts["Keep your blood results together"].waitForExistence(timeout: 5))
    }
}
