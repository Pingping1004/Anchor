import SwiftUI
import SwiftData

struct GoalRecommendationView: View {
    let goal: Goal
    
    private var analytics: GoalAnalyticsHelper {
        GoalAnalyticsHelper(goal: goal)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.title2)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(LinearGradient.primaryGradient)
                
                Text("Smart Insights")
                    .font(.title3.bold())
                    .foregroundStyle(.primary)
                
                Spacer()
            }
            .padding(.horizontal, 4)
            
            VStack(spacing: 12) {
                // 1. PACE
                let pace = analytics.paceRecommendation
                RecommendationCard(
                    title: pace.title,
                    description: pace.message,
                    icon: "gauge.with.needle.fill",
                    color: .blue
                )
                
                // 2. WORKLOAD
                let workload = analytics.workloadRecommendation
                RecommendationCard(
                    title: workload.title,
                    description: workload.message,
                    icon: "chart.pie.fill",
                    color: .purple
                )
                
                // 3. SYNERGY
                let synergy = analytics.synergyRecommendation
                RecommendationCard(
                    title: synergy.title,
                    description: synergy.message,
                    icon: "bolt.fill",
                    color: .indigo
                )
                
                // 4. RELIABILITY
                let reliability = analytics.reliabilityRecommendation
                RecommendationCard(
                    title: reliability.title,
                    description: reliability.message,
                    icon: "flame.fill",
                    color: .orange
                )
            }
        }
    }
}

struct RecommendationCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: icon)
                        .font(.caption.bold())
                        .foregroundStyle(color)
                }
                
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Spacer()
            }
            
            Text(description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(
            .regular.interactive(),
            in: .rect(cornerRadius: 20)
        )
    }
}

#Preview {
    @Previewable var sampleGoal: Goal = PreviewContent.sampleGoal
    
    GoalRecommendationView(goal: sampleGoal)
        .padding()
        .modelContainer(PreviewContent.container)
}
