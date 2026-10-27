import XCTest

/// Walks the first-launch flow on a fresh install, switching the app to
/// Vietnamese on the language step, and attaches a screenshot of each step.
/// Only runs with ONBOARDING_SHOTS=1 (it changes the in-app language).
final class OnboardingFlowTests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
        try XCTSkipUnless(ProcessInfo.processInfo.environment["ONBOARDING_SHOTS"] == "1", "Manual check only")
    }

    func testFirstLaunchInVietnamese() {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()

        XCTAssertTrue(app.staticTexts["Choose your language"].waitForExistence(timeout: 6))
        shot("1-language-en")

        app.buttons["Tiếng Việt"].tap()
        XCTAssertTrue(app.staticTexts["Chọn ngôn ngữ"].waitForExistence(timeout: 5), "UI did not switch to Vietnamese")
        shot("2-language-vi")

        app.buttons["Tiếp tục"].tap()
        for page in 1...3 {
            XCTAssertTrue(app.buttons["Tiếp"].waitForExistence(timeout: 5))
            shot("3-intro-\(page)")
            app.buttons["Tiếp"].tap()
        }
        XCTAssertTrue(app.staticTexts["Mục tiêu mỗi ngày"].waitForExistence(timeout: 5))
        shot("4-goal")

        app.buttons["Bắt đầu"].tap()
        XCTAssertTrue(app.staticTexts["Bữa ăn đủ sắt hôm nay"].waitForExistence(timeout: 5))
        shot("5-home")

        // Text built in code (food names) follows the in-app language too.
        app.buttons["Ghi món ăn"].firstMatch.tap()
        XCTAssertTrue(app.buttons["Thịt đỏ & gan"].waitForExistence(timeout: 5), "Food names did not switch")
        shot("6-log")
    }

    private func shot(_ name: String) {
        sleep(1)
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
