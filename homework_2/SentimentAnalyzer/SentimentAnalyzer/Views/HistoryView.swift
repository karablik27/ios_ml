//
//  HistoryView.swift
//  SentimentAnalyzer
//
//  Created by Karabelnikov Stepan on 23.01.2026.
//

import SwiftUI

struct HistoryView: View {
    @AppStorage("analysisHistory") private var historyData: Data = Data()
    @State private var history: [TextAnalysisResult] = []

    var body: some View {
        Group {
            if history.isEmpty {
                VStack(spacing: 16) {
                    StatisticsView(stats: emptyStats())

                    VStack(spacing: 8) {
                        Image(systemName: "clock")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        Text("История пуста")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                List {
                    Section {
                        StatisticsView(stats: makeStats())
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                    }

                    Section {
                        ForEach(history, id: \.timestamp) { result in
                            HistoryRow(result: result)
                        }
                        .onDelete(perform: deleteItems)
                    }
                }
                .listStyle(.plain)
            }
        }
        .onAppear(perform: loadHistory)
        .onChange(of: historyData) { _ in
            loadHistory()
        }
    }

    private func loadHistory() {
        guard
            !historyData.isEmpty,
            let decoded = try? JSONDecoder().decode([TextAnalysisResult].self, from: historyData)
        else {
            history = []
            return
        }
        history = decoded.sorted { $0.timestamp > $1.timestamp }
    }

    private func deleteItems(at offsets: IndexSet) {
        history.remove(atOffsets: offsets)
        saveHistory()
    }

    private func saveHistory() {
        guard let encoded = try? JSONEncoder().encode(history) else {
            historyData = Data()
            return
        }
        historyData = encoded
    }

    private func makeStats() -> [SentimentStat] {
        let grouped = Dictionary(grouping: history, by: { $0.sentiment })
        let positive = grouped[.positive]?.count ?? 0
        let neutral = grouped[.neutral]?.count ?? 0
        let negative = grouped[.negative]?.count ?? 0
        return [
            SentimentStat(id: "positive", sentiment: .positive, count: positive),
            SentimentStat(id: "neutral", sentiment: .neutral, count: neutral),
            SentimentStat(id: "negative", sentiment: .negative, count: negative)
        ]
    }

    private func emptyStats() -> [SentimentStat] {
        [
            SentimentStat(id: "positive", sentiment: .positive, count: 0),
            SentimentStat(id: "neutral", sentiment: .neutral, count: 0),
            SentimentStat(id: "negative", sentiment: .negative, count: 0)
        ]
    }
}

private struct HistoryRow: View {
    let result: TextAnalysisResult

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(result.text.prefix(50) + (result.text.count > 50 ? "..." : ""))
                    .font(.caption)
                    .lineLimit(2)

                HStack {
                    Text(result.sentiment.rawValue)
                        .font(.caption)
                        .foregroundColor(result.sentiment.color)

                    Text(result.sentiment.emoji)

                    Spacer()

                    Text(result.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}
