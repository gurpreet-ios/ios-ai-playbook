import Testing
import Foundation
@testable import SpotifyClone

@Suite("Track model")
struct TrackTests {
    @Test("New tracks start not downloaded")
    func newTrackIsNotDownloaded() throws {
        let streamURL = try #require(URL(string: "https://example.com/stream/1"))
        let track = Track(title: "Paranoid Android", artist: "Radiohead", streamURL: streamURL)

        #expect(track.isDownloaded == false)
        #expect(track.offlineFileURL == nil)
        #expect(track.streamURL == streamURL)
    }
}
