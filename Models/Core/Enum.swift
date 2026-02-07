import SwiftUI
import Foundation

enum GoalCategory: String, Codable, CaseIterable, CustomStringConvertible {
    case health, career, personal, finance, learning
    var description: String { rawValue.capitalized }
    
    var iconName: String {
        switch self {
        case .health:
            return "heart.fill"
        case .career:
            return "briefcase.fill"
        case .personal:
            return "person.fill"
        case .finance:
            return "dollarsign.circle.fill"
        case .learning:
            return "book.fill"
        }
    }
}

enum GoalCompletionStatus {
    case inProgress
    case completedOnTime
    case completedLate
}

enum TaskDifficultyLevel: String, CaseIterable, Codable {
    case Easy = "easy"
    case Medium = "medium"
    case Difficult = "difficult"
    
    static func < (lhs: TaskDifficultyLevel, rhs: TaskDifficultyLevel) -> Bool {
        let order: [TaskDifficultyLevel] = [.Easy, .Medium, .Difficult]
        return order.firstIndex(of: lhs)! < order.firstIndex(of: rhs)!
    }
}

enum TaskStatus: Equatable, Codable {
    case inProgress
    case completedOnTime(completedAt: Date = Date())
    case completedLate(completedAt: Date? = nil, daysLate: Int? = nil)
    
    
    var isOnTime: Bool {
        if case .completedOnTime = self { return true }
        return false
    }

    var isLate: Bool {
        if case .completedLate = self { return true }
        return false
    }

    var isCompleted: Bool {
        return isOnTime || isLate
    }
}

enum RepeatFrequency: String, Codable, CaseIterable {
    case never = "Never"
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
    case quarterly = "Quarterly"
}

enum GoalSheetType: Identifiable {
    case datePicker
    case categoryPicker
    
    var id: Int { hashValue }
}

enum TaskCardSheetType: Identifiable {
    case datePicker
    case habitSheet
    
    var id: Int { hashValue }
}

enum HabitType: String, Codable, CaseIterable {
    case wakeUp = "🌅 Wake Up"
    case morningCoffee = "☕ Morning Coffee"
    case startWorking = "🏢 Start Working"
    case prepateToSleep = "🛌 Prepate To Sleep"
    case arriveHome = "🏠 Arrive Home"
    case finishMeal = "🍽️ Finish Meal"
    
    var iconName: String {
        switch self {
        case .wakeUp: return "sunrise.fill"
        case .morningCoffee: return "cup.and.saucer.fill"
        case .startWorking: return "briefcase.fill"
        case .prepateToSleep: return "bed.double.fill"
        case .arriveHome: return "house.fill"
        case .finishMeal: return "fork.knife"
        }
    }
    
    var iconLabel: String {
        switch self {
        case .wakeUp: return "🌅"
        case .morningCoffee: return "☕"
        case .startWorking: return "🏢"
        case .prepateToSleep: return "🛌"
        case .arriveHome: return "🏠"
        case .finishMeal: return "🍽️"
        }
    }
    
    var color: Color {
        switch self {
        case .wakeUp: return .yellow
        case .morningCoffee: return .brown
        case .startWorking: return .blue
        case .prepateToSleep: return .indigo
        case .arriveHome: return .green
        case .finishMeal: return .orange
        }
    }
    
    var cleanTitle: String {
        return String(rawValue.dropFirst(2)).trimmingCharacters(in: .whitespaces)
    }
    
    var defaultTimeWindow: Int {
        switch self {
        case .wakeUp: return 6
        case .morningCoffee: return 8
        case .startWorking: return 9
        case .finishMeal: return 12
        case .arriveHome: return 19
        case .prepateToSleep: return 0
        }
    }
}
