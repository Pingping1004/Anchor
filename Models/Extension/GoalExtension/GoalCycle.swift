import Foundation

extension Goal {
    var effectiveDeadline: Date? {
        if let parentDeadline = self.deadline {
            return parentDeadline
        }
        
        return parent?.effectiveDeadline
    }
    
    var canShiftToNextDeadline: Bool {
        if repeatFrequency == .never { return false }
        
        guard let hardLimit = self.effectiveDeadline else { return true }
        
        let base = self.currentDeadline ?? self.startDate
        let isAtLimit = Calendar.current.isDate(base, inSameDayAs: hardLimit)
        
        return !isAtLimit && base < hardLimit
    }
    
    func restartCycleState() {
        self.isCompleted = false
        self.completedAt = nil
    }
    
    func completeCycleState() {
        self.isCompleted = true
        self.completedAt = Date()
    }
    
    @discardableResult
    func toggleGoal() -> Bool {
        if self.isCompleted {
            self.restartCycleState()
            return true
        }
        
        self.advanceOrComplete()
        return true
    }
    
    private func finishRealGoal() -> Bool {
        if let hardDeadline = self.deadline ?? self.parent?.deadline {
            if self.currentDeadline != hardDeadline {
                self.currentDeadline = hardDeadline
            }
        }
        
        self.completeCycleState()
        return true
    }
    
    private func handleRepeatingVirtualGoal() -> Bool {
        let cal = Calendar.current
        
        let base = self.currentDeadline ?? self.startDate
        let hardStop = self.deadline ?? self.parent?.deadline
        
        if let limit = hardStop {
            if cal.isDate(base, inSameDayAs: limit) || base > limit {
                let result = finishRealGoal()
                return result
            }
        }
        
        guard let next = calculatedNextDeadline(from: base, frequency: self.repeatFrequency) else {
            return finishRealGoal()
        }
        
        if let limit = hardStop {
            let nextDay = cal.startOfDay(for: next)
            let limitDay = cal.startOfDay(for: limit)
            
            if nextDay >= limitDay {
                self.currentDeadline = limit
                self.restartCycleState()
                return true
            }
        }
        
        self.currentDeadline = next
        self.restartCycleState()

        let rootTasks = self.tasks.filter { $0.parent == nil }

        for task in rootTasks {
            if task.isCompleted && task.repeatFrequency != .never {
                _ = task.advanceTaskCycle()
            } else if task.isCompleted {
                task.restartCycleState()
            }
        }

        return true
    }
    
    func advanceOrComplete() {
        if self.repeatFrequency == .never {
            _ = finishRealGoal()
            return
        }
        
        _ = handleRepeatingVirtualGoal()
    }
}
