import SwiftUI

struct NumbersView: View {
    @EnvironmentObject var userStats: UserStats
    @StateObject private var viewModel = NumbersViewModel()
    @StateObject private var adaptiveEngine = AdaptiveEngine()
    
    @State private var selectedDifficulty: DifficultyLevel = .level1
    @State private var showResultSheet = false
    @State private var showInfoSheet = false
    @State private var session: ExerciseSession?
    
    var body: some View {
        VStack(spacing: 16) {
            headerView
            
            // Center hint numbers
            if viewModel.showCenter && viewModel.isGameActive {
                centerHintsView
            }
            
            // Game columns
            gameColumns
            
            Spacer()
            
            controlsArea
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Поиск чисел")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showInfoSheet = true }) {
                    Image(systemName: "info.circle")
                }
            }
        }
        .sheet(isPresented: $showInfoSheet) {
            ExerciseInfoSheet(exercise: .numbers)
        }
        .onAppear {
            selectedDifficulty = userStats.recommendedDifficulty(for: .numbers)
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
    
    private var centerHintsView: some View {
        VStack(spacing: 8) {
            Text("Ищите эти числа:")
                .font(.caption)
                .foregroundColor(.secondary)
            
            FlowLayout(spacing: 8) {
                ForEach(viewModel.centerNumbers, id: \.self) { number in
                    if viewModel.foundPairs.contains(number) {
                        EmptyView()
                    } else {
                        Text("\(number)")
                            .font(.headline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(Color.accentColor.opacity(0.2))
                            )
                            .foregroundColor(.accentColor)
                    }
                }
            }
        }
        .padding()
        .gameCard()
    }
    
    private var gameColumns: some View {
        HStack(spacing: 20) {
            VStack(spacing: 8) {
                Text("Левая")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                ForEach(viewModel.leftColumn, id: \.self) { number in
                    numberButton(number, side: .left)
                }
            }
            
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 1)
            
            VStack(spacing: 8) {
                Text("Правая")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                ForEach(viewModel.rightColumn, id: \.self) { number in
                    numberButton(number, side: .right)
                }
            }
        }
        .padding()
        .gameCard()
    }
    
    private func numberButton(_ number: Int, side: NumbersViewModel.Side) -> some View {
        let isFound = viewModel.foundPairs.contains(number)
        
        return Button(action: {
            viewModel.selectNumber(number, fromSide: side)
        }) {
            Text("\(number)")
                .font(.title2)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isFound ? Color.green : Color(.tertiarySystemFill))
                )
                .foregroundColor(isFound ? .white : .primary)
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
            exerciseType: .numbers,
            difficulty: selectedDifficulty,
            startTime: Date().addingTimeInterval(-metrics.totalTime),
            endTime: Date(),
            metrics: metrics
        )
        
        if let session = session {
            let result = GameResult(from: session)
            userStats.addResult(result)
            
            let recent = userStats.results(for: .numbers, last: 5)
            _ = adaptiveEngine.analyze(exercise: .numbers, recentResults: recent)
            
            // Автоматически применяем рекомендацию
            applyRecommendation()
            
            showResultSheet = true
        }
    }
    
    private func applyRecommendation() {
        let nextDifficulty = adaptiveEngine.nextDifficulty(
            for: .numbers,
            current: selectedDifficulty,
            in: userStats
        )
        selectedDifficulty = nextDifficulty
        userStats.updateDifficulty(for: .numbers, to: nextDifficulty)
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
