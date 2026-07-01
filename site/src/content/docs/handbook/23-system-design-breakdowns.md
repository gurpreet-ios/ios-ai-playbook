---
title: "Chapter 23: System Design Breakdowns"
---

> "To build a skyscraper with robots, you do not tell them 'build a tall building.' You hand them the blueprint for the steel girders, then the blueprint for the plumbing, then the blueprint for the glass."

Part XIII of this playbook focuses on **Real Products**. 
We take massive, complex applications (Uber, Spotify, Instagram) and break them down into the exact architectural components and AI Prompts required to build them.

## 1. Why Deconstruct Real Products?

When a Junior developer tries to build an "Instagram Clone" using AI, they usually write a prompt like:
> *"Build an Instagram clone with a feed, profiles, and photo uploads."*

The AI will output a monolithic, unscalable mess with the UI and Database tightly coupled in a single file.

A Senior Engineer breaks the product down into bounded contexts and prompts the AI for each context individually.

## 2. The Blueprint Methodology

For every product breakdown in the `architecture-breakdowns/` directory, we follow a strict methodology:

1. **The Core Domain:** What is the fundamental entity of this app? (e.g., for Spotify, it's the `Track` and the `AudioPlayer`).
2. **The Architecture (ADRs):** What specific patterns must the AI follow? (e.g., for Uber, we need real-time bi-directional WebSockets, not REST polling).
3. **The Prompt Sequence:** The exact chronological order of prompts to feed the IDE. 

## 3. Example: The Uber Clone Breakdown

You cannot build Uber in one prompt. You build it in layers.

### Layer 1: The Core Entities
You start by defining the models.
- **Prompt:** *"Generate the SwiftData models for an Uber clone. We need `Rider`, `Driver`, `Trip`, and `LocationUpdate`. Ensure `Trip` has an enum for `status` (requested, accepted, in_progress, completed)."*

### Layer 2: The Real-Time Engine
You cannot use standard REST for a moving car.
- **Prompt:** *"Generate a `LocationService` using `CoreLocation`. It must run in the background. Generate a `WebSocketClient` that broadcasts the `CLLocation` coordinates to a server every 2 seconds. Ensure this is isolated to a background Actor."*

### Layer 3: The Map UI
Only after the engine is built do you touch the UI.
- **Prompt:** *"Generate a SwiftUI view containing an `MKMapView`. Bind it to the `LocationService` so it tracks the user. Overlay a custom pin for the `Driver`'s current location received via the WebSocket."*

By forcing the AI to build the application in this sequence, you maintain absolute control over the architecture.

*(Check the `architecture-breakdowns/` folder for the full blueprints of Spotify, Instagram, and Uber).*
