//
//  PredictionResultView+SwiftUI.swift
//  MortgageMLCalculator
//
//  Created by Stepan Karabelnikov on 29.05.2026.
//

import SwiftUI

struct PredictionResultView: View {
    let calculation: MortgageCalculation
    let downPayment: Double
    let loanTerm: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Прогнозируемая стоимость")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(calculation.price, format: .currency(code: "RUB").precision(.fractionLength(0)))
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.blue)
                    .accessibilityIdentifier("predictedPrice")
            }

            Divider()

            VStack(alignment: .leading, spacing: 10) {
                Text("Ипотечный расчет")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                resultRow("Первоначальный взнос:", "\(Int(downPayment))%")
                resultRow("Сумма кредита:", currency(calculation.creditAmount))
                resultRow("Ежемесячный платеж:", currency(calculation.monthlyPayment), color: .green, bold: true)
                resultRow("Переплата за \(Int(loanTerm)) лет:", currency(calculation.overpayment), color: .red)

                if calculation.creditAmount > 0 {
                    let percent = calculation.overpayment / calculation.creditAmount * 100
                    resultRow("Переплата:", String(format: "%.1f%%", percent), color: .orange)
                }
            }
        }
        .padding(.vertical, 8)
    }

    private func resultRow(
        _ title: String,
        _ value: String,
        color: Color = .primary,
        bold: Bool = false
    ) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer(minLength: 12)
            Text(value)
                .fontWeight(bold ? .bold : .medium)
                .foregroundStyle(color)
                .multilineTextAlignment(.trailing)
        }
    }

    private func currency(_ value: Double) -> String {
        value.formatted(.currency(code: "RUB").precision(.fractionLength(0)))
    }
}
