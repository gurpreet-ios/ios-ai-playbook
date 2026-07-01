// DriverMapViewModel.swift
// UberClone – ViewModels Layer
//
// Manages the map viewport and the collection of nearby drivers.
// The user's current location feeds into the driver-fetch radius,
// and all map-region state is owned here so the View remains a
// stateless renderer.

import MapKit
import SwiftUI

// MARK: - DriverMapViewModel

@MainActor @Observable
final class DriverMapViewModel {

    // MARK: Published State

    var nearbyDrivers: [Driver] = []
    var mapRegion: MKCoordinateRegion = .defaultRegion
    var selectedDriver: Driver?
    var isLoadingDrivers: Bool = false

    // MARK: Dependencies

    private let driverRepository: DriverRepositoryProtocol
    private let locationService: LocationService

    // MARK: Init

    init(driverRepository: DriverRepositoryProtocol, locationService: LocationService) {
        self.driverRepository = driverRepository
        self.locationService = locationService
    }

    // MARK: - Public Methods

    /// Fetches nearby drivers relative to the user's current
    /// location and updates the map region to center on the user.
    func loadNearbyDrivers() async {
        isLoadingDrivers = true

        do {
            let location = try await locationService.currentLocation()
            let coordinate = location.coordinate

            // Center the map on the user's position
            mapRegion = MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )

            let drivers = try await driverRepository.fetchNearbyDrivers(
                latitude: coordinate.latitude,
                longitude: coordinate.longitude
            )
            nearbyDrivers = drivers
        } catch is CancellationError {
            // Swallow — the view likely disappeared
        } catch {
            nearbyDrivers = []
        }

        isLoadingDrivers = false
    }

    /// Re-centers the map on the user's current location without
    /// reloading the driver list.
    func centerOnUser() async {
        do {
            let location = try await locationService.currentLocation()
            mapRegion = MKCoordinateRegion(
                center: location.coordinate,
                span: mapRegion.span  // preserve current zoom level
            )
        } catch {
            // Location unavailable — keep the existing region
        }
    }

    /// Selects a driver (e.g. for showing a detail card).
    func selectDriver(_ driver: Driver) {
        selectedDriver = driver
    }
}

// MARK: - MKCoordinateRegion + Default

extension MKCoordinateRegion {

    /// A sensible default region (San Francisco) used before the
    /// user's actual location is available.
    static let defaultRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
}
