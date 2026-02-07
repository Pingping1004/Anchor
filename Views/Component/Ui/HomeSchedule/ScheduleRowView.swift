import SwiftUI

struct ScheduleRow: View {
    let icon: String
    let title: String
    let value: String
    
    @ScaledMetric(relativeTo: .title) var rawIconSize: CGFloat = 64
    
    var body: some View {
        let finalIconSize = min(rawIconSize, 80)
        
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .center, spacing: 16) {
                responsiveIcon(icon: icon, size: finalIconSize)
                textStack(lineLimit: 2)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 12) {
                responsiveIcon(icon: icon, size: finalIconSize)
                textStack(lineLimit: 2)
            }
        }
    }
    
    private func textStack(lineLimit: Int? = nil) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.callout.weight(.bold))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(1)
                .minimumScaleFactor(0.9)
            
            Text(value)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(lineLimit)
        }
    }
}
