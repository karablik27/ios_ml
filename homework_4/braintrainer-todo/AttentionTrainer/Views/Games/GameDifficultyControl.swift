import SwiftUI

struct GameDifficultyControl: View {
    @Binding var selectedDifficulty: DifficultyLevel
    
    let isLocked: Bool
    let onChange: (DifficultyLevel) -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Уровень сложности")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                    
                    Label(selectedDifficulty.title, systemImage: selectedDifficulty.icon)
                        .font(.headline)
                        .foregroundColor(levelColor(selectedDifficulty))
                }
                
                Spacer()
                
                HStack(spacing: 10) {
                    Button(action: decrease) {
                        Image(systemName: "minus.circle.fill")
                            .font(.title2)
                    }
                    .disabled(isLocked || selectedDifficulty.rawValue <= DifficultyLevel.min)
                    
                    Button(action: increase) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                    .disabled(isLocked || selectedDifficulty.rawValue >= DifficultyLevel.max)
                }
            }
            
            HStack(spacing: 6) {
                ForEach(DifficultyLevel.allCases, id: \.self) { level in
                    Capsule()
                        .fill(level.rawValue <= selectedDifficulty.rawValue ? levelColor(level) : Color(.tertiarySystemFill))
                        .frame(maxWidth: .infinity)
                        .frame(height: 8)
                }
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .opacity(isLocked ? 0.72 : 1)
    }
    
    private func decrease() {
        guard !isLocked, selectedDifficulty.rawValue > DifficultyLevel.min else { return }
        setDifficulty(rawValue: selectedDifficulty.rawValue - 1)
    }
    
    private func increase() {
        guard !isLocked, selectedDifficulty.rawValue < DifficultyLevel.max else { return }
        setDifficulty(rawValue: selectedDifficulty.rawValue + 1)
    }
    
    private func setDifficulty(rawValue: Int) {
        guard let next = DifficultyLevel(rawValue: rawValue) else { return }
        selectedDifficulty = next
        onChange(next)
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
