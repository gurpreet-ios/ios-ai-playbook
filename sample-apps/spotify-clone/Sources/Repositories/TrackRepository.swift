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
        let predicate = #Predicate<Track> { $0.id == id }
        var fetchDescriptor = FetchDescriptor<Track>(predicate: predicate)
        fetchDescriptor.fetchLimit = 1
        
        if let track = try modelContext.fetch(fetchDescriptor).first {
            return track
        }
        
        // Note: In a real app, this would fetch from networkClient and insert into ModelContext
        // let trackDTO = try await networkClient.fetch(...)
        // let track = Track(from: trackDTO)
        // modelContext.insert(track)
        // try modelContext.save()
        
        throw URLError(.resourceUnavailable)
    }
    
    public func downloadTrack(id: UUID) async throws {
        let track = try await getTrack(id: id)
        
        // Simulate downloading via networkClient
        // let downloadedData = try await networkClient.download(...)
        
        let destinationURL = FileManager.default.temporaryDirectory.appending(component: "\(id.uuidString).mp3")
        
        track.offlineFileURL = destinationURL
        track.isDownloaded = true
        
        try modelContext.save()
    }
}
