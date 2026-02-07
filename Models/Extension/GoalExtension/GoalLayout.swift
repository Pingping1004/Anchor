import Foundation

extension Goal {
    func computeLayoutMetrics() -> (taskCounts: [Int: Int], visualCounts: [Int: Int]) {
        let taskCounts = calculateTaskCounts(startingFrom: activeRootTasks)
        let buttonCounts = calculateButtonCounts(startingFrom: activeRootTasks, using: taskCounts)
        
        var visualCounts = taskCounts
        for (tier, count) in buttonCounts {
            visualCounts[tier, default: 0] += count
        }
        
        return (taskCounts, visualCounts)
    }
    
    private func calculateTaskCounts(startingFrom tasks: [Task]) -> [Int: Int] {
        var counts = [Int: Int]()
        func traverse(_ tasks: [Task]) {
            for task in tasks {
                counts[task.taskTier, default: 0] += 1
                traverse(task.activeSubtasks)
            }
        }
        traverse(tasks)
        return counts
    }
    
    private func calculateButtonCounts(startingFrom tasks: [Task], using taskCounts: [Int: Int]) -> [Int: Int] {
        var counts = [Int: Int]()
        func traverse(_ tasks: [Task]) {
            for task in tasks {
                let childTier = task.taskTier + 1
                let taskCountInParentTier = taskCounts[task.taskTier] ?? 0
                let taskCountInChildTier = taskCounts[childTier] ?? 0
                
                let isCollapsed = task.activeSubtasks.count > 1 && (taskCountInChildTier >= 3 || taskCountInParentTier > 1)
                
                if isCollapsed {
                    counts[childTier, default: 0] += 1
                }
                traverse(task.activeSubtasks)
            }
        }
        traverse(tasks)
        return counts
    }
}
