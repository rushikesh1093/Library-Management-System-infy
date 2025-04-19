import SwiftUI

struct BookingView: View {
    @ObservedObject var libraryModel: LibraryModel // Change to @ObservedObject
    
    private var wishlistedBooks: [Book] {
        libraryModel.books.filter { $0.isWishlisted }
    }
    
    private var pendingBooks: [Book] {
        libraryModel.books.filter { $0.reservationStatus == .pending }
    }
    
    private var approvedBooks: [Book] {
        libraryModel.books.filter { $0.reservationStatus == .approved }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
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
                }
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Wishlisted Books")
                                .font(.headline)
                                .foregroundStyle(.blue)
                                .padding(.horizontal)
                            
                            if wishlistedBooks.isEmpty {
                                Text("No books in your wishlist.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal)
                            } else {
                                ForEach(wishlistedBooks) { book in
                                    NavigationLink(destination: BookDetailView(book: book, libraryModel: libraryModel)) {
                                        BookRowView(book: book)
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Pending Reservations")
                                .font(.headline)
                                .foregroundStyle(.blue)
                                .padding(.horizontal)
                            
                            if pendingBooks.isEmpty {
                                Text("No pending reservations.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal)
                            } else {
                                ForEach(pendingBooks) { book in
                                    NavigationLink(destination: BookDetailView(book: book, libraryModel: libraryModel)) {
                                        BookRowView(book: book)
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Approved Reservations")
                                .font(.headline)
                                .foregroundStyle(.blue)
                                .padding(.horizontal)
                            
                            if approvedBooks.isEmpty {
                                Text("No approved reservations.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal)
                            } else {
                                ForEach(approvedBooks) { book in
                                    NavigationLink(destination: BookDetailView(book: book, libraryModel: libraryModel)) {
                                        BookRowView(book: book)
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                    }
                    .padding(.vertical)
                }
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.blue.opacity(0.05))
            .navigationTitle("Booking")
        }
    }
}

struct BookingView_Previews: PreviewProvider {
    static var previews: some View {
        BookingView(libraryModel: LibraryModel())
    }
}
