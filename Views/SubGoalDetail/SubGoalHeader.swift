import SwiftUI

struct SubGoalHeader: View {
    @FocusState var isFocused: Bool
    @Binding var title: String
    let isEditing: Bool
    let label: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.title3.bold())
                .lineLimit(2)
                .padding(16)
                .glassEffect(
                    .regular.interactive(),
                    in: .capsule
                )
            Spacer()
        }
        .transition(.opacity)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
        .accessibilityLabel("\(label): \(title)")
        .accessibilityHint("Shows the current subgoal title.")
        .onChange(of: isEditing) { _, newValue in
            if newValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isFocused = true
                    UIAccessibility.post(notification: .layoutChanged, argument: nil)
                }
            } else {
                isFocused = false
                UIAccessibility.post(notification: .layoutChanged, argument: nil)
            }
        }
        .animation(.default, value: isEditing)
    }
}
