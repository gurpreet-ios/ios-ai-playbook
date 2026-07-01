// MARK: - APIModels.swift
// UberClone – Models Layer
// Data Transfer Objects (DTOs) for network request / response payloads.

import Foundation

// MARK: - TripRequestDTO

/// Outbound payload sent when the rider requests a new trip.
struct TripRequestDTO: Codable, Sendable, Hashable {

    /// Pickup location – latitude.
    var pickupLatitude: Double

    /// Pickup location – longitude.
    var pickupLongitude: Double

    /// Drop-off location – latitude.
    var dropoffLatitude: Double

    /// Drop-off location – longitude.
    var dropoffLongitude: Double
}

// MARK: - TripResponseDTO

/// Inbound payload returned by the backend after a trip is created.
struct TripResponseDTO: Codable, Sendable, Hashable {

    /// Server-assigned trip identifier.
    var tripId: UUID

    /// Estimated total fare in the rider's local currency.
    var estimatedFare: Double

    /// Estimated minutes until the assigned driver arrives at pickup.
    var estimatedArrivalMinutes: Int
}

// MARK: - FareEstimateDTO

/// Breakdown of a fare estimate returned before the rider confirms a trip.
struct FareEstimateDTO: Codable, Sendable, Hashable {

    /// Fixed base charge applied to every trip.
    var baseFare: Double

    /// Variable charge proportional to trip distance.
    var distanceFare: Double

    /// Variable charge proportional to estimated trip duration.
    var timeFare: Double

    /// Sum of all fare components (baseFare + distanceFare + timeFare + surcharges).
    var totalFare: Double

    /// ISO 4217 currency code (e.g. "USD", "INR").
    var currency: String
}
