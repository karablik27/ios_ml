import Foundation
import SwiftUI
import Combine

class NumbersViewModel: ObservableObject {
    @Published var leftColumn: [Int] = []
    @Published var rightColumn: [Int] = []
    @Published var centerNumbers: [Int] = []
    @Published var showCenter: Bool = true
    @Published var isGameActive = false
    @Published var isGameCompleted = false
    @Published var foundPairs: Set<Int> = []
    @Published var elapsedTime: TimeInterval = 0
    @Published var wrongAttempts = 0
    
    private var columnSize: Int = 5
    private var currentLevel: DifficultyLevel = .level1
    private var startTime: Date?
    private var timer: Timer?
    private var reactionTimes: [TimeInterval] = []
    private var lastSelectionTime: Date?
    
    func setup(difficulty: DifficultyLevel) {
        let config = DifficultyConfig(level: difficulty)
        currentLevel = difficulty
        columnSize = config.numbersColumnSize
        showCenter = config.numbersShowHints
    }
    
    func startGame() {
        generateNumbers()
        isGameActive = true
        isGameCompleted = false
        foundPairs.removeAll()
        wrongAttempts = 0
        elapsedTime = 0
        startTime = Date()
        lastSelectionTime = startTime
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let start = self.startTime else { return }
            self.elapsedTime = Date().timeIntervalSince(start)
        }
    }
    
    func selectNumber(_ number: Int, fromSide: Side) {
        guard isGameActive, !foundPairs.contains(number) else { return }
        
        let now = Date()
        if let last = lastSelectionTime {
            reactionTimes.append(now.timeIntervalSince(last))
        }
        lastSelectionTime = now
        
        // Проверяем, есть ли это число в обеих колонках
        let isInLeft = leftColumn.contains(number)
        let isInRight = rightColumn.contains(number)
        
        // Число должно быть в обеих колонках
        if isInLeft && isInRight {
            foundPairs.insert(number)
            
            #if os(iOS)
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            #endif
            
            // Проверка завершения (все пары найдены)
            checkCompletion()
        } else {
            wrongAttempts += 1
            
            #if os(iOS)
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
            #endif
        }
    }
    
    private func checkCompletion() {
        // Считаем, сколько пар должно быть найдено
        let leftSet = Set(leftColumn)
        let rightSet = Set(rightColumn)
        let totalPairs = leftSet.intersection(rightSet).count
        
        if foundPairs.count >= totalPairs {
            completeGame()
        }
    }
    
    private func completeGame() {
        timer?.invalidate()
        isGameActive = false
        isGameCompleted = true
    }
    
    func resetGame() {
        timer?.invalidate()
        isGameActive = false
        isGameCompleted = false
        leftColumn = []
        rightColumn = []
        centerNumbers = []
        foundPairs.removeAll()
        elapsedTime = 0
        wrongAttempts = 0
        reactionTimes = []
    }
    
    private func generateNumbers() {
        // Создаём пары (числа, которые будут в обеих колонках)
        let config = DifficultyConfig(level: currentLevel)
        let pairCount = config.numbersMatchingPairs
        var pairs: [Int] = []
        
        for _ in 0..<pairCount {
            var num: Int
            repeat {
                num = Int.random(in: 1...99)
            } while pairs.contains(num)
            pairs.append(num)
        }
        
        // Генерируем уникальные числа для левой колонки
        var leftUnique: [Int] = []
        while leftUnique.count < columnSize - pairCount {
            var num: Int
            repeat {
                num = Int.random(in: 1...99)
            } while pairs.contains(num) || leftUnique.contains(num)
            leftUnique.append(num)
        }
        
        // Генерируем уникальные числа для правой колонки
        var rightUnique: [Int] = []
        while rightUnique.count < columnSize - pairCount {
            var num: Int
            repeat {
                num = Int.random(in: 1...99)
            } while pairs.contains(num) || leftUnique.contains(num) || rightUnique.contains(num)
            rightUnique.append(num)
        }
        
        // Формируем колонки: пары + уникальные числа
        leftColumn = pairs + leftUnique
        rightColumn = pairs + rightUnique
        
        // Перемешиваем каждую колонку отдельно
        leftColumn.shuffle()
        rightColumn.shuffle()
        
        // Генерируем центральные числа (подсказки)
        if showCenter {
            centerNumbers = pairs.shuffled()
        } else {
            centerNumbers = []
        }
    }
    
    // MARK: - Метрики
    
    func getSessionMetrics() -> SessionMetrics? {
        guard isGameCompleted, let start = startTime else { return nil }
        
        let totalTime = Date().timeIntervalSince(start)
        let correct = foundPairs.count
        let totalAttempts = correct + wrongAttempts
        let accuracy = totalAttempts > 0 ? Double(correct) / Double(totalAttempts) : 0
        let avgReaction = reactionTimes.isEmpty ? 0 : reactionTimes.reduce(0, +) / Double(reactionTimes.count)
        
        return SessionMetrics(
            totalTime: totalTime,
            correctAnswers: correct,
            incorrectAnswers: wrongAttempts,
            averageReactionTime: avgReaction,
            accuracy: accuracy
        )
    }
    
    enum Side {
        case left, right
    }
}
