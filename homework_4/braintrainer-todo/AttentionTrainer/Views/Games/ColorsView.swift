import SwiftUI

struct ColorsView: View {
    @EnvironmentObject var userStats: UserStats
    @StateObject private var viewModel = ColorsViewModel()
    @StateObject private var adaptiveEngine = AdaptiveEngine()
    
    @State private var selectedDifficulty: DifficultyLevel = .level1
    @State private var showResultSheet = false
    @State private var showInfoSheet = false
    @State private var session: ExerciseSession?
    
    var body: some View {
        VStack(spacing: 16) {
            headerView
            
            // Game columns
            gameColumns
            
            Spacer()
            
            controlsArea
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Поиск цветов")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showInfoSheet = true }) {
                    Image(systemName: "info.circle")
                }
            }
        }
        .sheet(isPresented: $showInfoSheet) {
            ExerciseInfoSheet(exercise: .colors)
        }
        .onAppear {
            selectedDifficulty = userStats.recommendedDifficulty(for: .colors)
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
            
            GameStatPill(title: "Найдено", value: "\(viewModel.foundPairs.count)", icon: "checkmark.circle.fill", color: .green)
            GameStatPill(title: "Ошибки", value: "\(viewModel.wrongAttempts)", icon: "xmark.circle.fill", color: .red)
        }
    }
    
    private var gameColumns: some View {
        HStack(spacing: 20) {
            VStack(spacing: 8) {
                Text("Левая")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                ForEach(viewModel.leftColors) { colorOption in
                    colorButton(colorOption, side: .left)
                }
            }
            
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 1)
            
            VStack(spacing: 8) {
                Text("Правая")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                ForEach(viewModel.rightColors) { colorOption in
                    colorButton(colorOption, side: .right)
                }
            }
        }
        .padding()
        .gameCard()
    }
    
    private func colorButton(_ colorOption: ColorOption, side: ColorsViewModel.Side) -> some View {
        let isFound = viewModel.foundPairs.contains(colorOption.name)
        
        return Button(action: {
            viewModel.selectColor(colorOption, fromSide: side)
        }) {
            RoundedRectangle(cornerRadius: 8)
                .fill(colorOption.color)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isFound ? Color.green : Color.clear, lineWidth: 3)
                )
                .overlay(
                    isFound ?
                    Image(systemName: "checkmark")
                        .font(.title2)
                        .foregroundColor(.white)
                        .shadow(radius: 2)
                    : nil
                )
        }
        .disabled(isFound || !viewModel.isGameActive)
        .buttonStyle(PlainButtonStyle())
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
                if viewModel.isGameActive {
                    viewModel.resetGame()
                } else {
                    viewModel.startGame()
                }
            })
        }
    }
    
    private func formatTime(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func finishGame() {
        guard let metrics = viewModel.getSessionMetrics() else { return }
        
        session = ExerciseSession(
            exerciseType: .colors,
            difficulty: selectedDifficulty,
            startTime: Date().addingTimeInterval(-metrics.totalTime),
            endTime: Date(),
            metrics: metrics
        )
        
        if let session = session {
            let result = GameResult(from: session)
            userStats.addResult(result)
            
            let recent = userStats.results(for: .colors, last: 5)
            _ = adaptiveEngine.analyze(exercise: .colors, recentResults: recent)
            
            // Автоматически применяем рекомендацию
            applyRecommendation()
            
            showResultSheet = true
        }
    }
    
    private func applyRecommendation() {
        let nextDifficulty = adaptiveEngine.nextDifficulty(
            for: .colors,
            current: selectedDifficulty,
            in: userStats
        )
        selectedDifficulty = nextDifficulty
        userStats.updateDifficulty(for: .colors, to: nextDifficulty)
        viewModel.setup(difficulty: nextDifficulty)
        viewModel.resetGame()
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
