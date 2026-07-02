import Foundation

public protocol NetworkClientProtocol: Sendable {
    func fetchTracks() async throws -> [TrackDTO]
    func fetchTrack(id: UUID) async throws -> TrackDTO
    func downloadTrackFile(id: UUID) async throws -> URL
}

public actor NetworkClient: NetworkClientProtocol {
    private let session: URLSession
    private let baseURL: URL

    public init(session: URLSession = .shared, baseURL: URL = URL(string: "https://api.example.com")!) {
        self.session = session
        self.baseURL = baseURL
    }

    public func fetchTracks() async throws -> [TrackDTO] {
        try await fetch(url: baseURL.appendingPathComponent("tracks"))
    }

    public func fetchTrack(id: UUID) async throws -> TrackDTO {
        try await fetch(url: baseURL.appendingPathComponent("tracks/\(id.uuidString)"))
    }

    public func downloadTrackFile(id: UUID) async throws -> URL {
        let remoteURL = baseURL.appendingPathComponent("tracks/\(id.uuidString)/audio")
        let (tempURL, response) = try await session.download(from: remoteURL)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        let destination = URL.documentsDirectory.appending(path: "\(id.uuidString).m4a")
        try? FileManager.default.removeItem(at: destination)
        try FileManager.default.moveItem(at: tempURL, to: destination)
        return destination
    }

    private func fetch<T: Decodable & Sendable>(url: URL) async throws -> T {
        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    }
}
