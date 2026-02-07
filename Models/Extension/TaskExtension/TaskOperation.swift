import SwiftData
import Foundation

extension Task {
    func addSubtask(title: String, difficulty: TaskDifficultyLevel, frequency: RepeatFrequency, deadline: Date? = nil, habit: HabitType? = nil, habitTime: Date? = nil, context: ModelContext) {
        var finalDeadline = deadline
        if let parentDeadline = self.deadline, let proposed = deadline, proposed > parentDeadline {
            finalDeadline = parentDeadline
        }
        
        let newSubtask = Task(
            title: title,
            status: .inProgress,
            difficultyLevel: difficulty,
            repeatFrequency: frequency,
            taskTier: self.taskTier + 1,
            deadline: finalDeadline,
            habit: habit,
            habitTime: habitTime
        )
        
        newSubtask.goal = self.goal
        
        self.subtasks.append(newSubtask)
        context.insert(newSubtask)
        self.childDidChange()
    }
    
    func updateTask(title: String? = nil, difficulty: TaskDifficultyLevel? = nil, frequency: RepeatFrequency? = nil, deadline: Date? = nil, habit: HabitType? = nil, habitTime: Date? = nil, context: ModelContext) {
        if let title { self.title = title }
        if let difficulty { self.difficultyLevel = difficulty }
        
        if let newFrequency = frequency {
            let oldFrequency = self.repeatFrequency
            
            if oldFrequency != newFrequency {
                _ = updateFrequency(newFrequency: newFrequency)
            }
        }
        
        if let deadline {
            updateDeadline(newDeadline: deadline)
        }
        
        if let habit { self.habit = habit }
        if let habitTime { self.habitTime = habitTime }
        
        if self.currentDeadline == nil && self.deadline != nil {
            self.currentDeadline = self.deadline
        }
        
        try? context.save()
    }
    
    func deleteHabit(context: ModelContext) {
        self.habit = nil
        self.habitTime = nil
        
        try? context.save()
    }
    
    func deleteTask(context: ModelContext) {
        guard let parent = self.parent else {
            context.delete(self)
            return
        }
        
        if let index = parent.subtasks.firstIndex(of: self) {
            parent.subtasks.remove(at: index)
        }
        
        context.delete(self)
        
        try? context.save()
        parent.childDidChange()
    }
}
