import Foundation

// MARK: - Location Update

/// A lightweight, decodable model representing a driver's real-time
/// location update received over a WebSocket connection.
struct LocationUpdate: Codable, Sendable, Equatable {
    let driverId: String
    let latitude: Double
    let longitude: Double
    let heading: Double
    let timestamp: Date
}

// MARK: - WebSocket Connection State

/// The current state of the WebSocket connection.
enum WebSocketConnectionState: Sendable {
    case disconnected
    case connecting
    case connected
    case reconnecting(attempt: Int)
}

// MARK: - WebSocket Manager

/// An actor-isolated WebSocket manager that maintains a persistent
/// connection with automatic reconnection using exponential backoff.
///
/// Incoming messages are decoded as `LocationUpdate` and vended
/// through an `AsyncStream` for downstream consumers.
actor WebSocketManager {

    // MARK: - Constants

    /// Reconnection backoff configuration.
    private enum Backoff {
        static let initialDelay: TimeInterval = 1.0
        static let multiplier: Double = 2.0
        static let maxDelay: TimeInterval = 30.0
    }

    // MARK: - Properties

    private var webSocketTask: URLSessionWebSocketTask?
    private let session: URLSession

    /// The stream of decoded location updates from the server.
    nonisolated let locationUpdates: AsyncStream<LocationUpdate>
    private let updateContinuation: AsyncStream<LocationUpdate>.Continuation

    /// The current connection state.
    private(set) var connectionState: WebSocketConnectionState = .disconnected

    /// The URL to connect/reconnect to.
    private var serverURL: URL?

    /// Current reconnect attempt count (reset on successful connect).
    private var reconnectAttempt: Int = 0

    /// Whether the manager was intentionally disconnected.
    private var isIntentionalDisconnect: Bool = false

    private let decoder: JSONDecoder

    // MARK: - Initialization

    init(session: URLSession = .shared) {
        self.session = session

        let (stream, continuation) = AsyncStream<LocationUpdate>.makeStream()
        self.locationUpdates = stream
        self.updateContinuation = continuation

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    deinit {
        updateContinuation.finish()
    }

    // MARK: - Public API

    /// Opens a WebSocket connection to the given URL.
    /// If already connected, disconnects first.
    func connect(url: URL) {
        isIntentionalDisconnect = false
        serverURL = url
        reconnectAttempt = 0
        openConnection(to: url)
    }

    /// Cleanly disconnects the WebSocket. No auto-reconnect will be attempted.
    func disconnect() {
        isIntentionalDisconnect = true
        connectionState = .disconnected
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
    }

    /// Sends an `Encodable` message over the WebSocket as JSON text.
    ///
    /// - Parameter message: The value to encode and send.
    /// - Throws: If encoding fails or the WebSocket is not connected.
    func send(_ message: some Codable & Sendable) async throws {
        guard let task = webSocketTask else {
            throw WebSocketError.notConnected
        }

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(message)

        guard let text = String(data: data, encoding: .utf8) else {
            throw WebSocketError.encodingFailed
        }

        try await task.send(.string(text))
    }

    // MARK: - Private — Connection Lifecycle

    /// Creates and resumes a new WebSocket task.
    private func openConnection(to url: URL) {
        connectionState = reconnectAttempt == 0 ? .connecting : .reconnecting(attempt: reconnectAttempt)

        let task = session.webSocketTask(with: url)
        self.webSocketTask = task
        task.resume()

        connectionState = .connected
        reconnectAttempt = 0

        // Begin the receive loop.
        listenForMessages()
    }

    /// Continuously receives messages until the task closes or fails.
    private func listenForMessages() {
        guard let task = webSocketTask else { return }

        Task { [weak self] in
            do {
                let message = try await task.receive()
                guard let self else { return }
                await self.handleMessage(message)
                await self.listenForMessages()
            } catch {
                guard let self else { return }
                await self.handleDisconnection(error: error)
            }
        }
    }

    /// Dispatches a received WebSocket message to the appropriate handler.
    private func handleMessage(_ message: URLSessionWebSocketTask.Message) {
        let data: Data

        switch message {
        case .string(let text):
            guard let textData = text.data(using: .utf8) else { return }
            data = textData
        case .data(let binaryData):
            data = binaryData
        @unknown default:
            return
        }

        do {
            let update = try decoder.decode(LocationUpdate.self, from: data)
            updateContinuation.yield(update)
        } catch {
            print("[WebSocketManager] Failed to decode message: \(error.localizedDescription)")
        }
    }

    /// Handles an unexpected disconnection, scheduling a reconnect if appropriate.
    private func handleDisconnection(error: Error) {
        guard !isIntentionalDisconnect else { return }
        connectionState = .disconnected
        webSocketTask = nil

        scheduleReconnect()
    }

    // MARK: - Private — Reconnection

    /// Schedules a reconnection attempt with exponential backoff.
    private func scheduleReconnect() {
        guard let url = serverURL, !isIntentionalDisconnect else { return }

        reconnectAttempt += 1
        let delay = min(
            Backoff.initialDelay * pow(Backoff.multiplier, Double(reconnectAttempt - 1)),
            Backoff.maxDelay
        )

        connectionState = .reconnecting(attempt: reconnectAttempt)

        Task { [weak self] in
            try? await Task.sleep(for: .seconds(delay))

            guard let self else { return }
            guard await !self.isIntentionalDisconnect else { return }
            await self.openConnection(to: url)
        }
    }
}

// MARK: - WebSocket Error

/// Errors specific to the WebSocket manager.
enum WebSocketError: Error, Sendable, LocalizedError {
    case notConnected
    case encodingFailed

    var errorDescription: String? {
        switch self {
        case .notConnected:
            return "WebSocket is not connected."
        case .encodingFailed:
            return "Failed to encode message to JSON."
        }
    }
}
