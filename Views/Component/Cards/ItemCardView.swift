import SwiftUI
import SwiftData

struct CardView<T: CycleManagable & Observable>: View {
    @Environment(\.modelContext) private var context
    
    @Bindable var item: T
    
    let isEditing: Bool
    var showFrequencyText: Bool = true
    var onCommit: () -> Void = {}
    
    @State private var isTextExpanded: Bool = false
    @State private var editingTitle: String = ""

    private var dateToDisplay: Date? {
        item.currentDeadline ?? item.deadline
    }
    
    private var isVisuallyCompleted: Bool {
        item.isCompleted
    }
    
    var body: some View {
        Group {
            if isEditing {
                editingField
            } else {
                displayContent
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(item.title)
        .accessibilityValue(item.isCompleted ? "Completed" : "In Progress")
        .accessibilityHint("Tap to toggle completion and hover for more options.")
        .accessibilityAddTraits(item.isCompleted ? [.isButton, .isSelected] : [.isButton])
        .onChange(of: isEditing) { _, isNowEditing in
            if isNowEditing {
                editingTitle = item.title
            } else {
                if !editingTitle.isEmpty, editingTitle != item.title {
                    item.title = editingTitle
                }
                
                try? context.save()
                onCommit()
            }
        }

    }
    
    private var editingField: some View {
        TextField("Title", text: $editingTitle, axis: .vertical)
            .font(.subheadline)
            .tint(.blue)
            .lineLimit(nil)
            .textFieldStyle(.plain)
            .padding(.horizontal, 12)
            .padding(.vertical, 20)
            .onAppear {
                editingTitle = item.title
            }
    }

    private var displayContent: some View {
        VStack(alignment: .leading, spacing: 4) {
            statusHeader
            
            if (item.repeatFrequency != .never || item.deadline != nil) && item.habit?.iconLabel == nil {
                metadataFooter
            } else {
                Color.clear.frame(height: 16)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.title), due \(String(describing: item.deadline?.formattedDeadline))")
    }

    private var statusHeader: some View {
        VStack(alignment: .leading, spacing: 16) {
            Image(systemName: isVisuallyCompleted ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundStyle(LinearGradient.primaryGradient)
                .contentTransition(.symbolEffect(.replace))
                .animation(.spring(response: 0.35, dampingFraction: 0.9), value: isVisuallyCompleted)
            
            Text(item.title)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(isTextExpanded ? nil : 1)
                .fixedSize(horizontal: false, vertical: true)
                .strikethrough(isVisuallyCompleted, color: .secondary)
                .foregroundStyle(isVisuallyCompleted ? .secondary : .primary)
                .onTapGesture {
                    withAnimation(.snappy) { isTextExpanded.toggle() }
                }
        }
    }
    
    private var metadataFooter: some View {
        ViewThatFits {
            HStack(alignment: .center, spacing: 8) {
                footerContent
            }
            
            VStack(alignment: .leading, spacing: 4) {
                footerContent
            }
        }
        .lineLimit(2)
        .font(.caption2)
        .foregroundStyle(.secondary)
    }
    
    @ViewBuilder
    private var footerContent: some View {
        HStack {
            if let habitIconLabel = item.habit?.iconLabel {
                Text(habitIconLabel)
                    .font(.subheadline)
            }
            
            frequencyBadge
        }
        
        if let date = dateToDisplay {
            dateView(for: date)
                .id(date)
                .transition(.move(edge: .trailing).combined(with: .opacity))
        }
    }
    
    @ViewBuilder
    private var frequencyBadge: some View {
        if item.repeatFrequency != .never {
            HStack(spacing: 2) {
                Image(systemName: "repeat").font(.caption2)
                if showFrequencyText {
                    ViewThatFits {
                        Text(item.repeatFrequency.rawValue.capitalized)
                        EmptyView()
                    }
                }
            }
            .fontWeight(.semibold)
        }
    }
    
    private func dateView(for date: Date) -> some View {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let deadlineDay = calendar.startOfDay(for: date)
        let visuallyOverdue = !isVisuallyCompleted && (deadlineDay < startOfToday)
        
        return HStack(spacing: 2) {
            Image(systemName: visuallyOverdue ? "calendar.badge.exclamationmark" : "calendar")
                .foregroundStyle(visuallyOverdue ? .red : .secondary)
            Text(date.formattedDeadline)
                .foregroundStyle(visuallyOverdue ? .red : .secondary)
        }
        .font(.caption2)
    }
}
