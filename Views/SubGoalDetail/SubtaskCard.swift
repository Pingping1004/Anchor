import SwiftUI
import SwiftData

struct SubtaskCard: View {
    @Environment(\.modelContext) private var context
    @Bindable var task: Task
    
    @State private var refreshId = UUID()
    
    let goalId: UUID
    
    @State private var showRenameAlert = false
    @State private var renameText = ""
    
    private var canToggle: Bool {
        task.subtasks.isEmpty || task.subtasks.allSatisfy { $0.isCompleted }
    }
    
    private var progress: Double {
        let _ = refreshId
        let allDescendants = task.allActiveDescendants
        guard !allDescendants.isEmpty else { return 0 }
        
        let completed = allDescendants.filter { $0.isCompleted }.count
        return Double(completed) / Double(allDescendants.count)
    }
    
    var activeIncompletedTasks: [Task] {
        task.allActiveDescendants.filter { $0.isCompleted == false }
    }

    var body: some View {
        HStack(spacing: 16) {
            if task.activeSubtasks.isEmpty {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(LinearGradient.primaryGradient)
                    .onTapGesture {
                        toggleCompletion()
                    }
            } else {
                ZStack {
                    Circle().stroke(Color.gray.opacity(0.2), lineWidth: 3)
                    
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(LinearGradient.primaryGradient, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.spring, value: progress)
                        .animation(.spring, value: refreshId)
                }
                .frame(width: 24, height: 24)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.body.weight(.bold))
                    .lineLimit(1)
                    .strikethrough(task.isCompleted, color: .secondary)
                    .foregroundStyle(task.isCompleted ? .secondary : .primary)
                
                if !task.activeSubtasks.isEmpty {
                    let renderText = activeIncompletedTasks.count > 0 ? "\(task.allActiveDescendants.count) subtask" : "Done"
                    Text(renderText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(16)
        .background {
            NavigationLink(destination: SubGoalDetail(task: task, goalId: goalId, context: context)) {
                EmptyView()
            }
            .opacity(0)
        }
        .contextMenu {
            Button {
                renameText = task.title
                showRenameAlert = true
            } label: {
                Label("Rename", systemImage: "pencil")
            }
            
            Button(role: .destructive) {
                context.delete(task)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .alert("Rename Task", isPresented: $showRenameAlert) {
            TextField("Task Name", text: $renameText)
            
            Button("Save") {
                task.title = renameText
            }
            
            Button("Cancel", role: .cancel) {}
        }
        .onAppear {
            refreshId = UUID()
        }
    }
    
    private func toggleCompletion() {
        guard canToggle else { return }
        let _ = withAnimation {
            task.toggleTask()
        }
        
        if !task.isCompleted {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } else {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
    }
}
