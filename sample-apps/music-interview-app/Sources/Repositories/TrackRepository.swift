import Foundation
import SwiftData

@MainActor
public protocol TrackRepositoryProtocol: Sendable {
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
    
    public func getTrack(id: UUID) async throws -> Track {
        let trackId = id
        let descriptor = FetchDescriptor<Track>(predicate: #Predicate { $0.id == trackId })
        
        if let localTrack = try modelContext.fetch(descriptor).first {
            return localTrack
        }
        
        let remoteTrack = try await networkClient.fetchTrack(id: trackId)
        modelContext.insert(remoteTrack)
        try modelContext.save()
        
        return remoteTrack
    }
    
    public func downloadTrack(id: UUID) async throws {
        let track = try await getTrack(id: id)
        
        // Download the actual file data via the network client
        let fileURL = try await networkClient.downloadTrackFile(id: id)
        
        // Update the SwiftData model's offline URL
        track.offlineFileURL = fileURL
        try modelContext.save()
    }
}
