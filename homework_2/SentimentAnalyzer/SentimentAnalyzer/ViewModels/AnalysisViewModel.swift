//
//  AnalysisViewModel.swift
//  SentimentAnalyzer
//
//  Created by Karabelnikov Stepan on 23.01.2026.
//

import Foundation
import NaturalLanguage
import SwiftUI
import Combine

@MainActor
class AnalysisViewModel: ObservableObject {
    @Published var result: TextAnalysisResult?
    @Published var isAnalyzing = false
    @Published var analysisDetails: [TextAnalysisResult.AnalysisDetail] = []
    @Published var errorMessage: String?
    
    private let analyzer = SentimentAnalysisService()
    private let historyKey = "analysisHistory"
    
    func analyzeText(_ text: String) {
        guard !text.isEmpty else { return }
        
        isAnalyzing = true
        errorMessage = nil
        
        Task {
            do {
                let result = try await analyzer.analyze(text)
                self.result = result
                self.analysisDetails = result.details
                self.appendToHistory(result)
            } catch {
                self.errorMessage = "Ошибка анализа: \(error.localizedDescription)"
            }
            
            self.isAnalyzing = false
        }
    }
    
    func clearResults() {
        result = nil
        analysisDetails = []
        errorMessage = nil
    }

    private func appendToHistory(_ result: TextAnalysisResult) {
        var history = loadHistory()
        history.insert(result, at: 0)
        if history.count > 100 {
            history = Array(history.prefix(100))
        }
        saveHistory(history)
    }

    private func loadHistory() -> [TextAnalysisResult] {
        guard
            let data = UserDefaults.standard.data(forKey: historyKey),
            !data.isEmpty,
            let decoded = try? JSONDecoder().decode([TextAnalysisResult].self, from: data)
        else {
            return []
        }
        return decoded
    }

    private func saveHistory(_ history: [TextAnalysisResult]) {
        guard let data = try? JSONEncoder().encode(history) else { return }
        UserDefaults.standard.set(data, forKey: historyKey)
    }
}
