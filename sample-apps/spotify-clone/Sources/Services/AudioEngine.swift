import Foundation
import AVFoundation

public enum PlaybackState: Sendable {
    case playing
    case paused
    case buffering
    case stopped
}

public actor AudioEngine {
    private var player: AVPlayer?
    private var continuation: AsyncStream<PlaybackState>.Continuation?
    public let stateStream: AsyncStream<PlaybackState>
    
    public init() {
        let (stream, continuation) = AsyncStream.makeStream(of: PlaybackState.self)
        self.stateStream = stream
        self.continuation = continuation
        self.continuation?.yield(.stopped)
        
        setupAudioSession()
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
        let item = AVPlayerItem(url: url)
        self.player = AVPlayer(playerItem: item)
        self.player?.play()
        self.continuation?.yield(.playing)
    }
    
    public func pause() {
        self.player?.pause()
        self.continuation?.yield(.paused)
    }
    
    public func resume() {
        self.player?.play()
        self.continuation?.yield(.playing)
    }
    
    deinit {
        continuation?.finish()
    }
}
