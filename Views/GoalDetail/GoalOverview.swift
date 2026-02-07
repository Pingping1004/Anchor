import SwiftUI

struct GoalOverviewSection: View {
    let goal: Goal
    @Environment(\.sizeCategory) var sizeCategory
    
    var isGoalCompleted: Int {
        goal.isCompleted ? 1 : 0
    }
    
    var totalCount: Int {
        goal.totalTasks + 1
    }
    
    var inProgressCount: Int {
        totalCount - (goal.totalCompletedTasks + isGoalCompleted)
    }
    
    private var isAccessibilityMode: Bool {
        sizeCategory.isAccessibilityCategory
    }
    
    var body: some View {
        VStack(spacing: 20) {
            if isAccessibilityMode {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("\(goal.overallProgress)%")
                            .font(.system(.title, design: .rounded).weight(.bold))
                            .foregroundStyle(.primary)
                        
                        ProgressView(value: Double(goal.overallProgress), total: 100)
                            .tint(LinearGradient.primaryGradient)
                    }
                    
                    Divider()
                    
                    statsContent(inProgressCount: inProgressCount)
                }
            } else {
                HStack(spacing: 24) {
                    circularProgress(percentage: goal.overallProgress)
                    
                    statsContent(inProgressCount: inProgressCount)
                }
            }
            
            footerContent
        }
        .padding(24)
        .glassEffect(
            .regular.interactive(),
            in: .rect(cornerRadius: 24, style: .continuous)
        )
    }
    
    @ViewBuilder
    private func circularProgress(percentage: Int) -> some View {
        let progressValue: CGFloat = CGFloat(percentage) / 100.0
        
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.15), lineWidth: 12)
            
            Circle()
                .trim(from: 0.0, to: progressValue)
                .stroke(
                    LinearGradient.primaryGradient,
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 1.0), value: percentage)
            
            VStack(spacing: 2) {
                Text("\(percentage)%")
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                
                Text("Overall")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 110, height: 110)
    }
    
    @ViewBuilder
    private func statsContent(inProgressCount: Int) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .center, spacing: 12) {
                statRow
            }
            
            VStack(alignment: .leading, spacing: 12) {
                statRow
            }
        }
    }
    
    private var completedCount: Int {
        goal.totalCompletedTasks + (goal.isCompleted ? 1 : 0)
    }
    
    @ViewBuilder
    private var statRow: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(LinearGradient.primaryGradient)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 0) {
                Text("\(completedCount)")
                    .font(.headline)
                    .fontWeight(.bold)
                Text("Completed")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        
        if !isAccessibilityMode {
            Divider().frame(height: 30)
        }
        
        HStack {
            Image(systemName: "circle.dashed")
                .foregroundStyle(Color.secondaryMain)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 0) {
                Text("\(inProgressCount)")
                    .font(.headline)
                    .fontWeight(.bold)
                Text("In Progress")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private var footerContent: some View {
        let layout = isAccessibilityMode ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8)) : AnyLayout(HStackLayout(alignment: .center))
        
        return layout {
            Group {
                if let deadline = goal.deadline {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                        Text("\(goal.daysBeforeDeadline(to: deadline)) days")
                            .contentTransition(.numericText())
                    }
                }
            }
            .font(.caption2)
            
            if !isAccessibilityMode { Spacer() }
            
            if let endDate = goal.deadline {
                Text("End: \(endDate.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption2)
                    .contentTransition(.interpolate)
            } else {
                Text("No deadline")
                    .font(.caption2)
            }
        }
        .foregroundStyle(.secondary)
        .padding(.top, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(.snappy, value: goal.deadline)
    }
}
