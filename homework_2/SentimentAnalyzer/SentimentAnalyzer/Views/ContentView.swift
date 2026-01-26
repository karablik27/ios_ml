//
//  ContentView.swift
//  SentimentAnalyzer
//
//  Created by Верховный Маг on 23.01.2026.
//

import SwiftUI
import NaturalLanguage

struct ContentView: View {
    @StateObject private var viewModel = AnalysisViewModel()
    @State private var inputText = "Я очень доволен этим продуктом! Работает отлично."
    @State private var showingDetails = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Поле ввода текста
                    TextEditorView(text: $inputText)
                    
                    // Кнопка анализа
                    AnalysisButton(viewModel: viewModel, text: inputText)
                    
                    // Результаты анализа
                    AnalysisResultsView(viewModel: viewModel)
                    
                    // Тестовые примеры
                    TestCasesView(viewModel: viewModel, inputText: $inputText)
                    
                    // Детали анализа
                    AnalysisDetailsView(viewModel: viewModel, isExpanded: $showingDetails)
                }
                .padding()
            }
            .navigationTitle("Анализатор тональности")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingDetails.toggle() }) {
                        Image(systemName: showingDetails ? "info.circle.fill" : "info.circle")
                    }
                }
            }
        }
    }
}

struct TextEditorView: View {
    @Binding var text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Введите текст для анализа:")
                .font(.headline)
            
            TextEditor(text: $text)
                .frame(height: 150)
                .padding(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
            
            HStack {
                Text("Символов: \(text.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button("Очистить") {
                    text = ""
                }
                .font(.caption)
                .disabled(text.isEmpty)
            }
        }
    }
}

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

