import SwiftUI

struct GoalCategoryTags: View {
    let goalCategories: Set<GoalCategory>
    let showAllTags: Bool
    
    private let categoryColors: [GoalCategory: Color] = [
        .health: .green,
        .career: .orange,
        .finance: .indigo,
        .learning: .blue,
        .personal: .mint
    ]
    
    var body: some View {
        let categories = Array(goalCategories)
        let visibleCategories = showAllTags ? categories : Array(categories.prefix(2))
        let remainingCount = showAllTags ? 0 : (categories.count - 2)
        
        HStack(spacing: 8) {
            ForEach(visibleCategories, id: \.self) { category in
                let color = categoryColors[category] ?? .gray
                
                Text(category.description)
                    .font(.caption2)
                    .foregroundStyle(color)
                    .padding(8)
                    .background(color.opacity(0.2))
                    .cornerRadius(24)
            }
            
            if remainingCount > 0 {
                Text("+\(remainingCount)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(8)
                    .background(Color.secondary.opacity(0.2))
                    .cornerRadius(24)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(generateAccessibilityLabel(visible: visibleCategories, remaining: remainingCount))
    }
    
    private func generateAccessibilityLabel(visible: [GoalCategory], remaining: Int) -> String {
        guard !visible.isEmpty else { return "No categories" }
        
        let listString = visible.map { $0.description }.joined(separator: ", ")
        
        if remaining > 0 {
            return "Categories: \(listString), and \(remaining) more."
        } else {
            return "Categories: \(listString)."
        }
    }
}
