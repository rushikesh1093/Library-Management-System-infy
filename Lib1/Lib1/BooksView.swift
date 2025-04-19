import SwiftUI

class LibraryModel: ObservableObject {
    @Published var books: [Book] {
        didSet {
            saveBooks()
        }
    }
    
    init() {
        // Initialize books with an empty array or load from UserDefaults
        if let savedBooks = LibraryModel.loadBooks() {
            self.books = savedBooks
        } else {
            self.books = Book.loadBooksFromCSV()
        }
    }
    
    func updateCopies(for bookId: Int, newCopies: Int) {
        if let index = books.firstIndex(where: { $0.bookId == bookId }) {
            books[index].copies = newCopies
            books[index].isAvailable = newCopies > 0
        }
    }
    
    func updateReservationStatus(for bookId: Int, newStatus: Book.ReservationStatus) {
        if let index = books.firstIndex(where: { $0.bookId == bookId }) {
            books[index].reservationStatus = newStatus
        }
    }
    
    func updateWishlistStatus(for bookId: Int, isWishlisted: Bool) {
        if let index = books.firstIndex(where: { $0.bookId == bookId }) {
            books[index].isWishlisted = isWishlisted
        }
    }
    
    private func saveBooks() {
        do {
            let data = try JSONEncoder().encode(books)
            UserDefaults.standard.set(data, forKey: "savedBooks")
        } catch {
            print("Error saving books: \(error)")
        }
    }
    
    private static func loadBooks() -> [Book]? {
        guard let data = UserDefaults.standard.data(forKey: "savedBooks") else { return nil }
        do {
            let books = try JSONDecoder().decode([Book].self, from: data)
            return books
        } catch {
            print("Error loading books: \(error)")
            return nil
        }
    }
}

struct BooksView: View {
    @ObservedObject var libraryModel: LibraryModel // Change to @ObservedObject
    @State private var searchText: String = ""
    @State private var sortOption: SortOption = .titleAsc
    
    enum SortOption: String, CaseIterable, Identifiable {
        case titleAsc = "Title (A-Z)"
        case titleDesc = "Title (Z-A)"
        case authorAsc = "Author (A-Z)"
        case authorDesc = "Author (Z-A)"
        case yearAsc = "Year (Oldest First)"
        case yearDesc = "Year (Newest First)"
        
        var id: String { rawValue }
    }
    
    private var filteredAndSortedBooks: [Book] {
        var filteredBooks = libraryModel.books
        
        if !searchText.isEmpty {
            filteredBooks = filteredBooks.filter { book in
                book.title.lowercased().contains(searchText.lowercased()) ||
                book.author.lowercased().contains(searchText.lowercased())
            }
        }
        
        switch sortOption {
        case .titleAsc:
            return filteredBooks.sorted { $0.title.lowercased() < $1.title.lowercased() }
        case .titleDesc:
            return filteredBooks.sorted { $0.title.lowercased() > $1.title.lowercased() }
        case .authorAsc:
            return filteredBooks.sorted { $0.author.lowercased() < $1.author.lowercased() }
        case .authorDesc:
            return filteredBooks.sorted { $0.author.lowercased() > $1.author.lowercased() }
        case .yearAsc:
            return filteredBooks.sorted { $0.publishedYear < $1.publishedYear }
        case .yearDesc:
            return filteredBooks.sorted { $0.publishedYear > $1.publishedYear }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
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
                }
                
                if filteredAndSortedBooks.isEmpty {
                    Text(searchText.isEmpty ? "No books available." : "No books match your search.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding()
                } else {
                    List {
                        ForEach(filteredAndSortedBooks) { book in
                            NavigationLink(destination: BookDetailView(book: book, libraryModel: libraryModel)) {
                                BookRowView(book: book)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.blue.opacity(0.05))
            .navigationTitle("Books")
            .searchable(text: $searchText, prompt: "Search by title or author")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Picker("Sort By", selection: $sortOption) {
                            ForEach(SortOption.allCases) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                            .foregroundStyle(.blue)
                    }
                }
            }
        }
    }
}

// Subview for individual book row
struct BookRowView: View {
    let book: Book
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Book icon
            Image(systemName: "book.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .foregroundStyle(.blue)
            
            // Book details
            VStack(alignment: .leading, spacing: 4) {
                Text(book.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                Text(book.author)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Availability badge
            Text(book.isAvailable ? "Available" : "Checked Out")
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(book.isAvailable ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                .cornerRadius(8)
        }
        .padding(.vertical, 4)
    }
}

// Subview for book details
struct BookDetailView: View {
    let book: Book
    @ObservedObject var libraryModel: LibraryModel
    @State private var showReserveAlert: Bool = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Book Image (Placeholder)
                Image(systemName: "book.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 200)
                    .foregroundStyle(.blue)
                    .padding()
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .shadow(radius: 5)
                
                // Book Details
                VStack(alignment: .leading, spacing: 8) {
                    Text(book.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                    
                    Text(book.author)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                    
                    Text("Copies Available: \(book.copies)")
                        .font(.body)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                    
                    Text("Shelf Location: \(book.shelfLocation)")
                        .font(.body)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }
                
                // Action Buttons
                VStack(spacing: 12) {
                    // Wishlist and Share Buttons (Side by Side)
                    HStack(spacing: 20) {
                        // Wishlist Button
                        Button(action: {
                            libraryModel.updateWishlistStatus(for: book.bookId, isWishlisted: !book.isWishlisted)
                        }) {
                            Image(systemName: book.isWishlisted ? "heart.fill" : "heart")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                                .padding()
                                .background(book.isWishlisted ? Color.red.opacity(0.1) : Color.blue.opacity(0.1))
                                .foregroundStyle(book.isWishlisted ? .red : .blue)
                                .clipShape(Circle())
                        }
                        .accessibilityLabel(book.isWishlisted ? "Remove from Wishlist" : "Add to Wishlist")
                        
                        // Share Button
                        Button(action: {
                            shareBook()
                        }) {
                            Image(systemName: "square.and.arrow.up")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .foregroundStyle(.blue)
                                .clipShape(Circle())
                        }
                        .accessibilityLabel("Share Book")
                    }
                    
                    // Reserve Button
                    Button(action: {
                        if book.reservationStatus == .notReserved {
                            libraryModel.updateReservationStatus(for: book.bookId, newStatus: .pending)
                            libraryModel.updateCopies(for: book.bookId, newCopies: max(0, book.copies - 1))
                            showReserveAlert = true
                        }
                    }) {
                        Label(book.reservationStatus.rawValue, systemImage: "book.circle")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(buttonBackgroundColor)
                            .foregroundStyle(buttonForegroundColor)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .disabled(!book.isAvailable || book.reservationStatus != .notReserved)
                    .alert("Reservation Status", isPresented: $showReserveAlert) {
                        Button("OK", role: .cancel) { }
                    } message: {
                        Text("Your reservation request for \(book.title) is pending. You will be notified when approved.")
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.blue.opacity(0.05))
        .navigationTitle(book.title)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // Computed properties for reserve button styling
    private var buttonBackgroundColor: Color {
        switch book.reservationStatus {
        case .notReserved:
            return book.isAvailable ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1)
        case .pending:
            return Color.yellow.opacity(0.1)
        case .approved:
            return Color.green.opacity(0.1)
        }
    }
    
    private var buttonForegroundColor: Color {
        switch book.reservationStatus {
        case .notReserved:
            return book.isAvailable ? .blue : .gray
        case .pending:
            return .yellow
        case .approved:
            return .green
        }
    }
    
    // Share book details
    private func shareBook() {
        let shareText = "\(book.title) by \(book.author)\nISBN: \(book.isbn)\nAvailable Copies: \(book.copies)\nShelf: \(book.shelfLocation)"
        let activityController = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)
        
        // Present the share sheet
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            activityController.popoverPresentationController?.sourceView = rootViewController.view
            rootViewController.present(activityController, animated: true, completion: nil)
        }
    }
}

struct BooksView_Previews: PreviewProvider {
    static var previews: some View {
        BooksView(libraryModel: LibraryModel())
    }
}
