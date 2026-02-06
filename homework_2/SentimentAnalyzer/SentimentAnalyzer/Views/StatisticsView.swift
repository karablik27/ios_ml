//
//  StatisticsView.swift
//  SentimentAnalyzer
//
//  Created by Karabelnikov Stepan on 06.02.2026.
//

import SwiftUI
import Charts

struct SentimentStat: Identifiable {
    let id: String
    let sentiment: Sentiment
    let count: Int
}

struct StatisticsView: View {
    let stats: [SentimentStat]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Статистика по тональности")
                .font(.headline)

            Chart(stats) { item in
                BarMark(
                    x: .value("Тональность", item.sentiment.rawValue),
                    y: .value("Кол-во", item.count)
                )
                .foregroundStyle(item.sentiment.color)
                .annotation(position: .top) {
                    Text("\(item.count)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .frame(height: 180)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}
