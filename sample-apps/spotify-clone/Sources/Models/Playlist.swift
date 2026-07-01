import Foundation
import SwiftData

@Model
public final class Playlist {
    @Attribute(.unique) public var id: UUID
    public var name: String
    
    @Relationship
    public var tracks: [Track]
    
    public init(
        id: UUID = UUID(),
        name: String,
        tracks: [Track] = []
    ) {
        self.id = id
        self.name = name
        self.tracks = tracks
    }
}
