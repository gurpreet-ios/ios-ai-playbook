import UIKit

// MARK: - Haptic Service

/// A lightweight, stateless service that wraps UIKit's haptic feedback
/// generators for common tactile feedback patterns.
///
/// This is a plain struct (not an actor) because `UIImpactFeedbackGenerator`
/// and `UINotificationFeedbackGenerator` are `@MainActor`-bound and each
/// method creates its own generator instance, making thread-safety trivial.
struct HapticService: Sendable {

    // MARK: - Impact Feedback

    /// Triggers a light impact haptic (e.g., subtle UI selection).
    @MainActor
    func lightImpact() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }

    /// Triggers a medium impact haptic (e.g., toggling a switch).
    @MainActor
    func mediumImpact() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }

    /// Triggers a heavy impact haptic (e.g., dropping a dragged item).
    @MainActor
    func heavyImpact() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.prepare()
        generator.impactOccurred()
    }

    // MARK: - Notification Feedback

    /// Triggers a success notification haptic (e.g., ride confirmed).
    @MainActor
    func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
    }

    /// Triggers an error notification haptic (e.g., payment failed).
    @MainActor
    func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.error)
    }

    /// Triggers a warning notification haptic (e.g., driver is late).
    @MainActor
    func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.warning)
    }
}
