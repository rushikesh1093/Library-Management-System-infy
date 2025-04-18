////
////  Main.swift
////  Lib1
////
////  Created by admin100 on 17/04/25.
////
//
//import SwiftUI
//import FirebaseAuth
//
//struct MainView: View {
//    @State private var selectedTab: Tab = .home
//    
//    enum Tab: String {
//        case home
//        case booking
//        case profile
//    }
//    
//    var body: some View {
//        TabView(selection: $selectedTab) {
//            // Home Tab
//            HomeView()
//                .tabItem {
//                    Label("Home", systemImage: "house.fill")
//                }
//                .tag(Tab.home)
//            
//            // Booking Tab
//            BookingView()
//                .tabItem {
//                    Label("Booking", systemImage: "calendar")
//                }
//                .tag(Tab.booking)
//            
//            // Profile Tab
//            ProfileView()
//                .tabItem {
//                    Label("Profile", systemImage: "person.fill")
//                }
//                .tag(Tab.profile)
//        }
//        .tint(.blue)
//        .onAppear {
//            // Ensure the user is authenticated
//            if Auth.auth().currentUser == nil {
//                print("No authenticated user found, redirecting to login")
//            }
//        }
//    }
//}
//
//// Placeholder views for each tab
//struct HomeView: View {
//    var body: some View {
//        VStack {
//            Image(systemName: "book.circle.fill")
//                .resizable()
//                .scaledToFit()
//                .frame(width: 100, height: 100)
//                .foregroundColor(.blue)
//            Text("Welcome to the Library Management System")
//                .font(.title2)
//                .fontWeight(.semibold)
//                .foregroundColor(.blue)
//                .multilineTextAlignment(.center)
//                .padding()
//            Spacer()
//        }
//        .frame(maxWidth: .infinity, maxHeight: .infinity)
//        .background(Color.blue.opacity(0.05))
//    }
//}
//
//struct BookingView: View {
//    var body: some View {
//        VStack {
//            Image(systemName: "calendar")
//                .resizable()
//                .scaledToFit()
//                .frame(width: 100, height: 100)
//                .foregroundColor(.blue)
//            Text("Book Your Resources")
//                .font(.title2)
//                .fontWeight(.semibold)
//                .foregroundColor(.blue)
//                .padding()
//            Spacer()
//        }
//        .frame(maxWidth: .infinity, maxHeight: .infinity)
//        .background(Color.blue.opacity(0.05))
//    }
//}
//
//struct ProfileView: View {
//    var body: some View {
//        VStack {
//            Image(systemName: "person.circle.fill")
//                .resizable()
//                .scaledToFit()
//                .frame(width: 100, height: 100)
//                .foregroundColor(.blue)
//            Text("User Profile")
//                .font(.title2)
//                .fontWeight(.semibold)
//                .foregroundColor(.blue)
//                .padding()
//            if let user = Auth.auth().currentUser {
//                Text("Email: \(user.email ?? "N/A")")
//                    .font(.subheadline)
//                    .foregroundColor(.gray)
//                    .padding(.bottom, 5)
//                Button(action: {
//                    do {
//                        try Auth.auth().signOut()
//                        print("User signed out successfully")
//                    } catch {
//                        print("Error signing out: \(error.localizedDescription)")
//                    }
//                }) {
//                    Text("Sign Out")
//                        .font(.headline)
//                        .foregroundColor(.white)
//                        .padding()
//                        .frame(maxWidth: .infinity)
//                        .background(Color.red)
//                        .clipShape(RoundedRectangle(cornerRadius: 10))
//                        .padding(.horizontal)
//                }
//                .accessibilityLabel("Sign out button")
//            }
//            Spacer()
//        }
//        .frame(maxWidth: .infinity, maxHeight: .infinity)
//        .background(Color.blue.opacity(0.05))
//    }
//}
//
//#Preview {
//    MainView()
//}
