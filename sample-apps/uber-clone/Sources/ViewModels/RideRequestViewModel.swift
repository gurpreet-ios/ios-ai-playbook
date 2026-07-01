// RideRequestViewModel.swift
// UberClone – ViewModels Layer
//
// Manages the ride-request flow: location input, fare estimation,
// and trip creation. Relies on protocol-based DI so the View
// never touches networking directly.

import MapKit
import SwiftUI

// MARK: - RideRequestViewModel

@MainActor @Observable
final class RideRequestViewModel {

    // MARK: Published State

    var pickupAddress: String = ""
    var dropoffAddress: String = ""
    var pickupCoordinate: CLLocationCoordinate2D?
    var dropoffCoordinate: CLLocationCoordinate2D?
    var fareEstimate: FareEstimateDTO?
    var isLoading: Bool = false
    var errorMessage: String?
    var currentUserLocation: CLLocationCoordinate2D?

    // MARK: Dependencies (protocol-based)

    private let tripRepository: TripRepositoryProtocol
    private let locationService: LocationService

    // MARK: Init

    init(tripRepository: TripRepositoryProtocol, locationService: LocationService) {
        self.tripRepository = tripRepository
        self.locationService = locationService
    }

    // MARK: - Public Methods

    /// Retrieves the device's current location via `LocationService` and
    /// assigns it as the pickup coordinate.
    func fetchCurrentLocation() async {
        isLoading = true
        errorMessage = nil

        do {
            let location = try await locationService.currentLocation()
            currentUserLocation = location.coordinate
            pickupCoordinate = location.coordinate
        } catch {
            errorMessage = "Unable to determine your location: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// Calls the trip repository to fetch an estimated fare for the
    /// current pickup → dropoff route.
    func estimateFare() async {
        guard let pickup = pickupCoordinate,
              let dropoff = dropoffCoordinate else {
            errorMessage = "Please set both pickup and dropoff locations."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let estimate = try await tripRepository.estimateFare(
                from: pickup,
                to: dropoff
            )
            fareEstimate = estimate
        } catch is CancellationError {
            // Task was cancelled — don't surface as an error
        } catch {
            errorMessage = "Fare estimate failed: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// Requests a new ride and returns the server response DTO.
    /// - Throws: Re-throws repository errors so the caller can
    ///   decide how to handle them (e.g. navigate or show alert).
    func requestRide() async throws -> TripResponseDTO {
        guard let pickup = pickupCoordinate,
              let dropoff = dropoffCoordinate else {
            throw RideRequestError.missingLocations
        }

        isLoading = true
        errorMessage = nil

        do {
            let response = try await tripRepository.requestTrip(
                from: pickup,
                to: dropoff,
                pickupAddress: pickupAddress,
                dropoffAddress: dropoffAddress
            )
            isLoading = false
            return response
        } catch {
            isLoading = false
            errorMessage = "Ride request failed: \(error.localizedDescription)"
            throw error
        }
    }
}

// MARK: - RideRequestError

enum RideRequestError: LocalizedError {
    case missingLocations

    var errorDescription: String? {
        switch self {
        case .missingLocations:
            return "Both pickup and dropoff locations are required."
        }
    }
}
