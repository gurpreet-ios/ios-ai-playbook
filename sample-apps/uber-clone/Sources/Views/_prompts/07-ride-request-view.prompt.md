# Prompt 07 — RideRequestView

## Role
You are a Senior iOS Engineer writing production SwiftUI for an Uber clone.

## Prompt

> Create `RideRequestView.swift` — the primary ride-request screen for an Uber clone app.
>
> ### Requirements
>
> 1. **Framework & Target**: SwiftUI + MapKit, iOS 17+, Swift 6 strict concurrency.
> 2. **State management**: Accept a `RideRequestViewModel` (an `@Observable` class) via `@State`. Do **not** use `ObservableObject`, `@Published`, or Combine.
> 3. **Map layer**:
>    - Use the iOS 17 `Map(position:)` initializer with map content builder.
>    - Show pickup pin (green `circle.fill` annotation) and dropoff pin (red `mappin.circle.fill` annotation) when coordinates are available.
>    - Render the route polyline with `MapPolyline`.
>    - Include `MapUserLocationButton` and `MapCompass` controls.
> 4. **Bottom sheet**:
>    - Overlay a rounded-corner bottom sheet (`.ultraThinMaterial`) on top of the map.
>    - Include a drag handle capsule, two `AddressSearchBar` components for pickup/dropoff, a fare estimate row (shown conditionally), and a "Request Ride" button.
>    - Use `.spring` animations for interactive sheet drag.
> 5. **Request button**:
>    - Large, full-width `.borderedProminent` button.
>    - Show a `ProgressView` spinner when `viewModel.isLoading` is true.
>    - Disabled when loading **or** `viewModel.canRequestRide` is false.
>    - On tap, call `await viewModel.requestRide()` inside a `Task`.
> 6. **Error handling**: Display `viewModel.errorMessage` in an `.alert`. Dismiss clears the message.
> 7. **Lifecycle**: Use `.task` modifier to call `await viewModel.onAppear()`.
> 8. **No business logic in this file** — all data fetching, geocoding, and ride creation live in the ViewModel.

## Constraints

| Rule | Detail |
|------|--------|
| No business logic in view | All async work delegated to ViewModel |
| State via ViewModel | Single `@State` property for the `@Observable` ViewModel |
| Use `.task` for async | Ensures automatic cancellation on disappear |
| No Combine / `@Published` | Swift 6 `@Observable` only |
| One type per file | Only `RideRequestView` defined here |
| Animations | `.spring` for sheet; `.easeInOut` or `.move`+`.opacity` for transitions |

## Review Checklist

- [ ] `Map(position:)` uses a binding from the ViewModel.
- [ ] Pickup and dropoff annotations conditionally rendered.
- [ ] Bottom sheet uses `.ultraThinMaterial` with rounded corners.
- [ ] `AddressSearchBar` used for both text fields (not raw `TextField`).
- [ ] Fare estimate row only appears when `viewModel.fareEstimate` is non-nil.
- [ ] Request button shows `ProgressView` during loading.
- [ ] Button is disabled when `isLoading || !canRequestRide`.
- [ ] `.alert` bound to `errorMessage` with dismiss-to-nil logic.
- [ ] `.task` modifier calls `onAppear()` exactly once.
- [ ] No `DispatchQueue`, no `@Published`, no `ObservableObject`.
- [ ] File compiles independently as part of the Swift Package.
- [ ] Companion `_prompts/07-ride-request-view.prompt.md` exists (this file).
