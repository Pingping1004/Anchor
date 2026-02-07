import SwiftUI

struct HabitSheetView: View {
    @Environment(\.dismiss) var dismiss
    
    let taskTitle: String
    let currentHabit: HabitType?
    let currentTime: Date?
    
    var onDone: (HabitType?, Date?) -> Void
    
    @State private var habitType: HabitType
    @State private var habitTime: Date
    @State private var hasLoadedInitialState = false
    
    init(taskTitle: String, currentHabit: HabitType?, currentTime: Date?, onDone: @escaping (HabitType?, Date?) -> Void) {
        self.taskTitle = taskTitle
        self.currentHabit = currentHabit
        self.currentTime = currentTime
        self.onDone = onDone
        
        _habitType = State(initialValue: currentHabit ?? .morningCoffee)
        _habitTime = State(initialValue: currentTime ?? Date())
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Habit", selection: $habitType) {
                        ForEach(HabitType.allCases, id: \.self) { habit in
                            Text(habit.rawValue).tag(habit)
                        }
                    }
                    DatePicker("Time", selection: $habitTime, displayedComponents: .hourAndMinute)
                } header: { Text("Habit Integration") }
                
                Section {
                    HabitStackVisualView(taskTitle: taskTitle, selectedHabit: habitType, habitTime: habitTime)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }
                
                Section {
                    Button(role: .destructive) {
                        onDone(nil, nil)
                        dismiss()
                    } label: {
                        Text("Remove habit").frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
            .onChange(of: habitType) { _, newHabit in
                if hasLoadedInitialState { applyDefaultTime(for: newHabit) }
            }
            .onAppear { hasLoadedInitialState = true }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onDone(habitType, habitTime)
                        dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .navigationTitle("Integrate Task")
        }
    }

    private func applyDefaultTime(for habit: HabitType) {
        let defaultHour = habit.defaultTimeWindow
        if let newDate = Calendar.current.date(bySettingHour: defaultHour, minute: 0, second: 0, of: Date()) {
            withAnimation { self.habitTime = newDate }
        }
    }
}

#Preview {
    HabitSheetView(
        taskTitle: "Mockup Task Title",
        currentHabit: .finishMeal,
        currentTime: Date(),
        onDone: { habit, time in }
    )
}
