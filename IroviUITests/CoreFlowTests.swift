import XCTest

/// Walks the main flows a reviewer would try, to catch crashes before submitting.
final class CoreFlowTests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testMainFlows() {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()

        // Welcome (only on first launch of this install).
        if app.buttons["Continue"].waitForExistence(timeout: 3) {
            app.buttons["Continue"].tap()
            app.buttons["Start"].tap()
        }

        // Today: tick a food group. (The app reopens the last tab, so pick Today first.)
        app.tabBars.buttons["Today"].tap()
        let tile = app.buttons["Shellfish & fish"]
        XCTAssertTrue(tile.waitForExistence(timeout: 5))
        tile.tap()

        // Blood: add a result and see it listed.
        app.tabBars.buttons["Blood"].tap()
        XCTAssertTrue(app.navigationBars["Blood"].waitForExistence(timeout: 5))
        sleep(1) // a tap during the tab transition can be dropped
        app.navigationBars["Blood"].buttons["Add a result"].tap()
        let hb = app.textFields["hemoglobinField"]
        XCTAssertTrue(hb.waitForExistence(timeout: 5))
        hb.tap()
        hb.typeText("11.5")
        app.buttons["Save"].tap()
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label CONTAINS 'Hb 11.5 g/dL'")).firstMatch.waitForExistence(timeout: 5))

        // Learn: open an article.
        app.tabBars.buttons["Learn"].tap()
        app.buttons.matching(NSPredicate(format: "label CONTAINS 'Vitamin C helps plant iron'")).firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Sources"].waitForExistence(timeout: 5))

        // Settings opens and closes.
        app.tabBars.buttons["Today"].tap()
        app.buttons["Settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))
        app.buttons["Done"].tap()
    }
}
