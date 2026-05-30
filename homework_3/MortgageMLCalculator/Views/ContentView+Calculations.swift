//
//  ContentView+Calculations.swift
//  MortgageMLCalculator
//
//  Created by Stepan Karabelnikov on 29.05.2026.
//

import Foundation

extension ContentView {
    func debouncedCalculate() {
        viewModel.debouncedCalculate()
    }

    func calculateFull() {
        viewModel.calculateFull()
    }

    func recalculateMortgageOnly() {
        viewModel.recalculateMortgageOnly()
    }
}
