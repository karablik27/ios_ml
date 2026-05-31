import SwiftUI

struct SequenceMemoryView: View {
    @EnvironmentObject var userStats: UserStats
    @StateObject private var viewModel = SequenceMemoryViewModel()
    @StateObject private var adaptiveEngine = AdaptiveEngine()
    
    @State private var selectedDifficulty: DifficultyLevel = .level1
    @State private var showResultSheet = false
    @State private var showInfoSheet = false
    @State private var session: ExerciseSession?
    
    var body: some View {
        VStack(spacing: 20) {
            headerView
            statusView
            colorGrid
            Spacer()
            controlsArea
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Последовательность")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showInfoSheet = true }) {
                    Image(systemName: "info.circle")
                }
            }
        }
        .sheet(isPresented: $showInfoSheet) {
            ExerciseInfoSheet(exercise: .sequence)
        }
        .onAppear {
            selectedDifficulty = userStats.recommendedDifficulty(for: .sequence)
            viewModel.setup(difficulty: selectedDifficulty)
        }
        .onChange(of: viewModel.isGameCompleted) { _, completed in
            if completed {
                finishGame()
            }
        }
        .sheet(isPresented: $showResultSheet) {
            ResultSheet(
                session: session,
                recommendation: adaptiveEngine.currentRecommendation,
                analysis: adaptiveEngine.analysisResult,
                onContinue: {
                    showResultSheet = false
                }
            )
        }
    }
    
    private var headerView: some View {
        HStack(spacing: 12) {
            GameStatPill(title: "Время", value: formatTime(viewModel.elapsedTime), icon: "clock.fill", color: .blue)
            
            Spacer()
            
            GameStatPill(
                title: "Шаг",
                value: "\(viewModel.inputIndex)/\(max(viewModel.sequence.count, DifficultyConfig(level: selectedDifficulty).sequenceLength))",
                icon: "point.3.connected.trianglepath.dotted",
                color: .purple
            )
            GameStatPill(title: "Ошибки", value: "\(viewModel.wrongAnswers)", icon: "xmark.circle.fill", color: .red)
        }
    }
    
    private var statusView: some View {
        VStack(spacing: 10) {
            Image(systemName: statusIcon)
                .font(.system(size: 38, weight: .semibold))
                .foregroundColor(statusColor)
            
            Text(statusText)
                .font(.headline)
                .multilineTextAlignment(.center)
                .frame(minHeight: 44)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .gameCard()
    }
    
    private var colorGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
            ForEach(viewModel.options) { option in
                Button(action: { viewModel.select(option) }) {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(option.color)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(viewModel.highlightedID == option.id ? Color.primary : Color.clear, lineWidth: 5)
                        )
                        .overlay(
                            Text(option.name)
                                .font(.headline)
                                .foregroundColor(.white)
                                .shadow(radius: 2)
                        )
                        .frame(height: 92)
                        .scaleEffect(viewModel.highlightedID == option.id ? 1.06 : 1.0)
                        .animation(.easeInOut(duration: 0.15), value: viewModel.highlightedID)
                }
                .disabled(!viewModel.isInputActive)
                .buttonStyle(ScaleButtonStyle())
            }
        }
    }
    
    private var controlsArea: some View {
        VStack(spacing: 12) {
            GameDifficultyControl(
                selectedDifficulty: $selectedDifficulty,
                isLocked: viewModel.isGameActive,
                onChange: { viewModel.setup(difficulty: $0) }
            )
            
            GameActionButton(
                title: viewModel.isGameActive ? "Стоп" : "Начать",
                icon: viewModel.isGameActive ? "stop.fill" : "play.fill",
                color: viewModel.isGameActive ? .red : .accentColor,
                action: {
                viewModel.isGameActive ? viewModel.resetGame() : viewModel.startGame()
            })
        }
    }
    
    private var statusText: String {
        if viewModel.isShowingSequence { return "Запоминайте порядок" }
        if viewModel.isInputActive { return "Повторите последовательность" }
        return "Нажмите «Начать»"
    }
    
    private var statusIcon: String {
        if viewModel.isShowingSequence { return "eye.fill" }
        if viewModel.isInputActive { return "hand.tap.fill" }
        return "play.circle.fill"
    }
    
    private var statusColor: Color {
        if viewModel.isShowingSequence { return .blue }
        if viewModel.isInputActive { return .green }
        return .accentColor
    }
    
    private func finishGame() {
        guard let metrics = viewModel.getSessionMetrics() else { return }
        
        session = ExerciseSession(
            exerciseType: .sequence,
            difficulty: selectedDifficulty,
            startTime: Date().addingTimeInterval(-metrics.totalTime),
            endTime: Date(),
            metrics: metrics
        )
        
        if let session {
            let result = GameResult(from: session)
            userStats.addResult(result)
            _ = adaptiveEngine.analyze(exercise: .sequence, recentResults: userStats.results(for: .sequence, last: 5))
            applyRecommendation()
            showResultSheet = true
        }
    }
    
    private func applyRecommendation() {
        let nextDifficulty = adaptiveEngine.nextDifficulty(for: .sequence, current: selectedDifficulty, in: userStats)
        selectedDifficulty = nextDifficulty
        userStats.updateDifficulty(for: .sequence, to: nextDifficulty)
        viewModel.setup(difficulty: nextDifficulty)
        viewModel.resetGame()
    }
    
    private func formatTime(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func levelColor(_ level: DifficultyLevel) -> Color {
        switch level.rawValue {
        case 1...3: return .green
        case 4...6: return .orange
        case 7...8: return .red
        default: return .gray
        }
    }
}
