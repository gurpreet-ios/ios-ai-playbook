---
title: "🚗 Uber Clone — AI-Generated Sample App"
---

> **The entire codebase in this directory was generated using AI, guided by the exact prompts documented alongside each file.**

This sample app is the *living proof* of the **Senior AI Engineering Playbook**. It demonstrates how a Staff Engineer would use AI agents to build a complex, real-time ride-sharing application — not by prompting "build me an Uber clone," but by systematically constructing each architectural layer with precise, constrained prompts.

---

## Architecture

```
┌─────────────────────────────────────────────────┐
│                    Views                         │
│   RideRequestView · ActiveTripView · Components │
├─────────────────────────────────────────────────┤
│                  ViewModels                      │
│    RideRequestVM · ActiveTripVM · DriverMapVM    │
├─────────────────────────────────────────────────┤
│                 Repositories                     │
│         TripRepository · DriverRepository        │
├─────────────────────────────────────────────────┤
│                   Services                       │
│   LocationService · WebSocketManager · Network   │
├─────────────────────────────────────────────────┤
│                    Models                        │
│     Rider · Driver · Trip · LocationUpdate       │
└─────────────────────────────────────────────────┘
```

**The Dependency Rule:** Each layer only depends on the layer directly below it. Views never import Services. ViewModels never import URLSession. This is enforced by protocol-based dependency injection.

---

## How to Read This Codebase

Every layer contains a `_prompts/` directory with `.prompt.md` files. These document:

1. **The System Role** — The persona assigned to the AI.
2. **The Exact Prompt** — Copy-paste ready prompt that generated the code.
3. **The Constraints** — Hard rules the AI must follow (e.g., "Do NOT use Combine").
4. **The Review Checklist** — What a Senior Engineer checks after generation.

### The Layered Prompting Sequence

The prompts were executed in this exact order:

| Step | Layer | Prompt File | What It Generates |
|:-----|:------|:------------|:------------------|
| 1 | Models | `Models/_prompts/01-core-models.prompt.md` | Data entities and DTOs |
| 2 | Services | `Services/_prompts/02-location-service.prompt.md` | CoreLocation wrapper |
| 3 | Services | `Services/_prompts/03-websocket-manager.prompt.md` | Real-time connection |
| 4 | Services | `Services/_prompts/04-network-client.prompt.md` | REST API client |
| 5 | Repos | `Repositories/_prompts/05-repositories.prompt.md` | Data access abstraction |
| 6 | VMs | `ViewModels/_prompts/06-viewmodels.prompt.md` | Business logic |
| 7 | Views | `Views/_prompts/07-ride-request-view.prompt.md` | Ride request UI |
| 8 | Views | `Views/_prompts/08-active-trip-view.prompt.md` | Live tracking UI |
| 9 | Views | `Views/_prompts/09-components.prompt.md` | Reusable UI components |

---

## Tech Stack

- **Swift 6** with strict concurrency
- **SwiftUI** (iOS 17+)
- **SwiftData** (`@Model` macro)
- **Observation** (`@Observable` macro)
- **MapKit** (iOS 17 `Map` API)
- **CoreLocation** (via Actor isolation)
- **URLSession WebSocket** (no third-party dependencies)

## Key Patterns Demonstrated

- **Actor-based Services** — Thread-safe networking and location tracking
- **Repository Pattern** — Abstracts data sources behind protocols
- **Router Pattern** — Centralized navigation via `NavigationPath`
- **Optimistic UI** — Instant feedback with background sync
- **Task Cancellation** — Proper cleanup via `.task` modifier

## Running

Open `Package.swift` in Xcode 16+ and build for iOS 17 Simulator.

> ⚠️ This is a **demonstration codebase**. The API endpoints point to `api.example.com`. To run end-to-end, you would need to provide a real backend.
