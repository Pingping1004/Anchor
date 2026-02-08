import SwiftUI
import SwiftData

struct GoalListView: View {
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    
    @Bindable var goal: Goal
    
    var tasks: [Task] {
        goal.tasks
    }
    var completedTasks: [Task] {
        tasks.filter { $0.isCompleted == true }
    }
    var progress: Int {
        goal.overallProgress
    }
    var body: some View {
        goalListSection
    }
    
    private var goalListSection: some View {
        NavigationLink(destination: GoalDetail(goal: goal)) {
            VStack(alignment: .leading, spacing: 16) {
                
                ViewThatFits(in: .horizontal) {
                    headerTextContent
                    
                    VStack(alignment: .leading, spacing: 8) {
                        headerTextContent
                    }
                }
                
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .center) {
                        progressSection
                        Spacer(minLength: 20)
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        progressSection
                    }
                }
                
                GoalCategoryTags(goalCategories: goal.category, showAllTags: false)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .glassEffect(
            .regular.interactive(),
            in: .rect(cornerRadius: 24, style: .continuous)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(goal.title)
        .accessibilityValue(accessibilitySummary)
        .accessibilityHint("Tap to view goal details, including progress, and tasks.")
        .accessibilityAddTraits(.isButton)
    }
    
    private var accessibilitySummary: String {
        var summary = ""
        
        if goal.deadline != nil {
            summary += "Due in \(goal.timeRemaining). "
        } else {
            summary += "No deadline. "
        }
        
        summary += "\(progress)% complete. "
        
        if !goal.category.isEmpty {
            let tags = goal.category.map { $0.description }.joined(separator: ", ")
            summary += "Tags: \(tags)."
        }
        
        return summary
    }
    
    private var headerTextContent: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(goal.title)
                .font(.callout)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
                .lineLimit(2)
                .minimumScaleFactor(0.9)
            
            if goal.deadline != nil {
                Text(goal.timeRemaining)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                Text("No deadline")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private var progressSection: some View {
        HStack(spacing: 12) {
            Text("\(progress)%")
                .font(.caption)
                .foregroundStyle(Color.primaryMain)
                .fontWeight(.semibold)
                .fixedSize()
            
            ProgressView(value: Double(progress), total: 100)
                .progressViewStyle(.linear)
                .tint(LinearGradient.primaryGradient)
        }
    }
}
