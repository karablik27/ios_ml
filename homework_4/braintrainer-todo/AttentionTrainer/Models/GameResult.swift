import Foundation

// MARK: - Результат игры

/// Структура для хранения результата одной игровой сессии
///
/// Содержит все метрики одной сыгранной игры: время, точность, ошибки и т.д.
/// Используется для анализа прогресса и адаптации сложности.
///
/// ## Использование:
/// ```swift
/// let result = GameResult(from: exerciseSession)
/// userStats.addResult(result)
/// ```
///
/// ## Сохранение:
/// Соответствует Codable — сохраняется в UserDefaults как JSON
struct GameResult: Identifiable, Codable {
    
    // MARK: - Идентификация
    
    /// Уникальный идентификатор игры
    let id: UUID
    
    /// Тип упражнения в виде строки (rawValue из ExerciseType)
    /// Хранится как строка для совместимости при изменении enum
    let exerciseType: String
    
    // MARK: - Уровень сложности
    
    /// Уровень сложности как число (0-7 для уровней 1-8)
    let difficultyRaw: Int
    
    /// Уровень сложности как enum
    /// Вычисляется из difficultyRaw
    var difficulty: DifficultyLevel {
        DifficultyLevel(rawValue: difficultyRaw) ?? .level1
    }
    
    // MARK: - Время
    
    /// Дата и время начала игры
    let date: Date
    
    /// Общее время игры в секундах
    let totalTime: Double
    
    // MARK: - Результаты
    
    /// Количество правильных ответов
    let correctAnswers: Int
    
    /// Количество неправильных ответов
    let incorrectAnswers: Int
    
    /// Среднее время реакции в секундах
    let averageReactionTime: Double
    
    /// Точность (0.0 - 1.0)
    /// Формула: correctAnswers / (correctAnswers + incorrectAnswers)
    let accuracy: Double
    
    /// Общий счёт производительности (0-100)
    /// Комбинация точности и скорости
    let performanceScore: Double
    
    // MARK: - Инициализаторы
    
    /// Создает результат из игровой сессии
    ///
    /// - Parameter session: Сессия упражнения с метриками
    ///
    /// Извлекает данные из ExerciseSession и SessionMetrics
    init(from session: ExerciseSession) {
        self.id = session.id
        self.exerciseType = session.exerciseType.rawValue
        self.difficultyRaw = session.difficulty.rawValue
        self.date = session.startTime
        
        if let metrics = session.metrics {
            self.totalTime = metrics.totalTime
            self.correctAnswers = metrics.correctAnswers
            self.incorrectAnswers = metrics.incorrectAnswers
            self.averageReactionTime = metrics.averageReactionTime
            self.accuracy = metrics.accuracy
            self.performanceScore = metrics.performanceScore
        } else {
            // Fallback если метрики не доступны
            self.totalTime = 0
            self.correctAnswers = 0
            self.incorrectAnswers = 0
            self.averageReactionTime = 0
            self.accuracy = 0
            self.performanceScore = 0
        }
    }
    
    // MARK: - Computed свойства
    
    /// Общее количество попыток (правильные + неправильные)
    var totalAttempts: Int {
        correctAnswers + incorrectAnswers
    }
    
    /// Категория результата (для цветовой индикации)
    ///
    /// - .poor: плохо (точность < 50% или счёт < 40)
    /// - .average: средне
    /// - .good: хорошо
    /// - .excellent: отлично (точность >= 80% и счёт >= 75)
    var resultCategory: ResultCategory {
        if accuracy < 0.5 || performanceScore < 40 {
            return .poor
        } else if accuracy >= 0.8 && performanceScore >= 75 {
            return .excellent
        } else if accuracy >= 0.65 && performanceScore >= 55 {
            return .good
        } else {
            return .average
        }
    }
}

// MARK: - Категория результата

/// Категория качества результата игры
///
/// Используется для цветовой индикации и статистики
enum ResultCategory: String {
    /// Плохой результат (красный)
    case poor = "Требует улучшения"
    
    /// Средний результат (желтый)
    case average = "Средний"
    
    /// Хороший результат (синий)
    case good = "Хороший"
    
    /// Отличный результат (зеленый)
    case excellent = "Отличный"
    
    /// Название цвета для UI
    var color: String {
        switch self {
        case .poor: return "red"
        case .average: return "yellow"
        case .good: return "blue"
        case .excellent: return "green"
        }
    }
}
