// DriverAnnotationView.swift
// UberClone – Views / Components
// iOS 17+ · Swift 6 · SwiftUI

import SwiftUI

// MARK: - DriverAnnotationView

/// Custom map annotation that renders a car icon rotated to match
/// the driver's heading, with a subtle pulsing location indicator
/// underneath.
///
/// Usage inside a `Map`:
/// ```swift
/// Annotation("Driver", coordinate: coord) {
///     DriverAnnotationView(heading: 45.0)
/// }
/// ```
struct DriverAnnotationView: View {

    // MARK: - Properties

    /// The driver's compass heading in degrees (0 = north, 90 = east).
    let heading: Double

    // MARK: - Animation State

    @State private var isPulsing = false

    // MARK: - Body

    var body: some View {
        ZStack {
            pulsingCircle
            carIcon
        }
        .frame(width: 48, height: 48)
        .onAppear {
            withAnimation(
                .easeInOut(duration: 1.2)
                .repeatForever(autoreverses: true)
            ) {
                isPulsing = true
            }
        }
    }
}

// MARK: - Sub-views

private extension DriverAnnotationView {

    /// Pulsing circle underneath the car icon.
    var pulsingCircle: some View {
        Circle()
            .fill(.blue.opacity(0.25))
            .frame(width: isPulsing ? 36 : 24, height: isPulsing ? 36 : 24)
            .opacity(isPulsing ? 0.3 : 0.6)
    }

    /// Rotatable car icon.
    var carIcon: some View {
        Image(systemName: "car.fill")
            .font(.system(size: 22, weight: .bold))
            .foregroundStyle(.white)
            .padding(8)
            .background(
                Circle()
                    .fill(.blue)
                    .shadow(color: .blue.opacity(0.4), radius: 6, y: 2)
            )
            .rotationEffect(.degrees(heading))
            .animation(.easeInOut(duration: 0.4), value: heading)
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    VStack(spacing: 40) {
        DriverAnnotationView(heading: 0)
        DriverAnnotationView(heading: 45)
        DriverAnnotationView(heading: 135)
        DriverAnnotationView(heading: 270)
    }
    .padding()
}
#endif
