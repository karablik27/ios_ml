//
//  ContentView.swift
//  MortgageMLCalculator
//
//  Created by Stepan Karabelnikov on 29.05.2026.
//

import SwiftUI

struct ContentView: View {
    @StateObject var viewModel = MortgageCalculatorViewModel()

    var body: some View {
        TabView {
            NavigationStack {
                Form {
                    propertySection
                    mortgageSection
                    resultSection
                    chartSection
                }
                .navigationTitle("Ипотечный калькулятор")
                .navigationBarTitleDisplayMode(.inline)
            }
            .tabItem { Label("Расчет", systemImage: "house") }

            ComparisonView()
                .tabItem { Label("Сравнение", systemImage: "rectangle.split.2x1") }

            HistoryView(store: viewModel.historyStore) { entry in
                viewModel.applyHistory(entry)
            }
            .tabItem { Label("История", systemImage: "clock.arrow.circlepath") }
        }
        .onAppear {
            debouncedCalculate()
        }
        .onChange(of: viewModel.input) { _, _ in
            debouncedCalculate()
        }
        .onChange(of: viewModel.terms) { _, _ in
            recalculateMortgageOnly()
        }
    }

    private var propertySection: some View {
        Section("Характеристики недвижимости") {
            ParameterRow(title: "Площадь", unit: "м²") {
                TextField("70", value: $viewModel.input.area, format: .number)
                    .keyboardType(.decimalPad)
            }

            StepperParameterRow(title: "Комнаты", unit: "шт.", value: $viewModel.input.rooms, range: 1...12)
            StepperParameterRow(title: "Санузлы", unit: "шт.", value: $viewModel.input.bathrooms, range: 1...8)
            StepperParameterRow(title: "Парковочные места", unit: "шт.", value: $viewModel.input.garageSpaces, range: 0...5)

            ParameterRow(title: "Расстояние до центра", unit: "км") {
                TextField("8", value: $viewModel.input.distanceToCenter, format: .number)
                    .keyboardType(.decimalPad)
            }

            StepperParameterRow(title: "Этаж", unit: "эт.", value: $viewModel.input.floor, range: 1...100)

            Picker("Год постройки", selection: $viewModel.input.buildYear) {
                ForEach(1990...2031, id: \.self) { year in
                    Text(String(year)).tag(year)
                }
            }

            StepperParameterRow(title: "Балконы", unit: "шт.", value: $viewModel.input.balcony, range: 0...5)

            Picker("Ремонт", selection: $viewModel.input.renovationLevel) {
                Text("Без ремонта").tag(0)
                Text("Косметический").tag(1)
                Text("Хороший").tag(2)
                Text("Евро").tag(3)
                Text("Дизайнерский").tag(4)
            }

            Toggle("Лифт", isOn: $viewModel.input.hasElevator)

            ParameterRow(title: "Высота потолков", unit: "м") {
                TextField("2.7", value: $viewModel.input.ceilingHeight, format: .number)
                    .keyboardType(.decimalPad)
            }

            StepperParameterRow(title: "Рейтинг района", unit: "/10", value: $viewModel.input.districtRating, range: 1...10)
        }
    }

    private var mortgageSection: some View {
        Section("Условия ипотеки") {
            SliderRow(
                title: "Первоначальный взнос",
                value: $viewModel.terms.downPayment,
                range: 10...50,
                step: 5,
                valueText: "\(Int(viewModel.terms.downPayment))%"
            )

            SliderRow(
                title: "Срок кредита",
                value: $viewModel.terms.loanTerm,
                range: 5...30,
                step: 1,
                valueText: "\(Int(viewModel.terms.loanTerm)) лет"
            )

            SliderRow(
                title: "Процентная ставка",
                value: $viewModel.terms.interestRate,
                range: 3...15,
                step: 0.1,
                valueText: String(format: "%.1f%%", viewModel.terms.interestRate)
            )
        }
    }

    private var resultSection: some View {
        Section("Результаты расчета") {
            if viewModel.isCalculating {
                HStack {
                    ProgressView()
                    Text("Рассчитываем...")
                        .foregroundStyle(.secondary)
                }
                .accessibilityIdentifier("calculationProgress")
            } else if let error = viewModel.errorMessage {
                Label(error, systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.orange)
                    .accessibilityIdentifier("validationError")
            } else if let calculation = viewModel.calculation {
                PredictionResultView(
                    calculation: calculation,
                    downPayment: viewModel.terms.downPayment,
                    loanTerm: viewModel.terms.loanTerm
                )
            } else {
                Text("Введите параметры для расчета")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var chartSection: some View {
        Section("График платежа") {
            if let calculation = viewModel.calculation {
                PaymentChartView(price: calculation.price, terms: viewModel.terms)
            } else {
                Text("График появится после расчета")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct SliderRow: View {
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

#Preview {
    ContentView()
}
