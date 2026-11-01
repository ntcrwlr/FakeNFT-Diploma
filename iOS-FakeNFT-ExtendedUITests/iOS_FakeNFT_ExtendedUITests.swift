import XCTest

final class iOS_FakeNFT_ExtendedUITests: XCTestCase {
    func testFavoritesNavigationPreservesProfileAndSupportsBackGesture() {
        let app = XCUIApplication()
        app.launch()

        let favorites = app.buttons["profile.favorites"]
        XCTAssertTrue(favorites.waitForExistence(timeout: 5))
        let initialLabel = favorites.label
        favorites.tap()

        let navigationBar = app.navigationBars["Избранные NFT"]
        XCTAssertTrue(navigationBar.waitForExistence(timeout: 5))
        XCTAssertFalse(app.tabBars.firstMatch.exists)
        navigationBar.buttons.firstMatch.tap()

        XCTAssertTrue(favorites.waitForExistence(timeout: 5))
        XCTAssertEqual(favorites.label, initialLabel)
        XCTAssertTrue(app.staticTexts["Joaquin Phoenix"].exists)
        XCTAssertTrue(app.tabBars.buttons["Профиль"].isSelected)
        favorites.tap()
        XCTAssertTrue(navigationBar.waitForExistence(timeout: 5))

        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.01, dy: 0.5))
        let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5))
        start.press(forDuration: 0.1, thenDragTo: end)

        XCTAssertTrue(favorites.waitForExistence(timeout: 5))
        XCTAssertEqual(favorites.label, initialLabel)
        XCTAssertTrue(app.staticTexts["Joaquin Phoenix"].exists)
        XCTAssertTrue(app.buttons["profile.edit"].exists)
        XCTAssertTrue(app.tabBars.buttons["Профиль"].isSelected)
        favorites.tap()
        XCTAssertTrue(navigationBar.waitForExistence(timeout: 5))
    }

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
