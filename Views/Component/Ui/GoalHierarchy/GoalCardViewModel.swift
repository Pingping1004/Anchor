import Foundation
import SwiftData
import SwiftUI

typealias SystemTask = _Concurrency.Task

@MainActor
@Observable
class GoalCardViewModel {
    var goal: Goal
    var context: ModelContext
    
    var activeSheet: GoalSheetType?
    private var isProcessing = false
    
    init(goal: Goal, context: ModelContext) {
        self.goal = goal
        self.context = context
    }
    
    func handleToggle(completionCheckTasks: [Task]?) {
        if goal.isCompleted {
            withAnimation(.snappy) {
                goal.restartCycleState()
            }
            return
        }
        
        if goal.repeatFrequency == .never {
            withAnimation(.snappy) {
                goal.completeCycleState()
            }
            return
        }
        
        
        withAnimation(.snappy) {
            goal.completeCycleState()
        }
        
        
        let targetGoal = goal
        if targetGoal.canShiftToNextDeadline {
            SystemTask {
                try? await SystemTask.sleep(for: .seconds(0.4))
                
                withAnimation(.smooth) {
                    targetGoal.advanceOrComplete()
                }
            }
        }
    }
    
    private func saveAndFinish() {
        try? context.save()
        isProcessing = false
    }
}
