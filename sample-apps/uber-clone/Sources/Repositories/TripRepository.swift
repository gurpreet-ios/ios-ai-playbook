// MARK: - TripRepository.swift
// Repositories/TripRepository.swift
//
// Abstracts trip-related data access behind a protocol so that ViewModels
// never depend on networking primitives directly. The concrete implementation
// delegates to a `NetworkClient` for HTTP transport.

import CoreLocation
import Foundation

// MARK: - Protocol

/// All trip-related data operations.
/// ViewModels depend on this protocol — never on `NetworkClient` directly.
@MainActor
protocol TripRepositoryProtocol: Sendable {

    /// Request a new trip and return the server-assigned response.
    func requestTrip(
        from pickup: CLLocationCoordinate2D,
        to dropoff: CLLocationCoordinate2D,
        pickupAddress: String,
        dropoffAddress: String
    ) async throws -> TripResponseDTO

    /// Cancel an in-progress trip.
    func cancelTrip(tripId: UUID) async throws

    /// Return the rider's current active trip, if any.
    func fetchActiveTrip() async throws -> Trip?

    /// Return a fare estimate for a given origin → destination pair.
    func estimateFare(
        from pickup: CLLocationCoordinate2D,
        to dropoff: CLLocationCoordinate2D
    ) async throws -> FareEstimateDTO
}

// MARK: - Implementation

/// Concrete repository backed by a `NetworkClient`.
@MainActor
final class TripRepository: TripRepositoryProtocol {

    // MARK: - Dependencies

    private let networkClient: NetworkClient

    // MARK: - Init

    init(networkClient: NetworkClient) {
        self.networkClient = networkClient
    }

    // MARK: - TripRepositoryProtocol

    func requestTrip(
        from pickup: CLLocationCoordinate2D,
        to dropoff: CLLocationCoordinate2D,
        pickupAddress: String,
        dropoffAddress: String
    ) async throws -> TripResponseDTO {

        // Addresses are display-only today; the API keys off coordinates.
        let body = TripRequestDTO(
            pickupLatitude: pickup.latitude,
            pickupLongitude: pickup.longitude,
            dropoffLatitude: dropoff.latitude,
            dropoffLongitude: dropoff.longitude
        )

        // Pass the Encodable DTO itself — pre-encoding to Data would
        // double-encode the payload as a base64 string.
        let endpoint = Endpoint(
            path: "/api/v1/trips",
            method: .post,
            body: body
        )

        let response: TripResponseDTO = try await networkClient.request(endpoint)
        return response
    }

    func cancelTrip(tripId: UUID) async throws {
        let endpoint = Endpoint(
            path: "/api/v1/trips/\(tripId.uuidString)/cancel",
            method: .put
        )

        // Fire-and-forget style — server returns an empty JSON object.
        let _: EmptyResponse = try await networkClient.request(endpoint)
    }

    func fetchActiveTrip() async throws -> Trip? {
        let endpoint = Endpoint(path: "/api/v1/trips/active")

        // The server returns 200 with a trip payload, or 404 when none is active.
        do {
            let dto: TripDTO = try await networkClient.request(endpoint)
            return Self.makeTrip(from: dto)
        } catch APIError.httpError(let statusCode, _) where statusCode == 404 {
            return nil
        }
    }

    func estimateFare(
        from pickup: CLLocationCoordinate2D,
        to dropoff: CLLocationCoordinate2D
    ) async throws -> FareEstimateDTO {

        let endpoint = Endpoint(
            path: "/api/v1/trips/estimate",
            method: .get,
            queryItems: [
                URLQueryItem(name: "pickupLat", value: "\(pickup.latitude)"),
                URLQueryItem(name: "pickupLng", value: "\(pickup.longitude)"),
                URLQueryItem(name: "dropoffLat", value: "\(dropoff.latitude)"),
                URLQueryItem(name: "dropoffLng", value: "\(dropoff.longitude)"),
            ]
        )

        let estimate: FareEstimateDTO = try await networkClient.request(endpoint)
        return estimate
    }

    // MARK: - Mapping

    private static func makeTrip(from dto: TripDTO) -> Trip {
        Trip(
            id: dto.id,
            riderId: dto.riderId,
            driverId: dto.driverId,
            status: dto.status,
            pickupLatitude: dto.pickupLatitude,
            pickupLongitude: dto.pickupLongitude,
            dropoffLatitude: dto.dropoffLatitude,
            dropoffLongitude: dto.dropoffLongitude,
            requestedAt: dto.requestedAt,
            completedAt: dto.completedAt,
            fare: dto.fare
        )
    }
}

// MARK: - Supporting Types

/// Placeholder for endpoints that return no meaningful body.
struct EmptyResponse: Codable, Sendable {}
