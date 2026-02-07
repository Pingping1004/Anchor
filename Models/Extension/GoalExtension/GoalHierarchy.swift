import Foundation

extension Goal {
    var activeChildren: [any CycleManagable] {
        return tasks as [any CycleManagable]
    }
    
    // Returns the top-level tasks, filtering out old history versions of recurring tasks
    var activeRootTasks: [Task] {
        let roots = tasks.filter { $0.parent == nil }
        
        // Group by recurrence ID to find the latest repeating task
        let grouped = Dictionary(grouping: roots) { $0.recurrenceId ?? $0.id }
        
        let uniqueTasks = grouped.values.compactMap { siblings -> Task? in
            if let active = siblings.first(where: { !$0.isCompleted }) {
                return active
            }
            return siblings.sorted { $0.createdAt < $1.createdAt }.first
        }
        
        return uniqueTasks.sorted { $0.createdAt < $1.createdAt }
    }
    
    var allTasksFlattened: [Task] {
        let roots = activeRootTasks
        return roots + roots.flatMap { $0.allSubtasksFlattened }
    }
    
    var rootTasks: [Task] {
        return self.tasks
    }
    
    var neareseParentDeadline: Date? {
        if let parentDeadline = parent?.deadline {
            return parentDeadline
        }
        
        return parent?.neareseParentDeadline
    }
}
