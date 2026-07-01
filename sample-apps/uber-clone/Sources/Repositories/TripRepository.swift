// MARK: - TripRepository.swift
// Repositories/TripRepository.swift
//
// Abstracts trip-related data access behind a protocol so that ViewModels
// never depend on networking primitives directly. The concrete implementation
// delegates to a `NetworkClient` for HTTP transport.

import Foundation
import SwiftData

// MARK: - Protocol

/// All trip-related data operations.
/// ViewModels depend on this protocol — never on `NetworkClient` directly.
protocol TripRepositoryProtocol: Sendable {

    /// Request a new trip and return the server-assigned response.
    func requestTrip(
        pickupLat: Double,
        pickupLng: Double,
        dropoffLat: Double,
        dropoffLng: Double
    ) async throws -> TripResponseDTO

    /// Cancel an in-progress trip.
    func cancelTrip(tripId: UUID) async throws

    /// Return the rider's current active trip, if any.
    func getActiveTrip() async throws -> Trip?

    /// Return a fare estimate for a given origin → destination pair.
    func getFareEstimate(
        pickupLat: Double,
        pickupLng: Double,
        dropoffLat: Double,
        dropoffLng: Double
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
        pickupLat: Double,
        pickupLng: Double,
        dropoffLat: Double,
        dropoffLng: Double
    ) async throws -> TripResponseDTO {

        let body = TripRequestDTO(
            pickupLatitude: pickupLat,
            pickupLongitude: pickupLng,
            dropoffLatitude: dropoffLat,
            dropoffLongitude: dropoffLng
        )

        let endpoint = Endpoint(
            path: "/api/v1/trips",
            method: .post,
            body: try JSONEncoder().encode(body)
        )

        let response: TripResponseDTO = try await networkClient.request(endpoint)
        return response
    }

    func cancelTrip(tripId: UUID) async throws {
        let endpoint = Endpoint(
            path: "/api/v1/trips/\(tripId.uuidString)/cancel",
            method: .put,
            body: nil
        )

        // Fire-and-forget style — server returns 204 No Content.
        let _: EmptyResponse = try await networkClient.request(endpoint)
    }

    func getActiveTrip() async throws -> Trip? {
        let endpoint = Endpoint(
            path: "/api/v1/trips/active",
            method: .get,
            body: nil
        )

        // The server returns 200 with a Trip payload, or 404 when none is active.
        do {
            let trip: Trip = try await networkClient.request(endpoint)
            return trip
        } catch let error as NetworkError where error == .notFound {
            return nil
        }
    }

    func getFareEstimate(
        pickupLat: Double,
        pickupLng: Double,
        dropoffLat: Double,
        dropoffLng: Double
    ) async throws -> FareEstimateDTO {

        let queryItems = [
            "pickupLat": "\(pickupLat)",
            "pickupLng": "\(pickupLng)",
            "dropoffLat": "\(dropoffLat)",
            "dropoffLng": "\(dropoffLng)"
        ]

        let endpoint = Endpoint(
            path: "/api/v1/trips/estimate",
            method: .get,
            queryItems: queryItems,
            body: nil
        )

        let estimate: FareEstimateDTO = try await networkClient.request(endpoint)
        return estimate
    }
}

// MARK: - Supporting Types

/// Placeholder for endpoints that return no body (e.g. 204 No Content).
struct EmptyResponse: Codable, Sendable {}

/// Typed networking errors used within the repository layer.
enum NetworkError: Error, Equatable, Sendable {
    case notFound
    case unauthorized
    case serverError(statusCode: Int)
    case decodingFailed
    case unknown
}
