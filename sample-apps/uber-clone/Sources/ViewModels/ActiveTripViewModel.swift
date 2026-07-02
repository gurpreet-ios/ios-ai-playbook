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
    var driverLocation: LocationUpdate?
    var cameraPosition: MapCameraPosition = .automatic
    var route: MKRoute?
    var tripStatus: TripStatus = .requested
    var driverName: String = "--"
    var vehicleInfo: String = "--"
    var eta: String = "--"

    // MARK: Derived State

    var pickupCoordinate: CLLocationCoordinate2D? {
        trip.map { CLLocationCoordinate2D(latitude: $0.pickupLatitude, longitude: $0.pickupLongitude) }
    }

    var dropoffCoordinate: CLLocationCoordinate2D? {
        trip.map { CLLocationCoordinate2D(latitude: $0.dropoffLatitude, longitude: $0.dropoffLongitude) }
    }

    /// Cancellation is only offered before the ride is underway.
    var canCancel: Bool {
        tripStatus == .driverAssigned || tripStatus == .driverArrived
    }

    // MARK: Dependencies

    private let tripRepository: any TripRepositoryProtocol
    private let driverRepository: any DriverRepositoryProtocol

    // MARK: Task Management

    /// Retains the long-running driver-tracking task so it can be
    /// cancelled deterministically when the view disappears.
    private var trackingTask: Task<Void, Never>?

    // MARK: Init

    init(tripRepository: any TripRepositoryProtocol, driverRepository: any DriverRepositoryProtocol) {
        self.tripRepository = tripRepository
        self.driverRepository = driverRepository
    }

    // MARK: - Public Methods

    /// Entry point for the view's `.task`: loads the active trip and
    /// begins tracking the assigned driver (if any).
    func startTracking() async {
        do {
            guard let activeTrip = try await tripRepository.fetchActiveTrip() else { return }
            trip = activeTrip
            tripStatus = activeTrip.status

            if let driverId = activeTrip.driverId {
                let driver = try await driverRepository.getDriver(id: driverId)
                driverName = driver.name
                vehicleInfo = "\(driver.vehicleMake) \(driver.vehicleModel) · \(driver.licensePlate)"
                startTrackingDriver(driverId: driverId)
            }
        } catch is CancellationError {
            // Expected when the view disappears mid-load.
        } catch {
            // Non-fatal: the UI keeps its last-known state.
        }
    }

    /// Starts a long-running task that streams location updates for the
    /// given driver. Any previous tracking task is cancelled first.
    func startTrackingDriver(driverId: UUID) {
        stopTracking()

        trackingTask = Task { [weak self] in
            guard let self else { return }

            let stream = self.driverRepository.streamDriverLocation(driverId: driverId)
            for await update in stream {
                guard !Task.isCancelled else { break }
                self.driverLocation = update
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
            // The trip was not cancelled server-side — restore the status.
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

// MARK: - Preview Support

#if DEBUG
/// Stub repositories shared by the SwiftUI previews.
struct PreviewTripRepository: TripRepositoryProtocol {
    func requestTrip(
        from pickup: CLLocationCoordinate2D,
        to dropoff: CLLocationCoordinate2D,
        pickupAddress: String,
        dropoffAddress: String
    ) async throws -> TripResponseDTO {
        TripResponseDTO(tripId: UUID(), estimatedFare: 18.50, estimatedArrivalMinutes: 4)
    }

    func cancelTrip(tripId: UUID) async throws {}

    func fetchActiveTrip() async throws -> Trip? {
        Trip(
            riderId: UUID(),
            driverId: UUID(),
            status: .driverAssigned,
            pickupLatitude: 37.7749,
            pickupLongitude: -122.4194,
            dropoffLatitude: 37.7849,
            dropoffLongitude: -122.4094
        )
    }

    func estimateFare(
        from pickup: CLLocationCoordinate2D,
        to dropoff: CLLocationCoordinate2D
    ) async throws -> FareEstimateDTO {
        FareEstimateDTO(baseFare: 3.0, distanceFare: 10.0, timeFare: 5.5, totalFare: 18.5, currency: "USD")
    }
}

struct PreviewDriverRepository: DriverRepositoryProtocol {
    func fetchNearbyDrivers(latitude: Double, longitude: Double) async throws -> [Driver] { [] }

    func getDriver(id: UUID) async throws -> Driver {
        Driver(
            id: id,
            name: "Alex Johnson",
            vehicleMake: "Tesla",
            vehicleModel: "Model 3",
            licensePlate: "4RKT 829"
        )
    }

    func streamDriverLocation(driverId: UUID) -> AsyncStream<LocationUpdate> {
        AsyncStream { $0.finish() }
    }
}

extension ActiveTripViewModel {
    static var preview: ActiveTripViewModel {
        ActiveTripViewModel(
            tripRepository: PreviewTripRepository(),
            driverRepository: PreviewDriverRepository()
        )
    }
}
#endif
