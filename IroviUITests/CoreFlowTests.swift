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

        // Home → Log food: tick a food group. (The app reopens the last tab, so pick Home first.)
        app.tabBars.buttons["Home"].tap()
        app.buttons["Log food"].firstMatch.tap()
        let tile = app.buttons["Shellfish & fish"]
        XCTAssertTrue(tile.waitForExistence(timeout: 5))
        tile.tap()
        app.buttons["Done"].tap()

        // History opens from the week card.
        app.buttons["History"].firstMatch.tap()
        XCTAssertTrue(app.navigationBars["History"].waitForExistence(timeout: 5))
        app.navigationBars["History"].buttons.firstMatch.tap()

        // The + button → "Blood test result" → type a value → Save.
        app.buttons["Add"].tap()
        let option = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Blood test result'")).firstMatch
        XCTAssertTrue(option.waitForExistence(timeout: 5))
        option.tap()
        let hb = app.textFields["hemoglobinField"]
        XCTAssertTrue(hb.waitForExistence(timeout: 5))
        hb.tap()
        hb.typeText("11.5")
        app.buttons["Save"].tap()

        // The Blood tab lists it.
        app.tabBars.buttons["Blood"].tap()
        XCTAssertTrue(app.navigationBars["Blood"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label CONTAINS 'Hb 11.5 g/dL'")).firstMatch.waitForExistence(timeout: 5))

        // Learn: open an article.
        app.tabBars.buttons["Learn"].tap()
        app.buttons.matching(NSPredicate(format: "label CONTAINS 'Vitamin C helps plant iron'")).firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Sources"].waitForExistence(timeout: 5))

        // Settings opens and closes.
        app.tabBars.buttons["Home"].tap()
        app.buttons["Settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))
        app.buttons["Done"].tap()
    }
}
