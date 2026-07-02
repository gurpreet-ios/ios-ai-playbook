# AI Architecture Breakdown: Uber

## The Core Challenge

Real-time bi-directional state synchronization. A driver's location must appear on the rider's screen with sub-second latency, through tunnels, dead zones, and app backgrounding — and the *trip state machine* (requested → accepted → in progress → completed) must never glitch backwards or skip states no matter how messages arrive. The hard part is not the map; it is that **the network is a stream, not a request**, and streams drop, reorder, and reconnect.

> A verbose-prompt build of this design ships in [`sample-apps/uber-clone`](../sample-apps/uber-clone) (see the README's prompting-strategy notes; its repair is tracked in the backlog).

## The Core Domain

`Trip` (id, `TripStatus` enum with **explicit legal transitions**, rider, driver), `Driver`, `LocationUpdate` (coordinates + **sequence number** + timestamp — the sequence number is what makes out-of-order delivery detectable), `ETA`. Write the `TripStatus` transition table before prompting: the AI will otherwise happily apply a `driverArrived` event to a `completed` trip.

## The Architecture Decisions (state them before prompting)

| Decision | Choice | Why |
| :--- | :--- | :--- |
| Transport | WebSocket for live state; REST for commands (request/cancel trip) | Sub-second push needs a socket; commands want request/response semantics and retries |
| Consistency | **Snapshot + delta** with sequence numbers | Reconnects and gaps are the common case; deltas without a gap rule = silent divergence |
| State | Single reducer-style store per trip (unidirectional) | Events from socket, REST, and UI must serialize through one place or race |
| Location (driver app) | `CoreLocation` significant-movement throttling | Battery: raw GPS at 1Hz kills the driver's shift |
| Map rendering | Interpolated pin movement | Raw GPS jitter looks broken; animation between fixes looks alive |

## The Prompt Sequence

### 1. The Transport Layer (never prompt for the UI first)

> **Prompt:** "Generate a `WebSocketManager` **actor** over `URLSessionWebSocketTask`: connect/disconnect, automatic reconnect with **exponential backoff + jitter** (cap ~30s, reset on success), decode incoming frames into a `ServerEvent` enum (`tripStatusChanged`, `driverLocation`, `etaUpdated`), and expose them as a single `AsyncStream<ServerEvent>`. Declare each event with a `sequence: Int`. On reconnect, emit a `.reconnected` marker event before resuming — consumers must know a gap may have occurred."

**Watch for:** reconnect *without* jitter (a regional blip → thundering herd), and the AI declaring the manager `class … @unchecked Sendable` instead of an actor — the exact waiver dissected in [`interview-playbooks/code-review/data-race.md`](../interview-playbooks/code-review/data-race.md).

### 2. The Sync Rule: Snapshot + Delta

> **Prompt:** "Implement the consistency layer: on connect or `.reconnected`, fetch a full `TripSnapshot` via REST, then apply socket deltas **only if** `delta.sequence == lastApplied + 1`. On a gap: discard the delta and re-fetch the snapshot. Never apply deltas to a snapshot newer than they are (compare sequence, not arrival time)."

**Watch for:** the AI applying deltas by arrival order. Under reordering, that renders the driver *driving backwards*. The gap rule is the whole layer; make the AI restate it before writing code. (This is the same spine as [`interview-playbooks/architecture/live-sports-app.md`](../interview-playbooks/architecture/live-sports-app.md) — score updates and driver pins are the same problem.)

### 3. The Trip State Machine

> **Prompt:** "Generate a `TripStore` (`@Observable`, single reducer method `apply(_ event: ServerEvent)`): holds `TripStatus`, `driverLocation`, `eta`. Encode the legal transition table — `requested → accepted → driverArriving → inProgress → completed | cancelled` — and **reject** (log, don't crash) any event implying an illegal transition. UI actions (cancel trip) go through REST commands, never by mutating the store directly; the store only moves on server-confirmed events."

**Watch for:** the enum-case drift bug that actually shipped in the sample repo: views referencing `TripStatus.searching` when the case is `.requested` — generated per-file, never integrated. One store, one enum, one file that owns it.

### 4. Location Services (the driver side)

> **Prompt:** "Generate a `LocationTracker` around `CLLocationManager`: `always` authorization with the proper Info.plist strings, background updates enabled, distance filter ~10m, and a paused/active mode API (battery). Emit an `AsyncStream<CLLocation>`; the upload path throttles to at most one send per 2s and coalesces to the latest fix — never queue stale fixes."

**Watch for:** authorization prompted at launch instead of at go-online (App Review and conversion both hate it), and unthrottled uploads — GPS produces far more fixes than the product needs.

### 5. The Map UI

> **Prompt:** "SwiftUI `Map` bound to `TripStore`. The driver annotation animates between fixes (`withAnimation(.linear(duration: matchingTheUpdateCadence))`) so motion looks continuous. The ETA text and status banner are separate subviews reading only their own store properties — a location tick must not re-evaluate the whole screen. Show a designed 'reconnecting' state driven by the transport's connection state; never freeze silently on a dead socket."

**Watch for:** teleporting pins (no interpolation) and the Chapter 11 over-render: location ticks arrive several times per second — the same discipline as a playback progress bar.

### 6. The Verification Pass

> **Prompt:** "Swift Testing suites: the transition table (every illegal transition rejected), the gap rule (delta with `sequence + 2` triggers snapshot re-fetch and is not applied), and backoff scheduling (delays grow, jitter within bounds, reset on success). Drive the socket with a test-controlled `AsyncStream` — no sleeps. Then run `prompts/testing/tautology-audit.md` on the suite."

## The Failure Modes to Probe (interview extension bank)

- **The tunnel** — 90s offline: does the UI show stale-with-timestamp, or lie that it's live? What does the rider see the moment connectivity returns (snapshot re-fetch, not a delta flood)?
- **Reconnect storm** — the stadium problem: 50k clients reconnecting after a blip. Where's the jitter, and does the server get a say (retry-after)?
- **Backgrounding mid-trip** — the rider backgrounds the app: Live Activity for the lock screen (Ch 13), socket handoff to push updates, state re-sync on foreground.
- **Two devices, one account** — rider opens iPad mid-trip: does the snapshot+delta layer converge both, or does command echo double-apply?

## Related Assets

- Interview simulations: [`live-sports-app.md`](../interview-playbooks/architecture/live-sports-app.md) (this transport/consistency design as a full interview), [`data-race.md`](../interview-playbooks/code-review/data-race.md), [`rate-limiter.md`](../interview-playbooks/machine-coding/rate-limiter.md) (the throttle in layer 4)
- Chapters: 12 (actors and Sendable at the socket boundary), 13 (Live Activity for the active trip), 21 (tool-calling/MCP if the agent drives the build loop)
