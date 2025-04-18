
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct UserProfileView: View {
    @State private var userName: String = ""
    @State private var userId: String = ""
    @State private var joinedOn: String = ""
    @State private var expiryOn: String = ""
    @State private var isEditingName: Bool = false
    @State private var newName: String = ""
    @State private var notificationsEnabled: Bool = true
    @State private var borrowingReminders: Bool = true
    @State private var overdueAlerts: Bool = true
    @State private var prefersDarkMode: Bool = false
    @State private var selectedLanguage: Language = .english
    @State private var errorMessage: String = ""
    @State private var isLoading: Bool = true
    @State private var animateContent: Bool = false
    @State private var showNotificationSettings: Bool = false
    
    private let db = Firestore.firestore()
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
    
    enum Language: String, CaseIterable, Identifiable {
        case english = "English"
        case spanish = "Spanish"
        var id: String { rawValue }
    }
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [.blue.opacity(0.2), .white.opacity(0.1)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 5).repeatForever(autoreverses: true), value: animateContent)
            
            ScrollView {
                VStack(spacing: 20) {
                    // Profile Header
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.blue)
                        .opacity(animateContent ? 1 : 0)
                        .scaleEffect(animateContent ? 1 : 0.5)
                        .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.1), value: animateContent)
                        .accessibilityLabel("User profile icon")
                    
                    Text("User Profile")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.blue)
                        .opacity(animateContent ? 1 : 0)
                        .offset(y: animateContent ? 0 : -20)
                        .animation(.easeOut(duration: 0.6).delay(0.2), value: animateContent)
                        .accessibilityLabel("User Profile title")
                    
                    // Profile Card
                    VStack(spacing: 12) {
                        // Name with Edit Button
                        HStack {
                            Image(systemName: "person.fill")
                                .foregroundColor(.blue.opacity(0.7))
                                .frame(width: 20)
                            Text("Name")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            if isEditingName {
                                TextField("Enter name", text: $newName)
                                    .font(.body)
                                    .accessibilityLabel("Edit name input")
                            } else {
                                Text(userName.isEmpty ? "N/A" : userName)
                                    .font(.body)
                                    .foregroundColor(.primary)
                                    .accessibilityLabel("User name: \(userName.isEmpty ? "Not available" : userName)")
                            }
                            Spacer()
                            Button(action: {
                                withAnimation {
                                    if isEditingName {
                                        saveName()
                                    } else {
                                        newName = userName
                                        isEditingName = true
                                    }
                                }
                            }) {
                                Text(isEditingName ? "Save" : "Edit")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                            .accessibilityLabel(isEditingName ? "Save name button" : "Edit name button")
                        }
                        
                        Divider()
                        
                        // ID
                        HStack {
                            Image(systemName: "number")
                                .foregroundColor(.blue.opacity(0.7))
                                .frame(width: 20)
                            Text("ID")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            Spacer()
                            Text(userId.isEmpty ? "N/A" : String(userId.prefix(8)))
                                .font(.body)
                                .foregroundColor(.primary)
                                .accessibilityLabel("User ID: \(userId.isEmpty ? "Not available" : userId)")
                        }
                        
                        Divider()
                        
                        // Joined On
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(.blue.opacity(0.7))
                                .frame(width: 20)
                            Text("Joined On")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            Spacer()
                            Text(joinedOn.isEmpty ? "N/A" : joinedOn)
                                .font(.body)
                                .foregroundColor(.primary)
                                .accessibilityLabel("Joined on: \(joinedOn.isEmpty ? "Not available" : joinedOn)")
                        }
                        
                        Divider()
                        
                        // Expiry On
                        HStack {
                            Image(systemName: "calendar.badge.exclamationmark")
                                .foregroundColor(.blue.opacity(0.7))
                                .frame(width: 20)
                            Text("Expiry On")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            Spacer()
                            Text(expiryOn.isEmpty ? "N/A" : expiryOn)
                                .font(.body)
                                .foregroundColor(.primary)
                                .accessibilityLabel("Expiry on: \(expiryOn.isEmpty ? "Not available" : expiryOn)")
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.9))
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    .shadow(color: .gray.opacity(0.2), radius: 8, x: 0, y: 4)
                    .padding(.horizontal, 20)
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 20)
                    .animation(.easeOut(duration: 0.6).delay(0.3), value: animateContent)
                    
                    // General Settings
                    VStack(spacing: 12) {
                        Text("General Settings")
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                            .padding(.top, 10)
                            .accessibilityLabel("General Settings section")
                        
                        // Dark Mode Toggle
                        HStack {
                            Image(systemName: "moon.fill")
                                .foregroundColor(.blue.opacity(0.7))
                                .frame(width: 20)
                            Text("Dark Mode")
                                .font(.body)
                                .padding(.vertical, 10)
                            Spacer()
                            Toggle("", isOn: $prefersDarkMode)
                                .labelsHidden()
                                .accessibilityLabel("Toggle dark mode")
                        }
                        .padding(.horizontal)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .shadow(color: .gray.opacity(0.1), radius: 5, x: 0, y: 2)
                        
                        // Language Selection
                        HStack {
                            Image(systemName: "globe")
                                .foregroundColor(.blue.opacity(0.7))
                                .frame(width: 20)
                            Text("Language")
                                .font(.body)
                                .padding(.vertical, 10)
                            Spacer()
                            Picker("Language", selection: $selectedLanguage) {
                                ForEach(Language.allCases) { language in
                                    Text(language.rawValue).tag(language)
                                }
                            }
                            .pickerStyle(.menu)
                            .accessibilityLabel("Select language")
                        }
                        .padding(.horizontal)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .shadow(color: .gray.opacity(0.1), radius: 5, x: 0, y: 2)
                        
                        // Notification Settings
                        HStack {
                            Image(systemName: "bell.fill")
                                .foregroundColor(.blue.opacity(0.7))
                                .frame(width: 20)
                            Text("Notifications")
                                .font(.body)
                                .padding(.vertical, 10)
                            Spacer()
                            Button(action: {
                                withAnimation {
                                    showNotificationSettings.toggle()
                                }
                            }) {
                                Image(systemName: showNotificationSettings ? "chevron.up" : "chevron.down")
                                    .foregroundColor(.blue)
                            }
                            .accessibilityLabel("Toggle notification settings")
                        }
                        .padding(.horizontal)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .shadow(color: .gray.opacity(0.1), radius: 5, x: 0, y: 2)
                        
                        if showNotificationSettings {
                            VStack(spacing: 12) {
                                // Borrowing Reminders
                                HStack {
                                    Text("Borrowing Reminders")
                                        .font(.body)
                                        .padding(.vertical, 10)
                                    Spacer()
                                    Toggle("", isOn: $borrowingReminders)
                                        .labelsHidden()
                                        .accessibilityLabel("Toggle borrowing reminders")
                                }
                                .padding(.horizontal)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .shadow(color: .gray.opacity(0.1), radius: 5, x: 0, y: 2)
                                
                                // Overdue Alerts
                                HStack {
                                    Text("Overdue Alerts")
                                        .font(.body)
                                        .padding(.vertical, 10)
                                    Spacer()
                                    Toggle("", isOn: $overdueAlerts)
                                        .labelsHidden()
                                        .accessibilityLabel("Toggle overdue alerts")
                                }
                                .padding(.horizontal)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .shadow(color: .gray.opacity(0.1), radius: 5, x: 0, y: 2)
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 10)
                        }
                        
                        // Sign Out
                        Button(action: {
                            do {
                                try Auth.auth().signOut()
                                print("User signed out successfully")
                            } catch {
                                errorMessage = "Error signing out: \(error.localizedDescription)"
                                print("Sign out error: \(error.localizedDescription)")
                            }
                        }) {
                            Text("Sign Out")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.red, .red.opacity(0.8)]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .shadow(color: .red.opacity(0.3), radius: 5, x: 0, y: 2)
                        }
                        .accessibilityLabel("Sign out button")
                    }
                    .padding()
                    .background(Color.white.opacity(0.9))
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    .shadow(color: .gray.opacity(0.2), radius: 8, x: 0, y: 4)
                    .padding(.horizontal, 20)
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 20)
                    .animation(.easeOut(duration: 0.6).delay(0.4), value: animateContent)
                    
                    // Error Message
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.horizontal)
                            .padding(.top, 10)
                            .opacity(animateContent ? 1 : 0)
                            .offset(y: animateContent ? 0 : 10)
                            .animation(.easeInOut(duration: 0.3).delay(0.5), value: animateContent)
                            .accessibilityLabel("Error: \(errorMessage)")
                    }
                    
                    Spacer()
                }
                .frame(maxWidth: 400)
                .padding(.vertical, 20)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .onAppear {
                fetchUserData()
                animateContent = false
                withAnimation {
                    animateContent = true
                }
            }
            .navigationBarHidden(true)
            .preferredColorScheme(prefersDarkMode ? .dark : .light)
        }
    }
    
    private func fetchUserData() {
        guard let user = Auth.auth().currentUser else {
            errorMessage = "No authenticated user found"
            isLoading = false
            print("No authenticated user")
            return
        }
        
        userId = user.uid
        isLoading = true
        
        db.collection("users").document(user.uid).getDocument { (document, error) in
            if let error = error {
                errorMessage = "Failed to fetch user data: \(error.localizedDescription)"
                isLoading = false
                print("Firestore fetch error: \(error.localizedDescription)")
                return
            }
            
            if let document = document, document.exists {
                let data = document.data()
                userName = data?["name"] as? String ?? ""
                
                // Handle joinedOn
                if let joinedTimestamp = data?["joinedOn"] as? Timestamp {
                    let date = joinedTimestamp.dateValue()
                    joinedOn = dateFormatter.string(from: date)
                } else {
                    joinedOn = "N/A"
                }
                
                // Handle expiryOn
                if let expiryTimestamp = data?["expiryOn"] as? Timestamp {
                    let date = expiryTimestamp.dateValue()
                    expiryOn = dateFormatter.string(from: date)
                } else if let joinedTimestamp = data?["joinedOn"] as? Timestamp {
                    // Calculate expiry as 1 year from joinedOn for members
                    let joinedDate = joinedTimestamp.dateValue()
                    if let role = data?["role"] as? String, role == "Member" {
                        if let expiryDate = Calendar.current.date(byAdding: .year, value: 1, to: joinedDate) {
                            expiryOn = dateFormatter.string(from: expiryDate)
                            // Update Firestore with calculated expiry
                            db.collection("users").document(user.uid).updateData([
                                "expiryOn": Timestamp(date: expiryDate)
                            ]) { error in
                                if let error = error {
                                    print("Failed to update expiryOn: \(error.localizedDescription)")
                                }
                            }
                        } else {
                            expiryOn = "N/A"
                        }
                    } else {
                        expiryOn = "N/A"
                    }
                } else {
                    expiryOn = "N/A"
                }
                
                print("Fetched user data: name=\(userName), joinedOn=\(joinedOn), expiryOn=\(expiryOn)")
            } else {
                errorMessage = "User data not found"
                print("No user document in Firestore")
            }
            isLoading = false
        }
    }
    
    private func saveName() {
        guard let user = Auth.auth().currentUser else {
            errorMessage = "No authenticated user found"
            print("No authenticated user for name update")
            return
        }
        
        if newName.trimmingCharacters(in: .whitespaces).isEmpty {
            errorMessage = "Name cannot be empty"
            print("Validation failed: Empty name")
            return
        }
        
        isLoading = true
        db.collection("users").document(user.uid).updateData([
            "name": newName
        ]) { error in
            if let error = error {
                errorMessage = "Failed to update name: \(error.localizedDescription)"
                print("Firestore update error: \(error.localizedDescription)")
            } else {
                userName = newName
                isEditingName = false
                print("Name updated successfully: \(newName)")
            }
            isLoading = false
        }
    }
}

#Preview {
    UserProfileView()
}
