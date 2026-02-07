import SwiftUI

struct TreeConnectors: View {
    @Environment(\.colorSchemeContrast) var contrast
    @ScaledMetric(relativeTo: .body) var frameHeight: CGFloat = 48

    let tasks: [Task]
    let childCount: Int
    let maxTasksPerRow: Int
    let isCollapsed: Bool
    
    private let lineWidth: CGFloat = 2
    
    private var activeOpacity: Double {
        contrast == .increased ? 1.0 : 0.8
    }
    
    private var inactiveOpacity: Double {
        contrast == .increased ? 0.5 : 0.3
    }
    
    var displayCount: Int {
        if isCollapsed { return 1 }
        let limit = min(childCount, maxTasksPerRow)
        return min(tasks.count, limit)
    }
    
    var areAllDisplayedTasksCompleted: Bool {
        guard !tasks.isEmpty, displayCount > 0 else { return false }
        return tasks.prefix(displayCount).allSatisfy { $0.isCompleted }
    }
    
    var body: some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            let safeCount = CGFloat(max(1, displayCount))
            let columnWidth = screenWidth / safeCount
            let responsivePadding = columnWidth / 2
            
            let stemHeight = (frameHeight - lineWidth) / 2
            
            // Normal vertical line
            VStack(alignment: .center, spacing: 0) {
                if displayCount == 1 {
                    
                    let isSingleLineDone: Bool = {
                        if isCollapsed {
                            return tasks.allSatisfy { $0.isCompleted }
                        } else {
                            return tasks.first?.isCompleted ?? false
                        }
                    }()
                    
                    verticalLine(height: stemHeight * 1.5, isCompleted: isSingleLineDone)
                        .frame(width: screenWidth, height: frameHeight, alignment: .center)
                } else {
                    // Double and Tri arrow
                    VStack(alignment: .center, spacing: 0) {
                        verticalLine(height: stemHeight / 1.5, isCompleted: areAllDisplayedTasksCompleted)
                        
                        horizontalLine(isCompleted: areAllDisplayedTasksCompleted)
                            .padding(.horizontal, responsivePadding - (lineWidth / 2))
                        
                        HStack(alignment: .top, spacing: 0) {
                            ForEach(0..<displayCount, id: \.self) { index in
                                let isTaskDone = index < tasks.count ? tasks[index].isCompleted : false
                                
                                verticalLine(height: stemHeight, isCompleted: isTaskDone)
                                    .frame(width: columnWidth)
                            }
                        }
                    }
                    .frame(height: frameHeight, alignment: .center)
                }
            }
        }
        .frame(height: frameHeight)
        .accessibilityHidden(true)
    }
    
    private func verticalLine(height: CGFloat, isCompleted: Bool) -> some View {
        Rectangle()
            .fill(isCompleted ? Color.primaryMain.opacity(activeOpacity) : Color.gray.opacity(inactiveOpacity))
            .frame(width: 2, height: height)
    }
    
    private func horizontalLine(isCompleted: Bool) -> some View {
        Rectangle()
            .fill(isCompleted ? Color.primaryMain.opacity(activeOpacity) : Color.gray.opacity(inactiveOpacity))
            .frame(height: 2)
            .frame(maxWidth: .infinity)
    }
}
