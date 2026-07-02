# Prompt 09 — Reusable View Components

## Role
You are a Senior iOS Engineer writing production SwiftUI components for an Uber clone.

## Prompt

> Create three reusable SwiftUI components under `Views/Components/`.
> Each component is a self-contained, presentation-only struct with **no business logic**.
>
> ---
>
> ### 1. `AddressSearchBar.swift`
>
> A styled text-input component for entering addresses.
>
> - **Inputs**: `@Binding text: String`, `placeholder: String`, `icon: String` (SF Symbol name).
> - **Layout**: Leading icon → `TextField` → conditional clear button (shown when `text` is non-empty).
> - **Styling**: Rounded corners (`cornerRadius: 12`), secondary system background fill, subtle shadow (`radius: 4, y: 2`).
> - **Focus**: Use `@FocusState` to highlight the border in blue when focused.
> - **Clear button**: Animate disappearance with `.scale` + `.opacity` transition.
>
> ---
>
> ### 2. `TripStatusCard.swift`
>
> A glassmorphism-style card that renders different content per trip phase.
>
> - **Inputs**: `tripStatus: TripStatus`, `driverName: String`, `vehicleInfo: String`, `eta: String`.
> - **Background**: `.ultraThinMaterial` with `cornerRadius: 20` and a subtle shadow.
> - **Status-dependent content**:
>   - `.requested` — pulsing magnifying-glass animation ("finding your driver") (`repeatForever`).
>   - `.driverAssigned` — driver info row + "Arriving in" ETA.
>   - `.driverArrived` — driver info + "Meet at the pickup point".
>   - `.inProgress` — driver info + ETA + progress bar.
>   - `.completed` — checkered flag + thank-you text.
>   - `.cancelled` — red X + cancellation text.
> - **Transitions**: Use `.spring` animation keyed on `tripStatus` for smooth state changes.
>
> ---
>
> ### 3. `DriverAnnotationView.swift`
>
> A custom map annotation view for the driver's car.
>
> - **Input**: `heading: Double` (compass degrees).
> - **Layout**: `ZStack` of a pulsing translucent circle underneath a rotatable car icon.
> - **Car icon**: SF Symbol `car.fill`, white on a blue circle background.
> - **Rotation**: `.rotationEffect(.degrees(heading))` with `.easeInOut` animation.
> - **Pulse**: Circle scales and fades using `.repeatForever(autoreverses: true)`.

## Constraints

| Rule | Detail |
|------|--------|
| No business logic | Components receive data, never fetch or mutate it |
| Pure presentation | Visual rendering only; side-effect-free |
| `@Binding` for two-way data | `AddressSearchBar` uses `@Binding` for `text` |
| No Combine / GCD | Standard SwiftUI animation APIs only |
| One type per file | Each component in its own `.swift` file |
| iOS 17+ / Swift 6 | `@Observable`-ready; no deprecated APIs |

## Review Checklist

### AddressSearchBar
- [ ] `@Binding var text: String` — not a plain `let`.
- [ ] `@FocusState` drives border highlight color.
- [ ] Clear button hidden when `text.isEmpty`.
- [ ] Clear button has `.scale` + `.opacity` transition.
- [ ] `.autocorrectionDisabled()` applied.
- [ ] Shadow is subtle (opacity ≤ 0.1).

### TripStatusCard
- [ ] Background uses `.ultraThinMaterial`.
- [ ] All six `TripStatus` cases handled in a `switch`.
- [ ] Searching state has a repeating pulse animation.
- [ ] Driver info row shows name + vehicle.
- [ ] ETA row present for `.driverAssigned` and `.inProgress`.
- [ ] Transitions animated with `.spring` keyed on `tripStatus`.

### DriverAnnotationView
- [ ] `heading` applied via `.rotationEffect(.degrees(heading))`.
- [ ] Car icon has `.easeInOut` animation on heading changes.
- [ ] Pulsing circle uses `repeatForever(autoreverses: true)`.
- [ ] Overall frame is compact (≤ 48pt) for map annotation use.

### General
- [ ] No `DispatchQueue`, no `@Published`, no `ObservableObject`.
- [ ] Each file compiles independently within the Swift Package.
- [ ] Preview providers present for each component.
- [ ] Companion `_prompts/09-components.prompt.md` exists (this file).
