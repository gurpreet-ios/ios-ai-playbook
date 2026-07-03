// APIModels.swift
// Models layer — DTOs mirroring the search API's JSON, kept separate from
// the domain model so the API contract can change without touching the UI.

import Foundation

// MARK: - MovieDTO

/// One movie as returned by the search API.
///
/// Property names are camelCase because `NetworkClient`'s decoder uses
/// `.convertFromSnakeCase` (`release_date` → `releaseDate`).
struct MovieDTO: Codable, Sendable, Hashable {

    /// Backend identifier.
    let id: Int

    /// Raw title string.
    let title: String

    /// Plot summary; the API may return an empty string.
    let overview: String

    /// ISO date string ("2024-03-01") or nil/empty when unannounced.
    let releaseDate: String?

    /// Poster path fragment ("/abc123.jpg") to append to the image CDN base.
    let posterPath: String?

    /// Average rating, 0–10.
    let voteAverage: Double
}

// MARK: - SearchResponseDTO

/// Envelope for a paginated search response.
struct SearchResponseDTO: Codable, Sendable, Hashable {

    /// 1-based page index of this response.
    let page: Int

    /// Movies on this page.
    let results: [MovieDTO]

    /// Total number of pages available for the query.
    let totalPages: Int
}

// MARK: - DTO → Domain Mapping

extension Movie {

    /// Base URL of the poster image CDN (demonstration placeholder).
    private static let posterBaseURL = URL(string: "https://images.example.com/w500")!

    /// Maps an API DTO into the display-ready domain model.
    init(dto: MovieDTO) {
        self.init(
            id: dto.id,
            title: dto.title,
            overview: dto.overview,
            releaseYear: dto.releaseDate.flatMap { $0.count >= 4 ? String($0.prefix(4)) : nil },
            posterURL: dto.posterPath.map { Self.posterBaseURL.appending(path: $0) },
            rating: dto.voteAverage
        )
    }
}
