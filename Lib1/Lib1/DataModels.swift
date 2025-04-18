import Foundation

struct Announcement: Identifiable, Codable {
    let id: UUID
    let title: String
    let content: String
    let date: Date
    
    init(id: UUID = UUID(), title: String, content: String, date: Date) {
        self.id = id
        self.title = title
        self.content = content
        self.date = date
    }
    
    // Sample data for newsletter
    static let sampleNewsletter = Announcement(
        title: "April Library Update",
        content: "Join us for our Spring Book Fair on May 10th! New arrivals in fiction and non-fiction are now available.",
        date: Date().addingTimeInterval(-86400 * 2) // 2 days ago
    )
}



// Book struct with mutable copies and isAvailable
struct Book: Identifiable, Codable {
    let id: UUID
    let bookId: Int
    let title: String
    let author: String
    let isbn: String
    let category: String
    let language: String
    let publisher: String
    let publishedYear: Int
    let shelfLocation: String
    var isAvailable: Bool // Changed from let to var
    let status: String
    var copies: Int // Changed from let to var
    let dueDate: Date?
    let releaseDate: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case bookId = "book_id"
        case title
        case author
        case isbn
        case category
        case language
        case publisher
        case publishedYear = "published_year"
        case shelfLocation = "shelf_location"
        case isAvailable = "is_available"
        case status
        case copies
        case dueDate
        case releaseDate
    }
    
    init(
        id: UUID = UUID(),
        bookId: Int,
        title: String,
        author: String,
        isbn: String,
        category: String,
        language: String,
        publisher: String,
        publishedYear: Int,
        shelfLocation: String,
        isAvailable: Bool,
        status: String,
        copies: Int,
        dueDate: Date? = nil,
        releaseDate: Date? = nil
    ) {
        self.id = id
        self.bookId = bookId
        self.title = title
        self.author = author
        self.isbn = isbn
        self.category = category
        self.language = language
        self.publisher = publisher
        self.publishedYear = publishedYear
        self.shelfLocation = shelfLocation
        self.isAvailable = isAvailable
        self.status = status
        self.copies = copies
        self.dueDate = dueDate
        self.releaseDate = releaseDate
    }
    
    // Return empty arrays for borrowed and upcoming books unless user is logged in
    static func borrowedBooks(isLoggedIn: Bool) -> [Book] {
        return isLoggedIn ? [] : []
    }

    static func upcomingBooks(isLoggedIn: Bool) -> [Book] {
        return isLoggedIn ? [] : []
    }

    
    static func loadBooksFromCSV() -> [Book] {
        let fileName = "updated_books_dataset"
        guard let filePath = Bundle.main.path(forResource: fileName, ofType: "csv") else {
            print("Error: Could not find \(fileName).csv in the app bundle")
            return []
        }
        
        do {
            let csvString = try String(contentsOfFile: filePath, encoding: .utf8)
            return parseCSV(csvString)
        } catch {
            print("Error reading CSV file: \(error)")
            return []
        }
    }
    
    static func parseCSV(_ csvString: String) -> [Book] {
        var books: [Book] = []
        let rows = csvString.components(separatedBy: "\n")
        guard rows.count > 1 else { return books }
        
        let headers = rows[0].components(separatedBy: ",")
        for row in rows.dropFirst() {
            let values = row.components(separatedBy: ",")
            guard values.count == headers.count else { continue }
            
            var bookData: [String: String] = [:]
            for (index, header) in headers.enumerated() {
                bookData[header] = values[index]
            }
            
            guard
                let bookIdString = bookData["book_id"],
                let bookId = Int(bookIdString),
                let title = bookData["title"],
                let author = bookData["author"],
                let isbn = bookData["isbn"],
                let category = bookData["category"],
                let language = bookData["language"],
                let publisher = bookData["publisher"],
                let publishedYearString = bookData["published_year"],
                let publishedYear = Int(publishedYearString),
                let shelfLocation = bookData["shelf_location"],
                let isAvailableString = bookData["is_available"],
                let status = bookData["status"],
                let copiesString = bookData["copies"],
                let copies = Int(copiesString)
            else { continue }
            
            let isAvailable = isAvailableString.lowercased() == "yes"
            
            let book = Book(
                bookId: bookId,
                title: title,
                author: author,
                isbn: isbn,
                category: category,
                language: language,
                publisher: publisher,
                publishedYear: publishedYear,
                shelfLocation: shelfLocation,
                isAvailable: isAvailable,
                status: status,
                copies: copies
            )
            books.append(book)
        }
        
        return books
    }
}
