import Foundation
import SwiftUI
import Combine

// MARK: - Менеджер статистики пользователя

/// Класс для хранения и управления статистикой пользователя
///
/// ## Назначение:
/// - Хранит историю всех игр (history)
/// - Хранит текущий уровень сложности для каждой игры (currentDifficulty)
/// - Хранит серию тренировок (streak)
/// - Предоставляет методы для получения статистики и прогресса
///
/// ## Использование:
/// ```swift
/// @EnvironmentObject var userStats: UserStats
///
/// // Добавить результат игры
/// userStats.addResult(gameResult)
///
/// // Получить текущий уровень
/// let level = userStats.recommendedDifficulty(for: .schulte)
///
/// // Получить последние результаты
/// let recent = userStats.results(for: .colors, last: 5)
/// ```
///
/// ## Хранение данных:
/// Данные сохраняются в UserDefaults через StatsStorage
/// При изменении свойств автоматически вызывается objectWillChange.send()
final class UserStats: ObservableObject {
    
    // MARK: - Published свойства
    
    /// Текущий уровень сложности для каждой игры
    /// Ключ: тип упражнения, Значение: уровень сложности
    /// По умолчанию для всех игр - уровень 1
    @Published var currentDifficulty: [ExerciseType: DifficultyLevel] = [:]
    
    /// История всех результатов игр
    /// Каждый результат - это одна сыгранная игра
    @Published var history: [GameResult] = []
    
    /// Текущая серия тренировок (streak)
    /// Увеличивается при ежедневных тренировках, сбрасывается при пропуске дня
    @Published var streak: Int = 0
    
    /// Дата последней тренировки
    /// Используется для расчета streak
    @Published var lastTrainingDate: Date?
    
    // MARK: - Приватные свойства
    
    /// Сервис для сохранения/загрузки данных
    private let storage = StatsStorage()
    
    // MARK: - Инициализация
    
    /// При создании загружает сохраненные данные
    init() {
        loadData()
    }
    
    // MARK: - Публичные методы
    
    /// Возвращает рекомендуемый уровень сложности для игры
    ///
    /// - Parameter exercise: Тип упражнения
    /// - Returns: Уровень сложности (по умолчанию .level1)
    ///
    /// ## Логика выбора:
    /// 1. Если для игры уже есть сохраненный уровень - возвращает его
    /// 2. Иначе возвращает уровень 1 (начальный)
    ///
    /// - TODO: Можно улучшить интеллектуальный выбор начального уровня
    ///   на основе результатов в других играх
    func recommendedDifficulty(for exercise: ExerciseType) -> DifficultyLevel {
        currentDifficulty[exercise] ?? .level1
    }
    
    /// Обновляет уровень сложности для игры
    ///
    /// - Parameters:
    ///   - exercise: Тип упражнения
    ///   - level: Новый уровень сложности
    ///
    /// Автоматически сохраняет изменения и уведомляет подписчиков
    func updateDifficulty(for exercise: ExerciseType, to level: DifficultyLevel) {
        currentDifficulty[exercise] = level
        saveData()
        objectWillChange.send()
    }
    
    /// Добавляет результат игры в историю
    ///
    /// - Parameter result: Результат игры (GameResult)
    ///
    /// ## Что происходит:
    /// 1. Добавляет результат в history
    /// 2. Обновляет серию (streak)
    /// 3. Сохраняет данные
    /// 4. Уведомляет подписчиков об изменении
    func addResult(_ result: GameResult) {
        history.append(result)
        updateStreak()
        saveData()
        objectWillChange.send()
    }
    
    /// Возвращает результаты для конкретной игры
    ///
    /// - Parameters:
    ///   - exercise: Тип упражнения
    ///   - count: Максимальное количество результатов (по умолчанию 5)
    /// - Returns: Массив последних результатов
    ///
    /// ## Примечание:
    /// Результаты отсортированы по времени (старые → новые)
    /// Использует suffix(count) для получения последних N результатов
    func results(for exercise: ExerciseType, last count: Int = 5) -> [GameResult] {
        history
            .filter { $0.exerciseType == exercise.rawValue }
            .suffix(count)
    }
    
    /// Вычисляет среднюю производительность для игры
    ///
    /// - Parameter exercise: Тип упражнения
    /// - Returns: Средний performanceScore (0-100)
    ///
    /// ## Алгоритм:
    /// 1. Берет последние 5 результатов
    /// 2. Вычисляет среднее performanceScore
    /// 3. Если нет данных - возвращает 0
    func averagePerformance(for exercise: ExerciseType) -> Double {
        let recent = results(for: exercise, last: 5)
        guard !recent.isEmpty else { return 0 }
        return recent.map { $0.performanceScore }.reduce(0, +) / Double(recent.count)
    }
    
    /// Общее время тренировок в секундах
    ///
    /// - Returns: Сумма totalTime всех игр в истории
    func totalTrainingTime() -> TimeInterval {
        history.map { $0.totalTime }.reduce(0, +)
    }
    
    // MARK: - Приватные методы
    
    /// Обновляет серию тренировок (streak)
    ///
    /// ## Логика:
    /// - Если сегодня уже тренировались - ничего не меняем
    /// - Если последняя тренировка была вчера - увеличиваем streak
    /// - Если последняя тренировка была раньше - сбрасываем streak на 1
    /// - Если это первая тренировка - устанавливаем streak = 1
    private func updateStreak() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        if let last = lastTrainingDate {
            let lastDay = calendar.startOfDay(for: last)
            let daysSince = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0
            
            if daysSince == 0 {
                // Уже тренировались сегодня
                return
            } else if daysSince == 1 {
                // Вчера тренировались - продолжаем серию
                streak += 1
            } else {
                // Пропустили день - начинаем новую серию
                streak = 1
            }
        } else {
            // Первая тренировка
            streak = 1
        }
        
        lastTrainingDate = Date()
    }
    
    /// Сохраняет все данные в хранилище
    private func saveData() {
        storage.saveDifficulty(currentDifficulty)
        storage.saveHistory(history)
        storage.saveStreak(streak)
        storage.saveLastDate(lastTrainingDate)
    }
    
    /// Загружает данные из хранилища
    private func loadData() {
        currentDifficulty = storage.loadDifficulty()
        history = storage.loadHistory()
        streak = storage.loadStreak()
        lastTrainingDate = storage.loadLastDate()
    }
}

// MARK: - Расширение для работы с навыками

/// Расширение для расчета прогресса по навыкам
extension UserStats {
    
    /// Вычисляет прогресс по конкретному навыку
    ///
    /// - Parameter skill: Название навыка (например "Периферийное зрение")
    /// - Returns: Прогресс от 0 до 100
    ///
    /// ## Логика:
    /// 1. Находит все упражнения, которые развивают этот навык
    /// 2. Вычисляет среднюю производительность по этим упражнениям
    func skillProgress(_ skill: String) -> Double {
        // Находим упражнения, развивающие этот навык
        let relevantExercises = ExerciseType.allCases.filter { $0.targetSkills.contains(skill) }
        
        // Получаем средние очки по каждому упражнению
        let scores = relevantExercises.map { averagePerformance(for: $0) }
        
        guard !scores.isEmpty else { return 0 }
        
        // Среднее значение, ограниченное 100
        return min(100, scores.reduce(0, +) / Double(scores.count))
    }
    
    /// Все навыки с их прогрессом
    ///
    /// - Returns: Массив кортежей (название навыка, прогресс)
    var allSkills: [(name: String, progress: Double)] {
        let skills = [
            "Периферийное зрение",
            "Рабочая память",
            "Концентрация",
            "Кратковременная память",
            "Скорость восприятия",
            "Визуальная обработка",
            "Когнитивный контроль"
        ]
        return skills.map { ($0, skillProgress($0)) }
    }
}
