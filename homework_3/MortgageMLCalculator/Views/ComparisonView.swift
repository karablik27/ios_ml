//
//  ComparisonView.swift
//  MortgageMLCalculator
//
//  Created by Stepan Karabelnikov on 29.05.2026.
//

import SwiftUI

struct ComparisonView: View {
    @State private var firstInput = MortgageInput.standard
    @State private var secondInput = MortgageInput.premium
    @State private var terms = MortgageTerms(downPayment: 20, loanTerm: 20, interestRate: 7.5)

    private var firstCalculation: MortgageCalculation {
        MortgageCalculationEngine.calculate(input: firstInput, terms: terms)
    }

    private var secondCalculation: MortgageCalculation {
        MortgageCalculationEngine.calculate(input: secondInput, terms: terms)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Общие условия ипотеки") {
                    ComparisonSliderRow(
                        title: "Взнос",
                        value: $terms.downPayment,
                        range: 10...50,
                        step: 5,
                        valueText: "\(Int(terms.downPayment))%"
                    )

                    ComparisonSliderRow(
                        title: "Срок",
                        value: $terms.loanTerm,
                        range: 5...30,
                        step: 1,
                        valueText: "\(Int(terms.loanTerm)) лет"
                    )

                    ComparisonSliderRow(
                        title: "Ставка",
                        value: $terms.interestRate,
                        range: 3...15,
                        step: 0.1,
                        valueText: String(format: "%.1f%%", terms.interestRate)
                    )
                }

                Section("Параметры") {
                    ComparisonEditor(title: "Вариант A", input: $firstInput)
                    ComparisonEditor(title: "Вариант B", input: $secondInput)
                }

                Section("Сравнение") {
                    HStack(alignment: .top, spacing: 12) {
                        ComparisonResultCard(title: "Вариант A", calculation: firstCalculation)
                        ComparisonResultCard(title: "Вариант B", calculation: secondCalculation)
                    }
                }
            }
            .navigationTitle("Сравнение")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private struct ComparisonEditor: View {
    let title: String
    @Binding var input: MortgageInput

    var body: some View {
        DisclosureGroup(title) {
            ParameterRow(title: "Площадь", unit: "м²") {
                TextField("70", value: $input.area, format: .number)
                    .keyboardType(.decimalPad)
            }

            StepperParameterRow(title: "Комнаты", unit: "шт.", value: $input.rooms, range: 1...12)

            ParameterRow(title: "Расстояние", unit: "км") {
                TextField("8", value: $input.distanceToCenter, format: .number)
                    .keyboardType(.decimalPad)
            }

            Picker("Год постройки", selection: $input.buildYear) {
                ForEach(1990...2031, id: \.self) { year in
                    Text(String(year)).tag(year)
                }
            }

            Picker("Ремонт", selection: $input.renovationLevel) {
                Text("Нет").tag(0)
                Text("Косметический").tag(1)
                Text("Хороший").tag(2)
                Text("Евро").tag(3)
                Text("Дизайнерский").tag(4)
            }
        }
    }
}

private struct ComparisonResultCard: View {
    let title: String
    let calculation: MortgageCalculation

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)

            Text(calculation.price, format: .currency(code: "RUB").precision(.fractionLength(0)))
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.blue)
                .lineLimit(2)
                .minimumScaleFactor(0.75)

            Text("Платеж")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(calculation.monthlyPayment, format: .currency(code: "RUB").precision(.fractionLength(0)))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.green)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct ComparisonSliderRow: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let valueText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                Spacer()
                Text(valueText)
                    .foregroundStyle(.secondary)
            }

            Slider(value: $value, in: range, step: step)
        }
    }
}
