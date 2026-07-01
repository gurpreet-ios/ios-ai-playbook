import Foundation
import SwiftData

@Model
public final class Track: @unchecked Sendable {
    @Attribute(.unique) public var id: UUID
    public var title: String
    public var artist: String
    public var coverURL: URL?
    public var streamURL: URL
    public var offlineFileURL: URL?
    
    public var playlists: [Playlist]?
    
    public init(id: UUID = UUID(), title: String, artist: String, coverURL: URL? = nil, streamURL: URL, offlineFileURL: URL? = nil) {
        self.id = id
        self.title = title
        self.artist = artist
        self.coverURL = coverURL
        self.streamURL = streamURL
        self.offlineFileURL = offlineFileURL
    }
}
