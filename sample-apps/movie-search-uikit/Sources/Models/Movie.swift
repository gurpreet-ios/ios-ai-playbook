// Movie.swift
// Models layer — the app's core domain entity.

import Foundation

/// A movie as the app understands it — already mapped from the API DTO,
/// with display-ready fields and resolved URLs.
///
/// Plain value type: the app has no local database (favorites store only
/// IDs), so there is nothing to persist and no reason for a class.
struct Movie: Identifiable, Hashable, Sendable {

    // MARK: - Properties

    /// Stable backend identifier; also the key used by `FavoritesStore`.
    let id: Int

    /// Display title.
    let title: String

    /// Plot summary shown on the detail screen.
    let overview: String

    /// Four-digit release year, if the API provided a release date.
    let releaseYear: String?

    /// Fully-resolved poster image URL, if the movie has a poster.
    let posterURL: URL?

    /// Average user rating on a 0–10 scale.
    let rating: Double
}
