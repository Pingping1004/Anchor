import SwiftUI

func responsiveIcon(icon: String, size: CGFloat, color: Color? = nil) -> some View {
    ZStack {
        if color == nil {
            LinearGradient.primaryGradient
        } else {
            color
        }
        
        Image(systemName: icon)
            .resizable()
            .scaledToFit()
            .frame(width: size * 0.45)
            .foregroundStyle(.white)
    }
    .frame(width: size, height: size)
    .clipShape(RoundedRectangle(cornerRadius: size * 0.35, style: .continuous))
    .glassEffect(
        .regular.interactive(),
        in: .rect(cornerRadius: 24, style: .continuous)
    )
    .accessibilityHidden(true)
}
