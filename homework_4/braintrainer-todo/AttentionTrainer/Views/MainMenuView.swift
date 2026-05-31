import SwiftUI

struct MainMenuView: View {
    @EnvironmentObject var userStats: UserStats
    
    var body: some View {
        TabView {
            TodayView()
                .tabItem {
                    Label("Сегодня", systemImage: "sparkles")
                }
            
            TrainingLibraryView()
                .tabItem {
                    Label("Игры", systemImage: "square.grid.2x2.fill")
                }
            
            NavigationStack {
                ProgressDashboardView()
            }
            .tabItem {
                Label("Прогресс", systemImage: "chart.line.uptrend.xyaxis")
            }
        }
    }
}

// MARK: - Today

private struct TodayView: View {
    @EnvironmentObject var userStats: UserStats
    
    private var focusExercise: ExerciseType {
        let played = Set(userStats.history.map(\.exerciseType))
        return ExerciseType.allCases.first { !played.contains($0.rawValue) }
            ?? ExerciseType.allCases.min {
                userStats.results(for: $0, last: 9999).count < userStats.results(for: $1, last: 9999).count
            }
            ?? .schulte
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    dashboardHeader
                    focusCard
                    quickStats
                    recentActivity
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("AttentionTrainer")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private var dashboardHeader: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Тренировка на сегодня")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Адаптивный модуль подбирает уровень по точности, скорости, ошибкам и динамике последних попыток.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
                
                StreakPill(streak: userStats.streak)
            }
            
            HStack(spacing: 10) {
                DashboardChip(title: "Сессии", value: "\(userStats.history.count)", icon: "checkmark.circle.fill", color: .blue)
                DashboardChip(title: "Время", value: formatDuration(userStats.totalTrainingTime()), icon: "clock.fill", color: .green)
            }
        }
        .padding(18)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
    
    private var focusCard: some View {
        NavigationLink(destination: exerciseDestination(for: focusExercise)) {
            HStack(spacing: 16) {
                IconBadge(icon: focusExercise.icon, color: exerciseColor(focusExercise), size: 58)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Следующая игра")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                    
                    Text(focusExercise.title)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Уровень \(userStats.recommendedDifficulty(for: focusExercise).rawValue)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "play.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: 46, height: 46)
                    .background(Color.accentColor)
                    .clipShape(Circle())
            }
            .padding(18)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
    }
    
    private var quickStats: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ], spacing: 12) {
            TodayMetricCard(title: "Точность", value: String(format: "%.0f%%", overallAccuracy() * 100), icon: "target", color: .green)
            TodayMetricCard(title: "Средний счет", value: String(format: "%.0f", averageScore()), icon: "star.fill", color: .orange)
            TodayMetricCard(title: "Лучший счет", value: String(format: "%.0f", bestScore()), icon: "trophy.fill", color: .yellow)
            TodayMetricCard(title: "Игры", value: "\(ExerciseType.allCases.count)", icon: "gamecontroller.fill", color: .purple)
        }
    }
    
    private var recentActivity: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Последние попытки")
                    .font(.headline)
                Spacer()
                Text("Недавние")
                    .foregroundColor(.secondary)
                    .font(.subheadline)
            }
            
            let recent = Array(userStats.history.suffix(4).reversed())
            if recent.isEmpty {
                ContentUnavailableView(
                    "Пока нет тренировок",
                    systemImage: "figure.mind.and.body",
                    description: Text("Начните с любой игры из библиотеки")
                )
                .frame(minHeight: 140)
            } else {
                VStack(spacing: 10) {
                    ForEach(recent) { result in
                        RecentResultRow(result: result)
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
    
    private func overallAccuracy() -> Double {
        guard !userStats.history.isEmpty else { return 0 }
        return userStats.history.map(\.accuracy).reduce(0, +) / Double(userStats.history.count)
    }
    
    private func averageScore() -> Double {
        guard !userStats.history.isEmpty else { return 0 }
        return userStats.history.map(\.performanceScore).reduce(0, +) / Double(userStats.history.count)
    }
    
    private func bestScore() -> Double {
        userStats.history.map(\.performanceScore).max() ?? 0
    }
}

// MARK: - Training Library

private struct TrainingLibraryView: View {
    @EnvironmentObject var userStats: UserStats
    
    private let columns = [
        GridItem(.adaptive(minimum: 160), spacing: 12)
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    libraryHeader
                    
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(ExerciseType.allCases) { exercise in
                            NavigationLink(destination: exerciseDestination(for: exercise)) {
                                GameLibraryCard(
                                    exercise: exercise,
                                    difficulty: userStats.recommendedDifficulty(for: exercise),
                                    attempts: userStats.results(for: exercise, last: 9999).count,
                                    averageScore: userStats.averagePerformance(for: exercise)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Игры")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private var libraryHeader: some View {
        HStack(spacing: 14) {
            IconBadge(icon: "brain.head.profile", color: .indigo, size: 54)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Библиотека тренировок")
                    .font(.headline)
                Text("6 мини-игр, общий профиль сложности и сохраненная история.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer(minLength: 0)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

// MARK: - Shared Views

private struct GameLibraryCard: View {
    let exercise: ExerciseType
    let difficulty: DifficultyLevel
    let attempts: Int
    let averageScore: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                IconBadge(icon: exercise.icon, color: exerciseColor(exercise), size: 48)
                Spacer()
                DifficultyPill(level: difficulty)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(exercise.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                
                Text(exercise.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer(minLength: 0)
            
            HStack {
                Label("\(attempts)", systemImage: "number")
                Spacer()
                Text(averageScore > 0 ? String(format: "%.0f", averageScore) : "новая")
            }
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.secondary)
        }
        .frame(minHeight: 190, alignment: .top)
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct TodayMetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            IconBadge(icon: icon, color: color, size: 38)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 112, alignment: .leading)
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct DashboardChip: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.headline)
                    .lineLimit(1)
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct RecentResultRow: View {
    let result: GameResult
    
    private var exercise: ExerciseType {
        ExerciseType(rawValue: result.exerciseType) ?? .schulte
    }
    
    var body: some View {
        HStack(spacing: 12) {
            IconBadge(icon: exercise.icon, color: exerciseColor(exercise), size: 40)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text("Уровень \(result.difficulty.rawValue)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "%.0f", result.performanceScore))
                    .font(.subheadline)
                    .fontWeight(.bold)
                Text(String(format: "%.0f%%", result.accuracy * 100))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(10)
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct IconBadge: View {
    let icon: String
    let color: Color
    let size: CGFloat
    
    var body: some View {
        Image(systemName: icon)
            .font(.system(size: size * 0.42, weight: .semibold))
            .foregroundColor(color)
            .frame(width: size, height: size)
            .background(color.opacity(0.14))
            .clipShape(RoundedRectangle(cornerRadius: size * 0.28, style: .continuous))
    }
}

private struct DifficultyPill: View {
    let level: DifficultyLevel
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: level.icon)
            Text("\(level.rawValue)")
        }
        .font(.caption)
        .fontWeight(.bold)
        .foregroundColor(difficultyColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(difficultyColor.opacity(0.14))
        .clipShape(Capsule())
    }
    
    private var difficultyColor: Color {
        switch level.rawValue {
        case 1...3: return .green
        case 4...6: return .orange
        default: return .red
        }
    }
}

private struct StreakPill: View {
    let streak: Int
    
    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "flame.fill")
            Text("\(streak)")
        }
        .font(.subheadline)
        .fontWeight(.bold)
        .foregroundColor(.orange)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(Color.orange.opacity(0.14))
        .clipShape(Capsule())
    }
}

@ViewBuilder
private func exerciseDestination(for exercise: ExerciseType) -> some View {
    switch exercise {
    case .schulte:
        SchulteTableView()
    case .nback:
        NBackView()
    case .numbers:
        NumbersView()
    case .colors:
        ColorsView()
    case .stroop:
        StroopView()
    case .sequence:
        SequenceMemoryView()
    }
}

private func exerciseColor(_ exercise: ExerciseType) -> Color {
    switch exercise {
    case .schulte: return .blue
    case .nback: return .green
    case .numbers: return .orange
    case .colors: return .purple
    case .stroop: return .red
    case .sequence: return .teal
    }
}

private func formatDuration(_ interval: TimeInterval) -> String {
    let hours = Int(interval) / 3600
    let minutes = (Int(interval) % 3600) / 60
    return hours > 0 ? "\(hours)ч \(minutes)м" : "\(minutes)м"
}

struct MainMenuView_Previews: PreviewProvider {
    static var previews: some View {
        MainMenuView()
            .environmentObject(UserStats())
    }
}
