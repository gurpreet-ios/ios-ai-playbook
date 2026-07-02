# ADR 007: Router-Owned Navigation over Inline NavigationLinks

## Status
Accepted

## Context
SwiftUI permits navigation to be declared inline (`NavigationLink(destination:)`) anywhere in the view tree. AI code generators reach for this by default, which welds screens to their destinations, breaks reuse, makes deep-linking retrofits painful, and scatters the navigation graph across every view file — unreviewable as a whole.

## Decision
Navigation is owned by a **Router**: a `@MainActor @Observable` class holding a `NavigationPath`, with an app-level `enum Route: Hashable` enumerating destinations. Views call `router.navigate(to:)` and contain no destination types; one `.navigationDestination(for: Route.self)` at each stack root maps routes to screens. Sheets and full-screen covers follow the same pattern via optional route state on the router. Deep links and push-notification taps (Ch 13) resolve to `Route` values and go through the same router.

## Consequences
**Positive:**
- The navigation graph is one enum — reviewable, testable, deep-linkable by construction.
- Screens become reusable in any flow because they don't know where they go next.
- Push/universal-link handling is a parse-to-`Route` function, not view surgery.

**Negative:**
- Indirection tax on trivial flows; a two-screen app doesn't need it (MusicApp's two-tab shell defers the router until a third screen exists — Ch 9).
- One more injected dependency per navigating view.

## AI Anchor Usage
Inject when generating any screen that navigates, or when reviewing a diff containing `NavigationLink`. Anchor phrase: *"No inline `NavigationLink(destination:)` — add a `Route` case and call `router.navigate(to:)`."*
