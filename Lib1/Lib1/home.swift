import SwiftUI

struct MainView: View {
    @StateObject private var libraryModel = LibraryModel() // Single source of truth
    @State private var selectedTab: Tab = .home
    
    enum Tab: String {
        case home
        case booking
        case books
        case profile
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(Tab.home)
            
            BookingView(libraryModel: libraryModel) // Pass libraryModel
                .tabItem {
                    Label("Booking", systemImage: "calendar")
                }
                .tag(Tab.booking)
            
            BooksView(libraryModel: libraryModel) // Pass libraryModel
               

 .tabItem {
                    Label("Books", systemImage: "book.fill")
                }
                .tag(Tab.books)
            
            UserProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(Tab.profile)
        }
        .tint(.blue)
    }
}

struct HomeView: View {
    // Load books from CSV
    private let books: [Book] = Book.loadBooksFromCSV()
    // State for login status (placeholder, assuming login logic exists elsewhere)
    @State private var isLoggedIn: Bool = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Home Header
                    HomeHeaderView()
                    
                    // Recent Newsletter
                    NewsletterView()
                    
                    // Borrowed Books
                    BorrowedBooksView(isLoggedIn: isLoggedIn)
                    
                    // Upcoming Books
                    UpcomingBooksView(isLoggedIn: isLoggedIn)
                    
                    Spacer()
                }
                .padding(.vertical)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.blue.opacity(0.05))
            .navigationTitle("Home")
        }
    }
}

// Subview for the header
struct HomeHeaderView: View {
    var body: some View {
        VStack {
            Image(systemName: "house.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundStyle(.blue)
            Text("Home")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(.blue)
        }
    }
}

// Subview for the newsletter
struct NewsletterView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent Newsletter")
                .font(.headline)
                .foregroundStyle(.blue)
            VStack(alignment: .leading, spacing: 4) {
                Text(Announcement.sampleNewsletter.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(Announcement.sampleNewsletter.content)
                    .font(.body)
                    .foregroundStyle(.secondary)
                Text("Posted: \(Announcement.sampleNewsletter.date, format: .dateTime.day().month().year())")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .shadow(radius: 2)
        }
        .padding(.horizontal)
    }
}

// Subview for borrowed books
struct BorrowedBooksView: View {
    let isLoggedIn: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Borrowed Books")
                .font(.headline)
                .foregroundStyle(.blue)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    let borrowedBooks = Book.borrowedBooks(isLoggedIn: isLoggedIn)
                    if borrowedBooks.isEmpty {
                        Text("No books borrowed.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(borrowedBooks.sorted {
                            ($0.dueDate ?? Date.distantFuture) < ($1.dueDate ?? Date.distantFuture)
                        }) { book in
                            BookCardView(book: book, isUpcoming: false)
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
    }
}

// Subview for upcoming books
struct UpcomingBooksView: View {
    let isLoggedIn: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Upcoming Books")
                .font(.headline)
                .foregroundStyle(.blue)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    let upcomingBooks = Book.upcomingBooks(isLoggedIn: isLoggedIn)
                    if upcomingBooks.isEmpty {
                        Text("No upcoming books.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(upcomingBooks.sorted {
                            ($0.releaseDate ?? Date.distantFuture) < ($1.releaseDate ?? Date.distantFuture)
                        }) { book in
                            BookCardView(book: book, isUpcoming: true)
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
    }
}

// Reusable subview for book card
struct BookCardView: View {
    let book: Book
    let isUpcoming: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "book.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)
                .foregroundStyle(.blue)
            Text(book.title)
                .font(.caption)
                .fontWeight(.semibold)
                .lineLimit(1)
            Text(book.author)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            if isUpcoming, let release = book.releaseDate {
                Text("Releases: \(release, format: .dateTime.day().month())")
                    .font(.caption2)
                    .foregroundStyle(.blue)
            } else if let due = book.dueDate {
                Text("Due: \(due, format: .dateTime.day().month())")
                    .font(.caption2)
                    .foregroundStyle(.red)
            }
        }
        .frame(width: 110)
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(radius: 2)
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
