import Foundation
import AVFoundation

public enum PlaybackState: Sendable, Equatable {
    case playing
    case paused
    case buffering
    case stopped
}

public protocol AudioEngineProtocol: Sendable {
    var playbackStateStream: AsyncStream<PlaybackState> { get }
    func play(url: URL) async
    func pause() async
    func resume() async
    func stop() async
}

public actor AudioEngine: AudioEngineProtocol {
    private var player: AVPlayer?
    private var stateContinuation: AsyncStream<PlaybackState>.Continuation?
    private var timeControlStatusObservation: NSKeyValueObservation?

    public nonisolated let playbackStateStream: AsyncStream<PlaybackState>

    public init() {
        let (stream, continuation) = AsyncStream.makeStream(of: PlaybackState.self)
        self.playbackStateStream = stream
        self.stateContinuation = continuation

        setupAudioSession()
        continuation.yield(.stopped)
    }

    // Touches no actor state, so it can stay callable from the synchronous init.
    private nonisolated func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set audio session category: \(error)")
        }
    }

    public func play(url: URL) {
        let playerItem = AVPlayerItem(url: url)
        let newPlayer = AVPlayer(playerItem: playerItem)
        self.player = newPlayer

        setupObservations(for: newPlayer)

        newPlayer.play()
    }

    public func pause() {
        player?.pause()
    }

    public func resume() {
        player?.play()
    }

    public func stop() {
        timeControlStatusObservation?.invalidate()
        timeControlStatusObservation = nil
        player?.pause()
        player = nil
        stateContinuation?.yield(.stopped)
    }

    private func setupObservations(for player: AVPlayer) {
        timeControlStatusObservation?.invalidate()

        // Observers can capture the continuation since it's Sendable
        let continuation = self.stateContinuation

        timeControlStatusObservation = player.observe(\.timeControlStatus, options: [.new]) { observedPlayer, _ in
            switch observedPlayer.timeControlStatus {
            case .playing:
                continuation?.yield(.playing)
            case .paused:
                continuation?.yield(.paused)
            case .waitingToPlayAtSpecifiedRate:
                continuation?.yield(.buffering)
            @unknown default:
                continuation?.yield(.stopped)
            }
        }
    }

    deinit {
        timeControlStatusObservation?.invalidate()
        stateContinuation?.finish()
    }
}
