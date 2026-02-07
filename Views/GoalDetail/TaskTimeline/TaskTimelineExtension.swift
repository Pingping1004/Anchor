import SwiftUI

extension GoalTaskTimelineView {
    func shiftToTask(offset: Int) {
        guard let currentIndex = tasks.firstIndex(where: { $0.id == selectedTaskID }) else {
            return
        }
        
        let newIndex = currentIndex + offset
        
        if newIndex >= 0 && newIndex < tasks.count {
            let newTask = tasks[newIndex]
            
            withAnimation(.snappy) {
                selectedTaskID = newTask.id
            }
        }
    }
    
    var currentTaskSummary: String {
        guard let currentID = selectedTaskID,
              let index = timelineTasks.firstIndex(where: { $0.id == currentID }) else {
            return "No task selected"
        }
        
        let currentTask = timelineTasks[index]
        let status = currentTask.isCompleted ? "Completed" : "Incomplete"
        let deadline = currentTask.deadline?.formattedDeadline ?? "No deadline"
        
        return "Task \(index + 1) of \(timelineTasks.count): \(currentTask.title), \(status), due \(deadline)"
    }
}
