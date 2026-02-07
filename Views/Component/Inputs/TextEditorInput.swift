import SwiftUI

struct TextEditorField: View {
    @ScaledMetric(relativeTo: .body) var dynamicSpacing: CGFloat = 40
    
    @Binding var text: String
    @FocusState var isFocused: Bool
    var externalFocus: FocusState<Bool>.Binding?
    
    let label: String
    
    var body: some View {
        TextEditor(text: $text)
            .font(.body)
            .tint(.blue)
            .focused(externalFocus ?? $isFocused)
            .scrollContentBackground(.hidden)
            .frame(minHeight: dynamicSpacing)
            .padding(8)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .cornerRadius(12)
            .accessibilityLabel(label)
            .accessibilityHint("Tap to enter new value. Press enter button to dismiss.")
    }
}
