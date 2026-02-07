import SwiftUI
import SwiftData

@Observable
@MainActor
final class CreateGoalViewModel {
    var goalTitle: String = ""
    var selectedCategory: Set<GoalCategory> = []
    var whyMatter: String = ""
    var endAt: Date? = nil
    var draftTasks: [DraftTask] = []
    
    var showErrorAlert = false
    var showDatePicker: Bool = false
    var activateHabiSheet: Bool = false
    var errorMessage = ""
    var selectedTaskId: UUID? = nil
    
    let maxSubtasks = 3
    
    enum ValidationError: LocalizedError {
        case missingTitle
        case missingCategory
        case missingMotivation
        case noTasks
        case emptyTasks
        case invalidDeadline
        
        var errorDescription: String? {
            switch self {
            case .missingTitle: return "Please enter a goal title."
            case .missingCategory: return "Select at least one category."
            case .missingMotivation: return "Tell us why this goal matters."
            case .noTasks: return "Add at least one task to start."
            case .emptyTasks: return "All tasks must have a name."
            case .invalidDeadline: return "Goal deadline cannot be earlier than your task deadlines."
            }
        }
    }
    
    var isFormValid: Bool {
        !goalTitle.trimmingCharacters(in: .whitespaces).isEmpty &&
        !whyMatter.trimmingCharacters(in: .whitespaces).isEmpty &&
        !selectedCategory.isEmpty &&
        !draftTasks.isEmpty &&
        draftTasks.allSatisfy { !$0.title.trimmingCharacters(in: .whitespaces).isEmpty }
    }

    var minimumGoalDate: Date {
        let taskMax = draftTasks.compactMap { $0.deadline }.max()
        return taskMax ?? Date()
    }
    
    func addRootTask() {
        guard draftTasks.count < maxSubtasks else { return }
        
        let newTask = DraftTask()
        
        withAnimation {
            draftTasks.append(newTask)
        }
        
        UIAccessibility.post(notification: .announcement, argument: "New task added")
    }
    
    func deleteTask(id: UUID) {
        if let index = draftTasks.firstIndex(where: { $0.id == id }) {
            let taskTitle = draftTasks[index].title
            
            let _ = withAnimation {
                draftTasks.remove(at: index)
            }
            
            let message = taskTitle.isEmpty ? "Task deleted" : "\(taskTitle) deleted"
            UIAccessibility.post(notification: .announcement, argument: message)
        }
    }
    
    func removeTask(at offsets: IndexSet) {
        draftTasks.remove(atOffsets: offsets)
    }
    
    func prepareDatePicker(for taskId: UUID) {
        selectedTaskId = taskId
        showDatePicker = true
        
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
    
    func attemptCreateGoal(context: ModelContext, onSuccess: () -> Void) {
        do {
            try validateForm()
            
            try Goal.createGoal(title: goalTitle, category: selectedCategory, whyMatter: whyMatter, tasks: draftTasks, deadline: endAt, context: context)
            
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
            onSuccess()
            
        } catch let error as ValidationError {
            errorMessage = error.errorDescription ?? "Invalid Input"
            showErrorAlert = true
            
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
            
        } catch {
            errorMessage = "Could not save goal. Please try again."
            showErrorAlert = true
        }
    }
    
    private func validateForm() throws {
        if goalTitle.trimmingCharacters(in: .whitespaces).isEmpty { throw ValidationError.missingTitle }
        if whyMatter.trimmingCharacters(in: .whitespaces).isEmpty { throw ValidationError.missingMotivation }
        if selectedCategory.isEmpty { throw ValidationError.missingCategory }
        if draftTasks.isEmpty { throw ValidationError.noTasks }
        if !draftTasks.allSatisfy({ !$0.title.trimmingCharacters(in: .whitespaces).isEmpty }) { throw ValidationError.emptyTasks }
        
        if let goalDate = endAt {
            if let taskDate = draftTasks.compactMap({ $0.deadline }).max() {
                if goalDate < taskDate {
                    throw ValidationError.invalidDeadline
                }
            }
        }
    }

    func bindingForSelectedTask() -> Binding<Date?> {
        Binding<Date?>(
            get: { [weak self] in
                guard let self = self,
                      let id = self.selectedTaskId,
                      let task = self.draftTasks.first(where: { $0.id == id }) else {
                    return Date()
                }
                return task.deadline ?? Date()
            },
            set: { [weak self] newDate in
                guard let self = self,
                      let id = self.selectedTaskId,
                      let index = self.draftTasks.firstIndex(where: { $0.id == id }) else {
                    return
                }
                self.draftTasks[index].deadline = newDate
            }
        )
    }
    
    func prepareHabitSheet(for taskId: UUID) {
        selectedTaskId = taskId
    }
    
    var selectedDraftTask: DraftTask? {
        guard let id = selectedTaskId else { return nil }
        return draftTasks.first(where: { $0.id == id })
    }
    
    func updateHabit(type: HabitType, time: Date) {
        guard let id = selectedTaskId,
              let index = draftTasks.firstIndex(where: { $0.id == id }) else { return }
        
        draftTasks[index].habit = type
        draftTasks[index].habitTime = time
    }
    
    func deleteHabit() {
        guard let id = selectedTaskId,
              let index = draftTasks.firstIndex(where: { $0.id == id }) else { return }
        
        draftTasks[index].habit = nil
        draftTasks[index].habitTime = nil
    }
}
