// MARK: - Trip.swift
// UberClone – Models Layer
// SwiftData model representing a trip (ride) and its lifecycle.

import Foundation
import SwiftData

// MARK: - TripStatus

/// Discrete states a trip transitions through during its lifecycle.
enum TripStatus: String, Codable, Sendable, CaseIterable {
    /// Rider has submitted a trip request; awaiting driver match.
    case requested
    /// A driver has been matched and assigned to the trip.
    case driverAssigned
    /// The assigned driver has arrived at the pickup location.
    case driverArrived
    /// The ride is currently underway.
    case inProgress
    /// The ride has finished and the fare has been finalised.
    case completed
    /// The trip was cancelled by either party before completion.
    case cancelled
}

// MARK: - Trip

/// Persistent model tracking a single ride from request to resolution.
///
/// Coordinates are stored as individual `Double` properties rather than
/// a custom struct so that SwiftData can index and query them natively.
@Model
final class Trip {

    /// Stable unique identifier for the trip.
    @Attribute(.unique) var id: UUID

    /// Identifier of the rider who requested the trip.
    var riderId: UUID

    /// Identifier of the assigned driver, or `nil` while unmatched.
    var driverId: UUID?

    /// Current lifecycle state of the trip.
    var status: TripStatus

    /// Pickup location – latitude.
    var pickupLatitude: Double

    /// Pickup location – longitude.
    var pickupLongitude: Double

    /// Drop-off location – latitude.
    var dropoffLatitude: Double

    /// Drop-off location – longitude.
    var dropoffLongitude: Double

    /// Timestamp when the rider submitted the request.
    var requestedAt: Date

    /// Timestamp when the trip reached `.completed`, or `nil` if still active.
    var completedAt: Date?

    /// Calculated fare in the rider's local currency, or `nil` until finalised.
    var fare: Double?

    /// Memberwise initialiser – mirrors the stored properties.
    init(
        id: UUID = UUID(),
        riderId: UUID,
        driverId: UUID? = nil,
        status: TripStatus = .requested,
        pickupLatitude: Double,
        pickupLongitude: Double,
        dropoffLatitude: Double,
        dropoffLongitude: Double,
        requestedAt: Date = .now,
        completedAt: Date? = nil,
        fare: Double? = nil
    ) {
        self.id = id
        self.riderId = riderId
        self.driverId = driverId
        self.status = status
        self.pickupLatitude = pickupLatitude
        self.pickupLongitude = pickupLongitude
        self.dropoffLatitude = dropoffLatitude
        self.dropoffLongitude = dropoffLongitude
        self.requestedAt = requestedAt
        self.completedAt = completedAt
        self.fare = fare
    }
}
