import Testing
import Foundation
@testable import MusicInterviewApp

@Suite("Track model")
struct TrackTests {
    @Test("Initializer stores identity and leaves offline fields empty")
    func initializerDefaults() throws {
        let streamURL = try #require(URL(string: "https://example.com/stream/1"))
        let track = Track(title: "Karma Police", artist: "Radiohead", streamURL: streamURL)

        #expect(track.title == "Karma Police")
        #expect(track.artist == "Radiohead")
        #expect(track.streamURL == streamURL)
        #expect(track.coverURL == nil)
        #expect(track.offlineFileURL == nil)
    }
}
