import SwiftUI
import SwiftData

struct GoalCardView: View {
    @Environment(\.modelContext) private var context

    @Bindable var goal: Goal

    var selectedDate: Binding<Date?>
    var minimumDate: Date?
    var maximumDate: Date?
    let isEditing: Bool
    let taskCounts: [Int: Int]
    let maxTasksPerRow: Int
    
    var customToggleAction: (() -> Void)? = nil
    var onAddRootTask: () -> Void
    var completionCheckTasks: [Task]? = nil
    
    @State private var viewModel: GoalCardViewModel
    @State private var tapPulse: Bool = false
    
    init(goal: Goal,
         context: ModelContext,
         selectedDate: Binding<Date?>,
         minimumDate: Date? = nil,
         maximumDate: Date? = nil,
         isEditing: Bool,
         taskCounts: [Int: Int],
         maxTasksPerRow: Int,
         customToggleAction: (() -> Void)? = nil,
         onAddRootTask: @escaping () -> Void,
         completionCheckTasks: [Task]? = nil,
    ) {
        self.goal = goal
        self.selectedDate = selectedDate
        self.minimumDate = minimumDate
        self.maximumDate = maximumDate
        self.isEditing = isEditing
        self.taskCounts = taskCounts
        self.maxTasksPerRow = maxTasksPerRow
        self.customToggleAction = customToggleAction
        self.onAddRootTask = onAddRootTask
        self.completionCheckTasks = completionCheckTasks
        
        self._viewModel = State(initialValue: GoalCardViewModel(goal: goal, context: context))
    }
    
    var body: some View {
        let tasksToCheck = completionCheckTasks ?? goal.tasks
        let childTier = tasksToCheck.first?.taskTier ?? 0
        let taskInTier = taskCounts[childTier] ?? 0
            
        CardView(
            item: goal,
            isEditing: isEditing,
            showFrequencyText: goal.repeatFrequency != .never,
        )
        .accessibilityAction(named: "Toggle Completion") {
            performToggle()
        }
        .accessibilityAction(named: "Change Deadline") {
            viewModel.activeSheet = .datePicker
        }
        .accessibilityAction(named: "Edit Category") {
            viewModel.activeSheet = .categoryPicker
        }
        .accessibilityValue(accessibilityStatusString)
        .containerRelativeFrame(.horizontal) { length, _ in
            length / 1.5
        }
        .glassEffect(
            .regular.interactive(),
            in: .rect(cornerRadius: 16, style: .continuous)
        )
        .scaleEffect(tapPulse ? 0.98 : 1.0)
        .animation(.snappy(duration: 0.18), value: tapPulse)
        .onTapGesture { performToggle() }
        .onChange(of: goal.isCompleted) { _, isCompleted in
            triggerCompletionHaptics(isCompleted: isCompleted)
        }
        .contextMenu {
            contextMenuContent(taskCount: taskInTier)
        }
        .sheet(item: $viewModel.activeSheet) { type in
            sheetContent(for: type)
        }
    }
    
    @ViewBuilder
    private func contextMenuContent(taskCount: Int) -> some View {
        Button {
            viewModel.activeSheet = .datePicker
        } label: {
            Label(liveDateBinding.wrappedValue == nil ? "Set Deadline" : "Edit Deadline", systemImage: "calendar")
        }
        
        if taskCount < maxTasksPerRow {
            Button(action: onAddRootTask) {
                Label("Add Task", systemImage: "plus.circle")
            }
        }
        
        if !goal.isVirtualGoal {
            Button {
                viewModel.activeSheet = .categoryPicker
            } label: {
                Label("Edit Category", systemImage: "tag")
            }
        }
    }
    
    private func triggerCompletionHaptics(isCompleted: Bool) {
        if isCompleted && !goal.canShiftToNextDeadline {
            HapticSoundManager.shared.play(.success)
        } else if isCompleted {
            HapticSoundManager.shared.play(.tock)
        }
    }
    
    private func performToggle() {
        guard !isEditing else { return }
        
        tapPulse = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { tapPulse = false }
        
        if let customAction = customToggleAction {
            customAction()
            return
        }
        
        viewModel.handleToggle(completionCheckTasks: completionCheckTasks)
    }
    
    private var accessibilityStatusString: String {
        var status = goal.isCompleted ? "Completed" : "Incomplete"
        
        let categoryNames = goal.category.map { $0.description }.joined(separator: ", ")
        status += ", in \(categoryNames)"
        
        if let deadline = goal.currentDeadline {
            if deadline < Date.now && !goal.isCompleted {
                status += ", Overdue due \(deadline.formatted(date: .abbreviated, time: .omitted))"
            } else {
                status += ", due \(deadline.formatted(date: .abbreviated, time: .omitted))"
            }
        }
        
        return status
    }
    
    private var liveDateBinding: Binding<Date?> {
        Binding(
            get: {
                if let existingDeadline = goal.deadline {
                    return existingDeadline
                }
                
                if let inheritedDeadline = goal.neareseParentDeadline {
                    return inheritedDeadline
                }
                
                return Date()
            },
            set: { newDate in
                goal.updateGoal(deadline: newDate, context: context)
                try? context.save()
            }
        )
    }
    
    @ViewBuilder
    private func sheetContent(for type: GoalSheetType) -> some View {
        switch type {
        case .datePicker:
            DatePickerSheet(
                selectedDate: liveDateBinding,
                label: "Goal Deadline",
                isPastDateAllowed: false,
                maximumDate: maximumDate,
                minimumDate: minimumDate ?? max(Date(), goal.activeRootTasks.compactMap { $0.deadline }.max() ?? Date())
            )
            
        case .categoryPicker:
            NavigationStack {
                CategorySelection(selectedCategories: $goal.category)
                    .navigationTitle("Edit Categories")
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") { viewModel.activeSheet = nil }
                        }
                    }
            }
            .presentationDetents([.medium, .large])
        }
    }
}
