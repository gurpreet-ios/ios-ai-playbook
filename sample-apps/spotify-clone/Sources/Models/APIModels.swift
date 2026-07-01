import Foundation

public struct TrackDTO: Codable, Sendable {
    public let id: String
    public let title: String
    public let artist: String
    public let coverURL: URL?
    public let streamURL: URL
    
    public init(
        id: String,
        title: String,
        artist: String,
        coverURL: URL?,
        streamURL: URL
    ) {
        self.id = id
        self.title = title
        self.artist = artist
        self.coverURL = coverURL
        self.streamURL = streamURL
    }
}

public struct PlaylistDTO: Codable, Sendable {
    public let id: String
    public let name: String
    public let tracks: [TrackDTO]
    
    public init(
        id: String,
        name: String,
        tracks: [TrackDTO]
    ) {
        self.id = id
        self.name = name
        self.tracks = tracks
    }
}
