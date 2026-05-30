//
//  PaymentChartView.swift
//  MortgageMLCalculator
//
//  Created by Stepan Karabelnikov on 29.05.2026.
//

import Charts
import SwiftUI

struct PaymentChartView: View {
    let price: Double
    let terms: MortgageTerms

    private var points: [PaymentPoint] {
        stride(from: 5, through: 30, by: 5).map { years in
            let chartTerms = MortgageTerms(
                downPayment: terms.downPayment,
                loanTerm: Double(years),
                interestRate: terms.interestRate
            )
            return PaymentPoint(
                years: years,
                payment: MortgageCalculationEngine.calculateMonthlyPayment(price: price, terms: chartTerms)
            )
        }
    }

    var body: some View {
        Chart(points) { point in
            LineMark(
                x: .value("Срок", point.years),
                y: .value("Платеж", point.payment)
            )
            PointMark(
                x: .value("Срок", point.years),
                y: .value("Платеж", point.payment)
            )
        }
        .frame(height: 180)
        .chartXAxisLabel("Срок, лет")
        .chartYAxisLabel("Платеж")
    }
}

private struct PaymentPoint: Identifiable {
    let years: Int
    let payment: Double

    var id: Int { years }
}
