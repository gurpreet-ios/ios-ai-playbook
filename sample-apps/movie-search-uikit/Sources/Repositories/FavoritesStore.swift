// FavoritesStore.swift
// Repositories layer — favorites persistence behind a protocol.
// Storage is deliberately just movie IDs in UserDefaults (see DECISIONS.md #7).

import Foundation

// MARK: - FavoritesStoreProtocol

/// Read/write access to the user's favorite movies.
///
/// `@MainActor` because it is only ever touched from ViewModels and it keeps
/// the whole read-toggle-read cycle free of await suspension points.
@MainActor
protocol FavoritesStoreProtocol: AnyObject {

    /// Whether the movie is currently a favorite.
    func isFavorite(_ movieID: Int) -> Bool

    /// Adds the movie to favorites, or removes it if already present.
    func toggle(_ movieID: Int)
}

// MARK: - UserDefaultsFavoritesStore

/// UserDefaults-backed implementation storing a set of movie IDs.
@MainActor
final class UserDefaultsFavoritesStore: FavoritesStoreProtocol {

    // MARK: Properties

    private static let storageKey = "com.moviesearch.favoriteMovieIDs"

    private let defaults: UserDefaults

    /// In-memory mirror of the persisted set, written through on every change.
    private var favoriteIDs: Set<Int>

    // MARK: Initialisation

    /// - Parameter defaults: injectable so tests can use an isolated suite.
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let stored = defaults.array(forKey: Self.storageKey) as? [Int] ?? []
        self.favoriteIDs = Set(stored)
    }

    // MARK: FavoritesStoreProtocol

    func isFavorite(_ movieID: Int) -> Bool {
        favoriteIDs.contains(movieID)
    }

    func toggle(_ movieID: Int) {
        if favoriteIDs.contains(movieID) {
            favoriteIDs.remove(movieID)
        } else {
            favoriteIDs.insert(movieID)
        }
        defaults.set(Array(favoriteIDs), forKey: Self.storageKey)
    }
}
