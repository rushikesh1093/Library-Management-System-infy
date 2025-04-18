import SwiftUI

struct SplashScreenView: View {
    @State private var isActive = false
    @State private var scale = 0.5
    @State private var opacity = 0.0
    @State private var rotation = 0.0
    @State private var backgroundPulse = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Light, pastel layered background matching OnboardingView
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(hex: "#ffe5cc").opacity(backgroundPulse ? 0.9 : 0.8), // Soft peach
                        Color(hex: "#e6e6fa").opacity(backgroundPulse ? 0.7 : 0.6), // Light lavender
                        Color(hex: "#f5f5f5") // Off-white
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .overlay(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color(hex: "#ffb366").opacity(backgroundPulse ? 0.3 : 0.2),
                            .clear
                        ]),
                        center: .center,
                        startRadius: backgroundPulse ? 100 : 50,
                        endRadius: backgroundPulse ? 400 : 300
                    )
                    .opacity(0.4)
                )
                .scaleEffect(backgroundPulse ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 5).repeatForever(autoreverses: true), value: backgroundPulse)
                .ignoresSafeArea()
                
                Image(systemName: "book.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 150)
                    .foregroundColor(Color(hex: "#ffb366"))
                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                    .scaleEffect(scale)
                    .opacity(opacity)
                    .rotation3DEffect(.degrees(rotation), axis: (x: 0, y: 1, z: 0))
                    .accessibilityLabel("Library Management System Logo")
                    .onAppear {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.5)) {
                            scale = 1.0
                            opacity = 1.0
                            rotation = 10.0
                            backgroundPulse = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                            withAnimation(.easeInOut(duration: 0.7)) {
                                isActive = true
                            }
                        }
                    }
            }
            .navigationDestination(isPresented: $isActive) {
                OnboardingView()
            }
        }
    }
}

// Extension to support hex color


#Preview {
    SplashScreenView()
}
