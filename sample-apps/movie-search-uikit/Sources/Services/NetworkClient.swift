// NetworkClient.swift
// Services layer — generic async REST client, isolated as an actor.

import Foundation

// MARK: - NetworkError

/// Failures the network layer can surface to callers.
enum NetworkError: Error, LocalizedError {

    /// The path/query combination did not form a valid URL.
    case invalidURL

    /// The server responded outside the 2xx range.
    case requestFailed(statusCode: Int)

    /// The body could not be decoded into the expected type.
    case decodingFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The request URL was invalid."
        case .requestFailed(let statusCode):
            return "The server responded with status code \(statusCode)."
        case .decodingFailed:
            return "The server response could not be read."
        }
    }
}

// MARK: - NetworkClientProtocol

/// Abstraction over HTTP GET so repositories can be tested with a stub.
protocol NetworkClientProtocol: Sendable {

    /// Performs a GET against `path` (relative to the client's base URL)
    /// and decodes the JSON body into `Response`.
    func get<Response: Decodable & Sendable>(
        _ type: Response.Type,
        path: String,
        queryItems: [URLQueryItem]
    ) async throws -> Response
}

// MARK: - NetworkClient

/// URLSession-backed client. An `actor` so the shared decoder and any
/// future state (auth token, etc.) are data-race free under Swift 6.
actor NetworkClient: NetworkClientProtocol {

    // MARK: Properties

    private let baseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder

    // MARK: Initialisation

    init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder = decoder
    }

    // MARK: NetworkClientProtocol

    func get<Response: Decodable & Sendable>(
        _ type: Response.Type,
        path: String,
        queryItems: [URLQueryItem]
    ) async throws -> Response {
        guard var components = URLComponents(
            url: baseURL.appending(path: path),
            resolvingAgainstBaseURL: false
        ) else {
            throw NetworkError.invalidURL
        }
        components.queryItems = queryItems.isEmpty ? nil : queryItems

        guard let url = components.url else {
            throw NetworkError.invalidURL
        }

        let (data, response) = try await session.data(from: url)

        guard let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode) else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw NetworkError.requestFailed(statusCode: statusCode)
        }

        do {
            return try decoder.decode(Response.self, from: data)
        } catch {
            throw NetworkError.decodingFailed(underlying: error)
        }
    }
}
