import SwiftUI
import SwiftData
import AlertToast

struct CreateGoal: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    @AccessibilityFocusState private var isHeaderFocused: Bool
    @FocusState private var keyboardFocus: Bool
    
    @State var activeSheet: TaskCardSheetType?
    @State private var vm = CreateGoalViewModel()
    
    
    var body: some View {
        NavigationStack {
            Form {
                GoalInfoSection(
                    title: $vm.goalTitle,
                    whyMatter: $vm.whyMatter,
                    selectedCategory: $vm.selectedCategory,
                    goalDeadline: $vm.endAt
                )
                
                TaskChecklistSection(
                    tasks: $vm.draftTasks,
                    onAdd: vm.addRootTask,
                    onDateTap: { taskId in
                        vm.prepareDatePicker(for: taskId)
                        activeSheet = .datePicker
                    },
                    onDeleteTask: { taskId in
                        vm.deleteTask(id: taskId)
                        UIAccessibility.post(notification: .announcement, argument: "Task deleted")
                    },
                    onSwipeDelete: vm.removeTask,
                    onActiveHabitSheet: { taskId in
                        vm.prepareHabitSheet(for: taskId)
                        activeSheet = .habitSheet
                    },
                )
                
                Section {
                    Button {
                        vm.attemptCreateGoal(context: context) {
                            HapticSoundManager.shared.play(.pop)
                            UIAccessibility.post(notification: .announcement, argument: "Create Goal Successfully")
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                dismiss()
                            }
                        }
                    } label: {
                        Text("Create Goal")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(vm.isFormValid ? .white : Color.gray.opacity(0.2))
                        
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .disabled(!vm.isFormValid)
                    .listRowBackground(
                        vm.isFormValid
                        ? AnyView(LinearGradient.primaryGradient)
                        : AnyView(Color.gray.opacity(0.1))
                    )
                    .accessibilityHint(vm.isFormValid ? "Tap to save." : "Enter a title and category to continue.")
                } footer: {
                    Text("**Note:** You can add subtask later by hovering on the specific task card.")
                        .font(.caption2)
                        .foregroundStyle(.primary)
                        .padding(.top, 8)
                }
            }
            .navigationTitle("Create Your Goal")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .cancel) {
                        dismiss()
                    }
                    .accessibilityLabel("Cancel")
                }
            }
            .sheet(item: $activeSheet) { type in
                sheetContent(for: type)
            }
            .alert("Action Required", isPresented: $vm.showErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(vm.errorMessage)
            }
            .onChange(of: vm.showErrorAlert) { _, isPresented in
                if isPresented {
                    HapticSoundManager.shared.play(.error)
                }
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isHeaderFocused = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                keyboardFocus = true
            }
        }
    }
    
    @ViewBuilder
    private func sheetContent(for type: TaskCardSheetType) -> some View {
        switch type {
        case .datePicker:
            DatePickerSheet(
                selectedDate: vm.bindingForSelectedTask(),
                label: "Select Task Deadline",
                isPastDateAllowed: false,
                maximumDate: vm.endAt,
                showToolbar: true,
            )
            
        case .habitSheet:
            if let task = vm.selectedDraftTask {
                HabitSheetView(
                    taskTitle: task.title.isEmpty ? "Task" : task.title,
                    currentHabit: task.habit ?? .morningCoffee,
                    currentTime: task.habitTime ?? Date(),
                    onDone: { newHabit, newTime in
                        if let habit = newHabit, let time = newTime {
                            vm.updateHabit(type: habit, time: time)
                        } else {
                            vm.deleteHabit()
                        }
                    }
                )
            }
        }
    }
}

#Preview {
    CreateGoal()
            .preferredColorScheme(.dark)
        .environment(\.dynamicTypeSize, .xxxLarge)
}
