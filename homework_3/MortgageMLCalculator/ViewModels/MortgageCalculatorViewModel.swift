//
//  MortgageCalculatorViewModel.swift
//  MortgageMLCalculator
//
//  Created by Stepan Karabelnikov on 29.05.2026.
//

import Combine
import Foundation

@MainActor
final class MortgageCalculatorViewModel: ObservableObject {
    @Published var input: MortgageInput
    @Published var terms: MortgageTerms
    @Published private(set) var calculation: MortgageCalculation?
    @Published private(set) var isCalculating = false
    @Published private(set) var errorMessage: String?

    let historyStore: CalculationHistoryStore

    private var calculationWorkItem: DispatchWorkItem?

    init(
        input: MortgageInput = .standard,
        terms: MortgageTerms = MortgageTerms(downPayment: 20, loanTerm: 20, interestRate: 7.5),
        historyStore: CalculationHistoryStore = CalculationHistoryStore()
    ) {
        self.input = input
        self.terms = terms
        self.historyStore = historyStore
    }

    func debouncedCalculate() {
        calculationWorkItem?.cancel()

        let workItem = DispatchWorkItem { [weak self] in
            Task { @MainActor in
                self?.calculateFull()
            }
        }

        calculationWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: workItem)
    }

    func calculateFull(saveToHistory: Bool = true) {
        let validation = MortgageCalculationEngine.validate(input: input, terms: terms)
        guard validation.isValid else {
            errorMessage = validation.message
            calculation = nil
            isCalculating = false
            return
        }

        errorMessage = nil
        isCalculating = true

        let currentInput = input
        let currentTerms = terms

        DispatchQueue.global(qos: .userInitiated).async {
            let output = MortgageCalculationEngine.calculate(input: currentInput, terms: currentTerms)

            DispatchQueue.main.async { [weak self] in
                Task { @MainActor in
                guard let self else { return }

                self.calculation = output
                self.isCalculating = false

                if saveToHistory {
                    self.historyStore.add(
                        CalculationHistoryEntry(
                            input: currentInput,
                            terms: currentTerms,
                            price: output.price,
                            monthlyPayment: output.monthlyPayment
                        )
                    )
                }
                }
            }
        }
    }

    func recalculateMortgageOnly() {
        guard let calculation else {
            debouncedCalculate()
            return
        }

        let monthlyPayment = MortgageCalculationEngine.calculateMonthlyPayment(
            price: calculation.price,
            terms: terms
        )
        let creditAmount = calculation.price * (100 - terms.downPayment) / 100
        let totalPayment = monthlyPayment * terms.loanTerm * 12

        let updatedCalculation = MortgageCalculation(
            price: calculation.price,
            monthlyPayment: monthlyPayment,
            creditAmount: creditAmount,
            totalPayment: totalPayment,
            overpayment: totalPayment - creditAmount
        )

        self.calculation = updatedCalculation
        saveCurrentCalculation(updatedCalculation)
    }

    func saveCurrentCalculation() {
        guard let calculation else { return }
        saveCurrentCalculation(calculation)
    }

    func applyHistory(_ entry: CalculationHistoryEntry) {
        input = entry.input
        terms = entry.terms.mortgageTerms
        calculation = MortgageCalculationEngine.calculate(input: entry.input, terms: entry.terms.mortgageTerms)
        errorMessage = nil
    }

    private func saveCurrentCalculation(_ calculation: MortgageCalculation) {
        historyStore.add(
            CalculationHistoryEntry(
                input: input,
                terms: terms,
                price: calculation.price,
                monthlyPayment: calculation.monthlyPayment
            )
        )
    }
}
