import Foundation
import SwiftData
import SwiftUI

@MainActor
@Observable
class GoalDetailViewModel {
    var goal: Goal
    var showIncompleteAlert = false
    var showingMissingGoalAlert = false
    
    init(goal: Goal) {
        self.goal = goal
    }

    func handleGoalToggle(context: ModelContext) {
        if goal.isCompleted {
            withAnimation(.snappy) {
                _ = goal.toggleGoal()
            }
            
            try? context.save()
            return
        }
        
        let hasIncompleteTasks = goal.tasks.contains { !$0.isTrulyCompleted }
        if hasIncompleteTasks {
            self.showIncompleteAlert = true
            return
        }
        
        if goal.repeatFrequency == .never {
            withAnimation(.snappy) {
                goal.completeCycleState()
            }
            
            try? context.save()
            return
        }
        
        withAnimation(.snappy) {
            goal.completeCycleState()
        }
        
        let targetGoal = goal
        SystemTask {
            try? await SystemTask.sleep(for: .seconds(0.5))
            
            withAnimation(.smooth) {
                targetGoal.advanceOrComplete()
            }
            
            try? context.save()
        }
    }
    
    func completeGoalAndAllSubtasks(context: ModelContext) {
        let allTasks = goal.allTasksFlattened
        for task in allTasks where !task.isCompleted {
            task.completeCycleState()
        }
        
        withAnimation {
            goal.completeCycleState()
            goal.currentDeadline = goal.deadline
        }
        
        try? context.save()
    }
    
//    func prepareForEditing() {
//        newWhyMatter = goal.whyMatter
//    }
    
    func saveChanges(context: ModelContext) {
        if goal.isDeleted {
            showingMissingGoalAlert = true
            return
        }
        
//        if goal.whyMatter != newWhyMatter {
//            goal.whyMatter = newWhyMatter
//        }
        
        try? context.save()
    }
}
