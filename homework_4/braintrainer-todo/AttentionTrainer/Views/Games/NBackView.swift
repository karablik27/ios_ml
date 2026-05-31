import SwiftUI

struct NBackView: View {
    @EnvironmentObject var userStats: UserStats
    @StateObject private var viewModel = NBackViewModel()
    @StateObject private var adaptiveEngine = AdaptiveEngine()
    
    @State private var selectedDifficulty: DifficultyLevel = .level1
    @State private var showResultSheet = false
    @State private var showInfoSheet = false
    @State private var session: ExerciseSession?
    
    var body: some View {
        VStack(spacing: 20) {
            headerView
            
            Spacer()
            
            stimulusDisplay
            
            Spacer()
            
            // Показываем историю только на простых уровнях (1-3)
            if selectedDifficulty.rawValue <= 3 {
                historyView
                
                Spacer()
            }
            
            controlsArea
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .navigationTitle("N-Back (\(viewModel.n)-back)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showInfoSheet = true }) {
                    Image(systemName: "info.circle")
                }
            }
        }
        .sheet(isPresented: $showInfoSheet) {
            ExerciseInfoSheet(exercise: .nback)
        }
        .onAppear {
            selectedDifficulty = userStats.recommendedDifficulty(for: .nback)
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
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Раунд \(viewModel.currentIteration)/\(viewModel.totalIterations)")
                    .font(.headline)
                
                if viewModel.isGameActive {
                    Text("Нажмите, когда буква повторяется через \(viewModel.n)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            ProgressView(value: Double(viewModel.currentIteration), total: Double(viewModel.totalIterations))
                .frame(width: 100)
                .tint(.accentColor)
        }
        .padding()
        .gameCard()
    }
    
    private var stimulusDisplay: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 40, style: .continuous)
                .fill(Color.accentColor.opacity(0.12))
                .frame(width: 200, height: 200)
            
            if viewModel.isGameActive {
                Text(viewModel.currentStimulus)
                    .font(.system(size: 80, weight: .bold, design: .rounded))
                    .foregroundColor(.accentColor)
                    .transition(.scale.combined(with: .opacity))
                    .id(viewModel.currentStimulus)
            } else {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 60))
                    .foregroundColor(.secondary)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.currentStimulus)
    }
    
    private var historyView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("История")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(viewModel.stimulusHistory.count)/\(viewModel.totalIterations)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    // Показываем только последние 10 элементов для экономии места
                    let displayCount = min(viewModel.stimulusHistory.count, 10)
                    let startIndex = max(0, viewModel.stimulusHistory.count - 10)
                    
                    ForEach(Array(viewModel.stimulusHistory[startIndex..<startIndex+displayCount].enumerated()), id: \.offset) { offset, stimulus in
                        let actualIndex = startIndex + offset
                        Text(stimulus)
                            .font(.caption)
                            .fontWeight(.medium)
                            .frame(width: 32, height: 32)
                            .background(
                                Circle()
                                    .fill(backgroundColor(for: actualIndex))
                            )
                            .foregroundColor(.primary)
                    }
                }
            }
            .frame(height: 40)
            // Сдвигаем влево на полкружочка (16pt)
            .padding(.leading, -16)
        }
        .padding()
        .gameCard()
    }
    
    private var controlsArea: some View {
        VStack(spacing: 16) {
            // Match button
            if viewModel.isGameActive {
                GameActionButton(
                    title: "Совпадение!",
                    icon: "hand.tap.fill",
                    color: .green,
                    action: {
                    viewModel.userResponded()
                })
            }
            
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
    
    private func backgroundColor(for index: Int) -> Color {
        // Подсвечиваем совпадения
        if index >= viewModel.n {
            let current = viewModel.stimulusHistory[index]
            let previous = viewModel.stimulusHistory[index - viewModel.n]
            if current == previous {
                return .green.opacity(0.3)
            }
        }
        return Color(.tertiarySystemFill)
    }
    
    private func finishGame() {
        guard let metrics = viewModel.getSessionMetrics() else { return }
        
        session = ExerciseSession(
            exerciseType: .nback,
            difficulty: selectedDifficulty,
            startTime: Date().addingTimeInterval(-metrics.totalTime),
            endTime: Date(),
            metrics: metrics
        )
        
        if let session = session {
            let result = GameResult(from: session)
            userStats.addResult(result)
            
            let recent = userStats.results(for: .nback, last: 5)
            _ = adaptiveEngine.analyze(exercise: .nback, recentResults: recent)
            
            // Автоматически применяем рекомендацию
            applyRecommendation()
            
            showResultSheet = true
        }
    }
    
    private func applyRecommendation() {
        let nextDifficulty = adaptiveEngine.nextDifficulty(
            for: .nback,
            current: selectedDifficulty,
            in: userStats
        )
        selectedDifficulty = nextDifficulty
        userStats.updateDifficulty(for: .nback, to: nextDifficulty)
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

// MARK: - Button Style

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
