import SwiftUI

struct AddSubtaskButton: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("Add New Subtask")
            }
            .font(.headline)
            .foregroundStyle(LinearGradient.primaryGradient)
            .padding()
            .frame(maxWidth: .infinity)
            .cornerRadius(12)
            .contentShape(Rectangle())
        }
        .padding(.top, 8)
    }
}
