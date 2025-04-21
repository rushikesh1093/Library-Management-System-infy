
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
                    
                    NavigationLink {
                        MembersView()
                    } label: {
                        DashboardButton(title: "Members", icon: "person.2.fill")
                    }
                    .accessibilityLabel("View members")
                    
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

struct MembersView: View {
    @State private var members: [Member] = []
    @State private var isLoading: Bool = true
    @State private var errorMessage: String = ""
    @State private var searchText: String = ""
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var showRevokeConfirmation: Bool = false
    @State private var showExtendConfirmation: Bool = false
    @State private var memberToRevoke: Member? = nil
    @State private var memberToExtend: Member? = nil
    @State private var isUpdating: Bool = false
    
    private let db = Firestore.firestore()
    
    struct Member: Identifiable {
        let id: String
        let memberId: String
        let name: String
        let joinedDate: Date
        var expiryDate: Date
        let borrowedBooks: [BorrowedBook]
        var status: String
    }
    
    struct BorrowedBook {
        let bookId: String
        let title: String
        let author: String
    }
    
    var filteredMembers: [Member] {
        if searchText.isEmpty {
            return members
        } else {
            return members.filter { member in
                member.name.lowercased().contains(searchText.lowercased()) ||
                member.memberId.lowercased().contains(searchText.lowercased())
            }
        }
    }
    
    var body: some View {
        NavigationView {
            mainContent
                .navigationTitle("Members")
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
    
    private var mainContent: some View {
        VStack {
            contentView
                .searchable(text: $searchText, prompt: "Search by name or member ID")
                .accessibilityLabel("Search members")
                .disabled(isUpdating)
                .overlay {
                    if isUpdating {
                        updatingOverlay
                    }
                }
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Membership Update"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .alert("Confirm Extension", isPresented: $showExtendConfirmation, presenting: memberToExtend) { member in
            Button("Extend") {
                extendMembership(for: member)
            }
            Button("Cancel", role: .cancel) {}
        } message: { member in
            Text("Extend membership for \(member.name) by one year?")
        }
        .alert("Confirm Revocation", isPresented: $showRevokeConfirmation, presenting: memberToRevoke) { member in
            Button("Revoke", role: .destructive) {
                revokeMembership(for: member)
            }
            Button("Cancel", role: .cancel) {}
        } message: { member in
            Text("Are you sure you want to revoke membership for \(member.name)?")
        }
        .onAppear {
            fetchMembers()
        }
    }
    
    private var contentView: some View {
        Group {
            if isLoading {
                loadingView
            } else if !errorMessage.isEmpty {
                errorView
            } else if filteredMembers.isEmpty {
                emptyView
            } else {
                listView
            }
        }
    }
    
    private var loadingView: some View {
        ProgressView()
            .padding()
            .accessibilityLabel("Loading members")
    }
    
    private var errorView: some View {
        VStack {
            Text(errorMessage)
                .foregroundStyle(.red)
                .font(.caption)
                .padding()
                .accessibilityLabel("Error: \(errorMessage)")
            Button("Retry") {
                fetchMembers()
            }
            .padding()
            .background(.blue)
            .foregroundStyle(.white)
            .clipShape(.rect(cornerRadius: 8))
            .accessibilityLabel("Retry fetching members")
        }
    }
    
    private var emptyView: some View {
        Text(searchText.isEmpty ? "No members found" : "No matching members")
            .foregroundStyle(.secondary)
            .font(.subheadline)
            .padding()
            .accessibilityLabel(searchText.isEmpty ? "No members" : "No matching members")
    }
    
    private var listView: some View {
        List {
            ForEach(filteredMembers) { member in
                MemberCard(
                    member: member,
                    onExtend: {
                        print("Extend button tapped for \(member.name)")
                        memberToExtend = member
                        showExtendConfirmation = true
                    },
                    onRevoke: {
                        print("Revoke button tapped for \(member.name)")
                        memberToRevoke = member
                        showRevokeConfirmation = true
                    }
                )
            }
        }
        .listStyle(.plain)
    }
    
    private var updatingOverlay: some View {
        ProgressView("Updating...")
            .padding()
            .background(.white.opacity(0.8))
            .clipShape(.rect(cornerRadius: 10))
    }
    
    private struct MemberCard: View {
        let member: Member
        let onExtend: () -> Void
        let onRevoke: () -> Void
        
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "person.fill")
                        .foregroundStyle(.blue.opacity(0.7))
                        .imageScale(.large)
                    Text(member.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                }
                
                Text("Member ID: \(member.memberId)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text("Status: \(member.status.capitalized)")
                    .font(.caption)
                    .foregroundStyle(member.status == "active" ? .green : .red)
                
                Text("Joined: \(member.joinedDate, formatter: dateFormatter)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text("Expires: \(member.expiryDate, formatter: dateFormatter)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                borrowedBooksView
                buttonsView
            }
            .padding()
            .background(.white)
            .clipShape(.rect(cornerRadius: 12))
            .shadow(color: .gray.opacity(0.1), radius: 4)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(memberAccessibilityLabel)
        }
        
        private var borrowedBooksView: some View {
            Group {
                if member.borrowedBooks.isEmpty {
                    Text("No books borrowed")
                        .font(.caption)
                        .foregroundStyle(.gray)
                } else {
                    VStack(alignment: .leading) {
                        Text("Borrowed Books:")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.blue)
                        ForEach(member.borrowedBooks, id: \.bookId) { book in
                            Text("• \(book.title) by \(book.author)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        
        private var buttonsView: some View {
            HStack(spacing: 12) {
                Button(action: onExtend) {
                    Text("Extend Membership")
                        .font(.caption)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(.green.opacity(0.1))
                        .foregroundStyle(.green)
                        .clipShape(.rect(cornerRadius: 8))
                }
                .accessibilityLabel("Extend membership for \(member.name)")
                .disabled(member.status != "active")
                
                Button(action: onRevoke) {
                    Text("Revoke Membership")
                        .font(.caption)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(.red.opacity(0.1))
                        .foregroundStyle(.red)
                        .clipShape(.rect(cornerRadius: 8))
                }
                .accessibilityLabel("Revoke membership for \(member.name)")
                .disabled(member.status != "active")
            }
            .padding(.top, 4)
        }
        
        private var memberAccessibilityLabel: String {
            """
            Member: \(member.name), Member ID: \(member.memberId), Status: \(member.status.capitalized),
            Joined: \(member.joinedDate),
            Expires: \(member.expiryDate),
            Borrowed books: \(member.borrowedBooks.isEmpty ? "None" : member.borrowedBooks.map { "\($0.title) by \($0.author)" }.joined(separator: ", "))
            """
        }
        
        private let dateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter
        }()
    }
    
    private func fetchMembers() {
        guard let user = Auth.auth().currentUser else {
            errorMessage = "Please log in to view members"
            isLoading = false
            print("No authenticated user found")
            return
        }
        print("Authenticated user: \(user.uid) \(user.email ?? "No email")")
        
        db.collection("users").document(user.uid).getDocument { (document, error) in
            if let error = error {
                self.errorMessage = "Failed to fetch user role: \(error.localizedDescription)"
                self.isLoading = false
                print("Error fetching user document: \(error.localizedDescription)")
                return
            }
            
            guard let document = document, document.exists,
                  let data = document.data(),
                  let role = data["role"] as? String,
                  (role == "Librarian" || role == "Admin") else {
                self.errorMessage = "You do not have permission to view members"
                self.isLoading = false
                print("User does not have Librarian or Admin role")
                return
            }
            
            print("User role: \(role)")
            
            self.isLoading = true
            self.errorMessage = ""
            print("Fetching members from Firestore collection: users")
            
            db.collection("users").whereField("role", isEqualTo: "Member").addSnapshotListener { (snapshot, error) in
                if let error = error {
                    let userMessage = error.localizedDescription.contains("permission") ?
                        "Permission denied. Contact support." : "Failed to fetch members. Try again."
                    self.errorMessage = userMessage
                    self.isLoading = false
                    print("Firestore fetch error: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    self.errorMessage = "No members found in users collection"
                    self.isLoading = false
                    print("No documents found in Firestore users collection")
                    return
                }
                
                print("Found \(documents.count) documents in users collection")
                
                var tempMembers: [Member] = []
                let dispatchGroup = DispatchGroup()
                
                for doc in documents {
                    let data = doc.data()
                    print("Document \(doc.documentID): \(data)")
                    
                    guard let name = data["name"] as? String else {
                        print("Skipping document \(doc.documentID): missing required field (name)")
                        continue
                    }
                    
                    let joinedDate = (data["joinedDate"] as? Timestamp)?.dateValue() ?? Date()
                    let expiryDate = (data["expiryDate"] as? Timestamp)?.dateValue() ?? Date()
                    let status = (data["status"] as? String) ?? "active"
                    let memberId = "M\(doc.documentID.prefix(8))"
                    
                    var borrowedBooks: [BorrowedBook] = []
                    dispatchGroup.enter()
                    db.collection("issuedBooks")
                        .whereField("userId", isEqualTo: doc.documentID)
                        .whereField("status", isEqualTo: "issued")
                        .getDocuments { (issueSnapshot, issueError) in
                            defer { dispatchGroup.leave() }
                            
                            if let issueError = issueError {
                                print("Failed to fetch issued books for user \(doc.documentID): \(issueError.localizedDescription)")
                            } else if let issueDocs = issueSnapshot?.documents {
                                print("Found \(issueDocs.count) issued books for user \(doc.documentID)")
                                for issueDoc in issueDocs {
                                    let issueData = issueDoc.data()
                                    if let bookId = issueData["bookId"] as? String,
                                       let title = issueData["title"] as? String,
                                       let author = issueData["author"] as? String {
                                        borrowedBooks.append(BorrowedBook(bookId: bookId, title: title, author: author))
                                    } else {
                                        print("Invalid issued book data for user \(doc.documentID): \(issueData)")
                                    }
                                }
                            }
                            
                            tempMembers.append(Member(
                                id: doc.documentID,
                                memberId: memberId,
                                name: name,
                                joinedDate: joinedDate,
                                expiryDate: expiryDate,
                                borrowedBooks: borrowedBooks,
                                status: status
                            ))
                        }
                }
                
                dispatchGroup.notify(queue: .main) {
                    self.members = tempMembers.sorted { $0.name.lowercased() < $1.name.lowercased() }
                    self.isLoading = false
                    print("Mapped \(self.members.count) valid members")
                    
                    if self.members.isEmpty {
                        self.errorMessage = "No valid members found. Ensure member documents have a 'name' field."
                        print("No valid members after mapping")
                    }
                }
            }
        }
    }
    
    private func extendMembership(for member: Member) {
        print("Attempting to extend membership for \(member.name) (ID: \(member.id), Status: \(member.status))")
        isUpdating = true
        
        guard member.status == "active" else {
            alertMessage = "Cannot extend membership. \(member.name)'s membership is \(member.status)."
            showAlert = true
            isUpdating = false
            print("Extension blocked: \(member.name) is not active")
            return
        }
        
        guard let index = members.firstIndex(where: { $0.id == member.id }) else {
            alertMessage = "Member not found"
            showAlert = true
            isUpdating = false
            print("Member not found: \(member.name)")
            return
        }
        
        guard let newExpiryDate = Calendar.current.date(byAdding: .year, value: 1, to: member.expiryDate) else {
            alertMessage = "Failed to calculate new expiry date"
            showAlert = true
            isUpdating = false
            print("Failed to calculate new expiry date for \(member.name)")
            return
        }
        
        db.collection("users").document(member.id).updateData([
            "expiryDate": Timestamp(date: newExpiryDate)
        ]) { error in
            defer { self.isUpdating = false }
            if let error = error {
                let userMessage = error.localizedDescription.contains("permission") ?
                    "Permission denied. Contact support." : "Failed to extend membership. Try again."
                self.alertMessage = userMessage
                self.showAlert = true
                print("Failed to extend membership for \(member.name): \(error.localizedDescription)")
            } else {
                var updatedMember = member
                updatedMember.expiryDate = newExpiryDate
                self.members[index] = updatedMember
                self.alertMessage = "Membership extended for \(member.name) until \(self.dateFormatter.string(from: newExpiryDate))"
                self.showAlert = true
                print("Extended membership for \(member.name) to \(newExpiryDate)")
            }
        }
    }
    
    private func revokeMembership(for member: Member) {
        print("Attempting to revoke membership for \(member.name) (ID: \(member.id), Status: \(member.status))")
        isUpdating = true
        
        guard member.status == "active" else {
            alertMessage = "Cannot revoke membership. \(member.name)'s membership is already \(member.status)."
            showAlert = true
            isUpdating = false
            print("Revocation blocked: \(member.name) is not active")
            return
        }
        
        guard let index = members.firstIndex(where: { $0.id == member.id }) else {
            alertMessage = "Member not found"
            showAlert = true
            isUpdating = false
            print("Member not found: \(member.name)")
            return
        }
        
        if !member.borrowedBooks.isEmpty {
            alertMessage = "Cannot revoke membership. \(member.name) has \(member.borrowedBooks.count) borrowed book(s)."
            showAlert = true
            isUpdating = false
            print("Revocation blocked: \(member.name) has borrowed books")
            return
        }
        
        let currentDate = Date()
        
        db.collection("users").document(member.id).updateData([
            "expiryDate": Timestamp(date: currentDate),
            "status": "inactive"
        ]) { error in
            defer { self.isUpdating = false }
            if let error = error {
                let userMessage = error.localizedDescription.contains("permission") ?
                    "Permission denied. Contact support." : "Failed to revoke membership. Try again."
                self.alertMessage = userMessage
                self.showAlert = true
                print("Failed to revoke membership for \(member.name): \(error.localizedDescription)")
            } else {
                var updatedMember = member
                updatedMember.expiryDate = currentDate
                updatedMember.status = "inactive"
                self.members[index] = updatedMember
                self.alertMessage = "Membership revoked for \(member.name)"
                self.showAlert = true
                print("Revoked membership for \(member.name)")
            }
        }
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
}

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

