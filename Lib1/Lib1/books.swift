//
//  books.swift
//  Lib1
//
//  Created by admin100 on 17/04/25.
//
import Foundation
import FirebaseFirestore


struct Book: Identifiable, Codable, Equatable { // Add Equatable here
    @DocumentID var id: String?
    let title: String
    let author: String
    let genre: String
    let publicationDate: Date
    let isAvailable: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case author
        case genre
        case publicationDate
        case isAvailable
    }
}
