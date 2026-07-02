# Mock Interview: Live Sports App

## 1. The Prompt
**Interviewer:** "Design the iOS architecture for a live sports app: real-time scores for matches the user follows, sub-second updates during play, and it must be graceful about connectivity. Millions of users watch the same match."

## 2. Expected Reasoning
This is the real-time transport question, and the interviewer is listening for four things:
1. **Transport selection with reasons** — WebSocket vs SSE vs polling is a tradeoff table, not a fashion choice.
2. **Connection lifecycle on mobile** — backgrounding, network flapping, and reconnection with backoff + jitter. Mobile is not a server: your socket dies dozens of times an hour by design.
3. **The snapshot + delta protocol** — deltas alone break the moment you miss one; snapshots alone waste bandwidth. Every real system needs both and a gap-detection rule.
4. **Fan-out empathy** — millions of clients reconnecting after a goal is a thundering-herd problem the *client* must help solve.

## 3. The Poor Answer
> *"WebSocket, obviously — it's real-time. I'll connect on launch, subscribe to the user's matches, and update the UI on each message. If it disconnects I'll reconnect in a loop. When the app backgrounds I'll keep the socket alive so scores stay fresh."*

**Why it's poor:** "Reconnect in a loop" with no backoff is a self-inflicted DDoS multiplied by millions of fans at full-time. iOS will not keep the socket alive in background regardless of intent — that's not how suspension works. And updating UI per-message with no sequence numbers means one dropped frame of connectivity silently shows a wrong score — in a sports app, the worst possible failure.

## 4. The Great Answer
> *"Transport: WebSocket for the live match screen, but the decision is per-surface. The scores *list* can ride 30-second polling or SSE — it's glanceable, not sub-second. Reserving the socket for the match detail screen cuts connection count by an order of magnitude.
>
> Protocol: snapshot + delta with sequence numbers. On subscribe, the server sends a full match snapshot with `seq`; deltas increment it. The client's rule is mechanical: `delta.seq == last + 1` → apply; gap → discard and request a fresh snapshot. Correctness never depends on receiving every message.
>
> Lifecycle: a `ConnectionManager` actor owns one socket state machine — disconnected → connecting → connected → draining. Reconnects use exponential backoff *with jitter* (I'll come back to why), and network-path changes via `NWPathMonitor` reset the backoff. On background, we let the socket die and note the last `seq`; on foreground, snapshot-resync. No pretending iOS gives us persistent background sockets — for lock-screen scores, the OS-sanctioned answer is a Live Activity updated via push, not a socket.
>
> The UI observes a store the socket writes into — the transport is swappable without touching a view, which is also how we test this: replay a recorded delta stream."*

## 5. Driving the LLM

> **Plan:** "Live sports app. Before code: give me a transport tradeoff table (WebSocket / SSE / polling — battery, proxies, fan-out cost, reconnect semantics) and a recommendation per surface (list vs match detail vs lock screen). Then define the snapshot+delta message schema with sequence numbers. No code yet."

> **Generate (piece 1):** "The `MatchStateStore`: applies `Snapshot` and `Delta` messages with the gap rule (discard + request resync on non-contiguous seq). Pure logic, no networking — I want this fully unit-testable with a replayed message array."

> **Generate (piece 2):** "The `ConnectionManager` actor: state machine, exponential backoff with full jitter, `NWPathMonitor` integration, and a `AsyncStream<TransportEvent>` the store consumes. Backgrounding tears down cleanly and records last seq."

> **Review hook:** "Prove the gap rule: feed your own implementation seq 1, 2, 4. Show me the code path that refuses to apply 4 and requests a snapshot. Then explain what happens if the *snapshot itself* arrives with a seq older than one we already applied."

**What you're watching for:** reconnect loops without jitter, deltas applied without sequence checks ("it works in the demo"), state updates scattered across the socket callback instead of centralized in the store, and any suggestion that a background socket will stay alive.

## 6. The Follow-Up (Mid-Interview Extension)
**Interviewer:** "A goal is scored in a final watched by 5 million users. The stadium's cell network hiccups, 500k sockets drop and reconnect within 10 seconds. Also: product wants the score on the Lock Screen. Go."

## 7. The Ideal Discussion
> *"The reconnect storm is why jitter was non-negotiable earlier: 500k clients on exponential backoff *without* jitter reconnect in synchronized waves — retry storms with a metronome. Full jitter (`delay = random(0, base * 2^attempt)`) spreads them flat. The client also helps by resubscribing with its last `seq`: if the gap is small the server sends deltas, else one snapshot — and that snapshot should come from a cache/CDN layer, because 500k identical 'current score' requests is a caching problem, not a compute problem. I'd also honor a server-sent `retry-after` hint so the backend can shed load actively.
>
> Lock Screen: Live Activity via ActivityKit, updated through the push channel with the score payload — the app is suspended, so the socket is irrelevant. Two constraints matter: the payload budget is tiny (score + clock + state, no imagery beyond what's pre-bundled), and update frequency is budgeted by the system, so the server sends significant events (goals, cards, period changes), not every clock tick. Nicely, the snapshot+delta schema already defines 'significant': it's the same event types, filtered — the protocol design pays for itself at the OS boundary."*
