import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct LibrarianDashboardView: View {
    @State private var userEmail: String = "Loading..."
    @State private var isLoggedOut: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    
    private let db = Firestore.firestore()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Header with Profile Info
                VStack(spacing: 10) {
                    Text("Librarian Dashboard")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.blue)
                        .accessibilityLabel("Librarian Dashboard")
                    
                    Text("Logged in as: \(userEmail)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .accessibilityLabel("Logged in as \(userEmail)")
                }
                .padding(.top)
                
                // Navigation Buttons
                VStack(spacing: 15) {
                    NavigationLink {
                        AvailableBooksView()
                    } label: {
                        DashboardButton(title: "Available Books", icon: "book.fill")
                    }
                    .accessibilityLabel("View available books")
                    
                    NavigationLink {
                        AddBookView()
                    } label: {
                        DashboardButton(title: "Add New Book", icon: "plus.circle.fill")
                    }
                    .accessibilityLabel("Add a new book")
                    
                    NavigationLink {
                        IssuedBooksView()
                    } label: {
                        DashboardButton(title: "Issued Books", icon: "list.bullet.rectangle")
                    }
                    .accessibilityLabel("View issued books")
                    
                    Button(action: {
                        logout()
                    }) {
                        DashboardButton(title: "Logout", icon: "arrow.right.circle.fill", color: .red)
                    }
                    .accessibilityLabel("Logout")
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .frame(maxWidth: 400)
            .background(Color.white.opacity(0.95))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: .gray.opacity(0.3), radius: 10, x: 0, y: 5)
            .padding()
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Logout"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
            .onAppear {
                loadUserProfile()
            }
            .fullScreenCover(isPresented: $isLoggedOut) {
                // Replace with your app's login view
                Text("Login View")
                    .font(.title)
                    .accessibilityLabel("Login screen")
            }
        }
    }
    
    private func loadUserProfile() {
        if let user = Auth.auth().currentUser {
            userEmail = user.email ?? "No email"
            print("Loaded user profile: \(userEmail)")
        } else {
            userEmail = "Not logged in"
            alertMessage = "No user is logged in"
            showAlert = true
            print("No user logged in")
        }
    }
    
    private func logout() {
        do {
            try Auth.auth().signOut()
            isLoggedOut = true
            print("User logged out successfully")
        } catch {
            alertMessage = "Failed to logout: \(error.localizedDescription)"
            showAlert = true
            print("Logout error: \(error.localizedDescription)")
        }
    }
}

// Reusable Button Component
struct DashboardButton: View {
    let title: String
    let icon: String
    var color: Color = .blue
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.white)
                .imageScale(.large)
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
            Spacer()
        }
        .padding()
        .background(color)
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}

// AddBookView for Adding New Books
struct AddBookView: View {
    @Environment(\.dismiss) var dismiss
    @State private var title: String = ""
    @State private var author: String = ""
    @State private var isbn: String = ""
    @State private var category: String = "Fantasy"
    @State private var publicationYear: String = ""
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    
    private let db = Firestore.firestore()
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Book Details")) {
                    TextField("Title", text: $title)
                        .accessibilityLabel("Book title")
                    TextField("Author", text: $author)
                        .accessibilityLabel("Book author")
                    TextField("ISBN (optional)", text: $isbn)
                        .accessibilityLabel("Book ISBN")
                    Picker("Category", selection: $category) {
                        Text("Fantasy").tag("Fantasy")
                        Text("Fiction").tag("Fiction")
                        Text("Dystopian").tag("Dystopian")
                        Text("Historical Fiction").tag("Historical Fiction")
                        Text("Romance").tag("Romance")
                    }
                    .accessibilityLabel("Select book category")
                    TextField("Publication Year (optional)", text: $publicationYear)
                        .keyboardType(.numberPad)
                        .accessibilityLabel("Publication year")
                }
            }
            .navigationTitle("Add New Book")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .accessibilityLabel("Cancel adding book")
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveBook()
                    }
                    .disabled(title.isEmpty || author.isEmpty)
                    .accessibilityLabel("Save book")
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Add Book"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }
    
    private func saveBook() {
        let bookId = UUID().uuidString
        let year = Int(publicationYear)
        
        let bookData: [String: Any] = [
            "title": title,
            "author": author,
            "isbn": isbn.isEmpty ? NSNull() : isbn,
            "category": category,
            "language": NSNull(),
            "publisher": NSNull(),
            "publicationYear": year ?? NSNull(),
            "shelfLocation": NSNull(),
            "status": "Active",
            "copies": 1,
            "available": true,
            "createdAt": Timestamp(date: Date())
        ]
        
        db.collection("books").document(bookId).setData(bookData) { error in
            if let error = error {
                alertMessage = "Failed to add book: \(error.localizedDescription)"
                showAlert = true
                print("Firestore add book error: \(error.localizedDescription)")
            } else {
                alertMessage = "Book '\(title)' added successfully"
                showAlert = true
                title = ""
                author = ""
                isbn = ""
                publicationYear = ""
                print("Book added: \(bookId)")
            }
        }
    }
}

// Placeholder for IssuedBooksView
struct IssuedBooksView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Issued Books")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.blue)
                    .padding()
                    .accessibilityLabel("Issued books")
                
                Text("List of issued books will appear here")
                    .font(.callout)
                    .foregroundColor(.gray)
                    .accessibilityLabel("Placeholder for issued books list")
                
                Spacer()
            }
            .navigationTitle("Issued Books")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    NavigationLink(destination: LibrarianDashboardView()) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.blue)
                            .imageScale(.large)
                    }
                    .accessibilityLabel("Back to dashboard")
                }
            }
        }
    }
}

struct LibrarianDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        LibrarianDashboardView()
    }
}
