import Foundation
import Combine
import CoreML

// MARK: - ЗАДАЧА ДЛЯ СТУДЕНТОВ
//
// Этот файл содержит заглушку системы адаптации сложности.
// Необходимо реализовать интеллектуальный выбор уровня на основе результатов игрока.
//
// Задание описано в файле TASK.md в корне проекта.
//
// Кратко:
// 1. Метод analyze() должен анализировать recentResults и выдавать рекомендацию
// 2. Метод nextDifficulty() должен выбирать следующий уровень на основе рекомендации
// 3. Нужно учитывать: точность (accuracy), очки (performanceScore), тренд

// MARK: - Основной класс адаптивного движка

/// AdaptiveEngine анализирует результаты игрока и рекомендует уровень сложности
/// 
/// Использование:
/// ```swift
/// let engine = AdaptiveEngine()
/// let recommendation = engine.analyze(exercise: .schulte, recentResults: lastGames)
/// let nextLevel = engine.nextDifficulty(for: .schulte, current: currentLevel, in: userStats)
/// ```
///
class AdaptiveEngine: ObservableObject {
    
    // MARK: - Настройки адаптации
    
    private enum Thresholds {
        static let minimumUpgradeSessions = 3
        static let recentResultsLimit = 5
        static let trendPercentDelta = 0.10
        
        static let upgradeAccuracy = 0.85
        static let upgradePerformance = 80.0
        static let downgradeAccuracy = 0.50
        static let downgradePerformance = 45.0
    }
    
    // MARK: - Published свойства
    
    /// Текущая рекомендация (обновляется после вызова analyze)
    /// Изначально .maintain - оставить текущий уровень
    @Published var currentRecommendation: DifficultyRecommendation = .maintain
    
    /// Результат анализа с подробными метриками
    /// nil до первого вызова analyze
    @Published var analysisResult: AnalysisResult?
    
    private let mlModel: MLModel?
    
    init() {
        let modelURL = Bundle.main.url(
            forResource: "DifficultyRecommendationClassifier 1",
            withExtension: "mlmodelc"
        )
        self.mlModel = modelURL.flatMap { try? MLModel(contentsOf: $0) }
    }
    
    // MARK: - Основные методы
    
    /// Анализирует последние результаты и даёт рекомендацию по уровню сложности
    ///
    /// - Parameters:
    ///   - exercise: Тип упражнения (schulte, nback, numbers, colors)
    ///   - recentResults: Массив последних результатов (GameResult)
    ///
    /// - Returns: Рекомендация: .upgrade, .downgrade или .maintain
    ///
    /// ## Алгоритм реализации:
    /// 1. Проверить, что есть хотя бы один результат
    /// 2. Вычислить среднюю точность (avgAccuracy)
    /// 3. Вычислить средний performance score
    /// 4. Определить тренд (улучшается/ухудшается/стабильно)
    /// 5. Сравнить с пороговыми значениями и вернуть рекомендацию
    ///
    /// - Пороги для upgrade:
    ///   - avgAccuracy >= 0.85 ИЛИ avgPerformance >= 80
    ///   - минимум 3 игры на текущем уровне
    ///   - тренд = improving или stable
    ///
    /// - Пороги для downgrade:
    ///   - avgAccuracy < 0.50 ИЛИ avgPerformance < 45
    ///
    /// - В остальных случаях: .maintain
    func analyze(exercise: ExerciseType, recentResults: [GameResult]) -> DifficultyRecommendation {
        let exerciseResults = recentResults.filter { $0.exerciseType == exercise.rawValue }
        
        guard let latestResult = exerciseResults.last else {
            currentRecommendation = .maintain
            analysisResult = nil
            return .maintain
        }
        
        let currentLevel = latestResult.difficulty
        let currentLevelResults = exerciseResults.filter { $0.difficulty == currentLevel }
        let sessions = Double(currentLevelResults.count)
        let avgAccuracy = currentLevelResults.map { $0.accuracy }.reduce(0, +) / sessions
        let avgPerformance = currentLevelResults.map { $0.performanceScore }.reduce(0, +) / sessions
        let recentSessions = Double(exerciseResults.count)
        let recentAvgAccuracy = exerciseResults.map { $0.accuracy }.reduce(0, +) / recentSessions
        let recentAvgPerformance = exerciseResults.map { $0.performanceScore }.reduce(0, +) / recentSessions
        let recentAvgReactionTime = exerciseResults.map { $0.averageReactionTime }.reduce(0, +) / recentSessions
        let trend = calculateTrend(exerciseResults)
        let trendScore = calculateTrendScore(exerciseResults)
        
        analysisResult = AnalysisResult(
            averageAccuracy: recentAvgAccuracy,
            averagePerformance: recentAvgPerformance,
            averageReactionTime: recentAvgReactionTime,
            trend: trend,
            sessionsAnalyzed: exerciseResults.count
        )
        
        let recommendation = mlRecommendation(
            latestResult: latestResult,
            currentLevel: currentLevel,
            recentAvgAccuracy: recentAvgAccuracy,
            recentAvgPerformance: recentAvgPerformance,
            trendScore: trendScore,
            gamesOnCurrentLevel: currentLevelResults.count
        ) ?? ruleBasedRecommendation(
            latestResult: latestResult,
            currentLevel: currentLevel,
            averageAccuracy: avgAccuracy,
            averagePerformance: avgPerformance,
            sessions: currentLevelResults.count,
            trend: trend
        )
        
        currentRecommendation = recommendation
        return recommendation
    }
    
    /// Вычисляет тренд производительности на основе сравнения первой и второй половины результатов
    ///
    /// - Parameter results: Массив результатов игр
    /// - Returns: Тренд: .improving, .stable или .declining
    ///
    /// ## Алгоритм:
    /// 1. Разделить результаты на две половины
    /// 2. Вычислить средний performance для каждой половины
    /// 3. Сравнить:
    ///    - Разница > 10% → .improving
    ///    - Разница < -10% → .declining
    ///    - Иначе → .stable
    private func calculateTrend(_ results: [GameResult]) -> PerformanceTrend {
        guard results.count >= 2 else { return .stable }
        
        let halfCount = results.count / 2
        let firstHalf = Array(results.prefix(halfCount))
        let secondHalf = Array(results.suffix(halfCount))
        
        guard !firstHalf.isEmpty, !secondHalf.isEmpty else { return .stable }
        
        let firstAvg = firstHalf.map { $0.performanceScore }.reduce(0, +) / Double(firstHalf.count)
        let secondAvg = secondHalf.map { $0.performanceScore }.reduce(0, +) / Double(secondHalf.count)
        let threshold = firstAvg * Thresholds.trendPercentDelta
        
        if secondAvg > firstAvg + threshold { return .improving }
        if secondAvg < firstAvg - threshold { return .declining }
        return .stable
    }
    
    private func calculateTrendScore(_ results: [GameResult]) -> Double {
        guard results.count >= 2 else { return 0 }
        
        let halfCount = results.count / 2
        let firstHalf = Array(results.prefix(halfCount))
        let secondHalf = Array(results.suffix(halfCount))
        
        guard !firstHalf.isEmpty, !secondHalf.isEmpty else { return 0 }
        
        let firstAvg = firstHalf.map { $0.performanceScore }.reduce(0, +) / Double(firstHalf.count)
        let secondAvg = secondHalf.map { $0.performanceScore }.reduce(0, +) / Double(secondHalf.count)
        return (secondAvg - firstAvg) / 100
    }
    
    private func mlRecommendation(latestResult: GameResult, currentLevel: DifficultyLevel,
                                  recentAvgAccuracy: Double, recentAvgPerformance: Double,
                                  trendScore: Double, gamesOnCurrentLevel: Int) -> DifficultyRecommendation? {
        guard let mlModel else { return nil }
        
        do {
            let input = try MLDictionaryFeatureProvider(dictionary: [
                "accuracy": MLFeatureValue(double: latestResult.accuracy),
                "performanceScore": MLFeatureValue(double: latestResult.performanceScore),
                "totalTime": MLFeatureValue(double: latestResult.totalTime),
                "averageReactionTime": MLFeatureValue(double: latestResult.averageReactionTime),
                "incorrectAnswers": MLFeatureValue(int64: Int64(latestResult.incorrectAnswers)),
                "currentDifficulty": MLFeatureValue(int64: Int64(currentLevel.rawValue)),
                "recentAvgAccuracy": MLFeatureValue(double: recentAvgAccuracy),
                "recentAvgPerformance": MLFeatureValue(double: recentAvgPerformance),
                "trendScore": MLFeatureValue(double: trendScore),
                "gamesOnCurrentLevel": MLFeatureValue(int64: Int64(gamesOnCurrentLevel))
            ])
            let output = try mlModel.prediction(from: input)
            guard let label = output.featureValue(for: "recommendation")?.stringValue else {
                return nil
            }
            return recommendation(from: label, currentLevel: currentLevel)
        } catch {
            return nil
        }
    }
    
    private func recommendation(from label: String, currentLevel: DifficultyLevel) -> DifficultyRecommendation? {
        switch label.lowercased() {
        case "upgrade": return .upgrade(currentLevel)
        case "downgrade": return .downgrade(currentLevel)
        case "maintain": return .maintain
        default: return nil
        }
    }
    
    private func ruleBasedRecommendation(latestResult: GameResult, currentLevel: DifficultyLevel,
                                         averageAccuracy: Double, averagePerformance: Double,
                                         sessions: Int, trend: PerformanceTrend) -> DifficultyRecommendation {
        if shouldDowngrade(
            accuracy: latestResult.accuracy,
            performance: latestResult.performanceScore
        ) || shouldDowngrade(accuracy: averageAccuracy, performance: averagePerformance) {
            return .downgrade(currentLevel)
        }
        
        if shouldUpgrade(
            accuracy: averageAccuracy,
            performance: averagePerformance,
            sessions: sessions,
            trend: trend
        ) {
            return .upgrade(currentLevel)
        }
        
        return .maintain
    }
    
    /// Проверяет, стоит ли повысить сложность
    ///
    /// - Parameters:
    ///   - accuracy: Средняя точность (0.0 - 1.0)
    ///   - performance: Средний performance score
    ///   - sessions: Количество сыгранных сессий
    ///   - trend: Тренд производительности
    /// - Returns: true если рекомендуется повышение
    private func shouldUpgrade(accuracy: Double, performance: Double,
                               sessions: Int, trend: PerformanceTrend) -> Bool {
        let enoughSessions = sessions >= Thresholds.minimumUpgradeSessions
        let highMetrics = accuracy >= Thresholds.upgradeAccuracy || performance >= Thresholds.upgradePerformance
        let goodTrend = trend == .improving || trend == .stable
        
        return enoughSessions && highMetrics && goodTrend
    }
    
    /// Проверяет, стоит ли понизить сложность
    ///
    /// - Parameters:
    ///   - accuracy: Средняя точность
    ///   - performance: Средний performance score
    /// - Returns: true если рекомендуется понижение
    private func shouldDowngrade(accuracy: Double, performance: Double) -> Bool {
        accuracy < Thresholds.downgradeAccuracy || performance < Thresholds.downgradePerformance
    }
    
    /// Получает следующий рекомендуемый уровень сложности
    ///
    /// - Parameters:
    ///   - exercise: Тип упражнения
    ///   - current: Текущий уровень сложности
    ///   - stats: Статистика пользователя
    /// - Returns: Следующий уровень сложности
    ///
    /// ## Алгоритм:
    /// 1. Получить последние результаты (например, последние 5 игр)
    /// 2. Вызвать analyze() для получения рекомендации
    /// 3. Применить рекомендацию к текущему уровню:
    ///    - .upgrade → current + 1 (но не выше max)
    ///    - .downgrade → current - 1 (но не ниже min)
    ///    - .maintain → текущий уровень
    func nextDifficulty(for exercise: ExerciseType, current: DifficultyLevel,
                        in stats: UserStats) -> DifficultyLevel {
        let recentResults = stats.results(for: exercise, last: Thresholds.recentResultsLimit)
        let recommendation = analyze(exercise: exercise, recentResults: recentResults)
        
        switch recommendation {
        case .upgrade:
            let nextRaw = min(current.rawValue + 1, DifficultyLevel.max)
            return DifficultyLevel(rawValue: nextRaw) ?? current
        case .downgrade:
            let nextRaw = max(current.rawValue - 1, DifficultyLevel.min)
            return DifficultyLevel(rawValue: nextRaw) ?? current
        case .maintain:
            return current
        }
    }
}

// MARK: - Типы данных

/// Рекомендация по изменению сложности
enum DifficultyRecommendation: Equatable {
    /// Повысить сложность с указанного текущего уровня
    case upgrade(DifficultyLevel)
    
    /// Понизить сложность с указанного текущего уровня
    case downgrade(DifficultyLevel)
    
    /// Оставить текущий уровень без изменений
    case maintain
    
    /// Человекочитаемое описание рекомендации
    var description: String {
        switch self {
        case .upgrade:
            return "Рекомендуется повысить сложность 🎯"
        case .downgrade:
            return "Рекомендуется понизить сложность 💪"
        case .maintain:
            return "Сложность пока без изменений"
        }
    }
    
    /// Название цвета для UI (green/orange/blue)
    var color: String {
        switch self {
        case .upgrade: return "green"
        case .downgrade: return "orange"
        case .maintain: return "blue"
        }
    }
}

/// Тренд производительности игрока
enum PerformanceTrend {
    /// Производительность улучшается
    case improving
    
    /// Производительность стабильна
    case stable
    
    /// Производительность снижается
    case declining
    
    /// Иконка для отображения в UI
    var icon: String {
        switch self {
        case .improving: return "arrow.up.forward"
        case .stable: return "arrow.right"
        case .declining: return "arrow.down.forward"
        }
    }
}

/// Результат анализа производительности
struct AnalysisResult {
    /// Средняя точность по всем проанализированным играм (0.0 - 1.0)
    let averageAccuracy: Double
    
    /// Средний performance score
    let averagePerformance: Double
    
    /// Среднее время реакции в секундах
    let averageReactionTime: TimeInterval
    
    /// Тренд производительности
    let trend: PerformanceTrend
    
    /// Количество проанализированных сессий
    let sessionsAnalyzed: Int
    
    /// Отформатированная точность (например "85.5%")
    var formattedAccuracy: String {
        String(format: "%.1f%%", averageAccuracy * 100)
    }
    
    /// Отформатированный performance (например "75.3")
    var formattedPerformance: String {
        String(format: "%.1f", averagePerformance)
    }
    
    /// Отформатированное время реакции (например "1.23 с")
    var formattedReactionTime: String {
        String(format: "%.2f с", averageReactionTime)
    }
}
