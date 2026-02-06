//
//  ContentView.swift
//  SentimentAnalyzer
//
//  Created by Karabelnikov Stepan on 23.01.2026.
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = AnalysisViewModel()
    @State private var inputText = "Я очень доволен этим продуктом! Работает отлично."
    @State private var showingDetails = false
    @State private var showingHistory = false
    @State private var showingScanner = false
    @State private var showingPhotoPicker = false
    @State private var isExporting = false
    @State private var exportDocument: AnalysisExportDocument?
    @State private var exportFileName = "analysis"

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    TextEditorView(text: $inputText)

                    HStack(spacing: 12) {
                        Button(action: { showingScanner = true }) {
                            Label("Сканер", systemImage: "camera.viewfinder")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)

                        Button(action: { showingPhotoPicker = true }) {
                            Label("Галерея", systemImage: "photo.on.rectangle")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }

                    AnalysisButton(viewModel: viewModel, text: inputText)

                    AnalysisResultsView(viewModel: viewModel)

                    if let result = viewModel.result {
                        ExportButtonsView(
                            onExportText: { prepareExportText(from: result) },
                            onExportPDF: { prepareExportPDF(from: result) }
                        )
                    }

                    TestCasesView(viewModel: viewModel, inputText: $inputText)

                    Button("Запустить автотесты") {
                        runTests()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(10)

                    AnalysisDetailsView(viewModel: viewModel, isExpanded: $showingDetails)
                }
                .padding()
            }
            .navigationTitle("Анализатор тональности")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showingHistory = true }) {
                        Image(systemName: "clock.arrow.circlepath")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingDetails.toggle() }) {
                        Image(systemName: showingDetails ? "info.circle.fill" : "info.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $showingScanner) {
            PhotoImportView(importedText: $inputText, isPresented: $showingScanner)
        }
        .sheet(isPresented: $showingPhotoPicker) {
            PhotoPickerView(importedText: $inputText, isPresented: $showingPhotoPicker)
        }
        .sheet(isPresented: $showingHistory) {
            NavigationView {
                HistoryView()
                    .navigationTitle("История анализов")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Готово") { showingHistory = false }
                        }
                    }
            }
        }
        .fileExporter(
            isPresented: $isExporting,
            document: exportDocument,
            contentType: exportDocument?.contentType ?? .plainText,
            defaultFilename: exportFileName
        ) { _ in }
        .onChange(of: appState.quickAction) { action in
            guard let action else { return }
            switch action {
            case .newAnalysis:
                inputText = ""
                viewModel.clearResults()
            case .openHistory:
                showingHistory = true
            }
            appState.quickAction = nil
        }
    }
}

private extension ContentView {
    func prepareExportText(from result: TextAnalysisResult) {
        let text = AnalysisExportService.makeText(from: result)
        exportDocument = AnalysisExportDocument(
            data: Data(text.utf8),
            contentType: .plainText
        )
        exportFileName = fileName(for: result, ext: "txt")
        isExporting = true
    }

    func prepareExportPDF(from result: TextAnalysisResult) {
        let data = AnalysisExportService.makePDFData(from: result)
        exportDocument = AnalysisExportDocument(
            data: data,
            contentType: .pdf
        )
        exportFileName = fileName(for: result, ext: "pdf")
        isExporting = true
    }

    func fileName(for result: TextAnalysisResult, ext: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm"
        let date = formatter.string(from: result.timestamp)
        return "sentiment_\(date).\(ext)"
    }

    func runTests() {
        let testTexts = [
            "Это отличный день! Я счастлив.",
            "Все ужасно, ничего не работает.",
            "Сегодня обычный день, ничего особенного.",
            "Ты дурак, иди отсюда!"
        ]

        for (index, text) in testTexts.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 2) {
                inputText = text
                viewModel.analyzeText(text)
            }
        }
    }
}
