import Foundation

struct RecommendationContent {
    let title: String
    let message: String
}

struct GoalAnalyticsHelper {
    let goal: Goal
    
    private var today: Date { Date() }
    private var calendar: Calendar { Calendar.current }

    // Smart Pacer(calculate achievable feasibility)
    var paceRecommendation: RecommendationContent {
        guard let deadline = goal.deadline else {
            return RecommendationContent(title: "Define the Finish Line", message: "Without a deadline, I can't calculate velocity.")
        }
        
        let activeTasks = goal.tasks.filter { !$0.isCompleted }
        let daysLeft = max(1, calendar.dateComponents([.day], from: today, to: deadline).day ?? 1)
        
        let projectedLoad: (Task) -> Int = { task in
            switch task.repeatFrequency {
            case .never: return 1
            case .daily: return daysLeft
            case .weekly: return max(1, daysLeft / 7)
            case .monthly: return max(1, daysLeft / 30)
            case .quarterly: return max(1, daysLeft / 90)
            }
        }
        
        // Get Total Actions & Difficult Actions at once
        let stats = activeTasks.reduce(into: (total: 0, difficult: 0)) { res, task in
            let load = projectedLoad(task)
            res.total += load
            if task.difficultyLevel == .Difficult { res.difficult += load }
        }
        
        if stats.total == 0 {
            return RecommendationContent(title: "Ready to Archive?", message: "Goal looks complete!")
        }
        
        let dailyRate = Double(stats.total) / Double(daysLeft)
        
        if (dailyRate > 3.0 && stats.difficult >= 2) || dailyRate > 5.0 {
            return RecommendationContent(
                title: "⚠️ Pace Alert: \(Int(ceil(dailyRate))) Actions/Day",
                message: "Recurring habits are piling up. You need to clear ~\(Int(ceil(dailyRate))) items daily. Consider pausing some habits."
            )
        }
        
        if dailyRate > 1.2 {
            let activeOneTimeTaskCount = activeTasks.filter { $0.repeatFrequency == .never }.count
            return RecommendationContent(
                title: "Tight Schedule",
                message: "You have \(activeOneTimeTaskCount) milestones and ~\(stats.total - activeOneTimeTaskCount) repeat sessions left. Try a 'One-Off' task today."
            )
        }
        
        return RecommendationContent(title: "Sustainable Pace", message: "You're cruising. Current pace is enough to finish on time.")
    }
    
    // Burnout Guard (The "Friction" Detector)
    var workloadRecommendation: RecommendationContent {
        let activeTasks = goal.tasks.filter { !$0.isCompleted }
        let nonEasyTasks = activeTasks.filter({ $0.difficultyLevel != .Easy })
        
        var counts: [RepeatFrequency: Int] = [:]
        for task in nonEasyTasks {
            counts[task.repeatFrequency, default: 0] += 1
        }
        
        let limits: [RepeatFrequency: Int] = [
            .daily: 2,
            .weekly: 3,
            .monthly: 4,
            .quarterly: 2
        ]
        
        var worstOffender: (freq: RepeatFrequency, count: Int, excess: Int)? = nil
        for (freq, limit) in limits {
            let actualCount = counts[freq] ?? 0
            let excess = actualCount - limit
            
            if excess > 0 {
                if worstOffender == nil || excess > worstOffender!.excess {
                    worstOffender = (freq, actualCount, excess)
                }
            }
        }
        
        if let violation = worstOffender {
            let intervalName = violation.freq.rawValue.capitalized
            
            return RecommendationContent(
                title: "🛑 High Friction: \(intervalName)",
                message: "You have \(violation.count) non-easy tasks repeating \(violation.freq.rawValue). This exceeds the safe limit of \(limits[violation.freq]!). Consider downgrading some to 'Easy' or changing the frequency."
            )
        }
        
        let highDiff = activeTasks.filter { $0.difficultyLevel == .Difficult }
        if Double(highDiff.count) / Double(max(1, activeTasks.count)) > 0.5 {
            return RecommendationContent(
                title: "Divide & Conquer",
                message: "Over 50% of your remaining work is rated 'Difficult'. Break one of these big rocks into subtasks today."
            )
        }
        
        return RecommendationContent(
            title: "Healthy Balance",
            message: "Your workload mix looks good. No specific intervals are overloaded."
        )
    }
    
    // Detects "Procrastination Loops" (Skipping specific types of work)
    var synergyRecommendation: RecommendationContent {
        // Find tasks that haven't been touched in 7+ days despite being active
        if isWeekendWarrior() {
            return RecommendationContent(
                title: "Weekend Warrior Profile",
                message: "Data shows you clear queues on Sat/Sun. Don't stress about low weekday output; just load up your list for the weekend."
            )
        }
        
        if let bestDay = getBestDayName() {
            return RecommendationContent(
                title: "Peak Performance: \(bestDay)s",
                message: "You historically complete the most tasks on \(bestDay)s. Schedule your hardest remaining task ('\(goal.tasks.first(where: {!$0.isCompleted && $0.difficultyLevel == .Difficult})?.title ?? "Project")') for this \(bestDay)."
            )
        }
        
        return RecommendationContent(
            title: "Build Your Rhythm",
            message: "Try grouping similar tasks (e.g., do all 'Easy' tasks on Friday) to minimize context switching."
        )
    }
    
    // Distinguishes "Stuck" (needs easy win) vs "Rolling" (needs challenge)
    var reliabilityRecommendation: RecommendationContent {
        let lastCompletionDate = goal.tasks.filter({ $0.isCompleted }).compactMap({ $0.completedAt }).max() ?? Date.distantPast
        let daysSinceAction = calendar.dateComponents([.day], from: lastCompletionDate, to: today).day ?? 10
        
        if daysSinceAction > 4 {
            if let candyTask = goal.tasks.filter({ !$0.isCompleted && $0.difficultyLevel == .Easy }).first {
                return RecommendationContent(
                    title: "🧊 Ice Breaker",
                    message: "You've been stalled for \(daysSinceAction > 10 ? "10+" : String(daysSinceAction)) days. Forget the big picture. Just do '\(candyTask.title)' today. It's easy and will restart your engine."
                )
            } else {
                return RecommendationContent(
                    title: "Tiny Step Required",
                    message: "Momentum is cold. Create a dummy task called 'Open App' and check it off. Just keep the momentum."
                )
            }
        }
        
        if daysSinceAction <= 1 {
            if let blocker = goal.tasks.first(where: { !$0.isCompleted && $0.difficultyLevel == .Difficult }) {
                return RecommendationContent(
                    title: "🔥 You're On Fire",
                    message: "Momentum is high! Use this energy to tackle '\(blocker.title)' while you feel motivated. Don't waste a good mood on easy tasks."
                )
            }
        }
        
        if let streakInfo = getStrongestRepeatStreak() {
            return RecommendationContent(
                title: "Habit Formed: \(streakInfo.name)",
                message: "You've hit '\(streakInfo.name)' \(streakInfo.count) times in a row. This is the backbone of your success. Keep this chain unbroken!"
            )
        }
        
        return RecommendationContent(
            title: "Steady Progress",
            message: "You are consistent. Remember: 'Slow is smooth, and smooth is fast.'"
        )
    }
    
    private func isWeekendWarrior() -> Bool {
        let completed = goal.tasks.filter { $0.isCompleted }
        guard !completed.isEmpty else { return false }
        
        let weekends = completed.filter {
            let weekday = calendar.component(.weekday, from: $0.completedAt ?? Date())
            return weekday == 1 || weekday == 7 // Sun, Sat
        }
        return Double(weekends.count) / Double(completed.count) > 0.65
    }

    private func getBestDayName() -> String? {
        let completed = goal.tasks.filter { $0.isCompleted }
        guard !completed.isEmpty else { return nil }
        
        var counts: [Int: Int] = [:]
        for task in completed {
            if let date = task.completedAt {
                let weekday = calendar.component(.weekday, from: date)
                counts[weekday, default: 0] += 1
            }
        }
        
        guard let max = counts.max(by: { $0.value < $1.value }), max.value > 3 else { return nil }
        return calendar.weekdaySymbols[max.key - 1]
    }
    
    private func getStrongestRepeatStreak() -> (name: String, count: Int)? {
        let completed = goal.tasks.filter { $0.isCompleted && $0.repeatFrequency != .never }
        let grouped = Dictionary(grouping: completed, by: { $0.title })
        
        if let best = grouped.max(by: { $0.value.count < $1.value.count }), best.value.count >= 3 {
            return (best.key, best.value.count)
        }
        return nil
    }
}
