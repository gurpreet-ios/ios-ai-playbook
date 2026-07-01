import Foundation

public struct TrackDTO: Codable, Sendable, Identifiable {
    public let id: UUID
    public let title: String
    public let artist: String
    public let coverURL: URL?
    public let streamURL: URL
    
    public init(id: UUID, title: String, artist: String, coverURL: URL?, streamURL: URL) {
        self.id = id
        self.title = title
        self.artist = artist
        self.coverURL = coverURL
        self.streamURL = streamURL
    }
}

public struct PlaylistDTO: Codable, Sendable, Identifiable {
    public let id: UUID
    public let name: String
    public let tracks: [TrackDTO]
    
    public init(id: UUID, name: String, tracks: [TrackDTO]) {
        self.id = id
        self.name = name
        self.tracks = tracks
    }
}
