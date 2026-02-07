import SwiftUI

struct GoalInfoSection: View {
    @Binding var title: String
    @Binding var whyMatter: String
    @Binding var selectedCategory: Set<GoalCategory>
    @Binding var goalDeadline: Date?
    
    @State var showDeadlineSheet = false
    @State var draftDate: Date = Date()
    
    var hasDeadline: Binding<Bool> {
        Binding(
            get: { goalDeadline != nil },
            set: { isEnabled in
                if isEnabled {
                    goalDeadline = draftDate
                } else {
                    goalDeadline = nil
                }
            }
        )
    }
    
    private var goalDateBinding: Binding<Date> {
        Binding(
            get: { goalDeadline ?? Date() },
            set: { goalDeadline = $0 }
        )
    }
    
    var body: some View {
        Section {
            TextField("Goal Title", text: $title)
                .font(.headline)
                .tint(.blue)
                .accessibilityLabel("Goal Title")
            
            TextField("Why is this goal important?", text: $whyMatter, axis: .vertical)
                .tint(.blue)
                .lineLimit(3...6)
        } header: {
            Text("Goal Details")
        }
        
        Section {
            NavigationLink {
                CategorySelection(selectedCategories: $selectedCategory)
            } label: {
                LabeledContent {
                    if selectedCategory.isEmpty {
                        Text("Select")
                            .foregroundStyle(.secondary)
                    } else {
                        Text("\(selectedCategory.count)")
                            .foregroundStyle(.primary)
                    }
                } label: {
                    Label {
                        Text("Category")
                            .foregroundStyle(.primary)
                    } icon: {
                        Image(systemName: "tag")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .accessibilityValue(selectedCategory.isEmpty ? "None selected" : "\(selectedCategory.count) selected")
            
            Button {
                showDeadlineSheet.toggle()
            } label: {
                HStack {
                    Label {
                        Text("Deadline")
                    } icon: {
                        Image(systemName: "calendar")
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    if let goalDeadline {
                        Text(goalDeadline.formatted(date: .abbreviated, time: .omitted))
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
            .tint(.primary)
            .sheet(isPresented: $showDeadlineSheet) {
                DatePickerSheet(
                    selectedDate: $goalDeadline,
                    label: "Goal Deadline",
                    isPastDateAllowed: false,
                )
            }
        } header: {
            Text("Configuration")
        }
    }
    
    private var bindingHasDeadline: Binding<Bool> {
        Binding(
            get: { goalDeadline != nil },
            set: { isEnabled in
                if isEnabled {
                    goalDeadline = draftDate
                } else {
                    goalDeadline = nil
                }
            }
        )
    }
}

struct TaskChecklistSection: View {
    @Binding var tasks: [DraftTask]
    
    let onAdd: () -> Void
    let onDateTap: (UUID) -> Void
    let onDeleteTask: (UUID) -> Void
    let onSwipeDelete: (IndexSet) -> Void
    let onActiveHabitSheet: (UUID) -> Void
    
    private let maxTasksRender = 3
    
    var body: some View {
        Section {
            ForEach($tasks) { $task in
                DraftTaskRow(
                    title: $task.title,
                    difficulty: $task.difficulty,
                    frequency: $task.repeatFrequency,
                    habit: $task.habit,
                    deadline: $task.deadline,
                    onDateTap: { onDateTap(task.id) },
                    onDeleteTask: {
                        onDeleteTask(task.id)
                        HapticSoundManager.shared.play(.sent)
                    },
                    onActiveHabitSheet: { onActiveHabitSheet(task.id) }
                )
                .padding(.vertical, 4)
                .listRowSeparator(.hidden)
            }
            .onDelete(perform: onSwipeDelete)
            
            Button(action: {
                withAnimation { onAdd() }
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                    Text("Add New Task")
                        .fontWeight(.medium)
                }
                .foregroundStyle(isLimitReached ? .secondary : Color.primaryMain)
            }
            .disabled(isLimitReached)
        } header: {
            Text("Tasks")
        } footer: {
            if isLimitReached {
                Text("Maximum limit of \(maxTasksRender) direct subtasks reached.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .transition(.opacity)
            }
        }
    }
    
    private var isLimitReached: Bool {
        tasks.count >= maxTasksRender
    }
}
