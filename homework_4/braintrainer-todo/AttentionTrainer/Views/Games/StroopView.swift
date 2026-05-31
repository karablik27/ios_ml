import SwiftUI

struct StroopView: View {
    @EnvironmentObject var userStats: UserStats
    @StateObject private var viewModel = StroopViewModel()
    @StateObject private var adaptiveEngine = AdaptiveEngine()
    
    @State private var selectedDifficulty: DifficultyLevel = .level1
    @State private var showResultSheet = false
    @State private var showInfoSheet = false
    @State private var session: ExerciseSession?
    
    var body: some View {
        VStack(spacing: 20) {
            headerView
            promptView
            optionsGrid
            Spacer()
            controlsArea
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Stroop-тест")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showInfoSheet = true }) {
                    Image(systemName: "info.circle")
                }
            }
        }
        .sheet(isPresented: $showInfoSheet) {
            ExerciseInfoSheet(exercise: .stroop)
        }
        .onAppear {
            selectedDifficulty = userStats.recommendedDifficulty(for: .stroop)
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
                title: "Раунд",
                value: "\(min(viewModel.currentRound + 1, viewModel.totalRounds))/\(viewModel.totalRounds)",
                icon: "circle.grid.cross.fill",
                color: .purple
            )
            GameStatPill(title: "Ошибки", value: "\(viewModel.wrongAnswers)", icon: "xmark.circle.fill", color: .red)
        }
    }
    
    private var promptView: some View {
        VStack(spacing: 12) {
            Text("Выберите цвет текста")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(viewModel.currentWord?.name ?? "Готовы?")
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(viewModel.currentInk?.color ?? .primary)
                .frame(maxWidth: .infinity)
                .frame(height: 160)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
    }
    
    private var optionsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(viewModel.options) { option in
                Button(action: { viewModel.select(option) }) {
                    HStack {
                        Circle()
                            .fill(option.color)
                            .frame(width: 18, height: 18)
                        Text(option.name)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color(.tertiarySystemFill))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .disabled(!viewModel.isGameActive)
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
    
    private func finishGame() {
        guard let metrics = viewModel.getSessionMetrics() else { return }
        
        session = ExerciseSession(
            exerciseType: .stroop,
            difficulty: selectedDifficulty,
            startTime: Date().addingTimeInterval(-metrics.totalTime),
            endTime: Date(),
            metrics: metrics
        )
        
        if let session {
            let result = GameResult(from: session)
            userStats.addResult(result)
            _ = adaptiveEngine.analyze(exercise: .stroop, recentResults: userStats.results(for: .stroop, last: 5))
            applyRecommendation()
            showResultSheet = true
        }
    }
    
    private func applyRecommendation() {
        let nextDifficulty = adaptiveEngine.nextDifficulty(for: .stroop, current: selectedDifficulty, in: userStats)
        selectedDifficulty = nextDifficulty
        userStats.updateDifficulty(for: .stroop, to: nextDifficulty)
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
