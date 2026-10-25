import XCTest

final class iOS_FakeNFT_ExtendedUITests: XCTestCase {
    func testWebsitePushesAndReturnsWithoutChangingProfile() {
        let app = XCUIApplication()
        app.launch()

        let website = app.buttons["profile.website"]
        XCTAssertTrue(website.waitForExistence(timeout: 5))
        XCTAssertEqual(website.label, "https://example.com")
        website.tap()
        XCTAssertTrue(app.webViews.firstMatch.waitForExistence(timeout: 5))
        XCTAssertFalse(app.tabBars.firstMatch.exists)
        let back = app.navigationBars.buttons["profile.website.back"]
        XCTAssertTrue(back.exists)
        back.tap()

        XCTAssertTrue(website.waitForExistence(timeout: 5))
        XCTAssertEqual(website.label, "https://example.com")
        XCTAssertTrue(app.staticTexts["Joaquin Phoenix"].exists)
        XCTAssertTrue(app.buttons["profile.edit"].exists)
        XCTAssertTrue(app.tabBars.buttons["Профиль"].isSelected)
    }

    func testProfileTabAndEditingNavigation() throws {
        let app = XCUIApplication()
        app.launch()

        let tabs = app.tabBars
        XCTAssertTrue(tabs.buttons["Профиль"].isSelected)
        XCTAssertTrue(app.buttons["profile.edit"].waitForExistence(timeout: 5))

        tabs.buttons["Каталог"].tap()
        XCTAssertTrue(app.buttons["Открыть Nft"].exists)
        tabs.buttons["Профиль"].tap()

        app.buttons["profile.edit"].tap()
        XCTAssertTrue(app.textFields["profile.edit.name"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.textFields["profile.edit.name"].value as? String, "Joaquin Phoenix")
        app.buttons["profile.edit.cancel"].tap()
        XCTAssertTrue(app.buttons["profile.edit"].waitForExistence(timeout: 5))
        XCTAssertTrue(tabs.buttons["Профиль"].isSelected)
    }
}
