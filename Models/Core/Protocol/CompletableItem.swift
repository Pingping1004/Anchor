import Foundation

protocol CompletableItem: AnyObject {
    var title: String { get set }
    var isCompleted: Bool { get set }
    var deadline: Date? { get }
}

extension CompletableItem {
    func isOverdue() -> Bool {
        if isCompleted { return false }
        
        let targetDate: Date?
        
        if let cycleItem = self as? CycleManagable {
            targetDate = cycleItem.currentDeadline ?? cycleItem.deadline
        } else {
            targetDate = deadline
        }
        
        guard let validDate = targetDate else { return false }
        
        return Date() > validDate
    }
}
