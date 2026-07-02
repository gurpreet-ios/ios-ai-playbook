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
@MainActor
protocol DriverRepositoryProtocol: Sendable {

    /// Fetch drivers near a coordinate. The search radius is a repository
    /// policy, not a caller concern.
    func fetchNearbyDrivers(latitude: Double, longitude: Double) async throws -> [Driver]

    /// Fetch a single driver by identifier.
    func getDriver(id: UUID) async throws -> Driver

    /// Open a real-time stream of location updates for a specific driver.
    /// The stream emits until the WebSocket closes or the consumer cancels.
    func streamDriverLocation(driverId: UUID) -> AsyncStream<LocationUpdate>
}

// MARK: - Implementation

/// Concrete repository backed by `NetworkClient` (REST) and
/// `WebSocketManager` (real-time tracking).
@MainActor
final class DriverRepository: DriverRepositoryProtocol {

    // MARK: - Dependencies

    private let networkClient: NetworkClient
    private let webSocketManager: WebSocketManager

    /// Default nearby-search radius in kilometres.
    private let searchRadiusKm: Double = 5.0

    // MARK: - Init

    init(networkClient: NetworkClient, webSocketManager: WebSocketManager) {
        self.networkClient = networkClient
        self.webSocketManager = webSocketManager
    }

    // MARK: - DriverRepositoryProtocol

    func fetchNearbyDrivers(latitude: Double, longitude: Double) async throws -> [Driver] {
        let endpoint = Endpoint(
            path: "/api/v1/drivers/nearby",
            method: .get,
            queryItems: [
                URLQueryItem(name: "lat", value: "\(latitude)"),
                URLQueryItem(name: "lng", value: "\(longitude)"),
                URLQueryItem(name: "radiusKm", value: "\(searchRadiusKm)"),
            ]
        )

        // DTOs cross the network boundary; @Model types never do.
        let dtos: [DriverDTO] = try await networkClient.request(endpoint)
        return dtos.map(Self.makeDriver)
    }

    func getDriver(id: UUID) async throws -> Driver {
        let endpoint = Endpoint(path: "/api/v1/drivers/\(id.uuidString)")
        let dto: DriverDTO = try await networkClient.request(endpoint)
        return Self.makeDriver(from: dto)
    }

    func streamDriverLocation(driverId: UUID) -> AsyncStream<LocationUpdate> {
        // The socket vends one firehose stream; filter it for the target
        // driver. (Single-consumer: one active tracking screen at a time.)
        let upstream = webSocketManager.locationUpdates

        return AsyncStream<LocationUpdate> { continuation in
            let task = Task {
                for await update in upstream where update.driverId == driverId {
                    continuation.yield(update)
                }
                continuation.finish()
            }

            continuation.onTermination = { @Sendable _ in
                task.cancel()
            }
        }
    }

    // MARK: - Mapping

    private static func makeDriver(from dto: DriverDTO) -> Driver {
        Driver(
            id: dto.id,
            name: dto.name,
            vehicleMake: dto.vehicleMake,
            vehicleModel: dto.vehicleModel,
            licensePlate: dto.licensePlate,
            rating: dto.rating,
            isAvailable: dto.isAvailable,
            currentLatitude: dto.currentLatitude,
            currentLongitude: dto.currentLongitude
        )
    }
}
