import SwiftUI

struct DatePickerSheet: View {
    @Environment(\.dismiss) var dismiss
    
    @Binding var selectedDate: Date?
    @State private var draftDate: Date = Date()
    
    var label: String
    var displayedComponents: DatePickerComponents = [.date]
    var isPastDateAllowed: Bool
    var maximumDate: Date? = nil
    var minimumDate: Date? = nil
    
    var showToolbar: Bool = true
    
    private var computedMinDate: Date {
        if let explicitMin = minimumDate {
            return max(explicitMin, isPastDateAllowed ? Date.distantPast : Date())
        } else {
            return isPastDateAllowed ? Date.distantPast : Date()
        }
    }
    
    var dateRange: ClosedRange<Date> {
        let minDate = computedMinDate
        
        if let maxLimit = maximumDate {
            if minDate > maxLimit {
                return maxLimit...maxLimit
            }
            return minDate...maxLimit
        }
        
        return minDate...Date.distantFuture
    }
    
    var accessibilityDateHint: String {
        var hint = "Select a date."
        let minString = computedMinDate.formatted(date: .abbreviated, time: .omitted)
        
        if let max = maximumDate {
            let maxString = max.formatted(date: .abbreviated, time: .omitted)
            hint += " Must be between \(minString) and \(maxString)."
        } else {
            hint += " Must be after \(minString)."
        }
        return hint
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker(
                        "",
                        selection: showToolbar ? $draftDate : Binding(
                            get: { selectedDate ?? Date() },
                            set: { selectedDate = $0 }
                        ),
                        in: dateRange,
                        displayedComponents: displayedComponents
                    )
                    .datePickerStyle(.graphical)
                    .labelsHidden()
                    .accessibilityLabel(label)
                    .accessibilityHint(accessibilityDateHint)
                } footer: {
                    if let max = maximumDate {
                        Text("Must be before: \(max.formatted(date: .abbreviated, time: .omitted))")
                            .accessibilityLabel("Constraint: Must be before \(max.formattedDeadline)")
                    }
                }
                
                if selectedDate != nil {
                    Section {
                        Button(role: .destructive) {
                            withAnimation {
                                selectedDate = nil
                                dismiss()
                            }
                        } label: {
                            Text("Remove Deadline")
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                        .accessibilityLabel("Remove current deadline")
                        .accessibilityHint("Removes the date and closes the sheet.")
                    }
                }
            }
            .navigationTitle(label)
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if let existing = selectedDate {
                    draftDate = existing
                } else {
                    DispatchQueue.main.async {
                        draftDate = max(maximumDate ?? Date(), minimumDate ?? Date())
                    }
                }
            }
            .navigationBarBackButtonHidden(true)
            .toolbar {
                if showToolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button(role: .confirm) {
                            selectedDate = draftDate
                            dismiss()
                        }
                        .fontWeight(.bold)
                        .tint(LinearGradient.primaryGradient)
                        .accessibilityLabel("Save date")
                    }
                    
                    ToolbarItem(placement: .cancellationAction) {
                        Button(role: .cancel) {
                            dismiss()
                        }
                        .tint(.secondary)
                        .accessibilityLabel("Discard changes")
                    }
                }
            }
        }
        .onChange(of: maximumDate) { _, newMax in
            if let maxLimit = newMax {
                if draftDate > maxLimit {
                    withAnimation {
                        draftDate = maxLimit
                    }
                }
            }
        }
        .tint(LinearGradient.primaryGradient)
    }
}

#Preview {
    @Previewable @State var selectedDate: Date? = Date()
    let previewGoal = PreviewContent.sampleGoal
    
    DatePickerSheet(
        selectedDate: .constant(selectedDate),
        label: "Start Date",
        displayedComponents: [.date],
        isPastDateAllowed: true,
        maximumDate: previewGoal.deadline
    )
}
