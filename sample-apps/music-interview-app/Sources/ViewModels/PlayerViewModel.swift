import Foundation
import Observation

@MainActor
@Observable
public final class PlayerViewModel {
    public var playbackState: PlaybackState = .stopped
    public var errorMessage: String?
    
    private let audioEngine: any AudioEngineProtocol
    private var stateObservationTask: Task<Void, Never>?
    
    public init(audioEngine: any AudioEngineProtocol) {
        self.audioEngine = audioEngine
        startObserving()
    }
    
    private func startObserving() {
        stateObservationTask = Task { [weak self] in
            for await state in audioEngine.playbackStateStream {
                guard !Task.isCancelled else { break }
                self?.playbackState = state
            }
        }
    }
    
    public func play(track: Track) {
        Task {
            do {
                try await audioEngine.play(track)
            } catch {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    public func pause() {
        Task {
            await audioEngine.pause()
        }
    }
    
    public func resume() {
        Task {
            await audioEngine.resume()
        }
    }
    
    public func stop() {
        Task {
            await audioEngine.stop()
        }
    }
    
    /// Explicit cleanup to prevent memory leaks and cancel the ongoing AsyncStream observation.
    public func cleanup() {
        stateObservationTask?.cancel()
        stateObservationTask = nil
    }
}
