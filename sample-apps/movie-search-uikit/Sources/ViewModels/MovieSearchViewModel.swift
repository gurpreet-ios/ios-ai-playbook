// MovieSearchViewModel.swift
// ViewModels layer — owns search state, debounce, and navigation intent.

import Foundation

// MARK: - SearchState

/// Everything the search screen can display, as one exhaustive enum —
/// the ViewController is a `switch` over this and nothing more.
enum SearchState: Equatable {

    /// Nothing typed yet; show the search-prompt placeholder.
    case idle

    /// A search is in flight.
    case loading

    /// Results are available.
    case loaded([Movie])

    /// The query returned no results.
    case empty(query: String)

    /// The search failed; `message` is user-presentable.
    case failed(message: String)
}

// MARK: - MovieSearchViewModel

/// Drives the search screen: debounces input, runs the search, publishes
/// `SearchState`, and signals selection to its Coordinator.
@MainActor
final class MovieSearchViewModel {

    // MARK: State

    /// Bindable screen state.
    let state = Box<SearchState>(.idle)

    /// Navigation intent, fulfilled by the Coordinator — the ViewModel never
    /// sees a ViewController or a navigation stack.
    var onMovieSelected: ((Movie) -> Void)?

    // MARK: Dependencies

    private let repository: MovieRepositoryProtocol

    /// Debounce window between keystroke and request.
    private let debounceInterval: Duration

    /// The in-flight debounce+search task. Internal (not private) so tests
    /// can await completion instead of sleeping.
    private(set) var activeSearchTask: Task<Void, Never>?

    // MARK: Initialisation

    /// - Parameter debounceInterval: injectable so tests can pass `.zero`.
    init(
        repository: MovieRepositoryProtocol,
        debounceInterval: Duration = .milliseconds(300)
    ) {
        self.repository = repository
        self.debounceInterval = debounceInterval
    }

    // MARK: Input Events

    /// Called on every keystroke. Cancels the previous pending search so only
    /// the latest query ever reaches the network.
    func searchTextDidChange(_ text: String) {
        activeSearchTask?.cancel()

        let query = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            activeSearchTask = nil
            state.value = .idle
            return
        }

        activeSearchTask = Task { [weak self, debounceInterval] in
            try? await Task.sleep(for: debounceInterval)
            guard !Task.isCancelled else { return }
            await self?.performSearch(query)
        }
    }

    /// Called by the ViewController on cell selection.
    func didSelectMovie(_ movie: Movie?) {
        guard let movie else { return }
        onMovieSelected?(movie)
    }

    // MARK: Search

    private func performSearch(_ query: String) async {
        state.value = .loading
        do {
            let movies = try await repository.searchMovies(matching: query)
            guard !Task.isCancelled else { return }
            state.value = movies.isEmpty ? .empty(query: query) : .loaded(movies)
        } catch {
            guard !Task.isCancelled else { return }
            state.value = .failed(message: error.localizedDescription)
        }
    }
}
