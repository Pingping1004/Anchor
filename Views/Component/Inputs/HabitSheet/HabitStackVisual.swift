import SwiftUI

struct HabitStackVisualView: View {
    @ScaledMetric(relativeTo: .title) var iconSize: CGFloat = 64
    
    let taskTitle: String
    var selectedHabit: HabitType? = nil
    var habitTime: Date? = Date()
    
    var iconName: String {
        selectedHabit?.iconName ?? "link"
    }
    
    var displayHabit: String {
        guard let habit = selectedHabit else { return "Select Habit" }
        
        if let time = habitTime {
            return "\(habit.cleanTitle) at \(time.formatted(date: .omitted, time: .shortened))"
        } else {
            return habit.cleanTitle
        }
    }
    
    var body: some View {
        VStack(spacing: 32) {
            HStack(spacing: 16) {
                responsiveIcon(icon: iconName, size: iconSize, color: selectedHabit?.color)
                    .accessibilityHidden(true)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("After I...")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.primaryMain)
                    
                    Text(displayHabit)
                        .lineLimit(1)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(selectedHabit != nil ? .primary : .secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
            
            Text("Then, I will...")
                .font(.body)
                .foregroundStyle(.secondary)
                .padding()
                .glassEffect(
                    .regular.interactive()
                )
                .frame(maxWidth: .infinity)
            
            HStack(spacing: 16) {
                responsiveIcon(icon: "sparkles", size: iconSize)
                    .accessibilityHidden(true)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(taskTitle)
                        .lineLimit(2)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("I will \(taskTitle)")
            
            Divider()
                .padding(.horizontal, 16)
            
            HStack(spacing: 6) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 8, height: 8)
                
                Text("2-3x higher")
                    .fontWeight(.bold)
                    .foregroundStyle(.green)
                
                Text("success rate with pairing")
                    .foregroundStyle(.secondary)
            }
            .font(.footnote)
            .frame(maxWidth: .infinity, alignment: .center)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Statistic: 2 to 3 times higher success rate with pairing")
        }
        .padding(24)
        .glassEffect(
            .regular.interactive(),
            in: .rect(cornerRadius: 24)
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Habit Stack Visualization")
        .accessibilityHint("Shows how linking \(selectedHabit?.cleanTitle ?? "a habit") to \(taskTitle) improves success.")
    }
}

#Preview {
    HabitStackVisualView(taskTitle: "Upload Tiktok content", selectedHabit: .finishMeal)
//            .preferredColorScheme(.dark)
        .padding()
}
