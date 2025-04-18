//
//  CatalogView.swift
//  Lib1
//
//  Created by admin100 on 17/04/25.
//

import SwiftUI

struct CatalogView: View {
    @StateObject private var viewModel = CatalogViewModel()
    @State private var showDatePicker = false

    private let calendar = Calendar.current
    private let minDate = Date(timeIntervalSince1970: 0) // 1970
    private let maxDate = Date() // Today

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [.blue.opacity(0.2), .white.opacity(0.1)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 5).repeatForever(autoreverses: true), value: viewModel.books)

                VStack(spacing: 10) {
                    // Search Bar
                    TextField("Search by title or author", text: $viewModel.searchText)
                        .padding()
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .padding(.horizontal)
                        .accessibilityLabel("Search books by title or author")
                        .autocapitalization(.none)

                    // Filters
                    HStack {
                        Picker("Genre", selection: $viewModel.selectedGenre) {
                            Text("All Genres").tag(String?.none)
                            ForEach(Array(Set(viewModel.books.map { $0.genre })).sorted(), id: \.self) { genre in
                                Text(genre).tag(String?.some(genre))
                            }
                        }
                        .pickerStyle(.menu)
                        .accessibilityLabel("Filter by genre")

                        Picker("Availability", selection: $viewModel.selectedAvailability) {
                            ForEach(CatalogViewModel.AvailabilityFilter.allCases) { filter in
                                Text(filter.rawValue).tag(filter)
                            }
                        }
                        .pickerStyle(.menu)
                        .accessibilityLabel("Filter by availability")
                    }
                    .padding(.horizontal)

                    // Publication Date Filter
                    Button(action: { withAnimation { showDatePicker.toggle() } }) {
                        Text(viewModel.publicationDateRange == nil ? "Select Date Range" : "Date: \(formattedDateRange)")
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .foregroundColor(.primary)
                    }
                    .accessibilityLabel("Toggle publication date filter")

                    if showDatePicker {
                        VStack {
                            DatePicker(
                                "Start Date",
                                selection: Binding(
                                    get: { viewModel.publicationDateRange?.lowerBound ?? minDate },
                                    set: { viewModel.publicationDateRange = $0...maxDate }
                                ),
                                in: minDate...maxDate,
                                displayedComponents: [.date]
                            )
                            .datePickerStyle(.compact)
                            .accessibilityLabel("Select start publication date")

                            DatePicker(
                                "End Date",
                                selection: Binding(
                                    get: { viewModel.publicationDateRange?.upperBound ?? maxDate },
                                    set: { viewModel.publicationDateRange = minDate...$0 }
                                ),
                                in: minDate...maxDate,
                                displayedComponents: [.date]
                            )
                            .datePickerStyle(.compact)
                            .accessibilityLabel("Select end publication date")

                            Button("Clear Date Filter") {
                                viewModel.publicationDateRange = nil
                                withAnimation { showDatePicker = false }
                            }
                            .foregroundColor(.red)
                            .accessibilityLabel("Clear publication date filter")
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .padding(.horizontal)
                        .transition(.opacity)
                    }

                    // Book List
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .padding()
                            .accessibilityLabel("Error: \(errorMessage)")
                    } else {
                        List(viewModel.filteredBooks) { book in
                            NavigationLink(destination: BookDetailView(book: book)) {
                                BookRow(book: book)
                            }
                        }
                        .listStyle(.plain)
                        .accessibilityLabel("Library catalog list")
                    }
                }
                .padding(.top)
            }
            .navigationTitle("Library Catalog")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.searchText = ""
                        viewModel.selectedGenre = nil
                        viewModel.selectedAvailability = .all
                        viewModel.publicationDateRange = nil
                        showDatePicker = false
                    }) {
                        Image(systemName: "arrow.counterclockwise")
                    }
                    .accessibilityLabel("Reset filters")
                }
            }
        }
        .onAppear {
            viewModel.fetchBooks()
        }
    }

    private var formattedDateRange: String {
        guard let range = viewModel.publicationDateRange else { return "" }
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return "\(formatter.string(from: range.lowerBound)) - \(formatter.string(from: range.upperBound))"
    }
}

struct BookRow: View {
    let book: Book

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text(book.title)
                    .font(.headline)
                    .accessibilityLabel("Book title: \(book.title)")
                Text("Author: \(book.author)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .accessibilityLabel("Author: \(book.author)")
                Text("Genre: \(book.genre)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .accessibilityLabel("Genre: \(book.genre)")
                Text("Published: \(book.publicationDate, style: .date)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .accessibilityLabel("Publication date: \(book.publicationDate, style: .date)")
            }
            Spacer()
            Text(book.isAvailable ? "Available" : "On Loan")
                .font(.caption)
                .padding(5)
                .background(book.isAvailable ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .accessibilityLabel(book.isAvailable ? "Book is available" : "Book is on loan")
        }
        .padding(.vertical, 5)
    }
}

struct BookDetailView: View {
    let book: Book

    var body: some View {
        VStack(spacing: 20) {
            Text(book.title)
                .font(.title)
                .accessibilityLabel("Book title: \(book.title)")
            Text("Author: \(book.author)")
                .font(.headline)
                .accessibilityLabel("Author: \(book.author)")
            Text("Genre: \(book.genre)")
                .font(.subheadline)
                .accessibilityLabel("Genre: \(book.genre)")
            Text("Published: \(book.publicationDate, style: .date)")
                .font(.subheadline)
                .accessibilityLabel("Publication date: \(book.publicationDate, style: .date)")
            Text(book.isAvailable ? "Available" : "On Loan")
                .font(.body)
                .padding()
                .background(book.isAvailable ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .accessibilityLabel(book.isAvailable ? "Book is available" : "Book is on loan")
        }
        .padding()
        .navigationTitle(book.title)
    }
}

struct CatalogView_Previews: PreviewProvider {
    static var previews: some View {
        CatalogView()
    }
}
