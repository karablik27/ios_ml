//
//  SentimentAnalyzer.swift
//  SentimentAnalyzer
//
//  Created by Верховный Маг on 23.01.2026.
//

import Foundation
import SwiftUI
enum Sentiment: String {
    case positive = "Позитивный"
    case negative = "Негативный"
    case neutral = "Нейтральный"
    
    var color: Color {
        switch self {
        case .positive: return .green
        case .negative: return .red
        case .neutral: return .gray
        }
    }
    
    var emoji: String {
        switch self {
        case .positive: return "😊"
        case .negative: return "😠"
        case .neutral: return "😐"
        }
    }
}
struct TextAnalysisResult {
    let text: String
    let sentiment: Sentiment
    let confidence: Double
    let language: String
    let wordCount: Int
    let entities: [String]
    let details: [AnalysisDetail]
    let timestamp: Date
    
    struct AnalysisDetail {
        let title: String
        let value: String
        let type: DetailType
        
        enum DetailType {
            case info, warning, success, error
        }
    }
}
