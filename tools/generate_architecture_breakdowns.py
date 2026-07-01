import os

breakdowns = {
    "uber.md": """# AI Architecture Breakdown: Uber

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
""",
    "spotify.md": """# AI Architecture Breakdown: Spotify

## Core Challenge
Global playback state and massive offline caching. The audio must continue playing regardless of what screen the user navigates to, and downloaded tracks must be encrypted and instantly available.

## The Blueprint (AI Prompting Sequence)

### 1. The Audio Engine
*The engine must be entirely decoupled from the UI.*
**Prompt:** "Generate an `AudioEngine` using `AVFoundation`. It must handle background audio playback, lock screen controls (Now Playing Info Center), and headphone unplug events. Expose the current `PlaybackState` (playing, paused, buffering) as an async stream."

### 2. The Offline Cache (Repository)
**Prompt:** "Generate a `TrackRepository` using SwiftData. When fetching a track, it must first check the local SwiftData cache. If the track is downloaded, return the local file URL. If not, return the remote streaming URL. Hide this logic behind a `TrackFetching` protocol."

### 3. Global State (Observation)
**Prompt:** "Generate a `@Observable` class called `PlayerViewModel`. It must inject the `AudioEngine`. Any screen in the app should be able to read `PlayerViewModel.currentTrack` without causing the entire navigation stack to re-render."

### 4. The Mini Player UI
**Prompt:** "Generate a SwiftUI `MiniPlayerView`. It must sit at the bottom of the `ZStack` in the main App layout, persisting across all navigation pushes. It should observe the `PlayerViewModel` for state changes."
""",
    "instagram.md": """# AI Architecture Breakdown: Instagram

## Core Challenge
Infinite scrolling performance, massive image caching, and optimistic UI updates (liking a post).

## The Blueprint (AI Prompting Sequence)

### 1. The Image Pipeline
*Never decode images on the main thread.*
**Prompt:** "Generate an `ImageCache` actor. It should download images, downsample them to the requested bounding box on a background thread using `CGImageSourceCreateThumbnailAtIndex`, and cache the result in memory (NSCache) and on disk."

### 2. The Pagination Engine
**Prompt:** "Generate a `FeedRepository`. Implement cursor-based pagination. When the user scrolls to the 5th-to-last item, fetch the next page using the `next_cursor` token. Ensure duplicate posts are filtered out."

### 3. Optimistic UI Updates
**Prompt:** "When the user likes a post, immediately toggle the heart icon to red and increment the local like count in the view's state. Then, fire the network request in the background. If the request fails, revert the local state and show a toast error."

### 4. The Feed UI
**Prompt:** "Generate the feed using SwiftUI's `LazyVStack`. Ensure that the cell views are strictly isolated; a like on Cell #1 must NOT trigger a re-render of Cell #2."
"""
}

base_dir = "/Users/gurpreet029/Documents/antigravity/epic-volta/ai-engineering-playbook"
arch_dir = os.path.join(base_dir, "architecture-breakdowns")

os.makedirs(arch_dir, exist_ok=True)
with open(os.path.join(arch_dir, "README.md"), "w") as f:
    f.write("# Architecture Breakdowns\n\nBlueprints for orchestrating AI to build complex products layer-by-layer.\n")

for filename, content in breakdowns.items():
    with open(os.path.join(arch_dir, filename), "w") as f:
        f.write(content.strip() + "\n")
    print(f"Created {filename}")

print("Successfully generated architecture breakdowns.")
