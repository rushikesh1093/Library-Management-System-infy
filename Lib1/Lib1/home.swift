
import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import Combine

struct MainView: View {
    @State private var selectedTab: Tab = .home
    
    enum Tab: String {
        case home
        case booking
        case profile
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(Tab.home)
            
            BookingView()
                .tabItem {
                    Label("Booking", systemImage: "calendar")
                }
                .tag(Tab.booking)
            
            UserProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(Tab.profile)
        }
        .tint(.blue)
        .onAppear {
            if Auth.auth().currentUser == nil {
                print("No authenticated user found, redirecting to login")
            }
        }
    }
}

struct HomeView: View {
    @State private var userName: String = ""
    @State private var userRole: String = ""
    @State private var booksByCategory: [String: [Book]] = [:]
    @State private var recentlyBorrowed: [BorrowedBook] = []
    @State private var announcements: [Announcement] = []
    @State private var searchQuery: String = ""
    @State private var isLoading: Bool = true
    @State private var errorMessage: String = ""
    @State private var animateContent: Bool = false
    
    private let db = Firestore.firestore()
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
    
    struct Book: Identifiable, Equatable {
        let id: String
        let title: String
        let author: String
        let coverImage: String
        let category: String
        let description: String?
        let isbn: String?
        var likes: Int
        var isLiked: Bool
    }
    
    struct BorrowedBook: Identifiable, Equatable {
        let id: String
        let title: String
        let dueDate: Date?
    }
    
    struct Announcement: Identifiable {
        let id: String
        let title: String
        let content: String
        let date: Date
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "book.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 90, height: 90)
                            .foregroundStyle(.blue.gradient)
                            .opacity(animateContent ? 1 : 0)
                            .scaleEffect(animateContent ? 1 : 0.5)
                            .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.1), value: animateContent)
                            .accessibilityLabel("Library logo")
                        
                        Text("Welcome\(userName.isEmpty ? "" : ", \(userName)")!")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.blue.gradient)
                            .opacity(animateContent ? 1 : 0)
                            .offset(y: animateContent ? 0 : -20)
                            .animation(.easeOut(duration: 0.6).delay(0.2), value: animateContent)
                            .accessibilityLabel("Welcome message")
                    }
                    .padding(.top, 16)
                    
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.blue.opacity(0.7))
                            .frame(width: 20)
                        TextField("Search books...", text: $searchQuery, onCommit: {
                            print("Search query: \(searchQuery)")
                        })
                            .font(.body)
                            .padding(.vertical, 12)
                            .accessibilityLabel("Search books")
                    }
                    .padding(.horizontal, 16)
                    .background(.white)
                    .clipShape(.rect(cornerRadius: 12))
                    .shadow(color: .gray.opacity(0.1), radius: 4, x: 0, y: 2)
                    .padding(.horizontal)
                    .opacity(animateContent ? 1 : 0)
                    .animation(.easeOut(duration: 0.6).delay(0.3), value: animateContent)
                    
                    // Quick Actions
                    VStack(spacing: 16) {
                        Text("Quick Actions")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(.blue.gradient)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                            .accessibilityLabel("Quick Actions section")
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ActionButton(title: "Search Catalog", icon: "magnifyingglass", action: {
                                    print("Navigate to catalog search")
                                })
                                ActionButton(title: "My Books", icon: "books.vertical.fill", action: {
                                    print("Navigate to borrowed books")
                                })
                                if userRole == "Admin" || userRole == "Librarian" {
                                    ActionButton(title: "Manage Library", icon: "gearshape.fill", action: {
                                        print("Navigate to library management")
                                    })
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 20)
                    .animation(.easeOut(duration: 0.6).delay(0.4), value: animateContent)
                    
                    // Library Announcements
                    VStack(spacing: 16) {
                        Text("Library Announcements")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(.blue.gradient)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                            .accessibilityLabel("Library Announcements section")
                        
                        if announcements.isEmpty {
                            Text("No announcements at this time")
                                .foregroundStyle(.secondary)
                                .font(.subheadline)
                                .padding(.horizontal)
                                .accessibilityLabel("No announcements")
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(announcements) { announcement in
                                        AnnouncementCard(announcement: announcement, dateFormatter: dateFormatter)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 20)
                    .animation(.easeOut(duration: 0.6).delay(0.5), value: animateContent)
                    
                    // Books by Category
                    VStack(spacing: 16) {
                        Text("Browse by Category")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(.blue.gradient)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                            .accessibilityLabel("Browse by Category section")
                        
                        if isLoading {
                            ProgressView()
                                .padding()
                                .accessibilityLabel("Loading books")
                        } else if !errorMessage.isEmpty {
                            Text(errorMessage)
                                .foregroundStyle(.red)
                                .font(.caption)
                                .padding(.horizontal)
                                .accessibilityLabel("Error: \(errorMessage)")
                        } else if booksByCategory.isEmpty {
                            Text("No books available")
                                .foregroundStyle(.secondary)
                                .font(.subheadline)
                                .padding(.horizontal)
                                .accessibilityLabel("No books")
                        } else {
                            ForEach(booksByCategory.keys.sorted(), id: \.self) { category in
                                VStack(alignment: .leading, spacing: 12) {
                                    Text(category)
                                        .font(.headline)
                                        .fontWeight(.bold)
                                        .foregroundStyle(.blue.gradient)
                                        .padding(.horizontal)
                                        .accessibilityLabel("\(category) category")
                                    
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 12) {
                                            ForEach(booksByCategory[category] ?? []) { book in
                                                NavigationLink(destination: BookDetailView(book: book)) {
                                                    BookCard(book: book)
                                                }
                                            }
                                        }
                                        .padding(.horizontal)
                                    }
                                }
                            }
                        }
                    }
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 20)
                    .animation(.easeOut(duration: 0.6).delay(0.6), value: animateContent)
                    
                    // Recently Borrowed Books
                    VStack(spacing: 16) {
                        Text(userRole == "Member" ? "Recently Borrowed" : "Recent Transactions")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(.blue.gradient)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                            .accessibilityLabel(userRole == "Member" ? "Recently Borrowed section" : "Recent Transactions section")
                        
                        if recentlyBorrowed.isEmpty {
                            Text("No recent activity")
                                .foregroundStyle(.secondary)
                                .font(.subheadline)
                                .padding(.horizontal)
                                .accessibilityLabel("No recent activity")
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(recentlyBorrowed) { book in
                                        BorrowedBookCard(book: book, dateFormatter: dateFormatter)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 20)
                    .animation(.easeOut(duration: 0.6).delay(0.7), value: animateContent)
                    
                    // Category Highlights
                    VStack(spacing: 16) {
                        Text("Explore Categories")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(.blue.gradient)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                            .accessibilityLabel("Explore Categories section")
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                CategoryCard(title: "Fiction", icon: "book.closed.fill")
                                CategoryCard(title: "Non-Fiction", icon: "text.book.closed")
                                CategoryCard(title: "Academic", icon: "graduationcap.fill")
                                CategoryCard(title: "Children", icon: "teddybear.fill")
                            }
                            .padding(.horizontal)
                        }
                    }
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 20)
                    .animation(.easeOut(duration: 0.6).delay(0.8), value: animateContent)
                    
                    Spacer()
                }
                .padding(.vertical, 16)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.blue.opacity(0.03))
            .navigationTitle("Library")
            .onAppear {
                fetchUserData()
                fetchBooksByCategory()
                fetchAnnouncements()
                fetchRecentlyBorrowed()
                animateContent = false
                withAnimation {
                    animateContent = true
                }
            }
        }
    }
    
    private struct ActionButton: View {
        let title: String
        let icon: String
        let action: () -> Void
        
        var body: some View {
            Button(action: action) {
                VStack(spacing: 8) {
                    Image(systemName: icon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                        .foregroundStyle(.white)
                    Text(title)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .frame(width: 120)
                .background(.blue.gradient)
                .clipShape(.rect(cornerRadius: 12))
                .shadow(color: .blue.opacity(0.2), radius: 4, x: 0, y: 2)
            }
            .accessibilityLabel(title)
        }
    }
    
    private struct BookCard: View {
        let book: Book
        
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                AsyncImage(url: URL(string: book.coverImage)) { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 180)
                        .clipShape(.rect(cornerRadius: 10))
                        .shadow(color: .gray.opacity(0.2), radius: 4)
                } placeholder: {
                    Image(systemName: "book.fill")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 180)
                        .foregroundStyle(.blue.opacity(0.7))
                        .clipShape(.rect(cornerRadius: 10))
                }
                
                Text(book.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                
                Text(book.author)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    Image(systemName: book.isLiked ? "heart.fill" : "heart")
                        .foregroundStyle(book.isLiked ? .red : .gray)
                    Text("\(book.likes)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 120)
            .padding(12)
            .background(.white)
            .clipShape(.rect(cornerRadius: 12))
            .shadow(color: .gray.opacity(0.1), radius: 4, x: 0, y: 2)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Book: \(book.title) by \(book.author), \(book.likes) likes\(book.description != nil ? ", description: \(book.description!)" : "")")
        }
    }
    
    private struct AnnouncementCard: View {
        let announcement: Announcement
        let dateFormatter: DateFormatter
        
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                Text(announcement.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                
                Text(announcement.content)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                
                Text(dateFormatter.string(from: announcement.date))
                    .font(.caption2)
                    .foregroundStyle(.blue)
            }
            .frame(width: 200)
            .padding(12)
            .background(.white)
            .clipShape(.rect(cornerRadius: 12))
            .shadow(color: .gray.opacity(0.1), radius: 4, x: 0, y: 2)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Announcement: \(announcement.title), \(announcement.content), posted on \(dateFormatter.string(from: announcement.date))")
        }
    }
    
    private struct BorrowedBookCard: View {
        let book: BorrowedBook
        let dateFormatter: DateFormatter
        
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: "book.fill")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 150)
                    .foregroundStyle(.blue.opacity(0.7))
                    .clipShape(.rect(cornerRadius: 10))
                
                Text(book.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                
                if let dueDate = book.dueDate {
                    Text("Due: \(dateFormatter.string(from: dueDate))")
                        .font(.caption)
                        .foregroundStyle(Date() > dueDate ? .red : .secondary)
                }
            }
            .frame(width: 100)
            .padding(12)
            .background(.white)
            .clipShape(.rect(cornerRadius: 12))
            .shadow(color: .gray.opacity(0.1), radius: 4, x: 0, y: 2)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Borrowed book: \(book.title)\(book.dueDate != nil ? ", due on \(dateFormatter.string(from: book.dueDate!))" : "")")
        }
    }
    
    private struct CategoryCard: View {
        let title: String
        let icon: String
        
        var body: some View {
            Button(action: {
                print("Navigate to \(title) category")
            }) {
                VStack(spacing: 8) {
                    Image(systemName: icon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 36, height: 36)
                        .foregroundStyle(.blue)
                    Text(title)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .frame(width: 100)
                .background(.white)
                .clipShape(.rect(cornerRadius: 12))
                .shadow(color: .gray.opacity(0.1), radius: 4, x: 0, y: 2)
            }
            .accessibilityLabel("Category: \(title)")
        }
    }
    
    struct BookDetailView: View {
        let book: Book
        @State private var isLiked: Bool
        @State private var likes: Int
        @State private var showingShareSheet: Bool = false
        @State private var errorMessage: String = ""
        @Environment(\.dismiss) var dismiss
        
        private let db = Firestore.firestore()
        
        init(book: Book) {
            self.book = book
            _isLiked = State(initialValue: book.isLiked)
            _likes = State(initialValue: book.likes)
        }
        
        var body: some View {
            ScrollView {
                VStack(spacing: 24) {
                    AsyncImage(url: URL(string: book.coverImage)) { image in
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: 220, maxHeight: 330)
                            .clipShape(.rect(cornerRadius: 16))
                            .shadow(color: .gray.opacity(0.3), radius: 6)
                    } placeholder: {
                        Image(systemName: "book.fill")
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: 220, maxHeight: 330)
                            .foregroundStyle(.blue.opacity(0.7))
                            .clipShape(.rect(cornerRadius: 16))
                    }
                    .accessibilityLabel("Cover image for \(book.title)")
                    
                    VStack(spacing: 8) {
                        Text(book.title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.center)
                        
                        Text("by \(book.author)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Book: \(book.title) by \(book.author)")
                    
                    if let description = book.description {
                        Text(description)
                            .font(.body)
                            .foregroundStyle(.primary)
                            .padding(.horizontal)
                            .accessibilityLabel("Description: \(description)")
                    } else {
                        Text("No description available")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                            .accessibilityLabel("No description available")
                    }
                    
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .padding(.horizontal)
                            .accessibilityLabel("Error: \(errorMessage)")
                    }
                    
                    HStack(spacing: 16) {
                        Button(action: toggleLike) {
                            HStack(spacing: 4) {
                                Image(systemName: isLiked ? "heart.fill" : "heart")
                                    .foregroundStyle(isLiked ? .red : .gray)
                                Text("\(likes)")
                                    .font(.subheadline)
                                    .foregroundStyle(.primary)
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 16)
                            .background(.white)
                            .clipShape(.rect(cornerRadius: 10))
                            .shadow(color: .gray.opacity(0.1), radius: 3)
                        }
                        .accessibilityLabel(isLiked ? "Unlike book, \(likes) likes" : "Like book, \(likes) likes")
                        
                        Button(action: {
                            showingShareSheet = true
                        }) {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundStyle(.blue)
                                .padding(10)
                                .background(.white)
                                .clipShape(.rect(cornerRadius: 10))
                                .shadow(color: .gray.opacity(0.1), radius: 3)
                        }
                        .accessibilityLabel("Share book")
                        .sheet(isPresented: $showingShareSheet) {
                            ShareSheet(activityItems: ["Check out this book: \(book.title) by \(book.author)"])
                        }
                        
                        Button(action: reserveBook) {
                            Text("Reserve")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 16)
                                .background(.blue.gradient)
                                .clipShape(.rect(cornerRadius: 10))
                                .shadow(color: .blue.opacity(0.2), radius: 3)
                        }
                        .accessibilityLabel("Reserve book")
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
                .padding(.vertical, 24)
            }
            .frame(maxWidth: .infinity)
            .background(Color.blue.opacity(0.03))
            .navigationTitle(book.title)
            .navigationBarTitleDisplayMode(.inline)
        }
        
        private func toggleLike() {
            guard let user = Auth.auth().currentUser else {
                errorMessage = "Please log in to like this book"
                return
            }
            
            let userLikeRef = db.collection("users").document(user.uid).collection("likedBooks").document(book.id)
            let bookRef = db.collection("books").document(book.id)
            
            if isLiked {
                userLikeRef.delete { error in
                    if let error = error {
                        errorMessage = "Failed to unlike: \(error.localizedDescription)"
                        return
                    }
                    bookRef.updateData(["likes": FieldValue.increment(Int64(-1))]) { error in
                        if let error = error {
                            errorMessage = "Failed to update likes: \(error.localizedDescription)"
                            return
                        }
                        isLiked = false
                        likes -= 1
                    }
                }
            } else {
                userLikeRef.setData(["likedAt": Timestamp()]) { error in
                    if let error = error {
                        errorMessage = "Failed to like: \(error.localizedDescription)"
                        return
                    }
                    bookRef.updateData(["likes": FieldValue.increment(Int64(1))]) { error in
                        if let error = error {
                            errorMessage = "Failed to update likes: \(error.localizedDescription)"
                            return
                        }
                        isLiked = true
                        likes += 1
                    }
                }
            }
        }
        
        private func reserveBook() {
            guard let user = Auth.auth().currentUser else {
                errorMessage = "Please log in to reserve this book"
                return
            }
            
            let reservationRef = db.collection("reservations").document()
            let reservationData: [String: Any] = [
                "userId": user.uid,
                "bookId": book.id,
                "title": book.title,
                "author": book.author,
                "reservedAt": Timestamp(),
                "status": "pending"
            ]
            
            reservationRef.setData(reservationData) { error in
                if let error = error {
                    errorMessage = "Failed to reserve: \(error.localizedDescription)"
                    return
                }
                errorMessage = "Book reserved successfully!"
            }
        }
    }
    
    struct ShareSheet: UIViewControllerRepresentable {
        let activityItems: [Any]
        
        func makeUIViewController(context: Context) -> UIActivityViewController {
            let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
            return controller
        }
        
        func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
    }
    
    private func fetchUserData() {
        guard let user = Auth.auth().currentUser else {
            errorMessage = "No authenticated user found"
            isLoading = false
            print("No authenticated user")
            return
        }
        
        db.collection("users").document(user.uid).getDocument { (document, error) in
            if let error = error {
                errorMessage = "Failed to fetch user data: \(error.localizedDescription)"
                print("Firestore fetch error: \(error.localizedDescription)")
                return
            }
            
            if let document = document, document.exists {
                let data = document.data()
                userName = data?["name"] as? String ?? ""
                userRole = data?["role"] as? String ?? ""
                print("Fetched user data: name=\(userName), role=\(userRole)")
            }
        }
    }
    
    private func fetchBooksByCategory() {
        isLoading = true
        // Get unique categories
        db.collection("books")
            .getDocuments { (snapshot, error) in
                if let error = error {
                    errorMessage = "Failed to fetch books: \(error.localizedDescription)"
                    isLoading = false
                    print("Firestore books fetch error: \(error.localizedDescription)")
                    return
                }
                
                let categories = Set(snapshot?.documents.compactMap { $0.data()["category"] as? String } ?? []).filter { $0 != "Uncategorized" }
                var tempBooksByCategory: [String: [Book]] = [:]
                let dispatchGroup = DispatchGroup()
                
                // Fetch up to 5 books per category
                for category in categories {
                    dispatchGroup.enter()
                    db.collection("books")
                        .whereField("category", isEqualTo: category)
                        .limit(to: 5)
                        .getDocuments { (catSnapshot, catError) in
                            if let catError = catError {
                                print("Error fetching books for category \(category): \(catError.localizedDescription)")
                                dispatchGroup.leave()
                                return
                            }
                            
                            let books = catSnapshot?.documents.compactMap { doc -> Book? in
                                let data = doc.data()
                                guard let title = data["title"] as? String,
                                      let author = data["author"] as? String else {
                                    return nil
                                }
                                return Book(
                                    id: doc.documentID,
                                    title: title,
                                    author: author,
                                    coverImage: data["coverImage"] as? String ?? "",
                                    category: category,
                                    description: nil,
                                    isbn: data["isbn"] as? String,
                                    likes: data["likes"] as? Int ?? 0,
                                    isLiked: false
                                )
                            } ?? []
                            
                            if !books.isEmpty {
                                checkUserLikes(for: books) { booksWithLikes in
                                    enrichBooksWithOpenLibraryAPI(booksWithLikes) { enrichedBooks in
                                        tempBooksByCategory[category] = enrichedBooks
                                        dispatchGroup.leave()
                                    }
                                }
                            } else {
                                dispatchGroup.leave()
                            }
                        }
                }
                
                // Handle Uncategorized books separately
                dispatchGroup.enter()
                db.collection("books")
                    .whereField("category", isEqualTo: "Uncategorized")
                    .limit(to: 5)
                    .getDocuments { (uncatSnapshot, uncatError) in
                        if let uncatError = uncatError {
                            print("Error fetching uncategorized books: \(uncatError.localizedDescription)")
                            dispatchGroup.leave()
                            return
                        }
                        
                        let books = uncatSnapshot?.documents.compactMap { doc -> Book? in
                            let data = doc.data()
                            guard let title = data["title"] as? String,
                                  let author = data["author"] as? String else {
                                return nil
                            }
                            return Book(
                                id: doc.documentID,
                                title: title,
                                author: author,
                                coverImage: data["coverImage"] as? String ?? "",
                                category: "Uncategorized",
                                description: nil,
                                isbn: data["isbn"] as? String,
                                likes: data["likes"] as? Int ?? 0,
                                isLiked: false
                            )
                        } ?? []
                        
                        if !books.isEmpty {
                            checkUserLikes(for: books) { booksWithLikes in
                                enrichBooksWithOpenLibraryAPI(booksWithLikes) { enrichedBooks in
                                    tempBooksByCategory["Uncategorized"] = enrichedBooks
                                    dispatchGroup.leave()
                                }
                            }
                        } else {
                            dispatchGroup.leave()
                        }
                    }
                
                dispatchGroup.notify(queue: .main) {
                    booksByCategory = tempBooksByCategory
                    isLoading = false
                    print("Fetched books for \(booksByCategory.keys.count) categories")
                }
            }
    }
    
    private func checkUserLikes(for books: [Book], completion: @escaping ([Book]) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(books)
            return
        }
        
        db.collection("users").document(user.uid).collection("likedBooks").getDocuments { (snapshot, error) in
            if let error = error {
                print("Failed to fetch liked books: \(error.localizedDescription)")
                completion(books)
                return
            }
            
            let likedBookIds = snapshot?.documents.map { $0.documentID } ?? []
            let updatedBooks = books.map { book in
                Book(
                    id: book.id,
                    title: book.title,
                    author: book.author,
                    coverImage: book.coverImage,
                    category: book.category,
                    description: book.description,
                    isbn: book.isbn,
                    likes: book.likes,
                    isLiked: likedBookIds.contains(book.id)
                )
            }
            completion(updatedBooks)
        }
    }
    
    private func enrichBooksWithOpenLibraryAPI(_ books: [Book], completion: @escaping ([Book]) -> Void) {
        var enrichedBooks: [Book] = []
        let dispatchGroup = DispatchGroup()
        
        for book in books {
            dispatchGroup.enter()
            fetchOpenLibraryData(for: book) { updatedBook in
                enrichedBooks.append(updatedBook)
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            completion(enrichedBooks.sorted { $0.title < $1.title })
        }
    }
    
    private func fetchOpenLibraryData(for book: Book, completion: @escaping (Book) -> Void) {
        let query: String
        if let isbn = book.isbn, !isbn.isEmpty {
            query = isbn
        } else {
            query = "\(book.title) \(book.author)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        }
        
        let urlString = "https://openlibrary.org/search.json?q=\(query)"
        guard let url = URL(string: urlString) else {
            print("Invalid Open Library API URL for \(book.title)")
            completion(book)
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Open Library API error for \(book.title): \(error.localizedDescription)")
                completion(book)
                return
            }
            
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let docs = json["docs"] as? [[String: Any]],
                  let firstDoc = docs.first else {
                print("No Open Library data for \(book.title)")
                completion(book)
                return
            }
            
            let coverId = firstDoc["cover_i"] as? Int
            let coverImage = coverId != nil ? "https://covers.openlibrary.org/b/id/\(coverId!)-M.jpg" : book.coverImage
            
            let description = (firstDoc["first_sentence"] as? [String])?.joined(separator: " ") ?? ""
            
            let subjects = firstDoc["subject"] as? [String] ?? []
            let category = book.category != "Uncategorized" ? book.category : subjects.first?.capitalized ?? "Uncategorized"
            
            let updatedBook = Book(
                id: book.id,
                title: book.title,
                author: book.author,
                coverImage: coverImage,
                category: category,
                description: description.isEmpty ? nil : description,
                isbn: book.isbn,
                likes: book.likes,
                isLiked: book.isLiked
            )
            
            completion(updatedBook)
        }.resume()
    }
    
    private func fetchAnnouncements() {
        db.collection("announcements")
            .order(by: "date", descending: true)
            .limit(to: 5)
            .getDocuments { (snapshot, error) in
                if let error = error {
                    print("Firestore announcements fetch error: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("No announcements found in Firestore")
                    return
                }
                
                announcements = documents.compactMap { doc in
                    let data = doc.data()
                    guard let title = data["title"] as? String,
                          let content = data["content"] as? String,
                          let timestamp = data["date"] as? Timestamp else {
                        return nil
                    }
                    return Announcement(
                        id: doc.documentID,
                        title: title,
                        content: content,
                        date: timestamp.dateValue()
                    )
                }
                print("Fetched \(announcements.count) announcements")
            }
    }
    
    private func fetchRecentlyBorrowed() {
        guard let user = Auth.auth().currentUser else {
            print("No authenticated user for fetching borrowed books")
            return
        }
        
        let collectionPath = userRole == "Member" ? "users/\(user.uid)/borrowedBooks" : "transactions"
        let query = userRole == "Member" ?
            db.collection(collectionPath).limit(to: 5) :
            db.collection(collectionPath)
                .whereField("processedBy", isEqualTo: user.uid)
                .order(by: "borrowDate", descending: true)
                .limit(to: 5)
        
        query.getDocuments { (snapshot, error) in
            if let error = error {
                print("Firestore borrowed books fetch error: \(error.localizedDescription)")
                return
            }
            
            guard let documents = snapshot?.documents else {
                print("No borrowed books found in Firestore")
                return
            }
            
            recentlyBorrowed = documents.compactMap { doc in
                let data = doc.data()
                let title = data["title"] as? String ?? "Unknown Title"
                let dueDate = (data["dueDate"] as? Timestamp)?.dateValue()
                return BorrowedBook(id: doc.documentID, title: title, dueDate: dueDate)
            }
            print("Fetched \(recentlyBorrowed.count) recently borrowed books")
        }
    }
}

struct BookingView: View {
    var body: some View {
        VStack {
            Image(systemName: "calendar")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundStyle(.blue)
            Text("Book Your Resources")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(.blue)
                .padding()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.blue.opacity(0.03))
    }
}



#Preview {
    MainView()
}

