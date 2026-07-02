import Foundation
import Observation

@MainActor
@Observable
public final class PlayerViewModel {
    public var playbackState: PlaybackState = .stopped
    public private(set) var currentTrack: Track?
    public var errorMessage: String?

    public var isPlaying: Bool {
        playbackState == .playing
    }

    private var queue: [Track] = []
    private let audioEngine: any AudioEngineProtocol
    private var stateObservationTask: Task<Void, Never>?

    public init(audioEngine: any AudioEngineProtocol) {
        self.audioEngine = audioEngine
        startObserving()
    }

    private func startObserving() {
        stateObservationTask = Task { [weak self] in
            guard let stream = self?.audioEngine.playbackStateStream else { return }
            for await state in stream {
                guard !Task.isCancelled else { break }
                self?.playbackState = state
            }
        }
    }

    /// Starts playback of a track. Pass the surrounding list as `queue`
    /// so next/previous can navigate relative to it.
    public func play(track: Track, in queue: [Track] = []) async {
        currentTrack = track
        self.queue = queue.isEmpty ? [track] : queue
        await audioEngine.play(url: track.offlineFileURL ?? track.streamURL)
    }

    public func togglePlayPause() async {
        switch playbackState {
        case .playing, .buffering:
            await audioEngine.pause()
        case .paused:
            await audioEngine.resume()
        case .stopped:
            if let track = currentTrack {
                await audioEngine.play(url: track.offlineFileURL ?? track.streamURL)
            }
        }
    }

    public func playNext() async {
        guard let next = adjacentTrack(offset: 1) else { return }
        await play(track: next, in: queue)
    }

    public func playPrevious() async {
        guard let previous = adjacentTrack(offset: -1) else { return }
        await play(track: previous, in: queue)
    }

    public func stop() async {
        await audioEngine.stop()
        currentTrack = nil
    }

    private func adjacentTrack(offset: Int) -> Track? {
        guard let current = currentTrack,
              let index = queue.firstIndex(where: { $0.id == current.id }) else {
            return nil
        }
        let target = index + offset
        guard queue.indices.contains(target) else { return nil }
        return queue[target]
    }

    /// Explicit cleanup to prevent memory leaks and cancel the ongoing AsyncStream observation.
    public func cleanup() {
        stateObservationTask?.cancel()
        stateObservationTask = nil
    }
}
