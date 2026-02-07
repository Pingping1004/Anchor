import Foundation
import SwiftData

@Model
final class Goal: CompletableItem, CycleManagable {
    @Attribute(.unique) var id: UUID
    @Attribute(.ephemeral) var isVirtualGoal: Bool = false
    @Attribute(.ephemeral) var sourceTaskId: UUID? = nil
    
    var title: String
    var category: Set<GoalCategory>
    var whyMatter: String
    var completedAt: Date?
    var isCompleted: Bool
    var startDate: Date
    var deadline: Date?
    var repeatFrequency: RepeatFrequency
    var habit: HabitType?
    var currentDeadline: Date?
    weak var parent: Goal?
    
    @Relationship(deleteRule: .cascade, inverse: \Task.goal) var tasks: [Task] = []
    
    init(
        id: UUID = UUID(),
        title: String,
        category: Set<GoalCategory>,
        whyMatter: String,
        completedAt: Date? = nil,
        isCompleted: Bool = false,
        startDate: Date = Date(),
        deadline: Date? = nil,
        tasks: [Task] = [],
        repeatFrequency: RepeatFrequency = .never,
        habit: HabitType? = nil,
        currentDeadline: Date? = nil,
        parent: Goal? = nil,
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.whyMatter = whyMatter
        self.completedAt = completedAt
        self.isCompleted = isCompleted
        self.repeatFrequency = repeatFrequency
        self.habit = habit
        self.currentDeadline = currentDeadline
        self.startDate = startDate
        self.deadline = deadline
        self.parent = parent
        self.tasks = tasks
    }
}
