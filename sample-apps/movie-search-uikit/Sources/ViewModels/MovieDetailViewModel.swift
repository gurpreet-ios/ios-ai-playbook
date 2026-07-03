// MovieDetailViewModel.swift
// ViewModels layer — presentation formatting + favorite toggling for one movie.

import Foundation

/// Drives the detail screen for a single, already-loaded `Movie`.
///
/// The movie is passed in by the Coordinator (no re-fetch: the search screen
/// already has the full object), so the only live state is favorite status.
@MainActor
final class MovieDetailViewModel {

    // MARK: State

    /// Bindable favorite flag; the star button re-renders from this.
    let isFavorite: Box<Bool>

    // MARK: Presentation

    /// The movie being shown; the view reads `posterURL` from here.
    let movie: Movie

    /// Navigation-bar and headline title.
    var titleText: String { movie.title }

    /// "2024 · ★ 8.1"-style metadata line.
    var metadataText: String {
        let year = movie.releaseYear ?? "Year unknown"
        return "\(year) · ★ \(String(format: "%.1f", movie.rating))"
    }

    /// Plot summary with a fallback for movies the API returns blank.
    var overviewText: String {
        movie.overview.isEmpty ? "No overview available." : movie.overview
    }

    // MARK: Dependencies

    private let favorites: FavoritesStoreProtocol

    // MARK: Initialisation

    init(movie: Movie, favorites: FavoritesStoreProtocol) {
        self.movie = movie
        self.favorites = favorites
        self.isFavorite = Box(favorites.isFavorite(movie.id))
    }

    // MARK: Input Events

    /// Toggles persistence, then republishes the stored truth (rather than
    /// flipping the local flag) so the UI can never drift from the store.
    func toggleFavorite() {
        favorites.toggle(movie.id)
        isFavorite.value = favorites.isFavorite(movie.id)
    }
}
