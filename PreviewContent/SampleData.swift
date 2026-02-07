import SwiftUI
import SwiftData

@MainActor
struct PreviewContent {
    static let container: ModelContainer = {
        let schema = Schema([Goal.self, Task.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        
        do {
            let container = try ModelContainer(for: schema, configurations: config)
            insertSampleData(into: container.mainContext)
            
            return container
        } catch {
            fatalError("Failed to create preview container: \(error)")
        }
    }()
    
    static var sampleGoal: Goal {
        let context = container.mainContext
        
        let descriptor = FetchDescriptor<Goal>()
        if let foundGoal = try? context.fetch(descriptor).first {
            return foundGoal
        }
        
        return Goal(title: "Fallback Goal", category: [.career, .finance], whyMatter: "Error fallback matter")
    }
    
    static func insertSampleData(into context: ModelContext) {
        let twoWeeksLater = Calendar.current.date(byAdding: .weekOfYear, value: 2, to: Date())!
        
        let goal = Goal(
            title: "Launch 'FitTrack' MVP",
            category: [.career, .personal],
            whyMatter: "To build a passive income stream and master SwiftData architecture.",
            deadline: calculatedNextDeadline(from: Date(), frequency: .quarterly),
            repeatFrequency: .never
        )
        context.insert(goal)
        
        let taskA_Design = Task(
            title: "Finalize UI/UX Design System",
            status: .inProgress,
            difficultyLevel: .Difficult,
            repeatFrequency: .weekly,
            taskTier: 1,
            deadline: calculatedNextDeadline(from: Date(), frequency: .monthly),
            habit: .arriveHome
        )
        
        let taskB_Dev = Task(
            title: "Core Feature Implementation",
            status: .inProgress,
            difficultyLevel: .Difficult,
            repeatFrequency: .weekly,
            taskTier: 1,
            deadline: calculatedNextDeadline(from: Date(), frequency: .quarterly),
            habit: .wakeUp
        )
        
        goal.tasks.append(contentsOf: [taskA_Design, taskB_Dev])
        
        let task2a = Task(
            title: "High-Fidelity Prototyping",
            status: .inProgress,
            difficultyLevel: .Difficult,
            repeatFrequency: .never,
            taskTier: 2,
            deadline: calculatedNextDeadline(from: Date(), frequency: .monthly),
            habit: .morningCoffee
        )
        
        let task2b = Task(
            title: "Competitor Analysis",
            status: .inProgress,
            difficultyLevel: .Easy,
            repeatFrequency: .never,
            taskTier: 2,
            deadline: twoWeeksLater,
            habit: .prepateToSleep
        )
        
        let task2x = Task(
            title: "Daily UI Inspiration Log",
            status: .inProgress,
            difficultyLevel: .Easy,
            repeatFrequency: .daily,
            taskTier: 2,
            deadline: twoWeeksLater,
            habit: .arriveHome
        )
        
        taskA_Design.subtasks.append(contentsOf: [task2a, task2b, task2x])
        
        let task2c = Task(
            title: "Data Persistence Layer (SwiftData)",
            status: .inProgress,
            difficultyLevel: .Difficult,
            repeatFrequency: .weekly,
            taskTier: 2,
            deadline: calculatedNextDeadline(from: Date(), frequency: .monthly),
            habit: .wakeUp
        )
        
        let task2d = Task(
            title: "Write XCTests for ViewModels",
            status: .inProgress,
            difficultyLevel: .Medium,
            repeatFrequency: .weekly,
            taskTier: 2,
            deadline: calculatedNextDeadline(from: Date(), frequency: .monthly),
            habit: .finishMeal
        )
        
        taskB_Dev.subtasks.append(contentsOf: [task2c, task2d])
        
        let task3a = Task(
            title: "Draft 'Home' Dashboard Wireframe",
            status: .completedOnTime(completedAt: Date()),
            difficultyLevel: .Medium,
            repeatFrequency: .never,
            taskTier: 3,
            deadline: calculatedNextDeadline(from: Date(), frequency: .weekly)
        )
        
        let pastDate = Calendar.current.date(byAdding: .day, value: -3, to: Date())!
        let task3b = Task(
            title: "Export Icons & Assets ",
            status: .inProgress,
            difficultyLevel: .Easy,
            repeatFrequency: .never,
            taskTier: 3,
            deadline: pastDate
        )
        
        task2a.subtasks.append(contentsOf: [task3a, task3b])
        
        let task3c = Task(
            title: "Download and try to use top 5 fitness apps",
            status: .inProgress,
            difficultyLevel: .Easy,
            repeatFrequency: .never,
            taskTier: 3,
            deadline: calculatedNextDeadline(from: Date(), frequency: .weekly),
            habit: .arriveHome
        )
        task2b.subtasks.append(task3c)
        
        let task3x = Task(
            title: "Save 3 designs to Pinterest board",
            status: .inProgress,
            difficultyLevel: .Easy,
            repeatFrequency: .daily,
            taskTier: 3,
            deadline: calculatedNextDeadline(from: Date(), frequency: .weekly)
        )
        task2x.subtasks.append(task3x)
        
        let task3d1 = Task(
            title: "Define 'Workout' Model Schema",
            status: .inProgress,
            difficultyLevel: .Difficult,
            repeatFrequency: .never,
            taskTier: 3,
            deadline: calculatedNextDeadline(from: Date(), frequency: .weekly)
        )
        
        let task3e = Task(
            title: "Create Mock Data Seeder",
            status: .inProgress,
            difficultyLevel: .Medium,
            repeatFrequency: .never,
            taskTier: 3,
            deadline: calculatedNextDeadline(from: Date(), frequency: .weekly)
        )
        task2c.subtasks.append(contentsOf: [task3d1, task3e])
        
        let task3f = Task(
            title: "Test 'GoalCompletion' Logic",
            status: .inProgress,
            difficultyLevel: .Medium,
            repeatFrequency: .weekly,
            taskTier: 3,
            deadline: calculatedNextDeadline(from: Date(), frequency: .weekly)
        )
        
        let task3g = Task(
            title: "Refactor 'DetailView' Previews",
            status: .inProgress,
            difficultyLevel: .Easy,
            repeatFrequency: .never,
            taskTier: 3,
            deadline: calculatedNextDeadline(from: Date(), frequency: .monthly)
        )
        task2d.subtasks.append(contentsOf: [task3f, task3g])
    }
}
