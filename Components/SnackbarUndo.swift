import SwiftUI
import SwiftData

struct SnackbarUndo: View {
    @Binding var lastEvent: PointEvent?
    @Binding var isShowing: Bool
    @Environment(\.modelContext) private var modelContext
    @State private var timeRemaining = 15
    @State private var timer: Timer?
    
    var body: some View {
        Group {
            if isShowing, let event = lastEvent {
                VStack {
                    Spacer()
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Added \(event.points >= 0 ? "+" : "")\(event.points) for \(event.child?.name ?? "")")
                                .font(Theme.body())
                                .foregroundColor(.white)
                            
                            Text("\(event.behavior?.emoji ?? "") \(event.behavior?.name ?? "")")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.9))
                        }
                        
                        Spacer()
                        
                        Button(action: undoAction) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.uturn.backward")
                                Text("Undo (\(timeRemaining))")
                            }
                            .font(Theme.headline())
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(Color.white.opacity(0.2))
                            )
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: Theme.cornerRadius)
                            .fill(Color.black.opacity(0.85))
                    )
                    .padding()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .onAppear {
                    startTimer()
                }
                .onDisappear {
                    timer?.invalidate()
                }
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isShowing)
    }
    
    private func startTimer() {
        timeRemaining = 15
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                dismiss()
            }
        }
    }
    
    private func undoAction() {
        Theme.mediumImpact()
        if let event = lastEvent {
            modelContext.delete(event)
            try? modelContext.save()
        }
        dismiss()
    }
    
    private func dismiss() {
        timer?.invalidate()
        withAnimation {
            isShowing = false
            lastEvent = nil
        }
    }
}
