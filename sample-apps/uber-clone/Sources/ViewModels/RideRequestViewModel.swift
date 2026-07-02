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

    var pickupText: String = ""
    var dropoffText: String = ""
    var pickupCoordinate: CLLocationCoordinate2D?
    var dropoffCoordinate: CLLocationCoordinate2D?
    var route: MKRoute?
    var cameraPosition: MapCameraPosition = .automatic
    /// Formatted fare string ready for display, or `nil` before estimation.
    var fareEstimate: String?
    var isLoading: Bool = false
    var errorMessage: String?

    // MARK: Derived State

    var canRequestRide: Bool {
        pickupCoordinate != nil && dropoffCoordinate != nil && !isLoading
    }

    // MARK: Dependencies (protocol-based)

    private let tripRepository: any TripRepositoryProtocol
    private let locationService: LocationService

    // MARK: Init

    init(tripRepository: any TripRepositoryProtocol, locationService: LocationService) {
        self.tripRepository = tripRepository
        self.locationService = locationService
    }

    // MARK: - Public Methods

    /// Entry point for the view's `.task`: starts location tracking and
    /// centers the map on the first fix, using it as the default pickup.
    func onAppear() async {
        await locationService.startTracking()

        for await location in locationService.locations {
            let coordinate = location.coordinate
            pickupCoordinate = coordinate
            cameraPosition = .region(
                MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                )
            )
            break // First fix is enough to anchor the screen.
        }
    }

    /// Fetches an estimated fare for the current pickup → dropoff pair.
    func estimateFare() async {
        guard let pickup = pickupCoordinate, let dropoff = dropoffCoordinate else {
            errorMessage = "Please set both pickup and dropoff locations."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let estimate = try await tripRepository.estimateFare(from: pickup, to: dropoff)
            fareEstimate = String(format: "%.2f %@", estimate.totalFare, estimate.currency)
        } catch is CancellationError {
            // Task was cancelled — don't surface as an error.
        } catch {
            errorMessage = "Fare estimate failed: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// Requests a new ride. Errors surface through `errorMessage` so the
    /// view can stay a plain `Task { await … }` call site.
    func requestRide() async {
        guard let pickup = pickupCoordinate, let dropoff = dropoffCoordinate else {
            errorMessage = "Both pickup and dropoff locations are required."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let response = try await tripRepository.requestTrip(
                from: pickup,
                to: dropoff,
                pickupAddress: pickupText,
                dropoffAddress: dropoffText
            )
            fareEstimate = String(format: "$%.2f", response.estimatedFare)
        } catch is CancellationError {
            // View disappeared mid-request.
        } catch {
            errorMessage = "Ride request failed: \(error.localizedDescription)"
        }

        isLoading = false
    }
}

// MARK: - Preview Support

#if DEBUG
extension RideRequestViewModel {
    static var preview: RideRequestViewModel {
        RideRequestViewModel(
            tripRepository: PreviewTripRepository(),
            locationService: LocationService()
        )
    }
}
#endif
