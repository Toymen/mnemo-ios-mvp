import XCTest

final class CaptureApprovalFlowUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testCaptureTabExists() throws {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.tabBars.firstMatch.buttons["Capture"].exists)
    }

    func testReviewTabExists() throws {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.tabBars.firstMatch.buttons["Review"].exists)
    }

    func testMemoriesTabExists() throws {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.tabBars.firstMatch.buttons["Memories"].exists)
    }

    func testSubmitCaptureButtonVisible() throws {
        let app = XCUIApplication()
        app.launch()
        app.tabBars.firstMatch.buttons["Capture"].tap()

        let textEditor = app.textViews.firstMatch
        textEditor.tap()
        textEditor.typeText("I learned that testing is important.")

        let saveButton = app.buttons["Save & Extract"]
        XCTAssertTrue(saveButton.exists)
        XCTAssertTrue(saveButton.isEnabled)
    }
}
