import SwiftUI
import SwiftData

@MainActor
@Observable
class SubGoalViewModel {
    var task: Task
    var context: ModelContext
    
    var editMode: EditMode = .inactive
    var isAddingSubtask = false
    var showCompleteAllAlert = false
    var virtualGoal: Goal?
    var graphRefreshId = 0
    
    var isEditing: Bool {
        editMode == .active
    }
    
    var parentDeadline: Date? {
        task.parent?.deadline ?? task.goal?.deadline
    }
    
    var currentTier: Int {
        task.parent?.taskTier ?? 0
    }
    
    var customRoots: [Task] {
        task.activeSubtasks
    }
    
    var calculatedMinDate: Date {
        let latestSubtaskDeadline = task.activeSubtasks.compactMap { $0.deadline }.max() ?? Date()
        return max(Date(), latestSubtaskDeadline)
    }

    init(task: Task, context: ModelContext) {
        self.task = task
        self.context = context
    }
    
    func refreshVirtualGoal() {
        virtualGoal = task.createVirtualGoal()
        graphRefreshId += 1
    }
    
    func deleteSubtask(subtask: Task) {
        withAnimation {
            subtask.deleteTask(context: context)
            try? context.save()
        }
    }
    
    func addNewSubtask(title: String, difficulty: TaskDifficultyLevel, frequency: RepeatFrequency, deadline: Date?, habit: HabitType? = nil, habitTime: Date? = nil) {
        withAnimation(.bouncy) {
            task.addSubtask(
                title: title,
                difficulty: difficulty,
                frequency: frequency,
                deadline: deadline,
                habit: habit,
                habitTime: habitTime,
                context: context
            )
            try? context.save()
        }
    }
    
    func handleRealGoalToggle() {
        _ = task.toggleTask()
        refreshVirtualGoal()
        
        try? context.save()
        graphRefreshId += 1
    }
    
    func handleToggleRoot() {
        let hasIncomplete = task.activeSubtasks.contains { !$0.isTrulyCompleted }
        
        if hasIncomplete && virtualGoal?.isCompleted == false {
            self.showCompleteAllAlert = true
            return
        }
        
        withAnimation {
            virtualGoal?.isCompleted = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            guard let self else { return }
            _ = self.task.toggleTask()
            try? self.context.save()
            
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                self.refreshVirtualGoal()
            }
        }
    }
}
