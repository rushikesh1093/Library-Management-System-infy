import SwiftUI

struct OnboardingView: View {
    @State private var currentPage = 0
    @State private var isActive = false
    @State private var animateContent = false
    @State private var animateButton = false
    @State private var backgroundPulse = false
    
    let pages = [
        OnboardingPage(title: "Welcome to LMS", description: "Effortlessly manage your library with our intuitive system.", image: "books.vertical.fill"),
        OnboardingPage(title: "Smart Catalog", description: "Easily add, update, or remove library resources in real-time.", image: "book.fill"),
        OnboardingPage(title: "Seamless Experience", description: "Designed for admins, librarians, and members alike.", image: "person.3.fill")
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Light, pastel layered background
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(hex: "#ffe5cc").opacity(backgroundPulse ? 0.9 : 0.8), // Soft peach derived from #ffb366
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
                
                VStack(spacing: 30) {
                    TabView(selection: $currentPage) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            VStack(spacing: 25) {
                                Image(systemName: pages[index].image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 120, height: 120)
                                    .foregroundColor(Color(hex: "#ffb366"))
                                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                                    .accessibilityHidden(true)
                                    .scaleEffect(animateContent ? 1 : 0.7)
                                    .rotation3DEffect(.degrees(animateContent ? 0 : 10), axis: (x: 0, y: 1, z: 0))
                                    .opacity(animateContent ? 1 : 0)
                                    .animation(.spring(response: 0.5, dampingFraction: 0.5, blendDuration: 0.3).delay(0.1), value: animateContent)
                                
                                TypewriterText(text: pages[index].title, isAnimating: animateContent)
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundColor(.black.opacity(0.9)) // Changed to darker color for contrast on light background
                                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                                    .accessibilityLabel(pages[index].title)
                                    .opacity(animateContent ? 1 : 0)
                                    .offset(y: animateContent ? 0 : 30)
                                    .animation(.spring(response: 0.4, dampingFraction: 0.6).delay(0.2), value: animateContent)
                                
                                TypewriterText(text: pages[index].description, isAnimating: animateContent)
                                    .font(.system(size: 18, weight: .regular, design: .rounded))
                                    .foregroundColor(.black.opacity(0.7)) // Adjusted for readability
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 40)
                                    .accessibilityLabel(pages[index].description)
                                    .opacity(animateContent ? 1 : 0)
                                    .offset(y: animateContent ? 0 : 30)
                                    .animation(.spring(response: 0.4, dampingFraction: 0.6).delay(0.3), value: animateContent)
                            }
                            .padding(.vertical, 50)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.white.opacity(0.3))
                                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                            )
                            .padding(.horizontal, 20)
                            .tag(index)
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                            .onAppear {
                                animateContent = false
                                withAnimation {
                                    animateContent = true
                                }
                            }
                        }
                    }
                    .tabViewStyle(.page)
                    .indexViewStyle(.page(backgroundDisplayMode: .always))
                    
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                            if currentPage < pages.count - 1 {
                                currentPage += 1
                            } else {
                                isActive = true
                            }
                        }
                    }) {
                        Text(currentPage == pages.count - 1 ? "Get Started" : "Next")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color(hex: "#ffb366"), Color.orange]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                                .overlay(
                                    Color.white.opacity(animateButton ? 0.2 : 0)
                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                        .animation(.easeOut(duration: 0.3), value: animateButton)
                                )
                            )
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .padding(.horizontal, 30)
                            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                            .scaleEffect(animateButton ? 1 : 0.9)
                            .offset(y: animateButton ? 0 : 50)
                            .opacity(animateButton ? 1 : 0)
                    }
                    .accessibilityLabel(currentPage == pages.count - 1 ? "Get Started" : "Next")
                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.4), value: animateButton)
                    .onHover { isHovering in
                        withAnimation(.easeInOut(duration: 0.2)) {
                            animateButton = isHovering
                        }
                    }
                    .onAppear {
                        animateButton = false
                        withAnimation {
                            animateButton = true
                        }
                    }
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .navigationBarHidden(true)
                .navigationDestination(isPresented: $isActive) {
                    LoginView()
                }
                .onAppear {
                    animateContent = false
                    animateButton = false
                    backgroundPulse = false
                    withAnimation {
                        animateContent = true
                        animateButton = true
                        backgroundPulse = true
                    }
                }
            }
        }
    }
}

// Rewritten Typewriter Text View
struct TypewriterText: View {
    let text: String
    let isAnimating: Bool
    @State private var characterCount = 0
    
    var body: some View {
        Text(text.prefix(characterCount))
            .onChange(of: isAnimating) { newValue in
                if newValue {
                    characterCount = 0
                    withAnimation(.linear(duration: Double(text.count) * 0.03)) {
                        characterCount = text.count
                    }
                } else {
                    characterCount = text.count
                }
            }
            .onAppear {
                characterCount = isAnimating ? 0 : text.count
                if isAnimating {
                    withAnimation(.linear(duration: Double(text.count) * 0.03)) {
                        characterCount = text.count
                    }
                }
            }
    }
}

struct OnboardingPage {
    let title: String
    let description: String
    let image: String
}

// Extension to support hex color
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    OnboardingView()
}
