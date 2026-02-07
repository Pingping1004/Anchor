import SwiftUI

struct DraftTaskRow: View {
    @Binding var title: String
    @Binding var difficulty: TaskDifficultyLevel
    @Binding var frequency: RepeatFrequency
    @Binding var habit: HabitType?
    @Binding var deadline: Date?
    
    @State private var showDifficultyPicker: Bool = false
    
    var onDateTap: () -> Void
    var onDeleteTask: () -> Void
    var onActiveHabitSheet: () -> Void
    
    @FocusState private var isFocused: Bool
    @Environment(\.colorSchemeContrast) var contrast
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 12) {
                    titleField
                    
                    HStack(spacing: 12) {
                        deadlineButton
                        difficultyBadge
                    }
                }
                
                Spacer()
                
                actionButtons
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .cornerRadius(16)
        }
        .accessibilityAction(named: "Delete Task") { onDeleteTask() }
        .accessibilityAction(named: "Change Deadline") { onDateTap() }
        .accessibilityAction(named: "Toggle Difficulty") { cycleDifficulty() }
    }
    
    
    private var titleField: some View {
        TextField("Enter your task", text: $title)
            .font(.body.weight(.medium))
            .focused($isFocused)
            .submitLabel(.done)
            .tint(.blue)
            .accessibilityLabel("Task Title")
            .accessibilityHint("Tap to edit task title.")
    }
    
    private var deadlineButton: some View {
        Button(action: onDateTap) {
            HStack(spacing: 4) {
                Image(systemName: "calendar")
                    .font(.caption)
                
                if let date = deadline {
                    Text(date.formatted(date: .numeric, time: .omitted))
                } else {
                    Text("Set Deadline")
                }
            }
            .foregroundStyle(Color.primaryLight)
            .font(.caption.weight(.medium))
            .padding(8)
            .background(Color.primaryMain.opacity(0.1))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .tint(.primaryMain)
        .accessibilityLabel(deadlineLabel)
        .accessibilityInputLabels(["Deadline", "Date", "Calendar"])
    }
    
    private var difficultyBadge: some View {
        Menu {
            Picker("Difficulty", selection: $difficulty) {
                ForEach(TaskDifficultyLevel.allCases, id: \.self) { level in
                    Text(level.rawValue.capitalized).tag(level)
                }
            }
        } label: {
            Text(difficulty.rawValue.capitalized)
                .font(.caption2.weight(.bold))
                .foregroundStyle(badgeForeground)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(difficultyColor.opacity(0.15))
                .clipShape(Capsule())
        }
        .accessibilityLabel("Difficulty")
        .accessibilityValue(difficulty.rawValue.capitalized)
        .accessibilityInputLabels(["Difficulty", "Level"])
    }
    
    private var actionButtons: some View {
        Menu {
            Section {
                Button(action: onDateTap) {
                    if deadline == nil {
                        Label("Set Date", systemImage: "calendar")
                    } else {
                        Label("Edit Date", systemImage: "calendar.badge.clock")
                    }
                }
                
                Picker(selection: $difficulty) {
                    ForEach(TaskDifficultyLevel.allCases, id: \.self) { level in
                        Text(level.rawValue.capitalized).tag(level)
                    }
                } label: {
                    Label("Difficulty", systemImage: "flag")
                }
                .pickerStyle(.menu)
            }
            
            Section {
                Picker(selection: $frequency) {
                    ForEach(RepeatFrequency.allCases, id: \.self) { level in
                        Text(level.rawValue.capitalized).tag(level)
                    }
                } label: {
                    Label("Repeat", systemImage: "repeat")
                }
                .pickerStyle(.menu)
                
                Button {
                    onActiveHabitSheet()
                } label: {
                    Label(habit == nil ? "Add Habit" : "Edit Habit", systemImage: "clock.arrow.circlepath")
                }
            }
            
            Section {
                Button(role: .destructive, action: onDeleteTask) {
                    Label("Delete", systemImage: "trash")
                }
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.title3.weight(.medium))
                .foregroundStyle(Color(.secondaryLabel))
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .accessibilityLabel("More Actions")
    }
    
    private var deadlineLabel: String {
        if let deadline = deadline {
            return "Due \(deadline.formatted(date: .abbreviated, time: .omitted))"
        }
        return "Set Deadline"
    }
    
    private func cycleDifficulty() {
        switch difficulty {
        case .Easy: difficulty = .Medium
        case .Medium: difficulty = .Difficult
        case .Difficult: difficulty = .Easy
        }
    }
    
    private var difficultyColor: Color {
        switch difficulty {
        case .Easy: return .green
        case .Medium: return .orange
        case .Difficult: return .red
        }
    }
    
    private var badgeForeground: Color {
        contrast == .increased ? .black : difficultyColor
    }
}
