import SwiftUI
import SwiftData

struct TaskCardView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) var sizeClass
    @Environment(\.sizeCategory) var typeSize
    @Environment(\.dismiss) var dismiss
    
    @Bindable var task: Task
    let isEditing: Bool
    let rowDensity: Int
    let taskCounts: [Int: Int]
    
    var onAddSubtask: () -> Void
    var onDelete: () -> Void
    var onRefresh: () -> Void
    var onLockedToast: () -> Void
    
    @State var activeSheet: TaskCardSheetType?
    @State private var isProcessingRepeat = false
    @State private var isFinishing = false
    @State private var shakeTrigger: Int = 0
    
    let maxTasksPerRow: Int = 3
    
    private var latestDirectChildDeadline: Date? {
        let childDeadlines = task.subtasks.compactMap { $0.deadline }
        return childDeadlines.max()
    }
    
    private var isAccessibilityMode: Bool {
        typeSize.isAccessibilityCategory
    }
    
    private var frequencyBinding: Binding<RepeatFrequency> {
        Binding(
            get: { task.repeatFrequency },
            set: { newFrequency in
                task.updateTask(frequency: newFrequency, context: modelContext)
            }
        )
    }
    
    var body: some View {
        let isAddable: Bool = task.taskTier < 5 && task.activeSubtasks.count < 3
        let canInteract = task.canBeCompleted
        
        CardView(
            item: task,
            isEditing: isEditing,
            showFrequencyText: rowDensity <= 2 && !isAccessibilityMode && sizeClass == .regular
        )
        .errorShake(trigger: shakeTrigger)
        .animation(.smooth, value: task.currentDeadline)
        .animation(.smooth, value: isFinishing)
        .animation(.smooth, value: isProcessingRepeat)
        .accessibilityAction(named: "Delete Task") {
            withAnimation {
                onDelete()
                onRefresh()
            }
            HapticSoundManager.shared.play(.sent)
        }
        .accessibilityValue(accessibilityStatusString)
        .accessibilityAction(named: "Change Deadline") {
            activeSheet = .datePicker
        }
        .accessibilityAction(named: "Toggle Completion") {
            performToggle()
        }
        .accessibilityAction(named: "Edit Habit") {
            activeSheet = .habitSheet
        }
        .opacity(canInteract || isEditing ? 1.0 : 0.5)
        .frame(maxWidth: .infinity)
        .glassEffect(
            .regular,
            in: .rect(cornerRadius: 16, style: .continuous)
        )
        .onTapGesture {
            if !canInteract && !isEditing {
                withAnimation(.default) {
                    shakeTrigger += 1
                }
                
                onLockedToast()
            }
            
            if !isEditing && canInteract {
                performToggle()
            }
            
            if task.isCompleted && !isEditing && !task.canShiftToNextDeadline {
                HapticSoundManager.shared.play(.tock)
            }
        }
        .contextMenu {
            contextMenuContent(isAddable: isAddable)
        }
        .animation(.easeInOut(duration: 0.4), value: canInteract)
        .sheet(item: $activeSheet) { type in
            sheetContent(for: type)
        }
    }
    
    @ViewBuilder
    private func contextMenuContent(isAddable: Bool) -> some View {
        Button {
            activeSheet = .datePicker
        } label: {
            Label(task.deadline == nil ? "Set Deadline" : "Edit Deadline", systemImage: "calendar")
        }
 
        if isAddable {
            Button(action: onAddSubtask) {
                Label("Add Subtask", systemImage: "arrow.turn.down.right")
            }
        }
        
        Menu {
            Picker("Difficulty", selection: $task.difficultyLevel) {
                ForEach(TaskDifficultyLevel.allCases, id: \.self) { level in
                    Text(level.rawValue.capitalized).tag(level)
                }
            }
        } label: {
            Label("Task difficulty", systemImage: "flag")
        }
        
        Divider()
        
        Button {
            activeSheet = .habitSheet
        } label: {
            Label(task.habit == nil ? "Add Habit" : "Edit Habit", systemImage: "clock.arrow.circlepath")
        }
        
        Divider()
        
        Menu {
            Picker("Repeat", selection: frequencyBinding) {
                ForEach(RepeatFrequency.allCases, id: \.self) { freq in
                    Text(freq.rawValue.capitalized).tag(freq)
                }
            }
        } label: {
            Label("Repeat", systemImage: "repeat")
        }
        
        Divider()
        
        Button(role: .destructive) {
            withAnimation {
                onDelete()
                onRefresh()
            }
            
            HapticSoundManager.shared.play(.sent)
        } label: {
            Label("Delete Task", systemImage: "trash")
        }
    }
    
    private var accessibilityStatusString: String {
        var status = task.isCompleted ? "Completed" : "Incomplete"
        
        if let deadline = task.deadline {
            if deadline < Date.now && !task.isCompleted {
                status += ", Overdue due \(deadline.formatted(date: .abbreviated, time: .omitted))"
            } else {
                status += ", due \(deadline.formatted(date: .abbreviated, time: .omitted))"
            }
        }
        
        status += ", \(task.difficultyLevel.rawValue) difficulty"
        return status
    }
    
    @ViewBuilder
    private func sheetContent(for type: TaskCardSheetType) -> some View {
        switch type {
        case .datePicker:
            let maxLimit = task.parent?.deadline ?? task.goal?.deadline
            let minLimit = latestDirectChildDeadline
            
            DatePickerSheet(
                selectedDate: Binding<Date?>(
                    get: { task.deadline },
                    set: { newDate in
                        if let date = newDate {
                            task.updateTask(deadline: date, context: modelContext)
                        } else {
                            task.deadline = nil
                        }
                        
                        try? modelContext.save()
                    }
                ),
                label: "Edit Deadline",
                isPastDateAllowed: false,
                maximumDate: maxLimit,
                minimumDate: minLimit
            )
            
        case .habitSheet:
            HabitSheetView(
                taskTitle: task.title,
                currentHabit: task.habit ?? .morningCoffee,
                currentTime: task.habitTime,
                onDone: { selectedHabit, selectedTime in
                    if let habit = selectedHabit, let time = selectedTime {
                        task.updateTask(habit: habit, habitTime: time, context: modelContext)
                    } else {
                        task.deleteHabit(context: modelContext)
                    }
                }
            )
        }
    }
    
    private func performToggle() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        if !task.isCompleted {
            if task.repeatFrequency == .never {
                withAnimation(.snappy) {
                    isFinishing = true
                }
                withAnimation(.bouncy(duration: 0.4, extraBounce: 0.1)) {
                    _ = task.toggleTask(context: modelContext)
                    isFinishing = false
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
                try? modelContext.save()
                return
            }
            
            withAnimation(.snappy) {
                isFinishing = true
                isProcessingRepeat = true
                task.completeCycleState()
            }
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.smooth) {
                    _ = task.advanceTaskCycle()
                    isFinishing = false
                    isProcessingRepeat = false
                }
                try? modelContext.save()
            }
            return
        } else {
            withAnimation {
                _ = task.toggleTask(context: modelContext)
            }
            try? modelContext.save()
        }
    }
}
