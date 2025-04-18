import SwiftUI
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore

struct SignUpView: View {
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var selectedRole: UserRole = .member
    @State private var showLogin = false
    @State private var isLoggedIn = false
    @State private var animateButton = false
    @State private var animateContent = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    @State private var showSuccessAlert = false
    @FocusState private var focusedField: Field?
    
    enum UserRole: String, CaseIterable, Identifiable {
        case librarian = "Librarian"
        case member = "Member"
        
        var id: String { self.rawValue }
    }
    
    enum Field: Hashable {
        case name
        case email
        case password
        case confirmPassword
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
                
                Text("Sign Up for LMS")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.blue)
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : -20)
                    .animation(.easeOut(duration: 0.6).delay(0.2), value: animateContent)
                    .accessibilityLabel("Sign Up for Library Management System")
                
                VStack(spacing: 15) {
                    HStack {
                        Image(systemName: "person.fill")
                            .foregroundColor(.blue.opacity(0.7))
                            .frame(width: 20)
                        TextField("Name", text: $name)
                            .font(.body)
                            .autocapitalization(.words)
                            .focused($focusedField, equals: .name)
                            .padding(.vertical, 10)
                            .accessibilityLabel("Name input")
                    }
                    .padding(.horizontal)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .shadow(color: focusedField == .name ? .blue.opacity(0.3) : .gray.opacity(0.1), radius: 5, x: 0, y: 2)
                    .opacity(animateContent ? 1 : 0)
                    .animation(.easeOut(duration: 0.6).delay(0.3), value: animateContent)
                    
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
                    .animation(.easeOut(duration: 0.6).delay(0.4), value: animateContent)
                    
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
                    .animation(.easeOut(duration: 0.6).delay(0.5), value: animateContent)
                    
                    HStack {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.blue.opacity(0.7))
                            .frame(width: 20)
                        SecureField("Confirm Password", text: $confirmPassword)
                            .font(.body)
                            .focused($focusedField, equals: .confirmPassword)
                            .padding(.vertical, 10)
                            .accessibilityLabel("Confirm password input")
                    }
                    .padding(.horizontal)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .shadow(color: focusedField == .confirmPassword ? .blue.opacity(0.3) : .gray.opacity(0.1), radius: 5, x: 0, y: 2)
                    .opacity(animateContent ? 1 : 0)
                    .animation(.easeOut(duration: 0.6).delay(0.6), value: animateContent)
                    
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
                    .animation(.easeOut(duration: 0.6).delay(0.7), value: animateContent)
                    .accessibilityLabel("Select user role")
                    
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.horizontal)
                            .opacity(animateContent ? 1 : 0)
                            .offset(y: animateContent ? 0 : 10)
                            .animation(.easeInOut(duration: 0.3).delay(0.8), value: animateContent)
                            .accessibilityLabel("Error: \(errorMessage)")
                    }
                    
                    Button(action: {
                        withAnimation(.spring()) {
                            if name.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty {
                                errorMessage = "Please fill in all fields"
                                print("Validation failed: Empty fields")
                            } else if password != confirmPassword {
                                errorMessage = "Passwords do not match"
                                print("Validation failed: Password mismatch")
                            } else {
                                isLoading = true
                                errorMessage = ""
                                print("Attempting sign-up with email: \(email), name: \(name), role: \(selectedRole.rawValue)")
                                Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
                                    if let error = error as NSError? {
                                        switch error.code {
                                        case AuthErrorCode.emailAlreadyInUse.rawValue:
                                            errorMessage = "This email is already registered"
                                        case AuthErrorCode.invalidEmail.rawValue:
                                            errorMessage = "Invalid email format"
                                        case AuthErrorCode.weakPassword.rawValue:
                                            errorMessage = "Password must be at least 6 characters"
                                        default:
                                            errorMessage = "Sign-up failed: \(error.localizedDescription)"
                                        }
                                        print("Auth error: \(error.localizedDescription) (Code: \(error.code))")
                                        isLoading = false
                                        return
                                    }
                                    if let user = authResult?.user {
                                        print("Firebase Auth succeeded for user: \(user.uid)")
                                        let userData = [
                                            "name": name,
                                            "email": email,
                                            "role": selectedRole.rawValue,
                                            "createdAt": Timestamp()
                                        ]
                                        Firestore.firestore().collection("users").document(user.uid).setData(userData) { error in
                                            isLoading = false
                                            if let error = error {
                                                errorMessage = "Failed to save user data: \(error.localizedDescription)"
                                                print("Firestore write error: \(error.localizedDescription)")
                                            } else {
                                                print("Firestore saved: name=\(name), email=\(email), role=\(selectedRole.rawValue)")
                                                showSuccessAlert = true
                                            }
                                        }
                                    } else {
                                        errorMessage = "Sign-up failed: No user returned"
                                        print("No user returned from Firebase Auth")
                                        isLoading = false
                                    }
                                }
                            }
                        }
                    }) {
                        Text(isLoading ? "Signing Up..." : "Sign Up")
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
                    .accessibilityLabel("Sign Up button")
                    .animation(.spring(response: 0.4, dampingFraction: 0.6).delay(0.9), value: animateButton)
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
                        showLogin = true
                    }
                }) {
                    Text("Already have an account? Login")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                        .underline()
                }
                .accessibilityLabel("Navigate to login")
                .opacity(animateContent ? 1 : 0)
                .animation(.easeOut(duration: 0.6).delay(1.0), value: animateContent)
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
                    print("Cleared stale auth session on SignUpView appear")
                }
                animateContent = false
                withAnimation {
                    animateContent = true
                }
            }
            .alert("Success", isPresented: $showSuccessAlert) {
                Button("OK") {
                    showLogin = true
                }
            } message: {
                Text("Account created successfully!")
            }
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $showLogin) {
                LoginView()
            }
            .navigationDestination(isPresented: $isLoggedIn) {
                LoginView()
            }
        }
    }
}

#Preview {
    SignUpView()
}
