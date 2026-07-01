import Foundation

// MARK: - HTTP Method

/// Supported HTTP methods for REST API calls.
enum HTTPMethod: String, Sendable {
    case get    = "GET"
    case post   = "POST"
    case put    = "PUT"
    case delete = "DELETE"
}

// MARK: - Endpoint

/// Describes a single REST API endpoint.
struct Endpoint: Sendable {
    let path: String
    let method: HTTPMethod
    let body: (any Encodable & Sendable)?
    let queryItems: [URLQueryItem]?

    init(
        path: String,
        method: HTTPMethod = .get,
        body: (any Encodable & Sendable)? = nil,
        queryItems: [URLQueryItem]? = nil
    ) {
        self.path = path
        self.method = method
        self.body = body
        self.queryItems = queryItems
    }
}

// MARK: - API Error

/// Errors that can occur during network requests.
enum APIError: Error, Sendable {
    /// The constructed URL was invalid.
    case invalidURL

    /// The response body could not be decoded into the expected type.
    case decodingFailed(Error)

    /// The server returned a non-success HTTP status code.
    case httpError(statusCode: Int, data: Data)

    /// An underlying transport or connectivity error.
    case networkError(Error)
}

extension APIError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The request URL is invalid."
        case .decodingFailed(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .httpError(let statusCode, _):
            return "HTTP error \(statusCode)."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Network Client

/// An actor-isolated HTTP client that executes REST API requests
/// using `URLSession` and returns decoded `Decodable` responses.
actor NetworkClient {

    // MARK: - Properties

    /// The base URL prepended to every endpoint path.
    let baseURL: URL

    private let session: URLSession
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    // MARK: - Initialization

    init(
        baseURL: URL,
        session: URLSession = .shared,
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.baseURL = baseURL
        self.session = session
        self.encoder = encoder
        self.decoder = decoder
    }

    // MARK: - Public API

    /// Executes a REST request described by `endpoint` and decodes the
    /// response body into the given `Decodable` type `T`.
    ///
    /// - Parameter endpoint: The endpoint specification (path, method, body, query).
    /// - Returns: The decoded value of type `T`.
    /// - Throws: `APIError` on failure.
    func request<T: Decodable & Sendable>(_ endpoint: Endpoint) async throws -> T {
        let urlRequest = try buildRequest(for: endpoint)

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: urlRequest)
        } catch {
            throw APIError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError(
                URLError(.badServerResponse)
            )
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpError(
                statusCode: httpResponse.statusCode,
                data: data
            )
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingFailed(error)
        }
    }

    // MARK: - Private Helpers

    /// Constructs a `URLRequest` from the given `Endpoint`.
    private func buildRequest(for endpoint: Endpoint) throws -> URLRequest {
        var components = URLComponents(
            url: baseURL.appendingPathComponent(endpoint.path),
            resolvingAgainstBaseURL: true
        )
        components?.queryItems = endpoint.queryItems

        guard let url = components?.url else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let body = endpoint.body {
            request.httpBody = try encoder.encode(AnyEncodable(body))
        }

        return request
    }
}

// MARK: - AnyEncodable Wrapper

/// A type-erased `Encodable` wrapper used to encode endpoint bodies
/// without requiring the caller to box them manually.
private struct AnyEncodable: Encodable, @unchecked Sendable {
    private let _encode: (Encoder) throws -> Void

    init(_ wrapped: any Encodable) {
        self._encode = wrapped.encode(to:)
    }

    func encode(to encoder: Encoder) throws {
        try _encode(encoder)
    }
}
