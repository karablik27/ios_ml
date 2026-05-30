//
//  HistoryView.swift
//  MortgageMLCalculator
//
//  Created by Stepan Karabelnikov on 29.05.2026.
//

import SwiftUI

struct HistoryView: View {
    @ObservedObject var store: CalculationHistoryStore
    let onSelect: (CalculationHistoryEntry) -> Void

    var body: some View {
        NavigationStack {
            List {
                if store.entries.isEmpty {
                    ContentUnavailableView(
                        "История пуста",
                        systemImage: "clock",
                        description: Text("Расчеты будут сохраняться автоматически")
                    )
                } else {
                    ForEach(store.entries) { entry in
                        Button {
                            onSelect(entry)
                        } label: {
                            HistoryRow(entry: entry)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle("История")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Очистить") {
                        store.clear()
                    }
                    .disabled(store.entries.isEmpty)
                }
            }
        }
    }
}

private struct HistoryRow: View {
    let entry: CalculationHistoryEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(entry.date, style: .date)
                Text(entry.date, style: .time)
                Spacer()
                Text("\(Int(entry.input.area)) м²")
                    .foregroundStyle(.secondary)
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            Text(entry.price, format: .currency(code: "RUB").precision(.fractionLength(0)))
                .font(.headline)
                .foregroundStyle(.blue)

            Text("Платеж: \(entry.monthlyPayment.formatted(.currency(code: "RUB").precision(.fractionLength(0))))")
                .font(.subheadline)
                .foregroundStyle(.green)
        }
        .padding(.vertical, 4)
    }
}
