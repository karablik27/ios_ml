//
//  AnalysisButton.swift
//  SentimentAnalyzer
//
//  Created by Karabelnikov Stepan on 23.01.2026.
//

import SwiftUI

struct AnalysisButton: View {
    @ObservedObject var viewModel: AnalysisViewModel
    let text: String

    var body: some View {
        Button(action: {
            viewModel.analyzeText(text)
        }) {
            HStack {
                Image(systemName: "text.magnifyingglass")
                Text("Анализировать тональность")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .disabled(text.isEmpty)
        .opacity(text.isEmpty ? 0.6 : 1)
    }
}
