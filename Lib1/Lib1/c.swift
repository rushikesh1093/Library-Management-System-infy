
import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

class CatalogViewModel: ObservableObject {
    @Published var books: [Book] = []
    @Published var searchText: String = ""
    @Published var selectedGenre: String? = nil
    @Published var selectedAvailability: AvailabilityFilter = .all
    @Published var publicationDateRange: ClosedRange<Date>? = nil
    @Published var errorMessage: String? = nil

    private let db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()

    enum AvailabilityFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case available = "Available"
        case onLoan = "On Loan"

        var id: String { rawValue }
    }

    init() {
        fetchBooks()
        setupFilterBindings()
    }

    func fetchBooks() {
        guard Auth.auth().currentUser != nil else {
            errorMessage = "Please sign in to view the catalog."
            return
        }

        db.collection("books")
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    self?.errorMessage = "Failed to load catalog: \(error.localizedDescription)"
                    print("Error fetching books: \(error.localizedDescription)")
                    return
                }
                self?.books = snapshot?.documents.compactMap { document in
                    try? document.data(as: Book.self)
                } ?? []
                self?.errorMessage = (self?.books.isEmpty)! ? "No books found in the catalog." : nil
            }
    }

    private func setupFilterBindings() {
        Publishers.CombineLatest4(
            $searchText,
            $selectedGenre,
            $selectedAvailability,
            $publicationDateRange
        )
        .sink { [weak self] _ in
            self?.objectWillChange.send()
        }
        .store(in: &cancellables)
    }

    var filteredBooks: [Book] {
        books.filter { book in
            // Search by title or author
            let matchesSearch = searchText.isEmpty ||
                book.title.lowercased().contains(searchText.lowercased()) ||
                book.author.lowercased().contains(searchText.lowercased())

            // Genre filter
            let matchesGenre = selectedGenre == nil || book.genre == selectedGenre

            // Availability filter
            let matchesAvailability: Bool
            switch selectedAvailability {
            case .all:
                matchesAvailability = true
            case .available:
                matchesAvailability = book.isAvailable
            case .onLoan:
                matchesAvailability = !book.isAvailable
            }

            // Publication date filter
            let matchesDate = publicationDateRange == nil ||
                (book.publicationDate >= publicationDateRange!.lowerBound &&
                 book.publicationDate <= publicationDateRange!.upperBound)

            return matchesSearch && matchesGenre && matchesAvailability && matchesDate
        }
        .sorted { $0.title < $1.title }
    }
}
