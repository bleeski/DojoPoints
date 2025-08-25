import SwiftUI

struct BeltProgressRing: View {
    let progress: Double // 0.0 to 1.0
    let lineWidth: CGFloat
    let size: CGFloat
    
    init(progress: Double, lineWidth: CGFloat = 12, size: CGFloat = 100) {
        self.progress = min(max(progress, 0), 1) // Clamp between 0 and 1
        self.lineWidth = lineWidth
        self.size = size
    }
    
    private var beltColor: Color {
        // Progress determines belt color
        let beltIndex = Int(progress * Double(Theme.beltColors.count - 1))
        return Theme.beltColors[min(beltIndex, Theme.beltColors.count - 1)]
    }
    
    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: lineWidth)
                .frame(width: size, height: size)
            
            // Progress ring with belt color
            Circle()
                .trim(from: 0, to: progress)
                .stroke(beltColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: progress)
            
            // Center text
            VStack(spacing: 2) {
                Text("\(Int(progress * 100))%")
                    .font(Theme.headline())
                    .fontWeight(.bold)
                
                Image(systemName: "figure.martial.arts")
                    .font(.system(size: size * 0.2))
                    .foregroundColor(beltColor)
            }
        }
    }
}
