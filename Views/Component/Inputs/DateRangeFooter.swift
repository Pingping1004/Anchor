import SwiftUI

struct DateRangeFooter: View {
    var min: Date?
    var max: Date?
    
    private var isMinSignificant: Bool {
        guard let min else { return false }
        return min > Date().addingTimeInterval(60)
    }
    
    var body: some View {
        Group {
            if let max = max, let min = min, isMinSignificant {
                Text("Deadline must be between \(min.formatted(.dateTime.month().day())) and \(max.formatted(.dateTime.month().day())) due to parent/child tasks.")
            } else if let max = max {
                Text("Must be done before parent task: \(max.formatted(date: .abbreviated, time: .omitted)).")
            } else if let min = min, isMinSignificant {
                 Text("Must be done after subtasks: \(min.formatted(date: .abbreviated, time: .omitted)).")
            }
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
        .padding(.top, 4)
    }
}
