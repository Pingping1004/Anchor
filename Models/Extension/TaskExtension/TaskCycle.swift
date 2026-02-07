import Foundation
import SwiftData

extension Task {
    var activeChildren: [any CycleManagable] { subtasks as [any CycleManagable] }

    var isCompleted: Bool {
        get { return status != .inProgress }
        set {
            if newValue {
                completeCycleState()
            } else {
                restartCycleState()
            }
        }
    }
    
    var isTrulyCompleted: Bool {
        if !isCompleted { return false }
        if subtasks.isEmpty { return true }
        
        return activeSubtasks.allSatisfy { $0.isTrulyCompleted }
    }
    
    var areAllDescendantsCompleted: Bool {
        if subtasks.isEmpty { return true }
        return activeSubtasks.allSatisfy { $0.isTrulyCompleted }
    }
    
    var isDeadlineExceedingParent: Bool {
        guard let parent = self.parent else { return false }
        
        let parentLimit = parent.currentDeadline ?? parent.deadline ?? Date.distantFuture
        
        guard let myDeadline = self.currentDeadline ?? self.deadline else { return false }
        
        return Calendar.current.compare(myDeadline, to: parentLimit, toGranularity: .day) == .orderedDescending
    }

    var canBeCompleted: Bool {
        if subtasks.isEmpty { return true }
        if areAllDescendantsCompleted { return true }
        
        let deadline = self.currentDeadline ?? self.deadline ?? Date.distantFuture
        let calendar = Calendar.current
        
        let anyChildExceedsParent = activeSubtasks.contains { child in
            guard let childDeadline = child.currentDeadline ?? child.deadline else { return false }
            return calendar.compare(childDeadline, to: deadline, toGranularity: .day) == .orderedDescending
        }
        
        if anyChildExceedsParent {
            return true
        }
        
        for child in activeSubtasks {
            if !child.isTrulyCompleted {
                guard let childDeadline = child.currentDeadline ?? child.deadline else {
                    return false
                }
                
                let comparison = calendar.compare(childDeadline, to: deadline, toGranularity: .day)
                if comparison == .orderedAscending || comparison == .orderedSame {
                    return false
                }
            }
        }
        
        return true
    }
    
    var canShiftToNextDeadline: Bool {
        if repeatFrequency == .never { return false }
        
        guard let hardLimit = self.deadline ?? self.parent?.deadline else { return true }
        
        let base = self.currentDeadline ?? self.createdAt
        let isAtLimit = Calendar.current.isDate(base, inSameDayAs: hardLimit)
        
        return !isAtLimit && base < hardLimit
    }
    
    func restartCycleState() {
        self.status = .inProgress
        self.completedAt = nil
        
        if repeatFrequency == .never {
            self.currentDeadline = self.deadline
        }
        
        parent?.childWasUnchecked()
        checkGoalCompletion()
    }
    
    func completeCycleState() {
        self.status = .completedOnTime(completedAt: Date())
    }
    
    @discardableResult
    func toggleTask(context: ModelContext? = nil) -> Bool {
        switch status {
        case .inProgress:
            guard canBeCompleted else { return false }
            
            if repeatFrequency != .never {
                return advanceTaskCycle()
            } else {
                return completeTask()
            }
            
        case .completedOnTime, .completedLate:
            restartCycleState()
            return true
        }
    }
    
    private func completeTask() -> Bool {
        updateCompletionStatus()
        parent?.childDidChange()
        checkGoalCompletion()
        return true
    }
    
    private func checkGoalCompletion() {
        guard parent == nil, let goal = goal else { return }
        
        if goal.isCompleted {
            let hasInCompletedTasks = goal.tasks.contains { !$0.isCompleted }
            
            if hasInCompletedTasks {
                goal.restartCycleState()
            }
        }
    }
    
    func advanceTaskCycle() -> Bool {
        let baseDate = currentDeadline ?? deadline ?? Date()
        let calendar = Calendar.current
        
        if let hardDeadline = self.deadline,
           calendar.isDate(baseDate, inSameDayAs: hardDeadline) {
            return completeTask()
        }
        
        guard let nextDeadline = calculatedNextDeadline(from: baseDate, frequency: repeatFrequency) else {
            return completeTask()
        }
        
        // Check if next exceeds hard deadline
        if let hardDeadline = self.deadline {
            let nextDay = calendar.startOfDay(for: nextDeadline)
            let limitDay = calendar.startOfDay(for: hardDeadline)
            
            if nextDay >= limitDay {
                self.currentDeadline = hardDeadline
                self.restartCycleState()
                
                handleChildCascade(newParentDeadline: hardDeadline, strict: false)
                
                parent?.childDidChange()
                checkGoalCompletion()
                return true
            }
        }
        
        if let parent = parent,
           let parentCurrentDeadline = parent.currentDeadline ?? goal?.currentDeadline {
            let nextDay = calendar.startOfDay(for: nextDeadline)
            let parentDay = calendar.startOfDay(for: parentCurrentDeadline)
            
            if nextDay >= parentDay {
                self.completeCycleState()
                checkGoalCompletion()
                return true
            }
        }
        
        // Check parent's hard deadline (if exists)
        if let parent = parent,
           let parentHardDeadline = parent.deadline {
            if nextDeadline > parentHardDeadline {
                return completeTask()
            }
        }
        
        self.currentDeadline = nextDeadline
        self.restartCycleState()
        
        handleChildCascade(newParentDeadline: nextDeadline, strict: true)
        
        parent?.childDidChange()
        checkGoalCompletion()
        
        return true
    }
    
    private func handleChildCascade(newParentDeadline: Date, strict: Bool) {
        let calendar = Calendar.current
        let newDeadlineDay = calendar.startOfDay(for: newParentDeadline)
        
        for child in subtasks {
            guard child.isCompleted else { continue }
            
            if child.repeatFrequency == .never {
                continue
            }
            
            let childBase = child.currentDeadline ?? child.deadline ?? Date()
            guard let childNext = calculatedNextDeadline(from: childBase, frequency: child.repeatFrequency) else { continue }
            
            let childNextDay = calendar.startOfDay(for: childNext)
            if childNextDay <= newDeadlineDay {
                _ = child.advanceTaskCycle()
            } else {
                if !child.isCompleted { child.completeCycleState() }
            }
        }
    }
    
    func childWasUnchecked() {
        if isCompleted && !areAllDescendantsCompleted {
            self.restartCycleState()
            parent?.childWasUnchecked()
            checkGoalCompletion()
        }
    }
    
    func childDidChange() {
        if subtasks.isEmpty {
            parent?.childDidChange()
            checkGoalCompletion()
            return
        }
        
        let hasBlockingIncompleteChildren = activeSubtasks.contains { child in
            !child.isTrulyCompleted && !child.isDeadlineExceedingParent
        }
        
        if hasBlockingIncompleteChildren && isCompleted {
            self.restartCycleState()
        }
        
        parent?.childDidChange()
        checkGoalCompletion()
    }
    
    private func updateCompletionStatus() {
        let now = Date()
        
        guard let deadline = self.deadline else {
            self.status = .completedOnTime(completedAt: now)
            self.completedAt = now
            return
        }
        
        let calendar = Calendar.current
        if calendar.isDate(now, inSameDayAs: deadline) || now < deadline {
            self.status = .completedOnTime(completedAt: now)
        } else {
            let daysLate = calendar.dateComponents([.day], from: deadline, to: now).day ?? 1
            self.status = .completedLate(completedAt: now, daysLate: max(1, daysLate))
        }
        
        self.completedAt = now
    }
    
    func checkAndUnblockRepeatingSubtasks() {
        let parentLimit = self.currentDeadline ?? self.deadline ?? Date.distantFuture
        let calendar = Calendar.current
        
        for subtask in self.subtasks {
            if subtask.isCompleted && subtask.repeatFrequency != .never {
                
                let base = subtask.currentDeadline ?? subtask.createdAt
                if let next = calculatedNextDeadline(from: base, frequency: subtask.repeatFrequency) {
                    
                    let nextDay = calendar.startOfDay(for: next)
                    let limitDay = calendar.startOfDay(for: parentLimit)
                    
                    // Deadline shifting logic
                    if nextDay <= limitDay {
                        subtask.currentDeadline = next
                        subtask.restartCycleState()
                        subtask.checkAndUnblockRepeatingSubtasks()
                    }
                }
            } else {
                subtask.checkAndUnblockRepeatingSubtasks()
            }
        }
    }
}
