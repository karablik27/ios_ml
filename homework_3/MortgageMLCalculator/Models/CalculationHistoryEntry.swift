//
//  CalculationHistoryEntry.swift
//  MortgageMLCalculator
//
//  Created by Stepan Karabelnikov on 29.05.2026.
//

import Foundation

struct CalculationHistoryEntry: Codable, Identifiable, Equatable {
    let id: UUID
    let date: Date
    let input: MortgageInput
    let terms: MortgageTermsSnapshot
    let price: Double
    let monthlyPayment: Double

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        input: MortgageInput,
        terms: MortgageTerms,
        price: Double,
        monthlyPayment: Double
    ) {
        self.id = id
        self.date = date
        self.input = input
        self.terms = MortgageTermsSnapshot(terms: terms)
        self.price = price
        self.monthlyPayment = monthlyPayment
    }
}

struct MortgageTermsSnapshot: Codable, Equatable {
    let downPayment: Double
    let loanTerm: Double
    let interestRate: Double

    init(terms: MortgageTerms) {
        downPayment = terms.downPayment
        loanTerm = terms.loanTerm
        interestRate = terms.interestRate
    }

    var mortgageTerms: MortgageTerms {
        MortgageTerms(
            downPayment: downPayment,
            loanTerm: loanTerm,
            interestRate: interestRate
        )
    }
}
