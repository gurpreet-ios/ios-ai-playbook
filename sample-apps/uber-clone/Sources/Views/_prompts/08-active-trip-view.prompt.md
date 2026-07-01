# Prompt 08 — ActiveTripView

## Role
You are a Senior iOS Engineer writing production SwiftUI for an Uber clone.

## Prompt

> Create `ActiveTripView.swift` — the live trip-tracking screen shown after a ride is confirmed.
>
> ### Requirements
>
> 1. **Framework & Target**: SwiftUI + MapKit, iOS 17+, Swift 6 strict concurrency.
> 2. **State management**: Accept an `ActiveTripViewModel` (an `@Observable` class) via `@State`. No Combine.
> 3. **Map layer**:
>    - Use `Map(position:)` with a binding from the ViewModel.
>    - Render the driver's real-time position as a custom `DriverAnnotationView` annotation. The driver location comes from `viewModel.driverLocation` (a `LocationUpdate` with `coordinate` and `heading`).
>    - Show static pickup (green) and dropoff (red) markers.
>    - Render the route polyline via `MapPolyline`.
> 4. **TripStatusCard**:
>    - Placed at the bottom of the screen.
>    - Pass `viewModel.tripStatus`, `viewModel.driverName`, `viewModel.vehicleInfo`, and `viewModel.eta`.
>    - Animate transitions when `tripStatus` changes using `.spring`.
> 5. **Cancel button**:
>    - Shown **only** when `viewModel.canCancel` is true (i.e., status is `.driverAssigned` or `.driverArrived`).
>    - Tapping shows a `.confirmationDialog` with destructive "Cancel Ride" and neutral "Keep Ride" options.
>    - On confirm, call `await viewModel.cancelTrip()`.
> 6. **Lifecycle**: Use `.task` to call `await viewModel.startTracking()`. Automatic cancellation on disappear stops the real-time subscription.
> 7. **No business logic in this file.**

## Constraints

| Rule | Detail |
|------|--------|
| Real-time map updates | Driver annotation re-renders on each `driverLocation` change |
| Task cancellation via `.task` | SwiftUI `.task` modifier auto-cancels its `Task` on disappear |
| Status-driven UI | Cancel button and card content change based on `tripStatus` |
| No Combine / GCD | `async/await` + `@Observable` only |
| One type per file | Only `ActiveTripView` defined here |

## Review Checklist

- [ ] `Map(position:)` uses a binding from the ViewModel.
- [ ] Driver annotation uses `DriverAnnotationView(heading:)`.
- [ ] Pickup and dropoff markers are always rendered when coordinates exist.
- [ ] `TripStatusCard` receives all four parameters from the ViewModel.
- [ ] Cancel button visibility driven by `viewModel.canCancel`.
- [ ] `confirmationDialog` has both a destructive and a cancel action.
- [ ] `.task` calls `startTracking()` — no manual `Task {}` in `onAppear`.
- [ ] Status transitions animated with `.spring`.
- [ ] No `DispatchQueue`, no `@Published`, no `ObservableObject`.
- [ ] File compiles independently as part of the Swift Package.
- [ ] Companion `_prompts/08-active-trip-view.prompt.md` exists (this file).
