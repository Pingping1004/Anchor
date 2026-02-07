import SwiftUI
import Combine
import SwiftData

class HomeViewModel: ObservableObject {
    @Published var allGoals: [Goal]
    
    init(allGoals: [Goal] = []) {
        self.allGoals = allGoals
    }
    
    var currentFocusTask: Task? {
        let allIncompleteTasks = allGoals.flatMap { $0.tasks }.filter { !$0.isCompleted }
        
        return allIncompleteTasks.sorted { task1, task2 in
            let date1 = task1.deadline ?? Date.distantFuture
            let date2 = task2.deadline ?? Date.distantFuture
            
            let days1 = daysUntil(date1)
            let days2 = daysUntil(date2)
            
            if days1 != days2 {
                return days1 < days2
            }
            
            return task1.difficultyLevel.rawValue > task2.difficultyLevel.rawValue
        }.first
    }
    
    var upcomingDeadlineGoal: Goal? {
        let activeGoals = allGoals.filter { goal in
            guard let deadline = goal.deadline else { return false }
            return !goal.isCompleted && deadline > Date()
        }
        
        return activeGoals.sorted { ($0.deadline ?? Date.distantFuture) < ($1.deadline ?? Date.distantFuture) }.first
    }
    
    private func daysUntil(_ date: Date) -> Int {
        Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 999
    }
    
    func updateGoals(_ newGoals: [Goal]) {
        self.allGoals = newGoals
    }
}
