// Coordinator.swift
// Coordinators layer — the contract every flow coordinator conforms to.

import Foundation

/// A coordinator owns one navigation flow: it creates screens, wires their
/// ViewModels, and performs every push/present in that flow.
///
/// Memory contract (see DECISIONS.md #9): a parent keeps its children alive
/// via `childCoordinators`; children hold their parent `weak`; a finished
/// child is released through `childDidFinish(_:)`.
@MainActor
protocol Coordinator: AnyObject {

    /// Strong references keeping child flows alive while they run.
    var childCoordinators: [Coordinator] { get set }

    /// Builds the flow's first screen and puts it on screen.
    func start()
}

extension Coordinator {

    /// Releases a finished child flow. Identity comparison — coordinators
    /// are reference types and interchangeable value semantics make no sense.
    func childDidFinish(_ child: Coordinator?) {
        childCoordinators.removeAll { $0 === child }
    }
}
