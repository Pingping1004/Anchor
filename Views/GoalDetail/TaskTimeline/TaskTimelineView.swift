import SwiftUI
import SwiftData

struct GoalTaskTimelineView: View {
    @ScaledMetric(relativeTo: .body) var dynamicFrameHeight: CGFloat = 260
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @Namespace private var namespace
    
    let tasks: [Task]
    @State var selectedTaskID: UUID?
    
    var timelineTasks: [Task] {
        let sorted = tasks.sorted { t1, t2 in
            if t1.isCompleted != t2.isCompleted {
                return !t1.isCompleted
            }
            
            if let d1 = t1.deadline, let d2 = t2.deadline {
                return d1 < d2
            }
            
            if t1.deadline != nil { return true }
            if t2.deadline != nil { return false }
            
            return t1.persistentModelID < t2.persistentModelID
        }
        
        return Array(sorted.prefix(5))
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(Array(timelineTasks.enumerated()), id: \.element.id) { index, task in
                    taskView(at: index, task: task)
                        .padding(.vertical)
                        .matchedGeometryEffect(id: task.id, in: namespace)
                }
            }
            .scrollTargetLayout()
        }
        .contentMargins(.horizontal, 60, for: .scrollContent)
        .scrollTargetBehavior(.viewAligned)
        .scrollTargetLayout()
        .animation(reduceMotion ? nil : .snappy, value: timelineTasks)
        .scrollPosition(id: $selectedTaskID, anchor: .center)
        .sensoryFeedback(.selection, trigger: selectedTaskID)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Task Timeline")
        .accessibilityValue(currentTaskSummary)
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment:
                shiftToTask(offset: 1)
            case .decrement:
                shiftToTask(offset: -1)
            @unknown default:
                break
            }
        }
        .frame(minHeight: dynamicFrameHeight)
        .onAppear { scrollToCurrentTask() }
        .onChange(of: selectedTaskID) { old, new in
            if old != nil && new != nil {
                HapticSoundManager.shared.play(.selection)
            }
        }
    }
    
    @ViewBuilder
    private func taskView(at index: Int, task: Task) -> some View {
        let previousTask = (index > 0) ? timelineTasks[index - 1] : nil
        
        TimelineItemContainer(
            task: task,
            previousTask: previousTask,
            index: index,
            totalCount: timelineTasks.count
        )
        .scrollTransition(axis: .horizontal) { content, phase in
            content
                .scaleEffect(phase.isIdentity ? 1.0 : 0.9)
                .opacity(phase.isIdentity ? 1.0 : 0.6)
                .blur(radius: phase.isIdentity ? 0 : 2)
        }
    }
    
    private func scrollToCurrentTask() {
        guard selectedTaskID == nil else { return }
        
        DispatchQueue.main.async {
            if let firstIncomplete = tasks.first(where: { !$0.isCompleted }) {
                selectedTaskID = firstIncomplete.id
            } else {
                selectedTaskID = tasks.last?.id
            }
        }
    }
}

struct TimelineItemContainer: View {
    let task: Task
    let previousTask: Task?
    let index: Int
    let totalCount: Int
    
    private let activeColor: Color = .primaryMain
    private let inactiveColor: Color = Color.secondary.opacity(0.2)
    private let dotSize: CGFloat = 16
    
    var body: some View {
        VStack(spacing: 24) {
            if let deadline = task.deadline {
                Text(deadline.formatted(.dateTime.day().month()))
                    .font(.caption.bold())
                    .foregroundStyle(task.isCompleted ? activeColor : .secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .glassEffect(.regular.interactive(), in: .capsule)
            } else {
                Text("Someday")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .opacity(0.5)
                    .padding(.vertical, 6)
            }
            
            ZStack {
                HStack(spacing: 0) {
                    Rectangle()
                        .fill(leftLineColor)
                        .frame(height: 3)
                    
                    Rectangle()
                        .fill(rightLineColor)
                        .frame(height: 3)
                }
                
                Circle()
                    .fill(task.isCompleted ? activeColor : inactiveColor)
                    .frame(width: dotSize, height: dotSize)
                    .overlay {
                        if task.isCompleted {
                            Image(systemName: "checkmark")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                    .background(
                        Circle()
                            .fill(activeColor.opacity(0.3))
                            .frame(width: dotSize * 2, height: dotSize * 2)
                            .opacity(task.isCompleted ? 1 : 0)
                    )
            }
            .frame(height: dotSize)
            
            CardView(item: task, isEditing: false)
                .frame(maxWidth: .infinity)
                .padding()
                .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 24))
        }
        .padding(.horizontal, 16)
        .containerRelativeFrame(.horizontal, count: 1, spacing: 0)
    }
    
    private var leftLineColor: Color {
        if index == 0 { return .clear }
        if let prev = previousTask, prev.isCompleted {
            return activeColor
        }
        return inactiveColor
    }
    
    private var rightLineColor: Color {
        if index == totalCount - 1 { return .clear }
        return task.isCompleted ? activeColor : inactiveColor
    }
}

#Preview {
    let previewGoal: Goal = PreviewContent.sampleGoal
    
    GoalTaskTimelineView(tasks: previewGoal.tasks)
//        .environment(\.dynamicTypeSize, .accessibility5)
}
