//
//  MortgageTerms.swift
//  MortgageMLCalculator
//
//  Created by Stepan Karabelnikov on 25.02.2026.
//

import Foundation

struct MortgageTerms: Codable, Equatable {
    var downPayment: Double
    var loanTerm: Double
    var interestRate: Double
}
