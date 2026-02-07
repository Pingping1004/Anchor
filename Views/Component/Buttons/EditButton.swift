import SwiftUI

struct StyledEditButton: View {
    @Environment(\.editMode) var editMode
    @Binding var syncMode: EditMode
    
    private var editButtonColor: some ShapeStyle {
        if editMode?.wrappedValue == .active {
            return AnyShapeStyle(LinearGradient.primaryGradient)
        } else {
            return AnyShapeStyle(Color.primary)
        }
    }
    
    var body: some View {
        EditButton()
            .tint(editButtonColor)
            .onChange(of: editMode?.wrappedValue) { _, newValue in
                if let newValue = newValue {
                    withAnimation(.snappy) { syncMode = newValue }
                    HapticSoundManager.shared.play(.tock)
                }
            }
    }
}
