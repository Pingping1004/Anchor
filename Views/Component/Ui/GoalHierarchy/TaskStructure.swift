import SwiftUI
import SwiftData

struct TaskStructure: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.sizeCategory) var sizeCategory
    @Environment(\.dynamicTypeSize) var typeSize
    @ScaledMetric(relativeTo: .body) var dynamicSpacing: CGFloat = 20
    
    @Bindable var task: Task
    let rowDensity: Int
    let taskCounts: [Int: Int]
    
    var onDelete: () -> Void
    var onRefresh: () -> Void
    var onLockToast: () -> Void
    
    private let maxTasksPerRow = 3
    
    let isEditing: Bool
    @State private var isAddingSubtask: Bool = false
    
    private var children: [Task] {
        return task.activeSubtasks
    }
    
    private var gridColumns: [GridItem] {
        if isAccessibilityMode {
            return [GridItem(.flexible(), spacing: 16, alignment: .top)]
        } else {
            let count = max(1, min(children.count, maxTasksPerRow))
            return Array(repeating: GridItem(.flexible(), spacing: 16, alignment: .top), count: count)
        }
    }
    
    private var shouldCollapseTask: Bool {
        if children.isEmpty { return false }
        if children.count == 1 { return false}
        if taskCounts.isEmpty { return true }
        
        let childTier = task.activeSubtasks.first?.taskTier ?? (task.taskTier + 1)
        let parentTierCount: Int = taskCounts[task.taskTier] ?? 1
        let childTierCount = taskCounts[childTier] ?? 0
        let taskInRowLimit = isAccessibilityMode ? 2 : 3
        
        return children.count > 1 && (childTierCount >= taskInRowLimit && parentTierCount > 1)
    }
    
    private var isAccessibilityMode: Bool {
        sizeCategory.isAccessibilityCategory
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: isAccessibilityMode ? dynamicSpacing : 0) {
            contentCard
                .padding(.bottom, children.isEmpty ? dynamicSpacing : 0)
            
            if !children.isEmpty {
                if !isAccessibilityMode {
                    TreeConnectors(
                        tasks: children,
                        childCount: children.count,
                        maxTasksPerRow: maxTasksPerRow,
                        isCollapsed: shouldCollapseTask
                    )
                    .id(children.map { $0.isCompleted })
                }
                
                if shouldCollapseTask {
                    moreButton(subtaskCount: task.activeSubtasks.count)
                } else {
                    subtasksGrid
                }
            }
        }
        .padding(.bottom, 40)
        .sheet(isPresented: $isAddingSubtask) {
            TaskCreationSheet(
                minDate: Date(),
                maxDate: task.deadline ?? task.goal?.deadline,
                onAdd: {title, difficulty, frequency, deadline, habit, habitTime in
                    let _ = task.addSubtask(
                        title: title,
                        difficulty: difficulty,
                        frequency: frequency,
                        deadline: deadline,
                        habit: habit,
                        habitTime: habitTime,
                        context: modelContext
                    )
                    
                    onRefresh()
                    UIAccessibility.post(notification: .announcement, argument: "Subtask added")
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .id(task.deadline)
        }
    }
    
    private var contentCard: some View {
        TaskCardView(
            task: task,
            isEditing: isEditing,
            rowDensity: rowDensity,
            taskCounts: taskCounts,
            onAddSubtask: {
                isAddingSubtask = true
            },
            onDelete: { onDelete() },
            onRefresh: onRefresh,
            onLockedToast: onLockToast
        )
    }
    
    private var subtasksGrid: some View {
        let showMoreButton = shouldCollapseTask || (children.count < task.activeSubtasks.count)
        let siblingCount = children.count + (showMoreButton ? 1 : 0)
        let childRowDensity = max(siblingCount, rowDensity)
        
        return LazyVGrid(columns: gridColumns, alignment: .center, spacing: 16) {
            ForEach(children, id: \.self) { subtask in
                TaskStructure(
                    task: subtask,
                    rowDensity: childRowDensity,
                    taskCounts: taskCounts,
                    onDelete: {
                        withAnimation {
                            subtask.deleteTask(context: modelContext)
                            try? modelContext.save()
                            UIAccessibility.post(notification: .announcement, argument: "Task deleted")
                        }
                    },
                    onRefresh: onRefresh,
                    onLockToast: onLockToast,
                    isEditing: isEditing,
                )
            }
        }
    }
    
    private func moreButton(subtaskCount: Int) -> some View {
        NavigationLink {
            SubGoalDetail(
                task: task,
                goalId: UUID(),
                context: modelContext
            )
        } label: {
            Text("\(subtaskCount) Tasks")
                .font(.caption2)
                .fontWeight(.medium)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.center)
                .foregroundStyle(LinearGradient.primaryGradient)
                .aspectRatio(1.0, contentMode: .fit)
                .frame(width: 72 + dynamicSpacing, height: 72 + dynamicSpacing)
                .padding()
                .glassEffect(
                    .regular.interactive(),
                    in: .rect(cornerRadius: 16, style: .continuous)
                )
                .padding(.bottom, 40)
        }
        .opacity(isEditing ? 0.4 : 1)
        .accessibilityLabel("View all \(subtaskCount) subtasks")
        .accessibilityHint("Opens the subgoal detail view.")
        .accessibilityAddTraits(.isButton)
    }
}
