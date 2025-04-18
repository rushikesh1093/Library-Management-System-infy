import SwiftUI
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var selectedRole: UserRole = .member
    @State private var showSignUp = false
    @State private var isLoggedIn = false
    @State private var animateButton = false
    @State private var animateContent = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    @FocusState private var focusedField: Field?
    
    enum UserRole: String, CaseIterable, Identifiable {
        case admin = "Admin"
        case librarian = "Librarian"
        case member = "Member"
        
        var id: String { self.rawValue }
    }
    
    enum Field: Hashable {
        case email
        case password
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
            
            VStack(spacing: 20) {
                Image(systemName: "book.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.blue)
                    .opacity(animateContent ? 1 : 0)
                    .scaleEffect(animateContent ? 1 : 0.5)
                    .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.1), value: animateContent)
                    .accessibilityLabel("Library Management System logo")
                
                Text("Login to LMS")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.blue)
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : -20)
                    .animation(.easeOut(duration: 0.6).delay(0.2), value: animateContent)
                    .accessibilityLabel("Login to Library Management System")
                
                VStack(spacing: 15) {
                    HStack {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(.blue.opacity(0.7))
                            .frame(width: 20)
                        TextField("Email", text: $email)
                            .font(.body)
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
                            .focused($focusedField, equals: .email)
                            .padding(.vertical, 10)
                            .accessibilityLabel("Email input")
                    }
                    .padding(.horizontal)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .shadow(color: focusedField == .email ? .blue.opacity(0.3) : .gray.opacity(0.1), radius: 5, x: 0, y: 2)
                    .opacity(animateContent ? 1 : 0)
                    .animation(.easeOut(duration: 0.6).delay(0.3), value: animateContent)
                    
                    HStack {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.blue.opacity(0.7))
                            .frame(width: 20)
                        SecureField("Password", text: $password)
                            .font(.body)
                            .focused($focusedField, equals: .password)
                            .padding(.vertical, 10)
                            .accessibilityLabel("Password input")
                    }
                    .padding(.horizontal)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .shadow(color: focusedField == .password ? .blue.opacity(0.3) : .gray.opacity(0.1), radius: 5, x: 0, y: 2)
                    .opacity(animateContent ? 1 : 0)
                    .animation(.easeOut(duration: 0.6).delay(0.4), value: animateContent)
                    
                    Picker("Role", selection: $selectedRole) {
                        ForEach(UserRole.allCases) { role in
                            Text(role.rawValue).tag(role)
                        }
                    }
                    .pickerStyle(.menu)
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .shadow(color: .gray.opacity(0.1), radius: 5, x: 0, y: 2)
                    .opacity(animateContent ? 1 : 0)
                    .animation(.easeOut(duration: 0.6).delay(0.5), value: animateContent)
                    .accessibilityLabel("Select user role")
                    
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.horizontal)
                            .opacity(animateContent ? 1 : 0)
                            .offset(y: animateContent ? 0 : 10)
                            .animation(.easeInOut(duration: 0.3).delay(0.6), value: animateContent)
                            .accessibilityLabel("Error: \(errorMessage)")
                    }
                    
                    Button(action: {
                        withAnimation(.spring()) {
                            if email.isEmpty || password.isEmpty {
                                errorMessage = "Please fill in all fields"
                                print("Validation failed: Empty fields")
                            } else {
                                isLoading = true
                                errorMessage = ""
                                print("Attempting login with email: \(email), role: \(selectedRole.rawValue)")
                                Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
                                    if let error = error as NSError? {
                                        switch error.code {
                                        case AuthErrorCode.invalidEmail.rawValue:
                                            errorMessage = "Invalid email format"
                                        case AuthErrorCode.wrongPassword.rawValue:
                                            errorMessage = "Incorrect password"
                                        case AuthErrorCode.userNotFound.rawValue:
                                            errorMessage = "No account found for this email"
                                        case AuthErrorCode.tooManyRequests.rawValue:
                                            errorMessage = "Too many attempts, try again later"
                                        default:
                                            errorMessage = "Login failed: \(error.localizedDescription)"
                                        }
                                        print("Auth error: \(error.localizedDescription) (Code: \(error.code))")
                                        isLoading = false
                                        return
                                    }
                                    if let user = authResult?.user {
                                        print("Firebase Auth succeeded for user: \(user.uid)")
                                        // Fetch user role from Firestore
                                        Firestore.firestore().collection("users").document(user.uid).getDocument { (document, error) in
                                            if let error = error {
                                                errorMessage = "Failed to fetch user data: \(error.localizedDescription)"
                                                print("Firestore fetch error: \(error.localizedDescription)")
                                                isLoading = false
                                                return
                                            }
                                            if let document = document, document.exists, let userData = document.data(), let storedRole = userData["role"] as? String {
                                                print("Fetched user role: \(storedRole)")
                                                if storedRole != selectedRole.rawValue {
                                                    errorMessage = "Selected role does not match your account"
                                                    print("Role mismatch: Selected \(selectedRole.rawValue), Stored \(storedRole)")
                                                    isLoading = false
                                                    return
                                                }
                                                // Update Firestore document
                                                Firestore.firestore().collection("users").document(user.uid).setData([
                                                    "email": email,
                                                    "role": selectedRole.rawValue
                                                ], merge: true) { error in
                                                    if let error = error {
                                                        errorMessage = "Failed to save user data: \(error.localizedDescription)"
                                                        print("Firestore write error: \(error.localizedDescription)")
                                                        isLoading = false
                                                        return
                                                    }
                                                    print("Firestore updated: email=\(email), role=\(selectedRole.rawValue)")
                                                    isLoggedIn = true
                                                    isLoading = false
                                                }
                                            } else {
                                                errorMessage = "No role assigned to this account"
                                                print("No role found in Firestore for user: \(user.uid)")
                                                isLoading = false
                                            }
                                        }
                                    } else {
                                        errorMessage = "Authentication failed: No user returned"
                                        print("No user returned from Firebase Auth")
                                        isLoading = false
                                    }
                                }
                            }
                        }
                    }) {
                        Text(isLoading ? "Logging In..." : "Login")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [.blue, .blue.opacity(0.8)]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(color: .blue.opacity(0.3), radius: 5, x: 0, y: 2)
                            .scaleEffect(animateButton ? 1 : 0.95)
                    }
                    .disabled(isLoading)
                    .accessibilityLabel("Login button")
                    .animation(.spring(response: 0.4, dampingFraction: 0.6).delay(0.7), value: animateButton)
                    .onAppear {
                        animateButton = false
                        withAnimation {
                            animateButton = true
                        }
                    }
                }
                .padding()
                .background(Color.white.opacity(0.9))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(color: .gray.opacity(0.2), radius: 10, x: 0, y: 5)
                .padding(.horizontal, 20)
                
                Button(action: {
                    withAnimation(.easeInOut) {
                        showSignUp = true
                    }
                }) {
                    Text("Don't have an account? Sign Up")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                        .underline()
                }
                .accessibilityLabel("Navigate to sign up")
                .opacity(animateContent ? 1 : 0)
                .animation(.easeOut(duration: 0.6).delay(0.8), value: animateContent)
            }
            .frame(maxWidth: 400)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .onAppear {
                guard FirebaseApp.app() != nil else {
                    errorMessage = "Firebase is not configured. Please try again later."
                    print("Firebase not configured")
                    return
                }
                if Auth.auth().currentUser != nil {
                    try? Auth.auth().signOut()
                    print("Cleared stale auth session on LoginView appear")
                }
                animateContent = false
                withAnimation {
                    animateContent = true
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $showSignUp) {
                SignUpView()
            }
            .navigationDestination(isPresented: $isLoggedIn) {
                switch selectedRole {
                case .librarian:
                    LibrarianDashboardView()
                case .admin:
                    AdminDashboardView()
                case .member:
                    MainView()
                }
            }
        }
    }
}

#Preview {
    LoginView()
}
