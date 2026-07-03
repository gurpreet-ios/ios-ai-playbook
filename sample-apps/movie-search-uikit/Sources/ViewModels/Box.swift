// Box.swift
// ViewModels layer — the entire binding "framework": one generic class.
// Chosen over Combine/RxSwift deliberately; see DECISIONS.md #3.

import Foundation

/// A minimal observable box for MVVM binding in UIKit.
///
/// The ViewModel owns a `Box`, mutates `value`, and the bound ViewController
/// re-renders. `@MainActor` by design: bindings drive UIKit, so delivering
/// them anywhere else would be a bug the compiler should catch.
///
/// Limitation (acceptable here): one listener per box. The last `bind` wins,
/// which is exactly the 1 ViewModel → 1 ViewController shape of this app.
@MainActor
final class Box<Value> {

    // MARK: Properties

    /// Current value; assigning notifies the listener.
    var value: Value {
        didSet { listener?(value) }
    }

    private var listener: ((Value) -> Void)?

    // MARK: Initialisation

    init(_ value: Value) {
        self.value = value
    }

    // MARK: Binding

    /// Registers `listener` and immediately fires it with the current value,
    /// so a freshly-bound screen renders without waiting for a change.
    func bind(_ listener: @escaping (Value) -> Void) {
        self.listener = listener
        listener(value)
    }
}
