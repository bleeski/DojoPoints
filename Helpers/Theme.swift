import SwiftUI

struct Theme {
    // Colors
    static let primaryGradient = LinearGradient(
        colors: [Color.blue, Color.purple],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let successGradient = LinearGradient(
        colors: [Color.green, Color.mint],
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let warningGradient = LinearGradient(
        colors: [Color.orange, Color.red],
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let backgroundColor = Color(.systemGroupedBackground)
    static let cardBackground = Color(.systemBackground)
    
    // Belt colors for progress ring
    static let beltColors: [Color] = [
        .white,      // White belt
        .yellow,     // Yellow belt
        .orange,     // Orange belt
        .green,      // Green belt
        .blue,       // Blue belt
        .purple,     // Purple belt
        .brown,      // Brown belt
        .black       // Black belt
    ]
    
    // Typography
    static func largeTitle() -> Font {
        .system(.largeTitle, design: .rounded, weight: .bold)
    }
    
    static func title() -> Font {
        .system(.title2, design: .rounded, weight: .semibold)
    }
    
    static func headline() -> Font {
        .system(.headline, design: .rounded)
    }
    
    static func body() -> Font {
        .system(.body, design: .rounded)
    }
    
    // Sizing
    static let cornerRadius: CGFloat = 16
    static let padding: CGFloat = 16
    static let smallPadding: CGFloat = 8
    
    // Haptics
    static func lightImpact() {
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }
    
    static func mediumImpact() {
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
    }
    
    static func heavyImpact() {
        let impact = UIImpactFeedbackGenerator(style: .heavy)
        impact.impactOccurred()
    }
    
    static func successHaptic() {
        let notification = UINotificationFeedbackGenerator()
        notification.notificationOccurred(.success)
    }
}
