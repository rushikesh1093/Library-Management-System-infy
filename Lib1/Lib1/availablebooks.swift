//
//  availablebooks.swift
//  Lib1
//
//  Created by admin100 on 17/04/25.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct AvailableBooksView: View {
    @Environment(\.dismiss) var dismiss
    @State private var books: [Book] = []
    @State private var allBooks: [Book] = []
    @State private var selectedCategory: String = "All"
    @State private var isAvailableOnly: Bool = false
    @State private var isLoading: Bool = true
    @State private var errorMessage: String = ""
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    
    private let db = Firestore.firestore()
    
    struct Book: Identifiable {
        let id: String // Maps to book_id
        let title: String
        let author: String
        let isbn: String?
        let category: String
        let language: String?
        let publisher: String?
        let publicationYear: Int?
        let shelfLocation: String?
        let status: String?
        let copies: Int?
        let available: Bool
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Available Books")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.blue)
                    .padding(.top)
                    .accessibilityLabel("Available books")
                
                // Filters
                VStack(spacing: 10) {
                    Picker("Category", selection: $selectedCategory) {
                        Text("All").tag("All")
                        Text("Fantasy").tag("Fantasy")
                        Text("Fiction").tag("Fiction")
                        Text("Dystopian").tag("Dystopian")
                        Text("Historical Fiction").tag("Historical Fiction")
                        Text("Romance").tag("Romance")
                    }
                    .pickerStyle(.menu)
                    .padding(.horizontal)
                    .accessibilityLabel("Select category filter")
                    
                    Toggle("Available Only", isOn: $isAvailableOnly)
                        .padding(.horizontal)
                        .accessibilityLabel("Show only available books")
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .accessibilityLabel("Loading books")
                } else if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.callout)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                        .accessibilityLabel("Error: \(errorMessage)")
                } else if books.isEmpty {
                    Text("No books found. Check CSV format or filters.")
                        .font(.callout)
                        .foregroundColor(.gray)
                        .accessibilityLabel("No books found")
                } else {
                    List(books) { book in
                        HStack {
                            VStack(alignment: .leading, spacing: 5) {
                                Text(book.title)
                                    .font(.headline)
                                Text("Author: \(book.author)")
                                    .font(.subheadline)
                                Text("Category: \(book.category)")
                                    .font(.subheadline)
                                if let year = book.publicationYear {
                                    Text("Year: \(year)")
                                        .font(.subheadline)
                                }
                                Text("Status: \(book.available ? "Available" : "Checked Out")")
                                    .font(.subheadline)
                                    .foregroundColor(book.available ? .green : .red)
                            }
                            Spacer()
                            if book.available {
                                Button(action: {
                                    issueBook(book: book)
                                }) {
                                    Text("Issue")
                                        .font(.subheadline)
                                        .padding(.vertical, 4)
                                        .padding(.horizontal, 8)
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                }
                                .accessibilityLabel("Issue book: \(book.title)")
                            }
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Book: \(book.title), Author: \(book.author), Category: \(book.category), \(book.available ? "Available" : "Checked Out")")
                    }
                }
                
                Spacer()
            }
            .frame(maxWidth: 400)
            .background(Color.white.opacity(0.95))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: .gray.opacity(0.3), radius: 10, x: 0, y: 5)
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.blue)
                            .imageScale(.large)
                    }
                    .accessibilityLabel("Close available books")
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Issue Book"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
            .onAppear {
                loadBooks()
            }
            .onChange(of: selectedCategory) { _ in filterBooks() }
            .onChange(of: isAvailableOnly) { _ in filterBooks() }
        }
    }
    
    private func loadBooks() {
        isLoading = true
        print("Starting to load books from CSV")
        
        if let csvBooks = parseCSV() {
            allBooks = csvBooks
            books = csvBooks
            print("Loaded \(csvBooks.count) books from CSV")
            syncCSVToFirestore(books: csvBooks)
        } else {
            errorMessage = "Failed to load CSV file. Check file name or format."
            print("Failed to load CSV")
            isLoading = false
            return
        }
        
        isLoading = false
        filterBooks()
    }
    
    private func parseCSV() -> [Book]? {
        guard let filepath = Bundle.main.path(forResource: "real_books_dataset", ofType: "csv") else {
            errorMessage = "CSV file 'real_books_dataset.csv' not found in app bundle"
            print("Error: CSV file 'real_books_dataset.csv' not found")
            return nil
        }
        
        do {
            let contents = try String(contentsOfFile: filepath, encoding: .utf8)
            let rows = contents.components(separatedBy: "\n").filter { !$0.isEmpty }
            if rows.isEmpty {
                errorMessage = "CSV file is empty"
                print("Error: CSV file is empty")
                return nil
            }
            
            var csvBooks: [Book] = []
            var parseErrors: [String] = []
            
            for (index, row) in rows.dropFirst().enumerated() {
                let columns = row.splitCSV() // Assumes splitCSV handles quoted fields and commas correctly
                print("Row \(index + 1): \(columns)")
                
                if columns.count >= 12 {
                    let bookId = columns[0].isEmpty ? nil : columns[0].trimmingCharacters(in: .init(charactersIn: "\""))
                    let title = columns[1].isEmpty ? "Unknown" : columns[1].trimmingCharacters(in: .init(charactersIn: "\""))
                    let author = columns[2].isEmpty ? "Unknown" : columns[2].trimmingCharacters(in: .init(charactersIn: "\""))
                    let isbn = columns[3].isEmpty ? nil : columns[3].trimmingCharacters(in: .init(charactersIn: "\""))
                    let category = columns[4].isEmpty ? "Unknown" : columns[4].trimmingCharacters(in: .init(charactersIn: "\""))
                    let language = columns[5].isEmpty ? nil : columns[5].trimmingCharacters(in: .init(charactersIn: "\""))
                    let publisher = columns[6].isEmpty ? nil : columns[6].trimmingCharacters(in: .init(charactersIn: "\""))
                    let publicationYear = columns[7].isEmpty ? nil : Int(columns[7])
                    let shelfLocation = columns[8].isEmpty ? nil : columns[8].trimmingCharacters(in: .init(charactersIn: "\""))
                    let isAvailableStr = columns[9].isEmpty ? "Yes" : columns[9].trimmingCharacters(in: .init(charactersIn: "\""))
                    let status = columns[10].isEmpty ? nil : columns[10].trimmingCharacters(in: .init(charactersIn: "\""))
                    let copies = columns[11].isEmpty ? nil : Int(columns[11])
                    
                    let available = isAvailableStr.lowercased() == "yes"
                    
                    if let bookId = bookId, title != "Unknown", author != "Unknown" {
                        let book = Book(
                            id: bookId,
                            title: title,
                            author: author,
                            isbn: isbn,
                            category: category,
                            language: language,
                            publisher: publisher,
                            publicationYear: publicationYear,
                            shelfLocation: shelfLocation,
                            status: status,
                            copies: copies,
                            available: available
                        )
                        csvBooks.append(book)
                    } else {
                        parseErrors.append("Row \(index + 1): Missing book_id, title, or author")
                    }
                } else {
                    parseErrors.append("Row \(index + 1): Insufficient columns (\(columns.count))")
                }
            }
            
            if csvBooks.isEmpty && !parseErrors.isEmpty {
                errorMessage = "No valid books parsed. Errors: \(parseErrors.joined(separator: "; "))"
                print("Parsing errors: \(parseErrors)")
                return nil
            }
            
            print("Successfully parsed \(csvBooks.count) books")
            return csvBooks
        } catch {
            errorMessage = "Failed to parse CSV: \(error.localizedDescription)"
            print("CSV parse error: \(error.localizedDescription)")
            return nil
        }
    }
    
    private func filterBooks() {
        var filteredBooks = allBooks
        
        if isAvailableOnly {
            filteredBooks = filteredBooks.filter { $0.available }
            print("Applied availability filter: \(filteredBooks.count) books")
        }
        
        if selectedCategory != "All" {
            filteredBooks = filteredBooks.filter { $0.category.lowercased() == selectedCategory.lowercased() }
            print("Applied category filter (\(selectedCategory)): \(filteredBooks.count) books")
        }
        
        books = filteredBooks
        print("Total books after filtering: \(books.count)")
    }
    
    private func issueBook(book: Book) {
        guard let userId = Auth.auth().currentUser?.uid else {
            alertMessage = "No user logged in"
            showAlert = true
            print("Issue error: No user logged in")
            return
        }
        
        db.collection("books").document(book.id).setData([
            "title": book.title,
            "author": book.author,
            "isbn": book.isbn ?? NSNull(),
            "category": book.category,
            "language": book.language ?? NSNull(),
            "publisher": book.publisher ?? NSNull(),
            "publicationYear": book.publicationYear ?? NSNull(),
            "shelfLocation": book.shelfLocation ?? NSNull(),
            "status": book.status ?? NSNull(),
            "copies": book.copies ?? NSNull(),
            "available": false,
            "createdAt": Timestamp(date: Date())
        ]) { error in
            if let error = error {
                alertMessage = "Failed to issue book: \(error.localizedDescription)"
                showAlert = true
                print("Firestore update error: \(error.localizedDescription)")
                return
            }
            
            let issueData: [String: Any] = [
                "bookId": book.id,
                "userId": userId,
                "issueDate": Timestamp(date: Date()),
                "status": "issued"
            ]
            
            db.collection("issuedBooks").addDocument(data: issueData) { error in
                if let error = error {
                    alertMessage = "Failed to record issue: \(error.localizedDescription)"
                    showAlert = true
                    print("Firestore issue record error: \(error.localizedDescription)")
                } else {
                    if let index = allBooks.firstIndex(where: { $0.id == book.id }) {
                        allBooks[index] = Book(
                            id: book.id,
                            title: book.title,
                            author: book.author,
                            isbn: book.isbn,
                            category: book.category,
                            language: book.language,
                            publisher: book.publisher,
                            publicationYear: book.publicationYear,
                            shelfLocation: book.shelfLocation,
                            status: book.status,
                            copies: book.copies,
                            available: false
                        )
                    }
                    filterBooks()
                    alertMessage = "Book '\(book.title)' issued successfully"
                    showAlert = true
                    print("Book issued: \(book.title)")
                }
            }
        }
    }
    
    private func syncCSVToFirestore(books: [Book]) {
        let batch = db.batch()
        var booksAdded = 0
        
        for book in books {
            let bookData: [String: Any] = [
                "title": book.title,
                "author": book.author,
                "isbn": book.isbn ?? NSNull(),
                "category": book.category,
                "language": book.language ?? NSNull(),
                "publisher": book.publisher ?? NSNull(),
                "publicationYear": book.publicationYear ?? NSNull(),
                "shelfLocation": book.shelfLocation ?? NSNull(),
                "status": book.status ?? NSNull(),
                "copies": book.copies ?? NSNull(),
                "available": book.available,
                "createdAt": Timestamp(date: Date())
            ]
            
            let docRef = db.collection("books").document(book.id)
            batch.setData(bookData, forDocument: docRef)
            booksAdded += 1
        }
        
        batch.commit { error in
            if let error = error {
                errorMessage = "Failed to sync \(booksAdded) books to Firestore: \(error.localizedDescription)"
                print("Firestore sync error: \(error.localizedDescription)")
            } else {
                print("Successfully synced \(booksAdded) books to Firestore")
            }
        }
    }
}

// Extension for CSV parsing (same as before, included for completeness)
extension String {
    func splitCSV() -> [String] {
        var result: [String] = []
        var currentField = ""
        var insideQuotes = false
        
        for char in self {
            if char == "\"" {
                insideQuotes.toggle()
            } else if char == "," && !insideQuotes {
                result.append(currentField)
                currentField = ""
            } else {
                currentField.append(char)
            }
        }
        
        result.append(currentField)
        return result
    }
}
