//
//  Announcement.swift
//  Lib1
//
//  Created by admin12 on 18/04/25.
//


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

struct Book: Identifiable, Codable {
    let id: UUID
    let title: String
    let author: String
    let dueDate: Date? // For borrowed books
    let releaseDate: Date? // For upcoming books
    
    init(id: UUID = UUID(), title: String, author: String, dueDate: Date? = nil, releaseDate: Date? = nil) {
        self.id = id
        self.title = title
        self.author = author
        self.dueDate = dueDate
        self.releaseDate = releaseDate
    }
    
    // Sample data for borrowed books
    static let sampleBorrowedBooks = [
        Book(title: "The Great Gatsby", author: "F. Scott Fitzgerald", dueDate: Date().addingTimeInterval(86400 * 5)),
        Book(title: "1984", author: "George Orwell", dueDate: Date().addingTimeInterval(86400 * 2))
    ]
    
    // Sample data for upcoming books
    static let sampleUpcomingBooks = [
        Book(title: "New Sci-Fi Novel", author: "Jane Doe", releaseDate: Date().addingTimeInterval(86400 * 10)),
        Book(title: "Mystery Thriller", author: "John Smith", releaseDate: Date().addingTimeInterval(86400 * 15))
    ]
}