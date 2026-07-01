// MARK: - Driver.swift
// UberClone – Models Layer
// SwiftData model representing a driver in the system.

import Foundation
import SwiftData

// MARK: - Driver

/// Persistent model that stores driver profile and real-time location data.
///
/// `@Model` automatically provides `PersistentModel` & `Observable`.
/// `currentLatitude` / `currentLongitude` are updated as the driver moves;
/// they are **not** the canonical location stream (see `LocationUpdate`).
@Model
final class Driver {

    /// Stable unique identifier for the driver.
    @Attribute(.unique) var id: UUID

    /// Full display name.
    var name: String

    /// Vehicle manufacturer (e.g. "Toyota").
    var vehicleMake: String

    /// Vehicle model name (e.g. "Camry").
    var vehicleModel: String

    /// License plate string (e.g. "ABC-1234").
    var licensePlate: String

    /// Aggregate star rating (1.0 – 5.0).
    var rating: Double

    /// Whether the driver is currently accepting trip requests.
    var isAvailable: Bool

    /// Last-known latitude of the driver's vehicle.
    var currentLatitude: Double

    /// Last-known longitude of the driver's vehicle.
    var currentLongitude: Double

    /// Memberwise initialiser – mirrors the stored properties.
    init(
        id: UUID = UUID(),
        name: String,
        vehicleMake: String,
        vehicleModel: String,
        licensePlate: String,
        rating: Double = 5.0,
        isAvailable: Bool = true,
        currentLatitude: Double = 0.0,
        currentLongitude: Double = 0.0
    ) {
        self.id = id
        self.name = name
        self.vehicleMake = vehicleMake
        self.vehicleModel = vehicleModel
        self.licensePlate = licensePlate
        self.rating = rating
        self.isAvailable = isAvailable
        self.currentLatitude = currentLatitude
        self.currentLongitude = currentLongitude
    }
}
