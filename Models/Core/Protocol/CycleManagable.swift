import Foundation

protocol CycleManagable: CompletableItem, AnyObject {
    var currentDeadline: Date? { get set }
    var repeatFrequency: RepeatFrequency { get }
    var habit: HabitType? { get }
    
    var activeChildren: [any CycleManagable] { get }
    
    func restartCycleState()
    func completeCycleState()
}

extension CycleManagable {
    func resetForNextCycle(startOfNewCycle: Date) {
        for item in activeChildren {
            if let hardDeadline = item.deadline, startOfNewCycle > hardDeadline {
                continue
            }
            
            if let hardDeadline = item.deadline, Calendar.current.isDate(startOfNewCycle, inSameDayAs: hardDeadline) {
                continue
            }
            
            var shouldUpdateDate = false
            
            if item.repeatFrequency != .never, let childDeadline = item.currentDeadline {
                if childDeadline < startOfNewCycle {
                    shouldUpdateDate = true
                }
            }
            
            if shouldUpdateDate {
                let childBaseDate = item.currentDeadline ?? startOfNewCycle
                item.restartCycleState()
                handleRepeatingItem(item, startOfCycle: childBaseDate)
            }
            
            item.resetForNextCycle(startOfNewCycle: startOfNewCycle)
        }
    }
    
    func handleRepeatingItem(_ item: any CycleManagable, startOfCycle: Date) {
        let calendar = Calendar.current
        
        let candidateDate: Date? = calculatedNextDeadline(from: startOfCycle, frequency: item.repeatFrequency)
        guard let nextDate = candidateDate else { return }
        
        let hardDeadline = item.deadline ?? (item as? Task)?.parent?.deadline
        guard let limit = hardDeadline else {
            item.currentDeadline = nextDate
            return
        }
        
        let nextDay = calendar.startOfDay(for: nextDate)
        let limitDay = calendar.startOfDay(for: limit)
        
        if nextDay >= limitDay {
            item.currentDeadline = limit
        } else {
            item.currentDeadline = nextDate
        }
    }
}


