//
//  MortgageInput.swift
//  MortgageMLCalculator
//
//  Created by Stepan Karabelnikov on 29.05.2026.
//

import Foundation

struct MortgageInput: Codable, Equatable {
    var area: Double
    var rooms: Int
    var bathrooms: Int
    var garageSpaces: Int
    var distanceToCenter: Double
    var floor: Int
    var buildYear: Int
    var balcony: Int
    var renovationLevel: Int
    var hasElevator: Bool
    var ceilingHeight: Double
    var districtRating: Int

    static let standard = MortgageInput(
        area: 70,
        rooms: 3,
        bathrooms: 1,
        garageSpaces: 1,
        distanceToCenter: 8,
        floor: 7,
        buildYear: 2015,
        balcony: 1,
        renovationLevel: 2,
        hasElevator: true,
        ceilingHeight: 2.7,
        districtRating: 7
    )

    static let premium = MortgageInput(
        area: 120,
        rooms: 4,
        bathrooms: 2,
        garageSpaces: 2,
        distanceToCenter: 3,
        floor: 12,
        buildYear: 2022,
        balcony: 2,
        renovationLevel: 4,
        hasElevator: true,
        ceilingHeight: 3.1,
        districtRating: 9
    )
}

struct MortgageCalculation: Equatable {
    let price: Double
    let monthlyPayment: Double
    let creditAmount: Double
    let totalPayment: Double
    let overpayment: Double
}

struct ValidationResult: Equatable {
    let isValid: Bool
    let message: String?

    static let valid = ValidationResult(isValid: true, message: nil)
}
