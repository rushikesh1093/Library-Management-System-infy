import SwiftUI
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore

struct AdminDashboardView: View {
    @State private var userCount: Int = 0
    @State private var bookCount: Int = 0
    @State private var isLoading: Bool = true
    @State private var errorMessage: String = ""
    @State private var animateContent: Bool = false
    
    private let db = Firestore.firestore()
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [.blue.opacity(0.2), .white.opacity(0.1)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 10) {
                        Image(systemName: "person.3.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .foregroundColor(.blue)
                            .opacity(animateContent ? 1 : 0)
                            .scaleEffect(animateContent ? 1 : 0.5)
                            .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.1), value: animateContent)
                            .accessibilityLabel("Admin Dashboard logo")
                        
                        Text("Admin Dashboard")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.blue)
                            .opacity(animateContent ? 1 : 0)
                            .offset(y: animateContent ? 0 : -20)
                            .animation(.easeOut(duration: 0.6).delay(0.2), value: animateContent)
                            .accessibilityLabel("Admin Dashboard")
                    }
                    .padding(.top, 20)
                    
                    // Overview
                    VStack(spacing: 15) {
                        Text("System Overview")
                            .font(.headline)
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                            .accessibilityLabel("System Overview section")
                        
                        if isLoading {
                            ProgressView()
                                .padding()
                                .accessibilityLabel("Loading dashboard data")
                        } else if !errorMessage.isEmpty {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.caption)
                                .padding(.horizontal)
                                .accessibilityLabel("Error: \(errorMessage)")
                        } else {
                            DashboardCard(title: "Total Users", value: "\(userCount)", icon: "person.fill")
                            DashboardCard(title: "Total Books", value: "\(bookCount)", icon: "books.vertical.fill")
                        }
                    }
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 20)
                    .animation(.easeOut(duration: 0.6).delay(0.3), value: animateContent)
                    
                    // Quick Actions
                    VStack(spacing: 15) {
                        Text("Quick Actions")
                            .font(.headline)
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                            .accessibilityLabel("Quick Actions section")
                        
                        ActionButton(title: "Manage Users", icon: "person.crop.circle.fill", action: {
                            print("Navigate to user management")
                        })
                        ActionButton(title: "System Settings", icon: "gearshape.fill", action: {
                            print("Navigate to system settings")
                        })
                    }
                    .padding(.horizontal)
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 20)
                    .animation(.easeOut(duration: 0.6).delay(0.4), value: animateContent)
                    
                    Spacer()
                }
                .frame(maxWidth: 400)
                .padding(.vertical, 20)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear {
                fetchDashboardData()
                animateContent = false
                withAnimation {
                    animateContent = true
                }
            }
        }
    }
    
    // Dashboard Card Component
    private struct DashboardCard: View {
        let title: String
        let value: String
        let icon: String
        
        var body: some View {
            HStack {
                Image(systemName: icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading) {
                    Text(title)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Text(value)
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                Spacer()
            }
            .padding()
            .background(Color.white.opacity(0.9))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 2)
            .padding(.horizontal)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(title): \(value)")
        }
    }
    
    // Action Button Component
    private struct ActionButton: View {
        let title: String
        let icon: String
        let action: () -> Void
        
        var body: some View {
            Button(action: action) {
                HStack {
                    Image(systemName: icon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .foregroundColor(.white)
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding()
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [.blue, .blue.opacity(0.8)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .blue.opacity(0.3), radius: 5, x: 0, y: 2)
            }
            .accessibilityLabel(title)
        }
    }
    
    private func fetchDashboardData() {
        // Fetch user count
        db.collection("users").getDocuments { (snapshot, error) in
            if let error = error {
                errorMessage = "Failed to fetch users: \(error.localizedDescription)"
                print("Firestore users fetch error: \(error.localizedDescription)")
                isLoading = false
                return
            }
            userCount = snapshot?.documents.count ?? 0
            print("Fetched \(userCount) users")
            
            // Fetch book count
            db.collection("books").getDocuments { (snapshot, error) in
                if let error = error {
                    errorMessage = "Failed to fetch books: \(error.localizedDescription)"
                    print("Firestore books fetch error: \(error.localizedDescription)")
                } else {
                    bookCount = snapshot?.documents.count ?? 0
                    print("Fetched \(bookCount) books")
                }
                isLoading = false
            }
        }
    }
}

#Preview {
    AdminDashboardView()
}
