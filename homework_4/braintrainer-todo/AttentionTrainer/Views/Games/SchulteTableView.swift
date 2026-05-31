import SwiftUI

struct SchulteTableView: View {
    @EnvironmentObject var userStats: UserStats
    @StateObject private var viewModel = SchulteViewModel()
    @StateObject private var adaptiveEngine = AdaptiveEngine()
    
    @State private var selectedDifficulty: DifficultyLevel = .level1
    @State private var showResultSheet = false
    @State private var showInfoSheet = false
    @State private var session: ExerciseSession?
    
    var body: some View {
        VStack(spacing: 20) {
            headerView
            gameArea
            
            if viewModel.isGameActive {
                targetIndicator
            }
            
            Spacer()
            controlsArea
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Таблица Шульте")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showInfoSheet = true }) {
                    Image(systemName: "info.circle")
                }
            }
        }
        .sheet(isPresented: $showInfoSheet) {
            ExerciseInfoSheet(exercise: .schulte)
        }
        .onAppear {
            selectedDifficulty = userStats.recommendedDifficulty(for: .schulte)
            viewModel.setup(difficulty: selectedDifficulty)
        }
        .onChange(of: selectedDifficulty) { _, newValue in
            viewModel.setup(difficulty: newValue)
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
            GameStatPill(title: "Время", value: formatTime(viewModel.elapsedTime), icon: "clock.fill", color: .blue)
            
            Spacer()
            
            GameStatPill(title: "Ошибки", value: "\(viewModel.wrongAttempts)", icon: "xmark.circle.fill", color: .red)
        }
    }
    
    private var gameArea: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: viewModel.gridSize)
        
        return LazyVGrid(columns: columns, spacing: 8) {
            ForEach(0..<viewModel.numbers.count, id: \.self) { index in
                let number = viewModel.numbers[index]
                let isSelected = viewModel.selectedIndices.contains(index)
                let isNext = number == viewModel.currentTarget
                
                Button(action: {
                    viewModel.selectNumber(at: index)
                }) {
                    Text("\(number)")
                        .font(.system(size: fontSize, weight: .medium))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .aspectRatio(1, contentMode: .fit)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(backgroundColor(for: index, isSelected: isSelected, isNext: isNext))
                        )
                        .foregroundColor(isSelected ? .white : .primary)
                }
                .disabled(isSelected || !viewModel.isGameActive)
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding()
        .gameCard()
    }
    
    private var targetIndicator: some View {
        HStack {
            Text(viewModel.isReverseMode ? "Ищите:" : "Ищите:")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Иконка направления
            Image(systemName: viewModel.isReverseMode ? "arrow.down" : "arrow.up")
                .font(.caption)
                .foregroundColor(.accentColor)
            
            Text("\(viewModel.currentTarget)")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.accentColor)
                .frame(minWidth: 50)
        }
        .padding()
        .background(Color.accentColor.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
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
    
    private func levelColor(_ level: DifficultyLevel) -> Color {
        switch level.rawValue {
        case 1...3: return .green
        case 4...6: return .orange
        case 7...8: return .red
        default: return .gray
        }
    }
    
    // MARK: - Helpers
    
    private var fontSize: CGFloat {
        switch viewModel.gridSize {
        case 3: return 32
        case 4: return 28
        case 5: return 24
        case 6: return 20
        case 7: return 18
        case 8: return 16
        case 9: return 14
        case 10: return 12
        default: return 20
        }
    }
    
    private func backgroundColor(for index: Int, isSelected: Bool, isNext: Bool) -> Color {
        if isSelected {
            return .green
        } else if isNext && !viewModel.isGameActive {
            return .accentColor.opacity(0.3)
        } else {
            return Color(.tertiarySystemFill)
        }
    }
    
    private func formatTime(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        let tenths = Int((interval.truncatingRemainder(dividingBy: 1)) * 10)
        return String(format: "%d:%02d.%d", minutes, seconds, tenths)
    }
    
    private func finishGame() {
        guard let metrics = viewModel.getSessionMetrics() else { return }
        
        session = ExerciseSession(
            exerciseType: .schulte,
            difficulty: selectedDifficulty,
            startTime: Date().addingTimeInterval(-metrics.totalTime),
            endTime: Date(),
            metrics: metrics
        )
        
        if let session = session {
            let result = GameResult(from: session)
            userStats.addResult(result)
            
            // Анализируем для рекомендации
            let recent = userStats.results(for: .schulte, last: 5)
            _ = adaptiveEngine.analyze(exercise: .schulte, recentResults: recent)
            
            // Автоматически применяем рекомендацию
            applyRecommendation()
            
            showResultSheet = true
        }
    }
    
    private func applyRecommendation() {
        let nextDifficulty = adaptiveEngine.nextDifficulty(
            for: .schulte,
            current: selectedDifficulty,
            in: userStats
        )
        selectedDifficulty = nextDifficulty
        userStats.updateDifficulty(for: .schulte, to: nextDifficulty)
        viewModel.setup(difficulty: nextDifficulty)
        viewModel.resetGame()
    }
}

// MARK: - Result Sheet

struct ResultSheet: View {
    let session: ExerciseSession?
    let recommendation: DifficultyRecommendation
    let analysis: AnalysisResult?
    let onContinue: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    resultHero
                    
                    if let metrics = session?.metrics {
                        statsGrid(metrics: metrics)
                    }
                    
                    if let analysis = analysis {
                        analysisSection(analysis: analysis)
                    }
                    
                    recommendationSection
                    
                    Spacer()
                    
                    GameActionButton(title: "Продолжить", icon: "arrow.right", color: .accentColor, action: onContinue)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Результат")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Закрыть") {
                        dismiss()
                        onContinue()
                    }
                }
            }
        }
    }
    
    private var resultHero: some View {
        VStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(recommendationColor.opacity(0.16))
                    .frame(width: 96, height: 96)
                
                Image(systemName: recommendationIcon)
                    .font(.system(size: 46, weight: .bold))
                    .foregroundColor(recommendationColor)
            }
            
            VStack(spacing: 4) {
                Text("Сессия завершена")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(recommendation.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, 20)
    }
    
    private func statsGrid(metrics: SessionMetrics) -> some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            StatBox(title: "Время", value: formatTime(metrics.totalTime), icon: "clock.fill", color: .blue)
            StatBox(title: "Точность", value: String(format: "%.0f%%", metrics.accuracy * 100), icon: "target", color: .green)
            StatBox(title: "Ошибок", value: "\(metrics.incorrectAnswers)", icon: "xmark.circle.fill", color: .red)
            StatBox(title: "Очки", value: String(format: "%.0f", metrics.performanceScore), icon: "star.fill", color: .orange)
        }
    }
    
    private func analysisSection(analysis: AnalysisResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Анализ производительности")
                .font(.headline)
            
            VStack(spacing: 8) {
                AnalysisRow(title: "Средняя точность", value: analysis.formattedAccuracy)
                AnalysisRow(title: "Средний результат", value: analysis.formattedPerformance)
                AnalysisRow(title: "Время реакции", value: analysis.formattedReactionTime)
                AnalysisRow(title: "Тренд", value: trendText(analysis.trend))
            }
            .padding()
            .gameCard()
        }
    }
    
    private var recommendationSection: some View {
        VStack(spacing: 12) {
            Text("Рекомендация")
                .font(.headline)
            
            HStack {
                Image(systemName: recommendationIcon)
                    .foregroundColor(recommendationColor)
                Text(recommendation.description)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(recommendationColor.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }
    
    private var recommendationIcon: String {
        switch recommendation {
        case .upgrade: return "arrow.up.circle.fill"
        case .downgrade: return "arrow.down.circle.fill"
        case .maintain: return "checkmark.circle.fill"
        }
    }
    
    private var recommendationColor: Color {
        switch recommendation {
        case .upgrade: return .green
        case .downgrade: return .orange
        case .maintain: return .blue
        }
    }
    
    private func trendText(_ trend: PerformanceTrend) -> String {
        switch trend {
        case .improving: return "📈 Улучшается"
        case .stable: return "➡️ Стабильно"
        case .declining: return "📉 Снижается"
        }
    }
    
    private func formatTime(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct StatBox: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundColor(color)
                .frame(width: 34, height: 34)
                .background(color.opacity(0.14))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .gameCard()
    }
}

struct AnalysisRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}
