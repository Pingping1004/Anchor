import SwiftUI

struct SubtaskList: View {
    @Environment(\.sizeCategory) var sizeCategory
    @Environment(\.dynamicTypeSize) var typeSize
    @ScaledMetric(relativeTo: .body) private var spacingRegular: CGFloat = 90
    @ScaledMetric(relativeTo: .body) private var spacingAccessibility: CGFloat = 75
    
    private var isAccessibilityMode: Bool {
        typeSize.isAccessibilitySize
    }
    
    let parentTask: Task
    let goalId: UUID
    let isEditing: Bool
    
    var onDelete: (Task) -> Void
    
    private var visibleTasks: [Task] {
        parentTask.activeSubtasks
    }
    
    private var verticalHeight: CGFloat {
        let dynamicSpacing = isAccessibilityMode ? spacingAccessibility : spacingRegular
        
        return dynamicSpacing * CGFloat(visibleTasks.count)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Subtasks (\(visibleTasks.count))")
                    .font(.title3.bold())
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 24)
            
            List {
                ForEach(visibleTasks) { subtask in
                    SubtaskCard(task: subtask, goalId: goalId)
                        .listRowBackground(Color(.systemGroupedBackground))
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                withAnimation { onDelete(subtask) }
                                HapticSoundManager.shared.play(.sent)
                            } label: {
                                Image(systemName: "trash")
                            }
                        }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .scrollDisabled(true)
            .frame(minHeight: verticalHeight)
        }
        .animation(.snappy, value: visibleTasks)
    }
}
