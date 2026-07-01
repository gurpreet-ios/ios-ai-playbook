// MARK: - Rider.swift
// UberClone – Models Layer
// SwiftData model representing a rider (passenger) in the system.

import Foundation
import SwiftData

// MARK: - SavedAddress

/// A labeled geographic coordinate that a rider has bookmarked (e.g. "Home", "Work").
/// Embedded inside `Rider.savedAddresses` as a `Codable` collection.
struct SavedAddress: Codable, Sendable, Hashable {

    /// Human-readable label such as "Home" or "Work".
    var label: String

    /// Geographic latitude of the saved location.
    var latitude: Double

    /// Geographic longitude of the saved location.
    var longitude: Double
}

// MARK: - Rider

/// Persistent model that stores rider profile data.
///
/// `@Model` macro automatically synthesises `PersistentModel` & `Observable`
/// conformances required by SwiftData. The `savedAddresses` array is stored
/// as a transformable attribute because `SavedAddress` conforms to `Codable`.
@Model
final class Rider {

    /// Stable unique identifier for the rider.
    @Attribute(.unique) var id: UUID

    /// Full display name.
    var name: String

    /// Email address (used for account lookup).
    var email: String

    /// Phone number in E.164 format (e.g. "+14155551234").
    var phoneNumber: String

    /// Aggregate star rating (1.0 – 5.0).
    var rating: Double

    /// Bookmarked addresses the rider can quickly select as pickup / drop-off.
    var savedAddresses: [SavedAddress]

    /// Memberwise initialiser – mirrors the stored properties.
    init(
        id: UUID = UUID(),
        name: String,
        email: String,
        phoneNumber: String,
        rating: Double = 5.0,
        savedAddresses: [SavedAddress] = []
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.phoneNumber = phoneNumber
        self.rating = rating
        self.savedAddresses = savedAddresses
    }
}
