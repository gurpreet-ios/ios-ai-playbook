import CoreLocation
import Foundation

// MARK: - Location Service

/// An actor-isolated location service that wraps `CLLocationManager` and
/// vends continuous location updates via `AsyncStream`.
///
/// Because actors cannot directly conform to `@objc` protocols,
/// a nested `Delegate` class bridges `CLLocationManagerDelegate` callbacks
/// back into the actor's isolated state through continuations.
actor LocationService {

    // MARK: - Properties

    private let manager: CLLocationManager
    private let delegate: Delegate

    /// A continuous stream of the user's location.
    /// Consumers can `for await` over this to receive live updates.
    nonisolated let locations: AsyncStream<CLLocation>
    private let locationContinuation: AsyncStream<CLLocation>.Continuation

    /// A stream that emits whenever the authorization status changes.
    nonisolated let authorizationUpdates: AsyncStream<CLAuthorizationStatus>
    private let authorizationContinuation: AsyncStream<CLAuthorizationStatus>.Continuation

    /// The most recent location received, or `nil` if none yet.
    private(set) var currentLocation: CLLocation?

    // MARK: - Initialization

    init() {
        let manager = CLLocationManager()
        self.manager = manager

        // Build the location stream + continuation pair.
        let (locationStream, locationContinuation) = AsyncStream<CLLocation>.makeStream()
        self.locations = locationStream
        self.locationContinuation = locationContinuation

        // Build the authorization stream + continuation pair.
        let (authStream, authContinuation) = AsyncStream<CLAuthorizationStatus>.makeStream()
        self.authorizationUpdates = authStream
        self.authorizationContinuation = authContinuation

        // Create the delegate that bridges CLLocationManagerDelegate → continuations.
        let delegate = Delegate(
            locationContinuation: locationContinuation,
            authorizationContinuation: authContinuation
        )
        self.delegate = delegate

        manager.delegate = delegate
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 10 // meters
        manager.allowsBackgroundLocationUpdates = false
    }

    deinit {
        locationContinuation.finish()
        authorizationContinuation.finish()
    }

    // MARK: - Public API

    /// Requests when-in-use location permission from the user.
    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    /// Begins emitting location updates on the `locations` stream.
    /// Automatically requests permission if not yet determined.
    func startTracking() {
        let status = manager.authorizationStatus

        switch status {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
        case .denied, .restricted:
            // Cannot track — the authorization stream will have
            // already emitted the denied/restricted status.
            break
        @unknown default:
            break
        }
    }

    /// Stops emitting location updates.
    func stopTracking() {
        manager.stopUpdatingLocation()
    }

    /// Called by the delegate to update actor-isolated state.
    fileprivate func didUpdate(location: CLLocation) {
        currentLocation = location
    }
}

// MARK: - CLLocationManagerDelegate Bridge

extension LocationService {

    /// A `Sendable` delegate class that bridges `CLLocationManagerDelegate`
    /// callbacks into `AsyncStream` continuations.
    ///
    /// This is necessary because Swift actors cannot directly conform to
    /// `@objc` protocols that require class inheritance.
    final class Delegate: NSObject, CLLocationManagerDelegate, Sendable {

        private let locationContinuation: AsyncStream<CLLocation>.Continuation
        private let authorizationContinuation: AsyncStream<CLAuthorizationStatus>.Continuation

        init(
            locationContinuation: AsyncStream<CLLocation>.Continuation,
            authorizationContinuation: AsyncStream<CLAuthorizationStatus>.Continuation
        ) {
            self.locationContinuation = locationContinuation
            self.authorizationContinuation = authorizationContinuation
        }

        // MARK: - Location Updates

        func locationManager(
            _ manager: CLLocationManager,
            didUpdateLocations locations: [CLLocation]
        ) {
            guard let latest = locations.last else { return }
            locationContinuation.yield(latest)
        }

        func locationManager(
            _ manager: CLLocationManager,
            didFailWithError error: Error
        ) {
            // Log or handle error. We don't terminate the stream
            // because location errors can be transient (e.g., no GPS fix).
            print("[LocationService] Location error: \(error.localizedDescription)")
        }

        // MARK: - Authorization Changes

        func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
            let status = manager.authorizationStatus
            authorizationContinuation.yield(status)

            // Auto-start tracking when authorized.
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                manager.startUpdatingLocation()
            }
        }
    }
}
