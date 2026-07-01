// MARK: - DriverRepository.swift
// Repositories/DriverRepository.swift
//
// Abstracts driver-related data access — nearby lookups, individual fetch,
// and real-time location tracking — behind a protocol. ViewModels depend
// only on `DriverRepositoryProtocol`; they never touch `NetworkClient` or
// `WebSocketManager` directly.

import Foundation

// MARK: - Protocol

/// All driver-related data operations.
/// ViewModels depend on this protocol — never on networking types directly.
protocol DriverRepositoryProtocol: Sendable {

    /// Fetch drivers near a coordinate within a given radius.
    func getNearbyDrivers(
        latitude: Double,
        longitude: Double,
        radiusKm: Double
    ) async throws -> [Driver]

    /// Fetch a single driver by identifier.
    func getDriver(id: UUID) async throws -> Driver

    /// Open a real-time stream of location updates for a specific driver.
    /// The returned `AsyncStream` emits `LocationUpdate` values until the
    /// WebSocket connection is closed or the driver goes offline.
    func trackDriver(id: UUID) -> AsyncStream<LocationUpdate>
}

// MARK: - Implementation

/// Concrete repository backed by `NetworkClient` (REST) and
/// `WebSocketManager` (real-time tracking).
@MainActor
final class DriverRepository: DriverRepositoryProtocol {

    // MARK: - Dependencies

    private let networkClient: NetworkClient
    private let webSocketManager: WebSocketManager

    // MARK: - Init

    init(networkClient: NetworkClient, webSocketManager: WebSocketManager) {
        self.networkClient = networkClient
        self.webSocketManager = webSocketManager
    }

    // MARK: - DriverRepositoryProtocol

    func getNearbyDrivers(
        latitude: Double,
        longitude: Double,
        radiusKm: Double
    ) async throws -> [Driver] {

        let queryItems = [
            "lat": "\(latitude)",
            "lng": "\(longitude)",
            "radiusKm": "\(radiusKm)"
        ]

        let endpoint = Endpoint(
            path: "/api/v1/drivers/nearby",
            method: .get,
            queryItems: queryItems,
            body: nil
        )

        let drivers: [Driver] = try await networkClient.request(endpoint)
        return drivers
    }

    func getDriver(id: UUID) async throws -> Driver {
        let endpoint = Endpoint(
            path: "/api/v1/drivers/\(id.uuidString)",
            method: .get,
            body: nil
        )

        let driver: Driver = try await networkClient.request(endpoint)
        return driver
    }

    func trackDriver(id: UUID) -> AsyncStream<LocationUpdate> {
        // Delegate to WebSocketManager and filter for the target driver.
        let upstream: AsyncStream<LocationUpdate> = webSocketManager
            .locationUpdates(forChannel: "driver:\(id.uuidString)")

        return AsyncStream<LocationUpdate> { continuation in
            let task = Task { [upstream] in
                for await update in upstream {
                    // Only yield updates that match the requested driver.
                    if update.driverId == id {
                        continuation.yield(update)
                    }
                }
                continuation.finish()
            }

            continuation.onTermination = { @Sendable _ in
                task.cancel()
            }
        }
    }
}

// MARK: - WebSocketManager Protocol

/// Minimal contract for a WebSocket transport.
/// The Services layer provides the concrete implementation.
protocol WebSocketManager: Sendable {
    /// Returns an `AsyncStream` of location updates for the given channel key.
    func locationUpdates(forChannel channel: String) -> AsyncStream<LocationUpdate>
}
