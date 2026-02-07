import SwiftUI
import SwiftData
import AlertToast

struct SubGoalDetail: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    @AccessibilityFocusState private var focusOnAddButton: Bool
    
    @State private var viewModel: SubGoalViewModel
    let goalId: UUID
    
    @State private var showLockedToast: Bool = false
    
    init(task: Task, goalId: UUID, context: ModelContext) {
        self.goalId = goalId
        _viewModel = State(initialValue: SubGoalViewModel(task: task, context: context))
    }
    
    private var isEditing: Bool {
        viewModel.editMode == .active
    }
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    SubGoalHeader(title: Bindable(viewModel.task).title, isEditing: isEditing, label: "Subgoal header")
                        .animation(.smooth, value: isEditing)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityHeading(.h1)
                    
                    if !viewModel.task.activeSubtasks.isEmpty || isEditing {
                        SubtaskList(
                            parentTask: viewModel.task,
                            goalId: goalId,
                            isEditing: isEditing,
                            onDelete: viewModel.deleteSubtask
                        )
                        .transition(.opacity.combined(with: .scale))
                        .animation(.smooth, value: isEditing)
                    }
                    
                    if isEditing && viewModel.task.taskTier < 4 && viewModel.task.activeSubtasks.count < 3 {
                        AddSubtaskButton { viewModel.isAddingSubtask = true }
                            .transition(.move(edge: .top).combined(with: .opacity))
                            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isEditing)
                            .accessibilityLabel("Add new subtask")
                            .accessibilityHint("Creates a nested task under this subgoal.")
                            .accessibilityFocused($focusOnAddButton)
                    }
                    
                    VStack(alignment: .leading, spacing: 24) {
                        Text("Goal Structure")
                            .font(.title3)
                            .fontWeight(.bold)
                        
                        goalStructureView
                            .accessibilityElement(children: .contain)
                            .accessibilityLabel("Structure Diagram")
                    }
                    .animation(.smooth, value: isEditing)
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityLabel("Subgoal Details")
        .environment(\.editMode, $viewModel.editMode)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                StyledEditButton(syncMode: $viewModel.editMode)
            }
        }
        .toast(isPresenting: $showLockedToast) {
            AlertToast(
                displayMode: .hud,
                type: .systemImage("lock.fill", .secondary),
                title: "Complete Earlier Deadline First",
                style: .style(
                    backgroundColor: Color(.secondarySystemGroupedBackground),
                    titleColor: .primary,
                    titleFont: .caption,
                )
            )
        }
        .alert("Complete All", isPresented: $viewModel.showCompleteAllAlert) {
            Button("Confirm", role: .destructive) {
                viewModel.completeAllInSubGoal()
                UIAccessibility.post(notification: .announcement, argument: "Subgoal and tasks completed")
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will complete this subgoal and all of its subtasks through their final rounds.")
        }
        .sheet(isPresented: $viewModel.isAddingSubtask, content: creationSheet)
        .onAppear {
            if viewModel.virtualGoal == nil {
                viewModel.refreshVirtualGoal()
            }
        }
        .onAppear {
            viewModel.refreshVirtualGoal()
        }
        .onChange(of: viewModel.task.title) { _, v in
            viewModel.virtualGoal?.title = v
        }
        .onChange(of: viewModel.task.isCompleted) { _, v in
            viewModel.virtualGoal?.isCompleted = v
        }
        .onChange(of: viewModel.task.currentDeadline) { _, _ in
            try? context.save()
            withAnimation(.spring) {
                viewModel.refreshVirtualGoal()
            }
        }
        .onChange(of: viewModel.editMode) { _, newMode in
            if newMode == .inactive {
                if let vGoal = viewModel.virtualGoal {
                    let finalTitle = vGoal.title.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !finalTitle.isEmpty, finalTitle != viewModel.task.title {
                        viewModel.task.title = finalTitle
                    }
                }
                try? context.save()
            }
        }
    }
    
    @ViewBuilder
    private func creationSheet() -> some View {
        TaskCreationSheet(
            minDate: Date(),
            maxDate: viewModel.task.deadline ?? viewModel.task.goal?.deadline,
            onAdd: viewModel.addNewSubtask
        )
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .id(viewModel.task.deadline)
    }
    
    @ViewBuilder
    private var goalStructureView: some View {
        if let vGoal = viewModel.virtualGoal {
            GoalStructure(
                goal: vGoal,
                titleBinding: Bindable(viewModel.task).title,
                deadlineBinding: Bindable(viewModel.task).deadline,
                minimumDate: viewModel.calculatedMinDate,
                parentDeadline: viewModel.parentDeadline,
                currentTier: viewModel.currentTier,
                customRoots: viewModel.customRoots,
                onToggleRoot: viewModel.handleToggleRoot,
                onAddRootTask: viewModel.addNewSubtask,
                onRefresh: viewModel.refreshVirtualGoal,
                onLockToast: {
                    HapticSoundManager.shared.play(.error)
                    showLockedToast = true
                },
                isEditing: isEditing
            )
            .animation(.spring, value: viewModel.task.activeSubtasks.count)
        }
    }
}

#Preview {
    @Previewable @Environment(\.modelContext) var context
    let container = PreviewContent.container
    
    let previewGoal = PreviewContent.sampleGoal
    let demoTask = previewGoal.tasks.first ?? Task(title: "Preview Task", status: .inProgress, difficultyLevel: .Medium, taskTier: 1)
    
    let _ = {
        if !previewGoal.tasks.contains(demoTask) {
            previewGoal.tasks.append(demoTask)
        }
        container.mainContext.insert(previewGoal)
    }()
    
    NavigationStack {
        SubGoalDetail(
            task: demoTask,
            goalId: previewGoal.id,
            context: context
        )
    }
    .environment(\.dynamicTypeSize, .xxxLarge)
    .modelContainer(container)
}
