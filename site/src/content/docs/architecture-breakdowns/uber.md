---
title: "AI Architecture Breakdown: Uber"
---

## Core Challenge
Real-time bi-directional state synchronization. A driver's location must update on the rider's screen with sub-second latency, while gracefully handling network drops.

## The Blueprint (AI Prompting Sequence)

### 1. The Real-Time Transport Layer
*Do not prompt for the UI first. Prompt for the WebSocket.*
**Prompt:** "Generate a `WebSocketManager` in Swift. It must maintain a persistent connection, handle automatic reconnects with exponential backoff, and decode incoming JSON payloads into a `LocationUpdate` struct. Ensure thread safety using an Actor."

### 2. Location Services
**Prompt:** "Generate a `LocationTracker` using `CoreLocation`. Request `always` authorization. Track location in the background. Throttle updates to emit only when the device moves more than 10 meters."

### 3. State Management (Redux/CQRS)
**Prompt:** "Generate a Redux store for the Rider app. The state must contain `DriverLocation`, `TripStatus`, and `ETA`. Actions should include `driverMoved` and `statusChanged`."

### 4. The Map UI
**Prompt:** "Generate a SwiftUI `MapView` using `MapKit`. Bind it to the Redux store's `DriverLocation`. Animate the driver pin's movement linearly between the old location and the new location to smooth out GPS jitter."
