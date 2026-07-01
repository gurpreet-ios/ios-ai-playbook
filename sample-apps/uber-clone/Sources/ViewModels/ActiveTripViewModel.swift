// ActiveTripViewModel.swift
// UberClone – ViewModels Layer
//
// Drives the active-trip UI: loading the current trip, streaming
// driver location updates, and handling trip cancellation.
// The driver-tracking `Task` is explicitly managed to prevent leaks.

import MapKit
import SwiftUI

// MARK: - ActiveTripViewModel

@MainActor @Observable
final class ActiveTripViewModel {

    // MARK: Published State

    var trip: Trip?
    var driverLocation: CLLocationCoordinate2D?
    var driverHeading: Double = 0.0
    var estimatedArrival: String = "--"
    var tripStatus: TripStatus = .requested
    var showCancelConfirmation: Bool = false

    // MARK: Dependencies

    private let tripRepository: TripRepositoryProtocol
    private let driverRepository: DriverRepositoryProtocol

    // MARK: Task Management

    /// Retains the long-running driver-tracking task so it can be
    /// cancelled deterministically when the view disappears.
    private var trackingTask: Task<Void, Never>?

    // MARK: Init

    init(tripRepository: TripRepositoryProtocol, driverRepository: DriverRepositoryProtocol) {
        self.tripRepository = tripRepository
        self.driverRepository = driverRepository
    }

    // MARK: - Public Methods

    /// Loads the user's currently active trip from the repository
    /// and begins tracking the assigned driver (if any).
    func loadActiveTrip() async {
        do {
            let activeTrip = try await tripRepository.fetchActiveTrip()
            trip = activeTrip
            tripStatus = activeTrip.status

            if let driverId = activeTrip.driverId {
                await startTrackingDriver(driverId: driverId)
            }
        } catch is CancellationError {
            // Swallow cancellation silently
        } catch {
            tripStatus = .cancelled
        }
    }

    /// Starts a long-running task that streams location updates
    /// for the given driver. Any previously running tracking task
    /// is cancelled first to avoid duplicates.
    func startTrackingDriver(driverId: UUID) async {
        // Cancel any existing tracking before starting a new one
        stopTracking()

        trackingTask = Task { [weak self] in
            guard let self else { return }

            do {
                let stream = try await self.driverRepository.streamDriverLocation(driverId: driverId)

                for await update in stream {
                    // Bail out immediately if the task was cancelled
                    guard !Task.isCancelled else { break }

                    self.driverLocation = update.coordinate
                    self.driverHeading = update.heading
                    self.estimatedArrival = update.formattedETA
                    self.tripStatus = update.tripStatus
                }
            } catch is CancellationError {
                // Expected when stopTracking() is called
            } catch {
                // Non-fatal — the UI will show stale data until
                // the next successful update.
            }
        }
    }

    /// Cancels the current trip through the repository.
    func cancelTrip() async {
        guard let tripId = trip?.id else { return }

        do {
            try await tripRepository.cancelTrip(tripId: tripId)
            tripStatus = .cancelled
            trip = nil
            stopTracking()
        } catch {
            // Surface error — the trip was not cancelled server-side
            tripStatus = trip?.status ?? .requested
        }
    }

    /// Deterministically cancels the driver-tracking task.
    /// Safe to call multiple times.
    func stopTracking() {
        trackingTask?.cancel()
        trackingTask = nil
    }
}
