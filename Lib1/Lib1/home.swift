import SwiftUI

struct MainView: View {
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
            
            BookingView()
                .tabItem {
                    Label("Booking", systemImage: "calendar")
                }
                .tag(Tab.booking)
            
            BooksView()
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
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Home Header
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
                    
                    // Recent Newsletter
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
                    
                    // Borrowed Books
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Borrowed Books")
                            .font(.headline)
                            .foregroundStyle(.blue)
                        if Book.sampleBorrowedBooks.isEmpty {
                            Text("No books borrowed.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .padding()
                        } else {
                            ForEach(Book.sampleBorrowedBooks) { book in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(book.title)
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                        Text(book.author)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    if let dueDate = book.dueDate {
                                        Text("Due: \(dueDate, format: .dateTime.day().month())")
                                            .font(.caption)
                                            .foregroundStyle(.red)
                                    }
                                }
                                .padding()
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .shadow(radius: 2)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Upcoming Books
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Upcoming Books")
                            .font(.headline)
                            .foregroundStyle(.blue)
                        if Book.sampleUpcomingBooks.isEmpty {
                            Text("No upcoming books.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .padding()
                        } else {
                            ForEach(Book.sampleUpcomingBooks) { book in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(book.title)
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                        Text(book.author)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    if let releaseDate = book.releaseDate {
                                        Text("Releases: \(releaseDate, format: .dateTime.day().month())")
                                            .font(.caption)
                                            .foregroundStyle(.blue)
                                    }
                                }
                                .padding()
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .shadow(radius: 2)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Deadline to Handover Books
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Deadline to Handover Books")
                            .font(.headline)
                            .foregroundStyle(.blue)
                        if Book.sampleBorrowedBooks.isEmpty {
                            Text("No books due.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .padding()
                        } else {
                            ForEach(Book.sampleBorrowedBooks.filter { $0.dueDate != nil && $0.dueDate! < Date().addingTimeInterval(86400 * 7) }) { book in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(book.title)
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                        Text(book.author)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    if let dueDate = book.dueDate {
                                        Text("Due: \(dueDate, format: .dateTime.day().month())")
                                            .font(.caption)
                                            .foregroundStyle(.red)
                                    }
                                }
                                .padding()
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .shadow(radius: 2)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
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

struct BookingView: View {
    var body: some View {
        VStack {
            Image(systemName: "calendar")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundStyle(.blue)
            Text("Booking")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(.blue)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.blue.opacity(0.05))
        .navigationTitle("Booking")
    }
}

struct BooksView: View {
    var body: some View {
        VStack {
            Image(systemName: "book.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundStyle(.blue)
            Text("Books")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(.blue)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.blue.opacity(0.05))
        .navigationTitle("Books")
    }
}



#Preview {
    MainView()
}
