import Foundation

extension Goal {
    var totalTasks: Int {
        activeRootTasks.reduce(0) { $0 + $1.totalTasks }
    }
    
    var totalCompletedTasks: Int {
        activeRootTasks.reduce(0) { $0 + $1.totalCompletedTasks }
    }
    
    var overallProgress: Int {
        let isGoalCompleted = self.isCompleted ? 1 : 0
        guard totalTasks > 0 else { return isGoalCompleted * 100 }
        
        let totalItems = totalTasks + 1
        let completedItems = totalCompletedTasks + isGoalCompleted
        
        return Int((Double(completedItems) / Double(totalItems)) * 100.0)
    }
    
    var progressAsDecimal: Double {
        let isGoalCompleted = self.isCompleted ? 1.0 : 0.0
        guard !tasks.isEmpty else { return isGoalCompleted }
        
        let total = Double(totalTasks) + 1.0
        let completed = Double(totalCompletedTasks) + isGoalCompleted
        
        return total > 0 ? completed / total : 0.0
    }
    
    var deepestTaskTier: Int {
        return sumTasksPerTier().keys.max() ?? 0
    }
    
    func sumTasksPerTier() -> [Int: [Task]] {
        var dict: [Int: [Task]] = [:]
        func collectTasks(tasks: [Task]) {
            for task in tasks {
                dict[task.taskTier, default: []].append(task)
                if !task.activeSubtasks.isEmpty {
                    collectTasks(tasks: task.activeSubtasks)
                }
            }
        }
        collectTasks(tasks: self.activeRootTasks)
        return dict
    }
    
    func countTaskInTier() -> [Int: Int] {
        return sumTasksPerTier().mapValues { $0.count }
    }
    
    func countTaskInSpecificRow(inTier tier: Int) -> Int {
        return countTaskInTier()[tier] ?? 0
    }
}
