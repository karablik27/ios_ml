//
//  MortgageMLCalculatorUITests.swift
//  MortgageMLCalculatorUITests
//
//  Created by Stepan Karabelnikov on 24.02.2026.
//

import XCTest

final class MortgageMLCalculatorUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testCalculatorScreenLaunches() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.navigationBars["Ипотечный калькулятор"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.tabBars.buttons["Расчет"].exists)
        XCTAssertTrue(app.tabBars.buttons["Сравнение"].exists)
        XCTAssertTrue(app.tabBars.buttons["История"].exists)
    }
}
