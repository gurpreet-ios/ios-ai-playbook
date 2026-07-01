// TripStatusCard.swift
// UberClone – Views / Components
// iOS 17+ · Swift 6 · SwiftUI

import SwiftUI

// MARK: - TripStatusCard

/// Displays contextual trip information in a translucent card.
///
/// Content adapts automatically based on `TripStatus`:
/// - `.searching`      → pulsing search animation
/// - `.driverAssigned` → driver & vehicle details with ETA
/// - `.driverArrived`  → arrival notice
/// - `.inProgress`     → in-progress info with ETA to destination
/// - `.completed`      → ride summary
/// - `.cancelled`      → cancellation notice
///
/// Pure presentation — no business logic.
struct TripStatusCard: View {

    // MARK: - Properties

    let tripStatus: TripStatus
    let driverName: String
    let vehicleInfo: String
    let eta: String

    // MARK: - Animation State

    @State private var isPulsing = false

    // MARK: - Body

    var body: some View {
        VStack(spacing: 16) {
            statusContent
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.12), radius: 10, y: 4)
        )
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: tripStatus)
    }
}

// MARK: - Status Content

private extension TripStatusCard {

    @ViewBuilder
    var statusContent: some View {
        switch tripStatus {
        case .searching:
            searchingContent

        case .driverAssigned:
            driverAssignedContent

        case .driverArrived:
            driverArrivedContent

        case .inProgress:
            inProgressContent

        case .completed:
            completedContent

        case .cancelled:
            cancelledContent
        }
    }

    // MARK: Searching

    var searchingContent: some View {
        VStack(spacing: 12) {
            Circle()
                .fill(.blue.opacity(0.2))
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: "magnifyingglass")
                        .font(.title2)
                        .foregroundStyle(.blue)
                )
                .scaleEffect(isPulsing ? 1.15 : 1.0)
                .opacity(isPulsing ? 0.7 : 1.0)
                .onAppear {
                    withAnimation(
                        .easeInOut(duration: 1.0)
                        .repeatForever(autoreverses: true)
                    ) {
                        isPulsing = true
                    }
                }

            Text("Finding your driver…")
                .font(.headline)

            Text("This usually takes a minute or two")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: Driver Assigned

    var driverAssignedContent: some View {
        VStack(spacing: 12) {
            statusBadge(
                icon: "car.fill",
                title: "Driver is on the way",
                color: .blue
            )
            driverInfoRow
            etaRow(label: "Arriving in", value: eta)
        }
    }

    // MARK: Driver Arrived

    var driverArrivedContent: some View {
        VStack(spacing: 12) {
            statusBadge(
                icon: "checkmark.circle.fill",
                title: "Your driver has arrived",
                color: .green
            )
            driverInfoRow
            Text("Meet at the pickup point")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: In Progress

    var inProgressContent: some View {
        VStack(spacing: 12) {
            statusBadge(
                icon: "location.fill",
                title: "Trip in progress",
                color: .blue
            )
            driverInfoRow
            etaRow(label: "Arriving at destination in", value: eta)

            // Progress bar placeholder
            ProgressView(value: 0.5)
                .tint(.blue)
                .padding(.horizontal, 4)
        }
    }

    // MARK: Completed

    var completedContent: some View {
        VStack(spacing: 12) {
            statusBadge(
                icon: "flag.checkered",
                title: "You've arrived!",
                color: .green
            )
            Text("Thanks for riding with us")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: Cancelled

    var cancelledContent: some View {
        VStack(spacing: 12) {
            statusBadge(
                icon: "xmark.circle.fill",
                title: "Ride cancelled",
                color: .red
            )
            Text("Your ride has been cancelled")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Reusable Rows

private extension TripStatusCard {

    /// Icon + title badge shown at the top of every status state.
    func statusBadge(icon: String, title: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            Text(title)
                .font(.headline)
        }
    }

    /// Driver name + vehicle info.
    var driverInfoRow: some View {
        HStack(spacing: 14) {
            // Avatar placeholder
            Circle()
                .fill(Color(.tertiarySystemFill))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "person.fill")
                        .foregroundStyle(.secondary)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(driverName)
                    .font(.subheadline.weight(.semibold))
                Text(vehicleInfo)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.secondarySystemBackground).opacity(0.6))
        )
    }

    /// Label + value row for ETA display.
    func etaRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.semibold))
                .fontDesign(.rounded)
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Searching") {
    TripStatusCard(
        tripStatus: .searching,
        driverName: "",
        vehicleInfo: "",
        eta: ""
    )
    .padding()
}

#Preview("Driver Assigned") {
    TripStatusCard(
        tripStatus: .driverAssigned,
        driverName: "Alex Johnson",
        vehicleInfo: "White Tesla Model 3 · 4RKT 829",
        eta: "3 min"
    )
    .padding()
}

#Preview("In Progress") {
    TripStatusCard(
        tripStatus: .inProgress,
        driverName: "Alex Johnson",
        vehicleInfo: "White Tesla Model 3 · 4RKT 829",
        eta: "12 min"
    )
    .padding()
}
#endif
