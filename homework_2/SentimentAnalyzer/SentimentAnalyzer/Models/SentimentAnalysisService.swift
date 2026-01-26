


import NaturalLanguage
import CoreML

class SentimentAnalysisService {
    
    // MARK: - Базовый анализ NLP
    
    func analyze(_ text: String) async throws -> TextAnalysisResult {
        var details: [TextAnalysisResult.AnalysisDetail] = []
        
        // 1. Определение языка
        let language = try await detectLanguage(text)
        details.append(.init(title: "Язык", value: language, type: .info))
        
        // 2. Токенизация и статистика
        let (wordCount, sentences) = try await tokenize(text)
        details.append(.init(title: "Статистика",
                             value: "\(wordCount) слов, \(sentences) предложений",
                             type: .info))
        
        // 3. Анализ тональности
        let (sentiment, confidence) = try await analyzeSentiment(text)
        
        // 4. Определение частей речи
        let posDetails = try await analyzePartsOfSpeech(text)
        details.append(contentsOf: posDetails)
        
        // 5. Поиск именованных сущностей
        let entities = try await findNamedEntities(text)
        if !entities.isEmpty {
            details.append(.init(title: "Именованные сущности",
                                 value: entities.joined(separator: ", "),
                                 type: .info))
        }
        
        // 6. Проверка на токсичность
        let isToxic = try await checkToxicity(text)
        if isToxic {
            details.append(.init(title: "⚠️ Предупреждение",
                                 value: "Обнаружен потенциально токсичный контент",
                                 type: .warning))
        }
        
        return TextAnalysisResult(
            text: text,
            sentiment: sentiment,
            confidence: confidence,
            language: language,
            wordCount: wordCount,
            entities: entities,
            details: details,
            timestamp: Date()
        )
    }
    
    // MARK: - Детектирование языка
    
    private func detectLanguage(_ text: String) async throws -> String {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        
        guard let language = recognizer.dominantLanguage else {
            return "Не определен"
        }
        
        return language.rawValue
    }
    
    // MARK: - Токенизация
    
    private func tokenize(_ text: String) async throws -> (wordCount: Int, sentenceCount: Int) {
        let tagger = NLTagger(tagSchemes: [.tokenType])
        tagger.string = text
        
        var wordCount = 0
        var sentenceCount = 0
        
        // Подсчет слов
        tagger.enumerateTags(in: text.startIndex..<text.endIndex,
                             unit: .word,
                             scheme: .tokenType,
                             options: [.omitPunctuation, .omitWhitespace]) { _, _ in
            wordCount += 1
            return true
        }
        
        // Подсчет предложений
        tagger.enumerateTags(in: text.startIndex..<text.endIndex,
                             unit: .sentence,
                             scheme: .tokenType) { _, _ in
            sentenceCount += 1
            return true
        }
        
        return (wordCount, sentenceCount)
    }
    
    // MARK: - Анализ тональности
    
    private func analyzeSentiment(_ text: String) async throws -> (Sentiment, Double) {
        // Сначала пробуем встроенный анализатор
        let tagger = NLTagger(tagSchemes: [.sentimentScore])
        tagger.string = text
        
        if let sentimentTag = tagger.tag(at: text.startIndex,
                                         unit: .paragraph,
                                         scheme: .sentimentScore).0,
           let score = Double(sentimentTag.rawValue) {
            
            let sentiment: Sentiment
            switch score {
            case 0.3...:
                sentiment = .positive
            case -0.3..<0.3:
                sentiment = .neutral
            default:
                sentiment = .negative
            }
            
            return (sentiment, abs(score))
        }
        
        // Если встроенный не сработал, используем кастомную модель
        return try await analyzeWithCustomModel(text)
    }
    
    // MARK: - Кастомная модель
    
    private func analyzeWithCustomModel(_ text: String) async throws -> (Sentiment, Double) {
        let classifier = SentimentClassifier()
        let prediction = try classifier.predict(text: text)

        switch prediction.label {
        case .positive:
            return (.positive, prediction.confidence)
        case .negative:
            return (.negative, prediction.confidence)
        case .neutral:
            return (.neutral, prediction.confidence)
        }
    }

    
    // MARK: - Дополнительные функции NLP
    
    private func analyzePartsOfSpeech(
        _ text: String
    ) async throws -> [TextAnalysisResult.AnalysisDetail] {

        let tagger = NLTagger(tagSchemes: [.lexicalClass])
        tagger.string = text
        
        var posCount: [String: Int] = [:]
        
        tagger.enumerateTags(in: text.startIndex..<text.endIndex,
                             unit: .word,
                             scheme: .lexicalClass,
                             options: [.omitPunctuation, .omitWhitespace]) { tag, _ in
            if let tag = tag {
                posCount[tag.rawValue, default: 0] += 1
            }
            return true
        }
        
        return posCount.map { TextAnalysisResult.AnalysisDetail(
            title: "Часть речи: \($0.key)",
            value: "\($0.value)",
            type: .info
        )}
    }
    
    private func findNamedEntities(_ text: String) async throws -> [String] {
        let tagger = NLTagger(tagSchemes: [.nameType])
        tagger.string = text
        
        var entities: [String] = []
        
        tagger.enumerateTags(in: text.startIndex..<text.endIndex,
                             unit: .word,
                             scheme: .nameType,
                             options: [.joinNames]) { tag, range in
            if let tag = tag, tag != .otherWord {
                let entity = String(text[range])
                entities.append("\(entity) (\(tag.rawValue))")
            }
            return true
        }
        
        return entities
    }
    
    private func checkToxicity(_ text: String) async throws -> Bool {
        // Простая проверка по ключевым словам
        // В реальном приложении следует использовать ML модель
        let toxicPatterns = [
            "идиот", "дурак", "тупой", "ненавижу", "убей", "сдохни"
        ]
        
        let lowercasedText = text.lowercased()
        return toxicPatterns.contains { lowercasedText.contains($0) }
    }
    
    // MARK: - Ошибки
    
    enum AnalysisError: Error {
        case modelNotFound
        case invalidText
        case analysisFailed
    }
}

import Foundation
import NaturalLanguage

final class SentimentClassifier {

    enum Label: String {
        case positive
        case negative
        case neutral
    }

    struct Prediction {
        let label: Label
        let confidence: Double
    }

    // MARK: - Init (заглушка под CoreML)

    init() {
        // В будущем:
        // тут будет загрузка MLModel / NLModel
    }

    // MARK: - Predict

    func predict(text: String) throws -> Prediction {
        let lower = text.lowercased()

        let positiveKeywords = [
            "отлич", "класс", "супер", "доволен", "нрав", "хорош"
        ]

        let negativeKeywords = [
            "ужас", "плохо", "ненавижу", "идиот", "сломал", "отврат"
        ]

        if positiveKeywords.contains(where: { lower.contains($0) }) {
            return Prediction(label: .positive, confidence: 0.75)
        }

        if negativeKeywords.contains(where: { lower.contains($0) }) {
            return Prediction(label: .negative, confidence: 0.75)
        }

        return Prediction(label: .neutral, confidence: 0.5)
    }
}
