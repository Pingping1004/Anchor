import Foundation
import SwiftData

extension Task {
    var activeSubtasks: [Task] {
        let grouped = Dictionary(grouping: subtasks) { $0.recurrenceId ?? $0.id }
        let uniqueTasks = grouped.values.compactMap { siblings -> Task? in
            if let active = siblings.first(where: { !$0.isCompleted }) { return active }
            return siblings.max(by: { $0.createdAt < $1.createdAt })
        }
        return uniqueTasks.sorted { $0.createdAt < $1.createdAt }
    }
    
    var allActiveDescendants: [Task] {
        let directChildren = self.activeSubtasks
        let nestedChildren = directChildren.flatMap { $0.allActiveDescendants }
        return directChildren + nestedChildren
    }
    
    var allSubtasksFlattened: [Task] {
        var result: [Task] = subtasks
        for subtask in subtasks {
            result.append(contentsOf: subtask.allSubtasksFlattened)
        }
        return result
    }

    var totalTasks: Int {
        1 + subtasks.reduce(0) { $0 + $1.totalTasks }
    }
    
    var totalCompletedTasks: Int {
        (isTrulyCompleted ? 1 : 0) + subtasks.reduce(0) { $0 + $1.totalCompletedTasks }
    }
    
    func createVirtualGoal() -> Goal {
        let baseDate = self.currentDeadline ?? self.deadline
        
        let virtualGoal = Goal(
            id: self.id,
            title: self.title,
            category: self.goal?.category ?? [],
            whyMatter: "Sub level of \(self.title)",
            startDate: Date(),
            deadline: self.deadline,
            repeatFrequency: self.repeatFrequency,
            habit: self.habit,
            currentDeadline: baseDate
        )
        virtualGoal.isCompleted = self.isCompleted
        return virtualGoal
    }
}
