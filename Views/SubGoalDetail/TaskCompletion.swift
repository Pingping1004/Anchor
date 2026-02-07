import SwiftUI
import SwiftData

extension SubGoalViewModel {
    func completeAllInSubGoal() {
        completeTasksToFinalRound(tasks: task.subtasks)
        completeTaskFully(task)
        
        withAnimation(.spring) {
            refreshVirtualGoal()
        }
        
        try? context.save()
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    
    private func completeTasksToFinalRound(tasks: [Task]) {
        for t in tasks {
            completeTaskFully(t)
        }
    }
    
    private func completeTaskFully(_ t: Task) {
        if !t.subtasks.isEmpty {
            for child in t.subtasks {
                completeTaskFully(child)
            }
        }
        
        if t.isTrulyCompleted { return }
        
        if t.repeatFrequency == .never {
            markTaskCompleted(t)
            return
        }
        
        var safety = 256
        while !t.isTrulyCompleted && safety > 0 {
            safety -= 1
            _ = t.toggleTask()
            
            if !t.subtasks.isEmpty {
                for child in t.subtasks where !child.isTrulyCompleted {
                    completeTaskFully(child)
                }
            }
            
            if t.repeatFrequency == .never && !t.isTrulyCompleted {
                markTaskCompleted(t)
                break
            }
        }
    }
    
    private func markTaskCompleted(_ t: Task) {
        let now = Date()
        if let deadline = t.deadline {
            let cal = Calendar.current
            if cal.isDate(now, inSameDayAs: deadline) || now < deadline {
                t.status = .completedOnTime(completedAt: now)
            } else {
                let daysLate = cal.dateComponents([.day], from: deadline, to: now).day ?? 1
                t.status = .completedLate(completedAt: now, daysLate: max(1, daysLate))
            }
        } else {
            t.status = .completedOnTime(completedAt: now)
        }
        t.completedAt = now
    }
}
