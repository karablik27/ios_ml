//
//  ParameterRow.swift
//  MortgageMLCalculator
//
//  Created by Stepan Karabelnikov on 29.05.2026.
//

import SwiftUI

struct ParameterRow<Control: View>: View {
    let title: String
    let unit: String
    @ViewBuilder let control: Control

    var body: some View {
        HStack(spacing: 12) {
            Text(title)
            Spacer(minLength: 12)
            control
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 110)
            Text(unit)
                .foregroundStyle(.secondary)
                .frame(minWidth: 36, alignment: .leading)
        }
    }
}

struct StepperParameterRow: View {
    let title: String
    let unit: String
    @Binding var value: Int
    let range: ClosedRange<Int>

    var body: some View {
        Stepper(value: $value, in: range) {
            HStack {
                Text(title)
                Spacer()
                Text("\(value) \(unit)")
                    .foregroundStyle(.secondary)
            }
        }
    }
}
