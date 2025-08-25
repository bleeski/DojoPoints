import SwiftUI

struct AwardButton: View {
    let behavior: Behavior
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            Theme.lightImpact()
            action()
        }) {
            VStack(spacing: 8) {
                Text(behavior.emoji)
                    .font(.system(size: 32))
                
                Text(behavior.name)
                    .font(Theme.body())
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.8)
                
                HStack(spacing: 2) {
                    Image(systemName: behavior.points >= 0 ? "plus.circle.fill" : "minus.circle.fill")
                        .font(.system(size: 14))
                    Text("\(abs(behavior.points))")
                        .font(Theme.headline())
                }
                .foregroundColor(behavior.points >= 0 ? .green : .red)
            }
            .frame(maxWidth: .infinity, minHeight: 100)
            .padding(Theme.smallPadding)
            .background(
                RoundedRectangle(cornerRadius: Theme.cornerRadius)
                    .fill(behavior.category.color.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.cornerRadius)
                            .stroke(behavior.category.color.opacity(0.3), lineWidth: 2)
                    )
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}
