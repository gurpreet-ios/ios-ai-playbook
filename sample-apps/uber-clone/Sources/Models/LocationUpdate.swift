// MARK: - LocationUpdate.swift
// UberClone – Models Layer
// Lightweight value type for real-time driver location telemetry.

import Foundation
import CoreLocation

// MARK: - LocationUpdate

/// An ephemeral snapshot of a driver's position at a moment in time.
///
/// This is a plain `struct` — **not** a SwiftData `@Model` — because location
/// updates are transient events streamed over a WebSocket or push channel.
/// They are consumed by the UI and discarded; only the latest value matters.
struct LocationUpdate: Codable, Sendable, Hashable {

    /// Identifier of the driver whose location is being reported.
    var driverId: UUID

    /// Geographic latitude in decimal degrees (WGS 84).
    var latitude: Double

    /// Geographic longitude in decimal degrees (WGS 84).
    var longitude: Double

    /// Compass heading in degrees (0 = true north, clockwise).
    var heading: Double

    /// Instantaneous speed in metres per second.
    var speed: Double

    /// Wall-clock time when the reading was captured on the device.
    var timestamp: Date
}

extension LocationUpdate {
    /// Convenience bridge for MapKit consumers.
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
