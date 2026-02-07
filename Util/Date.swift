import Foundation

extension Date {
    var formattedDeadline: String {
        let calendar = Calendar.current
        
        if calendar.isDateInToday(self) {
            return String(localized: "Today")
        }
        
        if calendar.isDateInTomorrow(self) {
            return String(localized: "Tomorrow")
        }
        
        let isCurrentYear = calendar.isDate(self, equalTo: Date(), toGranularity: .year)
        
        if isCurrentYear {
            return self.formatted(.dateTime.day().month(.abbreviated))
        } else {
            return self.formatted(.dateTime.day().month(.defaultDigits).year(.twoDigits))
        }
    }
}

func calculatedNextDeadline(from baseDate: Date, frequency: RepeatFrequency) -> Date? {
    let calendar = Calendar.current
    
    if baseDate == .distantPast { return Date() }
    
    var calculatedDate: Date?
    
    switch frequency {
    case .daily: calculatedDate = calendar.date(byAdding: .day, value: 1, to: baseDate)
    case .weekly: calculatedDate = calendar.date(byAdding: .day, value: 7, to: baseDate)
    case .monthly: calculatedDate = calendar.date(byAdding: .month, value: 1, to: baseDate)
    case .quarterly: calculatedDate = calendar.date(byAdding: .month, value: 3, to: baseDate)
    case .never: return nil
    }
    
    if let date = calculatedDate {
        return calendar.date(bySettingHour: 23, minute: 59, second: 59, of: date)
    }
    
    return nil
}

func calculatePreviousDate(from date: Date, frequency: RepeatFrequency) -> Date {
    let calendar = Calendar.current
    let previousDate: Date?
    
    switch frequency {
    case .daily: previousDate = calendar.date(byAdding: .day, value: -1, to: date)
    case .weekly: previousDate = calendar.date(byAdding: .day, value: -7, to: date)
    case .monthly: previousDate = calendar.date(byAdding: .month, value: -1, to: date)
    case .quarterly: previousDate = calendar.date(byAdding: .month, value: -3, to: date)
    case .never: previousDate = date
    }
    
    return previousDate ?? date
}
