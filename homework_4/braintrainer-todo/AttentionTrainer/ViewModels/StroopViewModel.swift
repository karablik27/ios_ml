import Foundation
import SwiftUI
import Combine

struct StroopColorOption: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let color: Color
}

final class StroopViewModel: ObservableObject {
    @Published var currentWord: StroopColorOption?
    @Published var currentInk: StroopColorOption?
    @Published var options: [StroopColorOption] = []
    @Published var currentRound = 0
    @Published var totalRounds = 10
    @Published var correctAnswers = 0
    @Published var wrongAnswers = 0
    @Published var elapsedTime: TimeInterval = 0
    @Published var isGameActive = false
    @Published var isGameCompleted = false
    
    private var difficulty: DifficultyLevel = .level1
    private var startTime: Date?
    private var roundStartTime: Date?
    private var timer: Timer?
    private var reactionTimes: [TimeInterval] = []
    
    private let allOptions: [StroopColorOption] = [
        StroopColorOption(name: "Красный", color: .red),
        StroopColorOption(name: "Синий", color: .blue),
        StroopColorOption(name: "Зелёный", color: .green),
        StroopColorOption(name: "Жёлтый", color: .yellow),
        StroopColorOption(name: "Фиолетовый", color: .purple),
        StroopColorOption(name: "Оранжевый", color: .orange)
    ]
    
    func setup(difficulty: DifficultyLevel) {
        self.difficulty = difficulty
        let config = DifficultyConfig(level: difficulty)
        totalRounds = config.stroopRounds
        options = Array(allOptions.prefix(config.stroopOptionsCount))
        resetGame()
    }
    
    func startGame() {
        guard !options.isEmpty else { return }
        correctAnswers = 0
        wrongAnswers = 0
        currentRound = 0
        elapsedTime = 0
        reactionTimes = []
        isGameActive = true
        isGameCompleted = false
        startTime = Date()
        startTimer()
        nextRound()
    }
    
    func select(_ option: StroopColorOption) {
        guard isGameActive, let currentInk else { return }
        
        if let started = roundStartTime {
            reactionTimes.append(Date().timeIntervalSince(started))
        }
        
        if option.name == currentInk.name {
            correctAnswers += 1
        } else {
            wrongAnswers += 1
        }
        
        currentRound += 1
        if currentRound >= totalRounds {
            completeGame()
        } else {
            nextRound()
        }
    }
    
    func resetGame() {
        timer?.invalidate()
        timer = nil
        isGameActive = false
        isGameCompleted = false
        currentWord = nil
        currentInk = nil
        currentRound = 0
        elapsedTime = 0
        correctAnswers = 0
        wrongAnswers = 0
        reactionTimes = []
        startTime = nil
        roundStartTime = nil
    }
    
    func getSessionMetrics() -> SessionMetrics? {
        guard isGameCompleted, let startTime else { return nil }
        let totalTime = max(Date().timeIntervalSince(startTime), 0.1)
        let totalAttempts = correctAnswers + wrongAnswers
        let accuracy = totalAttempts > 0 ? Double(correctAnswers) / Double(totalAttempts) : 0
        let avgReaction = reactionTimes.isEmpty ? 0 : reactionTimes.reduce(0, +) / Double(reactionTimes.count)
        
        return SessionMetrics(
            totalTime: totalTime,
            correctAnswers: correctAnswers,
            incorrectAnswers: wrongAnswers,
            averageReactionTime: avgReaction,
            accuracy: accuracy
        )
    }
    
    private func nextRound() {
        currentWord = options.randomElement()
        currentInk = options.randomElement()
        roundStartTime = Date()
    }
    
    private func completeGame() {
        timer?.invalidate()
        timer = nil
        isGameActive = false
        isGameCompleted = true
    }
    
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self, let startTime = self.startTime else { return }
            self.elapsedTime = Date().timeIntervalSince(startTime)
        }
    }
}
