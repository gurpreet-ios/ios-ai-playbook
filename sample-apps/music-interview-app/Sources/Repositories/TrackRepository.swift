import Foundation
import SwiftData

@MainActor
public protocol TrackRepositoryProtocol: Sendable {
    func fetchTracks() async throws -> [Track]
    func getTrack(id: UUID) async throws -> Track
    func downloadTrack(id: UUID) async throws
}

@MainActor
public final class TrackRepository: TrackRepositoryProtocol {
    private let networkClient: any NetworkClientProtocol
    private let modelContext: ModelContext

    public init(networkClient: any NetworkClientProtocol, modelContext: ModelContext) {
        self.networkClient = networkClient
        self.modelContext = modelContext
    }

    public func fetchTracks() async throws -> [Track] {
        let dtos = try await networkClient.fetchTracks()
        let tracks = try dtos.map(upsert)
        try modelContext.save()
        return tracks
    }

    public func getTrack(id: UUID) async throws -> Track {
        let trackId = id
        let descriptor = FetchDescriptor<Track>(predicate: #Predicate { $0.id == trackId })

        if let localTrack = try modelContext.fetch(descriptor).first {
            return localTrack
        }

        let dto = try await networkClient.fetchTrack(id: trackId)
        let track = try upsert(dto)
        try modelContext.save()
        return track
    }

    public func downloadTrack(id: UUID) async throws {
        let track = try await getTrack(id: id)

        // Download the actual file data via the network client
        let fileURL = try await networkClient.downloadTrackFile(id: id)

        // Update the SwiftData model's offline URL
        track.offlineFileURL = fileURL
        try modelContext.save()
    }

    /// Maps a network DTO into the persisted domain model, updating the
    /// existing row when the track is already cached locally.
    private func upsert(_ dto: TrackDTO) throws -> Track {
        let dtoId = dto.id
        let descriptor = FetchDescriptor<Track>(predicate: #Predicate { $0.id == dtoId })

        if let existing = try modelContext.fetch(descriptor).first {
            existing.title = dto.title
            existing.artist = dto.artist
            existing.coverURL = dto.coverURL
            existing.streamURL = dto.streamURL
            return existing
        }

        let track = Track(
            id: dto.id,
            title: dto.title,
            artist: dto.artist,
            coverURL: dto.coverURL,
            streamURL: dto.streamURL
        )
        modelContext.insert(track)
        return track
    }
}
