//
//  CalculationHistoryStore.swift
//  MortgageMLCalculator
//
//  Created by Stepan Karabelnikov on 29.05.2026.
//

import Combine
import Foundation

final class CalculationHistoryStore: ObservableObject {
    @Published private(set) var entries: [CalculationHistoryEntry]

    private let defaults: UserDefaults
    private let key: String

    init(
        defaults: UserDefaults = .standard,
        key: String = "mortgage_calculation_history"
    ) {
        self.defaults = defaults
        self.key = key

        if let data = defaults.data(forKey: key),
           let decoded = try? JSONDecoder().decode([CalculationHistoryEntry].self, from: data) {
            entries = decoded
        } else {
            entries = []
        }
    }

    func add(_ entry: CalculationHistoryEntry) {
        entries.insert(entry, at: 0)

        if entries.count > 20 {
            entries = Array(entries.prefix(20))
        }

        save()
    }

    func clear() {
        entries.removeAll()
        defaults.removeObject(forKey: key)
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        defaults.set(data, forKey: key)
    }
}
