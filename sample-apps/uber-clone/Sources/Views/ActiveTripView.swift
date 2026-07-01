// ActiveTripView.swift
// UberClone – Views Layer
// iOS 17+ · Swift 6 · SwiftUI + MapKit

import SwiftUI
import MapKit

// MARK: - ActiveTripView

/// Displays the live trip screen once a ride has been confirmed.
///
/// The map tracks the driver's real-time position using a custom
/// `DriverAnnotationView`. A `TripStatusCard` at the bottom reflects
/// the current trip phase. Cancellation is allowed only during the
/// `.driverAssigned` and `.driverArrived` states.
struct ActiveTripView: View {

    // MARK: - State

    @State private var viewModel: ActiveTripViewModel

    @State private var showCancelConfirmation = false

    // MARK: - Init

    init(viewModel: ActiveTripViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .bottom) {
            mapLayer
            statusOverlay
        }
        .ignoresSafeArea(edges: .top)
        .confirmationDialog(
            "Cancel Ride",
            isPresented: $showCancelConfirmation,
            titleVisibility: .visible
        ) {
            Button("Cancel Ride", role: .destructive) {
                Task { await viewModel.cancelTrip() }
            }
            Button("Keep Ride", role: .cancel) {}
        } message: {
            Text("Are you sure you want to cancel this ride? A cancellation fee may apply.")
        }
        .task {
            await viewModel.startTracking()
        }
    }
}

// MARK: - Sub-views

private extension ActiveTripView {

    // MARK: Map

    var mapLayer: some View {
        Map(position: $viewModel.cameraPosition) {
            // Driver annotation
            if let driverLocation = viewModel.driverLocation {
                Annotation("Driver", coordinate: driverLocation.coordinate) {
                    DriverAnnotationView(heading: driverLocation.heading)
                }
            }

            // Pickup marker
            if let pickup = viewModel.pickupCoordinate {
                Annotation("Pickup", coordinate: pickup) {
                    Image(systemName: "circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }

            // Dropoff marker
            if let dropoff = viewModel.dropoffCoordinate {
                Annotation("Dropoff", coordinate: dropoff) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.red)
                }
            }

            // Route polyline
            if let route = viewModel.route {
                MapPolyline(route.polyline)
                    .stroke(.blue, lineWidth: 5)
            }
        }
        .mapControls {
            MapCompass()
        }
    }

    // MARK: Status Overlay

    var statusOverlay: some View {
        VStack(spacing: 12) {
            TripStatusCard(
                tripStatus: viewModel.tripStatus,
                driverName: viewModel.driverName,
                vehicleInfo: viewModel.vehicleInfo,
                eta: viewModel.eta
            )

            if viewModel.canCancel {
                cancelButton
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 24)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.tripStatus)
    }

    // MARK: Cancel Button

    var cancelButton: some View {
        Button(role: .destructive) {
            showCancelConfirmation = true
        } label: {
            HStack {
                Image(systemName: "xmark.circle.fill")
                Text("Cancel Ride")
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 48)
        }
        .buttonStyle(.bordered)
        .tint(.red)
        .buttonBorderShape(.roundedRectangle(radius: 12))
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Driver Assigned") {
    ActiveTripView(viewModel: .preview)
}
#endif
