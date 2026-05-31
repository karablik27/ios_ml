import SwiftUI
import Charts

struct ProgressDashboardView: View {
    @EnvironmentObject var userStats: UserStats
    @State private var selectedSection: ProgressSection = .overview
    
    private enum ProgressSection: String, CaseIterable, Identifiable {
        case overview = "Обзор"
        case games = "Игры"
        case skills = "Навыки"
        
        var id: String { rawValue }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Picker("Раздел", selection: $selectedSection) {
                    ForEach(ProgressSection.allCases) { section in
                        Text(section.rawValue).tag(section)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                
                Group {
                    switch selectedSection {
                    case .overview:
                        overviewContent
                    case .games:
                        gamesContent
                    case .skills:
                        skillsContent
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.vertical, 12)
        }
        .navigationTitle("Прогресс")
        .navigationBarTitleDisplayMode(.large)
        .background(Color(.systemGroupedBackground))
    }
    
    private var overviewContent: some View {
        VStack(spacing: 16) {
            summaryGrid
            activityChartSection
            distributionSection
        }
    }
    
    private var gamesContent: some View {
        VStack(spacing: 12) {
            ForEach(ExerciseType.allCases) { exercise in
                NavigationLink(destination: ExerciseProgressChartView(exercise: exercise)) {
                    ProgressGameCard(
                        exercise: exercise,
                        attempts: allResults(for: exercise).count,
                        averageScore: averagePerformance(for: exercise),
                        accuracy: averageAccuracy(for: exercise),
                        difficulty: userStats.recommendedDifficulty(for: exercise)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private var skillsContent: some View {
        VStack(spacing: 16) {
            SkillFocusCard(skills: userStats.allSkills)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Карта навыков")
                    .font(.headline)
                
                VStack(spacing: 12) {
                    ForEach(userStats.allSkills, id: \.name) { skill in
                        SkillBar(name: skill.name, progress: skill.progress)
                    }
                }
            }
            .padding(16)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }
    
    private var summaryGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ], spacing: 12) {
            ProgressMetricCard(title: "Тренировки", value: "\(userStats.history.count)", icon: "checkmark.circle.fill", color: .blue)
            ProgressMetricCard(title: "Серия", value: "\(userStats.streak) дн", icon: "flame.fill", color: .orange)
            ProgressMetricCard(title: "Время", value: progressDuration(userStats.totalTrainingTime()), icon: "clock.fill", color: .green)
            ProgressMetricCard(title: "Точность", value: String(format: "%.0f%%", overallAccuracy() * 100), icon: "target", color: .purple)
        }
    }
    
    private var activityChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Активность", subtitle: "Последние 7 дней")
            
            let days = last7DaysData()
            if days.contains(where: { $0.count > 0 }) {
                Chart(days) { day in
                    BarMark(
                        x: .value("День", day.date, unit: .day),
                        y: .value("Тренировки", day.count)
                    )
                    .foregroundStyle(Color.blue.gradient)
                    .cornerRadius(5)
                }
                .frame(height: 170)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { _ in
                        AxisValueLabel(format: .dateTime.weekday(.short))
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
            } else {
                ContentUnavailableView(
                    "Нет активности",
                    systemImage: "chart.bar",
                    description: Text("После тренировок здесь появится недельная динамика")
                )
                .frame(height: 170)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
    
    private var distributionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Баланс игр", subtitle: "Какие упражнения используются чаще")
            
            let distribution = exerciseDistribution()
            if distribution.isEmpty {
                ContentUnavailableView(
                    "Нет данных",
                    systemImage: "chart.pie",
                    description: Text("Запустите любую игру, чтобы увидеть распределение")
                )
                .frame(height: 170)
            } else {
                VStack(spacing: 10) {
                    ForEach(distribution) { item in
                        DistributionRow(item: item, total: max(1, userStats.history.count))
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
    
    // MARK: - Helpers
    
    private func allResults(for exercise: ExerciseType) -> [GameResult] {
        userStats.history.filter { $0.exerciseType == exercise.rawValue }
    }
    
    private func overallAccuracy() -> Double {
        guard !userStats.history.isEmpty else { return 0 }
        return userStats.history.map(\.accuracy).reduce(0, +) / Double(userStats.history.count)
    }
    
    private func averageAccuracy(for exercise: ExerciseType) -> Double {
        let results = allResults(for: exercise)
        guard !results.isEmpty else { return 0 }
        return results.map(\.accuracy).reduce(0, +) / Double(results.count)
    }
    
    private func averagePerformance(for exercise: ExerciseType) -> Double {
        let results = allResults(for: exercise)
        guard !results.isEmpty else { return 0 }
        return results.map(\.performanceScore).reduce(0, +) / Double(results.count)
    }
    
    private func last7DaysData() -> [DayActivity] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        return (0..<7).map { offset in
            let date = calendar.date(byAdding: .day, value: -offset, to: today) ?? today
            let count = userStats.history.filter {
                calendar.isDate($0.date, inSameDayAs: date)
            }.count
            return DayActivity(date: date, count: count)
        }.reversed()
    }
    
    private func exerciseDistribution() -> [ExerciseCount] {
        ExerciseType.allCases.compactMap { exercise in
            let count = allResults(for: exercise).count
            return count > 0 ? ExerciseCount(exercise: exercise, count: count) : nil
        }
        .sorted { $0.count > $1.count }
    }
}

// MARK: - Data Models

struct DayActivity: Identifiable {
    let id = UUID()
    let date: Date
    let count: Int
}

struct ExerciseCount: Identifiable {
    let exercise: ExerciseType
    let count: Int
    
    var id: String { exercise.rawValue }
}

// MARK: - Components

private struct SectionHeader: View {
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.headline)
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

private struct ProgressMetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundColor(color)
                .frame(width: 38, height: 38)
                .background(color.opacity(0.14))
                .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                
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

private struct ProgressGameCard: View {
    let exercise: ExerciseType
    let attempts: Int
    let averageScore: Double
    let accuracy: Double
    let difficulty: DifficultyLevel
    
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: exercise.icon)
                .font(.title3)
                .foregroundColor(progressExerciseColor(exercise))
                .frame(width: 48, height: 48)
                .background(progressExerciseColor(exercise).opacity(0.14))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            
            VStack(alignment: .leading, spacing: 5) {
                Text(exercise.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                HStack(spacing: 10) {
                    Label("\(attempts)", systemImage: "number")
                    Label("Ур. \(difficulty.rawValue)", systemImage: difficulty.icon)
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(averageScore > 0 ? String(format: "%.0f", averageScore) : "-")
                    .font(.headline)
                    .foregroundColor(.primary)
                Text(String(format: "%.0f%%", accuracy * 100))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct DistributionRow: View {
    let item: ExerciseCount
    let total: Int
    
    private var share: Double {
        Double(item.count) / Double(total)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Label(item.exercise.title, systemImage: item.exercise.icon)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(item.count)")
                    .font(.subheadline)
                    .fontWeight(.bold)
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color(.tertiarySystemFill))
                    
                    RoundedRectangle(cornerRadius: 5)
                        .fill(progressExerciseColor(item.exercise))
                        .frame(width: max(8, geo.size.width * share))
                }
            }
            .frame(height: 10)
        }
        .padding(12)
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct SkillFocusCard: View {
    let skills: [(name: String, progress: Double)]
    
    private var strongest: (name: String, progress: Double)? {
        skills.max { $0.progress < $1.progress }
    }
    
    private var weakest: (name: String, progress: Double)? {
        skills.min { $0.progress < $1.progress }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            SkillMiniStat(title: "Сильнее", skill: strongest, color: .green, icon: "arrow.up.forward")
            SkillMiniStat(title: "Фокус", skill: weakest, color: .orange, icon: "scope")
        }
    }
}

private struct SkillMiniStat: View {
    let title: String
    let skill: (name: String, progress: Double)?
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 34, height: 34)
                .background(color.opacity(0.14))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(skill?.name ?? "-")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                
                Text(String(format: "%.0f%%", skill?.progress ?? 0))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 136, alignment: .leading)
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

struct SkillBar: View {
    let name: String
    let progress: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Spacer()
                
                Text("\(Int(progress))%")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color(.tertiarySystemFill))
                    
                    RoundedRectangle(cornerRadius: 5)
                        .fill(skillColor)
                        .frame(width: max(8, geo.size.width * CGFloat(progress) / 100))
                }
            }
            .frame(height: 10)
        }
    }
    
    private var skillColor: Color {
        if progress < 40 { return .red }
        if progress < 70 { return .orange }
        return .green
    }
}

private func progressExerciseColor(_ exercise: ExerciseType) -> Color {
    switch exercise {
    case .schulte: return .blue
    case .nback: return .green
    case .numbers: return .orange
    case .colors: return .purple
    case .stroop: return .red
    case .sequence: return .teal
    }
}

private func progressDuration(_ interval: TimeInterval) -> String {
    let hours = Int(interval) / 3600
    let minutes = (Int(interval) % 3600) / 60
    return hours > 0 ? "\(hours)ч \(minutes)м" : "\(minutes)м"
}

struct ProgressDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ProgressDashboardView()
                .environmentObject(UserStats())
        }
    }
}
