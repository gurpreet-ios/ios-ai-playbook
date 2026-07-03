// MovieRepository.swift
// Repositories layer — abstracts "where movies come from" behind a protocol
// so ViewModels never know about URLs, DTOs, or decoding.

import Foundation

// MARK: - MovieRepositoryProtocol

/// The ViewModels' only window onto movie data.
protocol MovieRepositoryProtocol: Sendable {

    /// Searches the catalogue and returns display-ready domain models.
    func searchMovies(matching query: String) async throws -> [Movie]
}

// MARK: - RemoteMovieRepository

/// Production implementation backed by the REST API.
///
/// Owns the DTO → domain mapping so `MovieDTO` never leaks above this layer.
struct RemoteMovieRepository: MovieRepositoryProtocol {

    // MARK: Properties

    private let networkClient: NetworkClientProtocol

    // MARK: Initialisation

    init(networkClient: NetworkClientProtocol) {
        self.networkClient = networkClient
    }

    // MARK: MovieRepositoryProtocol

    func searchMovies(matching query: String) async throws -> [Movie] {
        let response = try await networkClient.get(
            SearchResponseDTO.self,
            path: "search/movie",
            queryItems: [URLQueryItem(name: "query", value: query)]
        )
        return response.results.map(Movie.init(dto:))
    }
}
