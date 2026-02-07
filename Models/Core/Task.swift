import Foundation
import SwiftData

@available(iOS 17, *)
@Model
final class Task: CompletableItem, CycleManagable {
    @Attribute(.unique) var id: UUID
    var recurrenceId: UUID?
    var title: String
    var status: TaskStatus
    var difficultyLevel: TaskDifficultyLevel
    var repeatFrequency: RepeatFrequency
    var taskTier: Int
    var deadline: Date?
    var currentDeadline: Date?
    var createdAt: Date
    var completedAt: Date?
    var habit: HabitType?
    var habitTime: Date?
    var parent: Task?
    var goal: Goal?
    
    @Relationship(deleteRule: .cascade, inverse: \Task.parent) var subtasks: [Task]
    
    init(
        id: UUID = UUID(),
        recurrenceId: UUID? = nil,
        title: String,
        status: TaskStatus,
        difficultyLevel: TaskDifficultyLevel,
        repeatFrequency: RepeatFrequency = .never,
        taskTier: Int,
        subtasks: [Task] = [],
        deadline: Date? = nil,
        currentDeadline: Date? = nil,
        habit: HabitType? = nil,
        habitTime: Date? = nil,
        createdAt: Date = Date(),
        completedAt: Date? = nil,
        
    ) {
        self.id = id
        self.recurrenceId = recurrenceId ?? (repeatFrequency != .never ? UUID() : nil)
        self.title = title
        self.status = status
        self.difficultyLevel = difficultyLevel
        self.repeatFrequency = repeatFrequency
        self.taskTier = taskTier
        self.subtasks = subtasks
        self.deadline = deadline
        
        if let currentDeadline = currentDeadline {
            self.currentDeadline = currentDeadline
        } else if repeatFrequency != .never {
            self.currentDeadline = createdAt
        } else {
            self.currentDeadline = deadline
        }
        
        self.habit = habit
        self.habitTime = habitTime
        self.createdAt = createdAt
        self.completedAt = completedAt
    }
}


struct DraftTask: Identifiable, Equatable {
    let id = UUID()
    var recurrenceId: UUID? = nil
    var title: String = ""
    var difficulty: TaskDifficultyLevel = .Medium
    var repeatFrequency: RepeatFrequency = .never
    var deadline: Date? = nil
    var habit: HabitType? = nil
    var habitTime: Date? = nil
    var tier: Int = 1
}
