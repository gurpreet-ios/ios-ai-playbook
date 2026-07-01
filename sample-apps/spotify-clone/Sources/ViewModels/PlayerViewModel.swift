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
    
    deinit {
        stateObservationTask?.cancel()
    }
    
    public func play(track: Track) async {
        currentTrack = track
        await audioEngine.play(track: track)
    }
    
    public func togglePlayPause() async {
        if playbackState == .playing {
            await audioEngine.pause()
        } else {
            await audioEngine.resume()
        }
    }
}
