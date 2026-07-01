// RideRequestView.swift
// UberClone – Views Layer
// iOS 17+ · Swift 6 · SwiftUI + MapKit

import SwiftUI
import MapKit

// MARK: - RideRequestView

/// Primary screen where the rider enters pickup/dropoff addresses,
/// sees a fare estimate, and requests a ride.
///
/// All business logic lives in `RideRequestViewModel`; this view is
/// a pure presentation layer that binds to observable state.
struct RideRequestView: View {

    // MARK: - State

    @State private var viewModel: RideRequestViewModel

    /// Controls the vertical offset of the bottom sheet.
    @State private var sheetOffset: CGFloat = 0

    // MARK: - Init

    init(viewModel: RideRequestViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .bottom) {
            mapLayer
            bottomSheet
        }
        .ignoresSafeArea(edges: .top)
        .alert(
            "Error",
            isPresented: alertBinding,
            actions: { Button("OK", role: .cancel) {} },
            message: { Text(viewModel.errorMessage ?? "") }
        )
        .task {
            await viewModel.onAppear()
        }
    }
}

// MARK: - Sub-views

private extension RideRequestView {

    // MARK: Map

    var mapLayer: some View {
        Map(position: $viewModel.cameraPosition) {
            // Pickup pin
            if let pickup = viewModel.pickupCoordinate {
                Annotation("Pickup", coordinate: pickup) {
                    Image(systemName: "circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }

            // Dropoff pin
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
            MapUserLocationButton()
            MapCompass()
        }
    }

    // MARK: Bottom Sheet

    var bottomSheet: some View {
        VStack(spacing: 16) {
            // Drag handle
            Capsule()
                .fill(Color.secondary.opacity(0.4))
                .frame(width: 40, height: 5)
                .padding(.top, 8)

            // Address fields
            AddressSearchBar(
                text: $viewModel.pickupText,
                placeholder: "Pickup location",
                icon: "circle.fill"
            )

            AddressSearchBar(
                text: $viewModel.dropoffText,
                placeholder: "Where to?",
                icon: "mappin.circle.fill"
            )

            // Fare estimate
            if let fare = viewModel.fareEstimate {
                fareEstimateRow(fare)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            // Request button
            requestButton
                .padding(.bottom, 8)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.15), radius: 12, y: -4)
        )
        .offset(y: sheetOffset)
        .gesture(dragGesture)
        .animation(.spring(response: 0.45, dampingFraction: 0.8), value: sheetOffset)
    }

    // MARK: Fare Estimate

    func fareEstimateRow(_ fare: String) -> some View {
        HStack {
            Image(systemName: "banknote")
                .foregroundStyle(.green)
            Text("Estimated fare")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(fare)
                .font(.headline)
                .fontDesign(.rounded)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }

    // MARK: Request Button

    var requestButton: some View {
        Button {
            Task { await viewModel.requestRide() }
        } label: {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Request Ride")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.roundedRectangle(radius: 14))
        .controlSize(.large)
        .disabled(viewModel.isLoading || !viewModel.canRequestRide)
    }
}

// MARK: - Helpers

private extension RideRequestView {

    /// Binding that converts the optional `errorMessage` into a `Bool` for the alert.
    var alertBinding: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )
    }

    /// Interactive drag gesture for the bottom sheet.
    var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                let translation = value.translation.height
                sheetOffset = max(0, translation)
            }
            .onEnded { value in
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    sheetOffset = 0
                }
            }
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    // Uses a stub ViewModel for canvas preview.
    RideRequestView(viewModel: .preview)
}
#endif
