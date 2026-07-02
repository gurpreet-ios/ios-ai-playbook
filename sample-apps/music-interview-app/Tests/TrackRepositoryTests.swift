import Testing
import Foundation
import SwiftData
@testable import MusicInterviewApp

/// Regression guard for the composition-root wiring crash (Chapter 16):
/// constructs the real object graph — container, context, repository — so a
/// container-less `ModelContext` fails in `swift test`, not on first launch.
@MainActor
@Suite("TrackRepository wiring")
struct TrackRepositoryTests {
    private struct StubNetworkClient: NetworkClientProtocol {
        let tracks: [TrackDTO]

        func fetchTracks() async throws -> [TrackDTO] { tracks }

        func fetchTrack(id: UUID) async throws -> TrackDTO {
            guard let dto = tracks.first(where: { $0.id == id }) else {
                throw URLError(.resourceUnavailable)
            }
            return dto
        }

        func downloadTrackFile(id: UUID) async throws -> URL {
            URL.documentsDirectory.appending(path: "\(id).mp3")
        }
    }

    @Test("fetchTracks upserts DTOs through a container-backed context, idempotently")
    func fetchTracksUpserts() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Track.self, Playlist.self, configurations: config)
        let dto = TrackDTO(
            id: UUID(),
            title: "Weird Fishes",
            artist: "Radiohead",
            coverURL: nil,
            streamURL: try #require(URL(string: "https://example.com/stream/2"))
        )
        let repository = TrackRepository(
            networkClient: StubNetworkClient(tracks: [dto]),
            modelContext: container.mainContext
        )

        let first = try await repository.fetchTracks()
        let second = try await repository.fetchTracks()

        #expect(first.count == 1)
        #expect(first.first?.title == "Weird Fishes")
        #expect(second.count == 1)

        let persisted = try container.mainContext.fetch(FetchDescriptor<Track>())
        #expect(persisted.count == 1, "upsert must update, not duplicate")
    }
}
