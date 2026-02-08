import SwiftUI
import SwiftData

struct GoalStructure: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.sizeCategory) var sizeCategory
    @Environment(\.dynamicTypeSize) var typeSize
    @ScaledMetric(relativeTo: .body) var dynamicSpacing: CGFloat = 20
    
    @Bindable var goal: Goal
    
    var titleBinding: Binding<String>? = nil
    var deadlineBinding: Binding<Date?>? = nil
    var minimumDate: Date? = nil
    var parentDeadline: Date? = nil
    var currentTier: Int = 0
    
    var customRoots: [Task]? = nil
    var onToggleRoot: (() -> Void)? = nil
    
    var onAddRootTask: ((String, TaskDifficultyLevel, RepeatFrequency, Date?, HabitType?, Date?) -> Void)? = nil
    var onRefresh: () -> Void
    var onLockToast: () -> Void
    
    let isEditing: Bool
    
    @State private var isAddingTask: Bool = false
    
    private let maxTasksPerRow = 3
    
    private var taskCounts: [Int: Int] {
        return goal.computeLayoutMetrics().taskCounts
    }
    
    private var isAccessibilityMode: Bool {
        sizeCategory.isAccessibilityCategory
    }
    
    private var allTasks: [Task] {
        if let customRoots = customRoots {
            return customRoots
        } else {
            return goal.activeRootTasks
        }
    }
    
    private var layoutData: (taskCounts: [Int: Int], visualCounts: [Int: Int]) {
        goal.computeLayoutMetrics()
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: isAccessibilityMode ? dynamicSpacing : 0) {
                if allTasks.isEmpty {
                    emptyState
                } else {
                    GoalCardView(
                        goal: goal,
                        context: modelContext,
                        selectedDate: deadlineBinding ?? $goal.deadline,
                        minimumDate: minimumDate,
                        maximumDate: parentDeadline,
                        isEditing: isEditing,
                        taskCounts: taskCounts,
                        maxTasksPerRow: maxTasksPerRow,
                        customToggleAction: onToggleRoot,
                        onAddRootTask: { isAddingTask = true },
                        completionCheckTasks: allTasks,
                    )
                    .frame(maxWidth: .infinity)
                    
                    if !isAccessibilityMode {
                        TreeConnectors(
                            tasks: allTasks,
                            childCount: allTasks.count,
                            maxTasksPerRow: maxTasksPerRow,
                            isCollapsed: false
                        )
                        .id(allTasks.map { $0.isCompleted })
                        .accessibilityHidden(true)
                        .offset(y: dynamicSpacing / 2)
                    }
                    
                    tasksList
                        .padding(.top, 24)
                }
            }
        }
        .sheet(isPresented: $isAddingTask) {
            TaskCreationSheet(
                minDate: Date(),
                maxDate: goal.deadline,
                onAdd: { title, difficulty, frequency, deadline, habit, habitTime in
                    if let customAdder = onAddRootTask {
                        customAdder(title, difficulty, frequency, deadline, habit, habitTime)
                    } else {
                        goal.addRootTask(
                            title: title,
                            difficultyLevel: difficulty,
                            repeatFrequency: frequency,
                            deadline: deadline,
                            habit: habit,
                            habitTime: habitTime,
                            context: modelContext
                        )
                    }
                    
                    onRefresh()
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .id(goal.deadline)
        }
    }
    
    private var tasksList: some View {
        let count = max(1, min(allTasks.count, maxTasksPerRow))
        let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: count)
        let rootDensity = allTasks.count
        
        return LazyVGrid(columns: columns, spacing: 24) {
            ForEach(allTasks, id: \.self) { task in
                TaskStructure(
                    task: task,
                    rowDensity: rootDensity,
                    taskCounts: taskCounts,
                    onDelete: {
                        withAnimation {
                            if let index = goal.tasks.firstIndex(where: { $0.id == task.id }) {
                                goal.tasks.remove(at: index)
                            }
                            
                            task.deleteTask(context: modelContext)
                        }
                        
                        onRefresh()
                    },
                    onRefresh: onRefresh,
                    onLockToast: onLockToast,
                    isEditing: isEditing
                )
                .frame(maxHeight: .infinity, alignment: .top)
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Tasks Yet", systemImage: "checklist")
        } description: {
            Text("Break down your goal into manageable steps.")
        } actions: {
            if allTasks.isEmpty && currentTier < 3 {
                AddSubtaskButton { isAddingTask = true }
            }
        }
        .foregroundStyle(.primary)
        .padding(.vertical, 24)
    }
}
