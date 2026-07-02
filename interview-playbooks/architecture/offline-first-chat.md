# Mock Interview: Offline-First Chat System

## 1. The Prompt
**Interviewer:** "Design the architecture for a WhatsApp-style chat application. Users must be able to read and send messages even when they have no internet connection. When connection is restored, messages should sync."

## 2. Expected Reasoning
The interviewer is testing your ability to handle complex state synchronization, conflict resolution, and separation of concerns. They want to see if you instinctively separate the local database from the network layer using a Repository pattern or CQRS.

## 3. The Poor Answer
> *"I would use SwiftUI and Firebase. When the user hits send, I'll write it to Firestore. Firestore has offline support built-in so it will just work automatically. I'll bind the UI directly to a Firestore snapshot listener."*

**Why it's poor:** It relies entirely on a third-party framework's "magic" without demonstrating architectural understanding. If asked to use a custom backend, the candidate will fail.

## 4. The Great Answer
> *"I'll structure this using a local-first architecture. The local database (e.g., SwiftData or SQLite) is the single source of truth for the UI.
> 
> When the user sends a message, it is written immediately to the local database with a status of `pending`. The UI updates instantly. 
> 
> Concurrently, a background synchronization engine picks up `pending` messages and attempts to send them to the server. If it succeeds, it updates the local status to `sent`. If it fails, it queues them for retry using exponential backoff.
> 
> For receiving messages, I'd use a WebSocket or Server-Sent Events (SSE) connection that writes incoming payloads directly to the local database, which then triggers a reactive UI update via Observation."*

## 5. Driving the LLM

> **Plan:** "We're designing offline-first chat: local DB as single source of truth, outbox with pending/sent states, WebSocket for incoming. Before code: draw me the module boundaries as a dependency list (UI → ViewModel → Repository → {SwiftData store, SyncEngine}), and state which module owns message ordering. No code yet."

> **Generate (piece 1):** "Define the SwiftData `@Model` for `Message`: local UUID, optional server `sequenceID`, `status` enum (pending/sent/failed), timestamps. Then the `Outbox` actor: `enqueue`, `pendingBatch()`, `markSent(localID:sequenceID:)`. No networking yet."

> **Generate (piece 2):** "Now the `SyncEngine`: drains the outbox with exponential backoff, and applies incoming WebSocket payloads to the store. All writes go through one `ModelActor` — explain how UI updates propagate from there before you write it."

> **Review hook:** "Adversarial pass: the app is force-quit after `enqueue` but before the send completes. Walk me through what happens on next launch, line by line. If the answer is 'the message is lost or duplicated,' fix the design."

**What you're watching for:** the LLM binding the UI to network responses instead of the local store (breaking the local-first invariant), retry loops with no backoff cap, and no idempotency key on sends — the force-quit scenario then double-sends on relaunch.

## 6. The Follow-Up (Mid-Interview Extension)
**Interviewer:** "Two extensions. First: a user is offline, sends a message, and at the same moment their friend sends them one — when they reconnect, how do you order the chat? Second: product adds *group* chats with 200 members. What breaks in your design?"

## 7. The Ideal Discussion
> *"Ordering: client timestamps are untrustworthy — clocks drift. The server assigns a strictly monotonic `sequence_id` per conversation. The pending local message renders at the bottom using its local timestamp as a placeholder; when the ack arrives with the official sequence, the list re-sorts. Eventual consistency, and the user never sees their own message jump backward more than once.
> 
> Group chats stress two spots. The outbox is fine — sending is still one write. Receiving is not: 200 members means bursts of interleaved messages, so per-message UI updates become 200 view invalidations a second. The fix is batching at the ModelActor boundary — apply WebSocket payloads in transactions and let one save notification re-render the visible window. Read receipts are the real scaling trap: per-member-per-message receipts are O(members × messages) rows. I'd aggregate server-side — 'read up to sequence N per member' — one row per member, and the client renders receipt state by comparing sequence numbers, not by joining a receipts table."*
