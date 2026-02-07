import SwiftUI

struct TaskCreationSheet: View {
    @Environment(\.dismiss) var dismiss
    
    var minDate: Date = Date()
    var maxDate: Date?
    
    @State private var title: String = ""
    @State private var difficulty: TaskDifficultyLevel = .Medium
    @State private var repeatFrequency: RepeatFrequency = .never
    @State private var deadline: Date? = nil
    @State private var showDeadlineSheet: Bool = false
    @State private var habit: HabitType? = nil
    @State private var habitTime: Date? = nil
    
    @State private var showMECEAlert: Bool = false
    @State var activeSheet: TaskCardSheetType?
    
    var onAdd: (String, TaskDifficultyLevel, RepeatFrequency, Date?, HabitType?, Date?) -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Task Title", text: $title)
                        .tint(.blue)
                } header: {
                    HStack {
                        Text("Title")
                        
                        Spacer()
                        
                        Button {
                            showMECEAlert = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "lightbulb.max.fill")
                                    .font(.caption2)
                                
                                Text("Breakdown Tips")
                                    .font(.footnote.weight(.semibold))
                            }
                            .foregroundStyle(Color.primaryMain)
                        }
                        .textCase(nil)
                        .buttonStyle(.plain)
                        .accessibilityLabel("Learn MECE Strategy")
                        .accessibilityHint("Shows a tip on how to name your tasks effectively.")
                        .accessibilityAddTraits(.isButton)
                    }
                }
                    
                Section("Organisation") {
                    Picker(selection: $difficulty) {
                        ForEach(TaskDifficultyLevel.allCases, id: \.self) { level in
                            Text(level.rawValue.capitalized).tag(level)
                        }
                    } label: {
                        Label {
                            Text("Difficulty")
                        } icon: {
                            Image(systemName: "flag")
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Picker(selection: $repeatFrequency) {
                        ForEach(RepeatFrequency.allCases, id: \.self) { frequency in
                            Text(frequency.rawValue.capitalized).tag(frequency)
                        }
                    } label: {
                        Label {
                            Text("Repeat")
                        } icon: {
                            Image(systemName: "repeat")
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Button {
                        activeSheet = .habitSheet
                    } label: {
                        HStack {
                            Label {
                                Text(habit == nil ? "Add Habit" : "Edit Habit")
                            } icon: {
                                Image(systemName: "clock.arrow.circlepath")
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            if let habit = habit {
                                Text(habit.rawValue)
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("None")
                                    .foregroundStyle(.secondary)
                            }
                            
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .tint(.primary)
                }
                
                Section {
                    Button {
                        activeSheet = .datePicker
                    } label: {
                        HStack {
                            Label {
                                Text("Deadline")
                            } icon: {
                                Image(systemName: "calendar")
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            if let deadline {
                                Text("\(deadline.formatted(date: .abbreviated, time: .omitted))")
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("None")
                                    .foregroundStyle(.secondary)
                            }
                            
                                Image(systemName: "chevron.right")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .tint(.primaryMain)
                } header: {
                    Text("Timeline")
                } footer: {
                    DateRangeFooter(min: minDate, max: maxDate)
                }
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(role: .confirm) {
                        var finalDate = deadline
                        
                        if let selected = finalDate {
                            if let max = maxDate, selected > max {
                                finalDate = max
                            }
                            
                            if selected < minDate {
                                finalDate = minDate
                            }
                        }
                        
                        onAdd(title, difficulty, repeatFrequency, finalDate, habit, habitTime)
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .tint(LinearGradient.primaryGradient)
                    .disabled(title.isEmpty)
                }
            }
            .alert("MECE Rule", isPresented: $showMECEAlert) {
                Button("Got it", role: .confirm) { }
            } message: {
                Text("- Ensure this doesn't overlap with other tasks.\n- Ensure this is necessary to complete the goal.")
            }
        }
        .sheet(item: $activeSheet) { type in
            sheetContent(for: type)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .onAppear {
            if var deadline = deadline, deadline < minDate {
                deadline = minDate
            }
        }
    }
    
    @ViewBuilder
    private func sheetContent(for type: TaskCardSheetType) -> some View {
        switch type {
        case .datePicker:
            DatePickerSheet(
                selectedDate: $deadline,
                label: "Task Deadline",
                isPastDateAllowed: false,
                maximumDate: maxDate,
                minimumDate: minDate
            )
            .id(maxDate)
            
        case .habitSheet:
            HabitSheetView(
                taskTitle: title.isEmpty ? "Your Task" : title,
                currentHabit: habit ?? .morningCoffee,
                currentTime: habitTime,
                onDone: { selectedHabit, selectedTime in
                    self.habit = selectedHabit
                    self.habitTime = selectedTime
                }
            )
        }
    }
}

#Preview {
    let newTitle: String = "New title example"
    let taskDifficulty: TaskDifficultyLevel = .Medium
    let repeatFrequency: RepeatFrequency = .never
    let taskDeadline: Date? = Calendar.current.date(byAdding: .day, value: 1, to: Date())
    let habit: HabitType? = .arriveHome
    let habitTime: Date? = Date()
    
    TaskCreationSheet { title, difficulty, frequency, deadline, selectedHabit, selectedHabitTime in
        _ = (newTitle, taskDifficulty, repeatFrequency, taskDeadline, habit, habitTime, title, difficulty, frequency, deadline, selectedHabit as Any, selectedHabitTime as Any)
    }
}
