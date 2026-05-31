import Foundation
import SwiftUI
import Combine

struct SequenceColorOption: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let color: Color
}

final class SequenceMemoryViewModel: ObservableObject {
    @Published var options: [SequenceColorOption] = []
    @Published var sequence: [SequenceColorOption] = []
    @Published var highlightedID: UUID?
    @Published var inputIndex = 0
    @Published var correctAnswers = 0
    @Published var wrongAnswers = 0
    @Published var elapsedTime: TimeInterval = 0
    @Published var isShowingSequence = false
    @Published var isInputActive = false
    @Published var isGameActive = false
    @Published var isGameCompleted = false
    
    private var difficulty: DifficultyLevel = .level1
    private var startTime: Date?
    private var inputStartTime: Date?
    private var timer: Timer?
    private var reactionTimes: [TimeInterval] = []
    private var playbackToken = UUID()
    
    private let allOptions: [SequenceColorOption] = [
        SequenceColorOption(name: "Красный", color: .red),
        SequenceColorOption(name: "Синий", color: .blue),
        SequenceColorOption(name: "Зелёный", color: .green),
        SequenceColorOption(name: "Жёлтый", color: .yellow),
        SequenceColorOption(name: "Фиолетовый", color: .purple),
        SequenceColorOption(name: "Оранжевый", color: .orange)
    ]
    
    func setup(difficulty: DifficultyLevel) {
        self.difficulty = difficulty
        let config = DifficultyConfig(level: difficulty)
        options = Array(allOptions.prefix(config.sequenceOptionsCount))
        resetGame()
    }
    
    func startGame() {
        guard !options.isEmpty else { return }
        resetCounters()
        isGameActive = true
        isGameCompleted = false
        startTime = Date()
        startTimer()
        
        let length = DifficultyConfig(level: difficulty).sequenceLength
        sequence = (0..<length).compactMap { _ in options.randomElement() }
        showSequence()
    }
    
    func select(_ option: SequenceColorOption) {
        guard isInputActive, inputIndex < sequence.count else { return }
        
        if let started = inputStartTime {
            reactionTimes.append(Date().timeIntervalSince(started))
        }
        inputStartTime = Date()
        
        if option.name == sequence[inputIndex].name {
            correctAnswers += 1
        } else {
            wrongAnswers += 1
        }
        
        inputIndex += 1
        if inputIndex >= sequence.count {
            completeGame()
        }
    }
    
    func resetGame() {
        playbackToken = UUID()
        timer?.invalidate()
        timer = nil
        resetCounters()
        sequence = []
        highlightedID = nil
        isShowingSequence = false
        isInputActive = false
        isGameActive = false
        isGameCompleted = false
        startTime = nil
        inputStartTime = nil
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
    
    private func resetCounters() {
        inputIndex = 0
        correctAnswers = 0
        wrongAnswers = 0
        elapsedTime = 0
        reactionTimes = []
    }
    
    private func showSequence() {
        let token = UUID()
        playbackToken = token
        isShowingSequence = true
        isInputActive = false
        
        for (index, item) in sequence.enumerated() {
            let delay = Double(index) * 0.75
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                guard let self, self.playbackToken == token else { return }
                self.highlightedID = item.id
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + delay + 0.45) { [weak self] in
                guard let self, self.playbackToken == token else { return }
                self.highlightedID = nil
            }
        }
        
        let finishDelay = Double(sequence.count) * 0.75 + 0.2
        DispatchQueue.main.asyncAfter(deadline: .now() + finishDelay) { [weak self] in
            guard let self, self.playbackToken == token else { return }
            self.isShowingSequence = false
            self.isInputActive = true
            self.inputStartTime = Date()
        }
    }
    
    private func completeGame() {
        timer?.invalidate()
        timer = nil
        isInputActive = false
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
