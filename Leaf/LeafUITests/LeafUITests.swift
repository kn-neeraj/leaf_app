import XCTest

final class LeafUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testMainWindowAppearsOnLaunch() throws {
        let app = XCUIApplication()
        app.launchArguments.append("--ui-testing")
        app.launch()

        XCTAssertTrue(app.windows.firstMatch.waitForExistence(timeout: 5))
    }

    @MainActor
    func testSidebarAndPreviewExistInAccessibilityTree() throws {
        let app = XCUIApplication()
        app.launchArguments.append("--ui-testing")
        app.launch()

        XCTAssertTrue(app.descendants(matching: .any)["sidebar"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.descendants(matching: .any)["preview"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testFixtureLoadsIntoReader() throws {
        let app = XCUIApplication()
        app.launchArguments.append("--ui-testing")
        app.launchEnvironment["LEAF_UI_TEST_FILE_NAME"] = "leaf-ui-test.md"
        app.launchEnvironment["LEAF_UI_TEST_FILE_CONTENTS"] = """
        # Fixture Heading

        This fixture is used by Leaf UI tests.
        """
        app.launch()

        XCTAssertTrue(app.staticTexts["leaf-ui-test.md"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.descendants(matching: .any)["emptyStateHero"].exists)
        XCTAssertFalse(app.staticTexts["Unable to open file."].exists)
    }

    @MainActor
    func testCopyModeToggleButtonChangesState() throws {
        let app = XCUIApplication()
        app.launchArguments.append("--ui-testing")
        app.launch()

        let toggle = app.buttons.matching(identifier: "copyModeToggle").firstMatch
        XCTAssertTrue(toggle.waitForExistence(timeout: 5))
        XCTAssertEqual(toggle.value as? String, "off")

        toggle.click()
        XCTAssertEqual(toggle.value as? String, "on")

        toggle.click()
        XCTAssertEqual(toggle.value as? String, "off")
    }

    @MainActor
    func testEmptyStateOpenButtonAppearsOnLaunch() throws {
        let app = XCUIApplication()
        app.launchArguments.append("--ui-testing")
        app.launch()

        XCTAssertTrue(app.buttons["emptyStateOpenButton"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Reading stack"].exists)
    }
}
