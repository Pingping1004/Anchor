import Foundation

extension Goal {
    
    var minimumAllowedDate: Date {
        let latestTaskDate = activeRootTasks.compactMap { $0.deadline }.max()
        return latestTaskDate ?? Date()
    }
    
    var timeRemaining: String {
        guard let end = deadline else { return "No Deadline" }
        if isCompleted { return "Completed" }
        
        let now = Date()
        let calendar = Calendar.current
        
        if calendar.isDateInToday(end) { return "Ends Today" }
        if calendar.isDateInTomorrow(end) { return "Ends Tomorrow" }
        
        if end < now {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .full
            return "Overdue " + formatter.localizedString(for: end, relativeTo: now)
        }
        
        let daysUntil = calendar.dateComponents([.day], from: now, to: end).day ?? 0
        
        if daysUntil < 14 {
            let formatter = RelativeDateTimeFormatter()
            formatter.dateTimeStyle = .named
            return formatter.localizedString(for: end, relativeTo: now)
        } else {
            return end.formatted(date: .abbreviated, time: .omitted)
        }
    }
    
    func daysBeforeDeadline(from start: Date = Date(), to end: Date) -> Int {
        let calendar = Calendar.current
        let startDay = calendar.startOfDay(for: start)
        let endDay = calendar.startOfDay(for: end)
        return max(0, calendar.dateComponents([.day], from: startDay, to: endDay).day ?? 0)
    }
    
    var timeToFinish: Int {
        guard let goalDeadLine = deadline else { return 0 }
        let calendar = Calendar.current
        let startOfGoal = calendar.startOfDay(for: startDate)
        let endOfGoal = calendar.startOfDay(for: goalDeadLine)
        return max(0, calendar.dateComponents([.day], from: startOfGoal, to: endOfGoal).day ?? 0)
    }
    
    func isOverdue(date: Date) -> Bool {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let deadlineDay = calendar.startOfDay(for: date)
        return deadlineDay < startOfToday && !self.isCompleted
    }
}
