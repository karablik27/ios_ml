//
//  MortgageMLCalculatorTests.swift
//  MortgageMLCalculatorTests
//
//  Created by Stepan Karabelnikov on 24.02.2026.
//

import XCTest
@testable import MortgageMLCalculator

final class MortgageMLCalculatorTests: XCTestCase {

    func testValidationRejectsUnrealisticArea() {
        var input = MortgageInput.standard
        input.area = 5

        let result = MortgageCalculationEngine.validate(
            input: input,
            terms: MortgageTerms(downPayment: 20, loanTerm: 20, interestRate: 7.5)
        )

        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.message, "Площадь должна быть от 10 до 1000 м²")
    }

    func testMonthlyPaymentUsesAnnuityFormula() {
        let payment = MortgageCalculationEngine.calculateMonthlyPayment(
            price: 10_000_000,
            terms: MortgageTerms(downPayment: 20, loanTerm: 20, interestRate: 7.5)
        )

        XCTAssertEqual(payment, 64_474, accuracy: 500)
    }

    func testFallbackPriceHasMinimumValue() {
        var input = MortgageInput.standard
        input.area = 10
        input.rooms = 1
        input.distanceToCenter = 80
        input.buildYear = 1900
        input.renovationLevel = 0
        input.districtRating = 1

        let price = MortgageCalculationEngine.fallbackPrice(input: input)

        XCTAssertGreaterThanOrEqual(price, 1_000_000)
    }

    @MainActor
    func testHistoryPersistsInUserDefaults() {
        let suiteName = "MortgageMLCalculatorTests.history"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let store = CalculationHistoryStore(defaults: defaults, key: "history_test")
        let entry = CalculationHistoryEntry(
            input: .standard,
            terms: MortgageTerms(downPayment: 20, loanTerm: 20, interestRate: 7.5),
            price: 12_000_000,
            monthlyPayment: 76_000
        )

        store.add(entry)

        let restored = CalculationHistoryStore(defaults: defaults, key: "history_test")
        XCTAssertEqual(restored.entries.count, 1)
        XCTAssertEqual(restored.entries.first?.price, 12_000_000)

        defaults.removePersistentDomain(forName: suiteName)
    }
}
