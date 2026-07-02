import Foundation
import SwiftUI

@MainActor
@Observable
public final class PlayerViewModel {
    public var currentTrack: Track?
    public var playbackState: PlaybackState = .stopped
    
    private let audioEngine: AudioEngine
    
    private var stateObservationTask: Task<Void, Never>?
    
    public init(audioEngine: AudioEngine) {
        self.audioEngine = audioEngine
        
        stateObservationTask = Task { [weak self] in
            for await state in await audioEngine.stateStream {
                self?.playbackState = state
            }
        }
    }
    
    /// Explicit cleanup: `deinit` is nonisolated and cannot touch
    /// main-actor state, so the owner calls this instead.
    public func cleanup() {
        stateObservationTask?.cancel()
        stateObservationTask = nil
    }

    public func play(track: Track) async {
        currentTrack = track
        await audioEngine.play(url: track.offlineFileURL ?? track.streamURL)
    }
    
    public func togglePlayPause() async {
        if playbackState == .playing {
            await audioEngine.pause()
        } else {
            await audioEngine.resume()
        }
    }
}
