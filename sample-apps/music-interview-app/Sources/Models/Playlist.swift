import Foundation
import SwiftData

@Model
public final class Playlist: @unchecked Sendable {
    @Attribute(.unique) public var id: UUID
    public var name: String
    
    @Relationship(inverse: \Track.playlists)
    public var tracks: [Track]
    
    public init(id: UUID = UUID(), name: String, tracks: [Track] = []) {
        self.id = id
        self.name = name
        self.tracks = tracks
    }
}
