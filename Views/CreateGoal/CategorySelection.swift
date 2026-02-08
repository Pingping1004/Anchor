import SwiftUI

struct CategorySelection: View {
    @Binding var selectedCategories: Set<GoalCategory>
    
    var body: some View {
        List {
            ForEach(GoalCategory.allCases, id: \.self) { category in
                Button {
                    toggleSelection(for: category)
                } label: {
                    HStack(spacing: 16) {
                        Label(category.description, systemImage: category.iconName)
                            .foregroundStyle(.primary)
                        
                        Spacer()
                        
                        if selectedCategories.contains(category) {
                            Image(systemName: "checkmark")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(LinearGradient.primaryGradient)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(category.description)
                .accessibilityAddTraits(selectedCategories.contains(category) ? .isSelected : [])
                .accessibilityHint("Tap to add or remove goal categories.")
            }
        }
        .navigationTitle("Select Category")
    }
    
    private func toggleSelection(for category: GoalCategory) {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        HapticSoundManager.shared.play(.selection)
        
        if selectedCategories.contains(category) {
            selectedCategories.remove(category)
        } else {
            selectedCategories.insert(category)
        }
    }
}
