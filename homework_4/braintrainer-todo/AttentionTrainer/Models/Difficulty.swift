import Foundation

// MARK: - Уровни сложности

/// Перечисление уровней сложности для всех мини-игр
///
/// Поддерживается 8 уровней сложности (1-8)
/// Каждый уровень влияет на параметры игр через `DifficultyConfig`
///
/// ## Прогрессия сложности:
/// - Уровни 1-3 (🟢 зеленые): Начальные, простые
/// - Уровни 4-6 (🟠 оранжевые): Средние
/// - Уровни 7-8 (🔴 красные): Сложные
///
/// ## Использование:
/// ```swift
/// let level: DifficultyLevel = .level5
/// print(level.title) // "Уровень 5"
/// print(level.rawValue) // 5
/// ```
enum DifficultyLevel: Int, CaseIterable, Identifiable {
    // MARK: - Случаи
    
    case level1 = 1
    case level2 = 2
    case level3 = 3
    case level4 = 4
    case level5 = 5
    case level6 = 6
    case level7 = 7
    case level8 = 8
    
    // MARK: - Свойства
    
    /// Уникальный идентификатор (используется SwiftUI)
    var id: Int { rawValue }
    
    /// Полное название уровня (например "Уровень 5")
    var title: String {
        return "Уровень \(rawValue)"
    }
    
    /// Короткое название (только цифра, например "5")
    var shortTitle: String {
        return "\(rawValue)"
    }
    
    /// Иконка SF Symbols для уровня
    /// - 1-3: звезда (star)
    /// - 4-6: звезда закрашенная (star.fill)
    /// - 7-8: пламя (flame.fill)
    var icon: String {
        switch rawValue {
        case 1...3: return "star"
        case 4...6: return "star.fill"
        case 7...8: return "flame.fill"
        default: return "star"
        }
    }
    
    /// Название цвета для UI
    /// - 1-3: зеленый
    /// - 4-6: оранжевый
    /// - 7-8: красный
    var color: String {
        switch rawValue {
        case 1...3: return "green"
        case 4...6: return "orange"
        case 7...8: return "red"
        default: return "green"
        }
    }
    
    // MARK: - Константы
    
    /// Минимальный уровень (1)
    static var min: Int { 1 }
    
    /// Максимальный уровень (8)
    static var max: Int { 8 }
}

// MARK: - Конфигурация сложности

/// Структура для получения параметров игры на основе уровня сложности
///
/// Использование:
/// ```swift
/// let config = DifficultyConfig(level: .level5)
/// let gridSize = config.schulteGridSize // 7 для уровня 5
/// ```
struct DifficultyConfig {
    
    // MARK: - Свойства
    
    /// Текущий уровень сложности
    let level: DifficultyLevel
    
    // MARK: - Параметры для Таблицы Шульте
    
    /// Размер сетки (3x3 до 10x10)
    ///
    /// Прогрессия:
    /// - Уровень 1: 3x3 (9 чисел)
    /// - Уровень 8: 10x10 (100 чисел)
    var schulteGridSize: Int {
        // Level 1 = 3x3, Level 8 = 10x10
        return min(10, 3 + level.rawValue - 1)
    }
    
    // MARK: - Параметры для N-Back
    
    /// Значение N (сколько шагов назад помнить)
    ///
    /// Прогрессия:
    /// - Уровни 1-3: N=1 (предыдущий стимул)
    /// - Уровни 4-6: N=2 (2 назад)
    /// - Уровни 7-8: N=3 (3 назад)
    var nBackN: Int {
        switch level.rawValue {
        case 1...3: return 1
        case 4...6: return 2
        case 7...8: return 3
        default: return 1
        }
    }
    
    /// Интервал между стимулами в секундах
    ///
    /// Прогрессия:
    /// - Уровень 1: 2.5 сек
    /// - Уровень 8: 0.9 сек
    var nBackInterval: Double {
        return max(0.9, 2.5 - Double(level.rawValue - 1) * 0.23)
    }
    
    /// Количество итераций (сколько букв показать)
    ///
    /// Прогрессия:
    /// - Уровень 1: 12 итераций
    /// - Уровень 8: 26 итераций
    var nBackIterations: Int {
        return 10 + level.rawValue * 2
    }
    
    // MARK: - Параметры для Поиска чисел
    
    /// Размер колонки (сколько чисел показывать)
    ///
    /// Прогрессия:
    /// - Уровень 1: 5 чисел
    /// - Уровень 8: 12 чисел
    var numbersColumnSize: Int {
        return 4 + level.rawValue
    }
    
    /// Количество совпадающих пар для поиска
    ///
    /// Прогрессия:
    /// - Уровень 1: 2 пары
    /// - Уровень 8: 6 пар
    var numbersMatchingPairs: Int {
        return 2 + level.rawValue / 2
    }
    
    /// Показывать ли подсказки в центре
    ///
    /// Отключается на высоких уровнях для усложнения:
    /// - Уровни 1-4: показывать подсказки
    /// - Уровни 5-8: скрыть подсказки
    var numbersShowHints: Bool {
        return level.rawValue <= 4
    }
    
    // MARK: - Параметры для Поиска цветов
    
    /// Размер колонки (сколько цветов показывать)
    ///
    /// Прогрессия:
    /// - Уровень 1: 5 цветов
    /// - Уровень 8: 12 цветов
    var colorsColumnSize: Int {
        return 4 + level.rawValue
    }
    
    /// Количество совпадающих пар цветов
    ///
    /// Прогрессия:
    /// - Уровень 1: 2 пары
    /// - Уровень 8: 5 пар
    var colorsMatchingPairs: Int {
        return 2 + level.rawValue / 2
    }
    
    // MARK: - Параметры для Stroop-теста
    
    /// Количество заданий в Stroop-тесте
    var stroopRounds: Int {
        return 8 + level.rawValue * 2
    }
    
    /// Количество вариантов ответа в Stroop-тесте
    var stroopOptionsCount: Int {
        return level.rawValue >= 5 ? 5 : 4
    }
    
    // MARK: - Параметры для Запоминания последовательности
    
    /// Длина последовательности для запоминания
    var sequenceLength: Int {
        return 3 + level.rawValue
    }
    
    /// Количество доступных цветов в игре последовательности
    var sequenceOptionsCount: Int {
        return min(6, 3 + level.rawValue / 2)
    }
    
    // MARK: - Устаревшие/синонимы (для совместимости)
    
    /// Устаревшее свойство - используйте numbersColumnSize или colorsColumnSize
    @available(*, deprecated, message: "Используйте numbersColumnSize или colorsColumnSize")
    var columnSize: Int {
        return 4 + level.rawValue
    }
    
    /// Устаревшее свойство - используйте numbersShowHints
    @available(*, deprecated, message: "Используйте numbersShowHints")
    var showCenterNumbers: Bool {
        return level.rawValue <= 4
    }
    
    /// Устаревшее свойство
    @available(*, deprecated)
    var matchingPairsCount: Int {
        return 2 + (level.rawValue - 1) / 2
    }
}
