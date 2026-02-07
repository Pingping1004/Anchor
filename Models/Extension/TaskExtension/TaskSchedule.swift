import Foundation
import SwiftData

extension Task {
    func calculateCurrentDeadline() {
        if repeatFrequency != .never {
            self.currentDeadline = calculatedNextDeadline(from: createdAt, frequency: repeatFrequency)
        } else {
            self.currentDeadline = deadline
        }
    }
    
    func updateFrequency(newFrequency: RepeatFrequency) -> Bool {
        let oldFreq = self.repeatFrequency
        if oldFreq == newFrequency { return false }
        
        self.repeatFrequency = newFrequency
        
        if newFrequency == .never {
            self.currentDeadline = self.deadline
            return true
        }
        
        if self.status.isCompleted {
            self.restartCycleState()
            parent?.childWasUnchecked()
            goal?.isCompleted = false
            
            if let hardDeadline = self.deadline, hardDeadline < Date() {
                self.deadline = nil
            }
        }
        
        if oldFreq == .never {
            self.restartCycleState()
            let newDeadline = calculatedNextDeadline(from: Date(), frequency: newFrequency) ?? Date()
            self.currentDeadline = clampToHierarchy(newDeadline)
            return true
        }
        
        let hardDeadline = self.deadline ?? self.goal?.deadline ?? Date()
        let baseDate = self.currentDeadline ?? Date()
        let checkpointDate = calculatePreviousDate(from: baseDate, frequency: oldFreq)
        let newDeadline = calculatedNextDeadline(from: checkpointDate, frequency: newFrequency) ?? hardDeadline
        
        self.currentDeadline = clampToHierarchy(newDeadline)
        return true
    }
    
    func updateDeadline(newDeadline: Date) {
        guard isDeadlineValidForHierarchy(newDeadline) else { return }
        
        self.deadline = newDeadline
        
        if self.repeatFrequency == .never {
            self.currentDeadline = newDeadline
            return
        }
        
        if let current = self.currentDeadline, current > newDeadline {
            self.currentDeadline = newDeadline
        }
        
        checkAndUnblockRepeatingSubtasks()
    }
    
    private func clampToHierarchy(_ date: Date) -> Date {
        if let parentDeadline = self.parent?.deadline {
            if date > parentDeadline {
                return parentDeadline
            }
        }
        
        if let hardDeadline = self.deadline {
            if date > hardDeadline {
                return hardDeadline
            }
        }
        
        return date
    }
    
    var latestDirectChildDeadline: Date? {
        let childDeadlines = subtasks.compactMap { $0.deadline }
        return childDeadlines.max()
    }
    
    func isDeadlineValidForHierarchy(_ proposed: Date?) -> Bool {
        if let parentDeadline = parent?.deadline, let proposed {
            if proposed > parentDeadline { return false }
        }
        
        if let proposed, let latestChild = latestDirectChildDeadline {
            if proposed < latestChild { return false }
        }
        return true
    }
}
