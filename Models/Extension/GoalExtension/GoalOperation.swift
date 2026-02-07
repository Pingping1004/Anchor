import Foundation
import SwiftData

extension Goal {
    static func createGoal(title: String, category: Set<GoalCategory>, whyMatter: String, tasks: [DraftTask], deadline: Date? = nil, context: ModelContext) throws {
        let newGoal = Goal(title: title, category: category, whyMatter: whyMatter, deadline: deadline)
        context.insert(newGoal)
        
        for draft in tasks {
            var finalDeadline = draft.deadline
            if let goalDeadline = deadline, let taskDeadline = draft.deadline, taskDeadline > goalDeadline {
                finalDeadline = goalDeadline
            }
            
            let newTask = Task(
                title: draft.title,
                status: .inProgress,
                difficultyLevel: draft.difficulty,
                repeatFrequency: draft.repeatFrequency,
                taskTier: draft.tier,
                deadline: finalDeadline
            )
            
            newGoal.tasks.append(newTask)
        }
        
        try context.save()
    }
    
    func addRootTask(title: String, difficultyLevel: TaskDifficultyLevel, repeatFrequency: RepeatFrequency, deadline: Date? = nil, habit: HabitType? = nil, habitTime: Date? = nil, context: ModelContext) {
        let newTask = Task(
            title: title,
            status: .inProgress,
            difficultyLevel: difficultyLevel,
            repeatFrequency: repeatFrequency,
            taskTier: 1,
            deadline: deadline,
            currentDeadline: deadline,
            habit: habit,
            habitTime: habitTime
        )
        
        newTask.goal = self
        self.tasks.append(newTask)
        
        // Re-open goal if a new task is added
        if self.isCompleted {
            self.isCompleted = false
            self.deadline = nil
        }
        
        context.insert(newTask)
        try? context.save()
    }
    
    static func getAllGoals(context: ModelContext, sortedBy sortDescriptor: SortDescriptor<Goal> = SortDescriptor(\.startDate)) -> [Goal] {
        let descriptor = FetchDescriptor<Goal>(sortBy: [sortDescriptor])
        return (try? context.fetch(descriptor)) ?? []
    }
    
    static func findGoalById(goalId: UUID, in context: ModelContext) -> Goal? {
        let predicate = #Predicate<Goal> { $0.id == goalId }
        var descriptor = FetchDescriptor<Goal>(predicate: predicate)
        descriptor.fetchLimit = 1
        return (try? context.fetch(descriptor))?.first
    }
    
    func updateGoal(title: String? = nil, whyMatter: String? = nil, category: Set<GoalCategory>? = nil, startDate: Date? = nil, endDate: Date? = nil, currentDeadline: Date? = nil, deadline: Date? = nil, context: ModelContext) {
        if let title { self.title = title }
        if let whyMatter { self.whyMatter = whyMatter }
        if let category { self.category = category }
        if let startDate { self.startDate = startDate }
        if let deadline { self.deadline = deadline }
        if let currentDeadline { self.currentDeadline = currentDeadline }
        
        try? context.save()
    }
    
    func deleteGoal(context: ModelContext) {
        context.delete(self)
    }
}
