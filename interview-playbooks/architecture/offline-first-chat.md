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

## 5. The Follow-Up
**Interviewer:** "What happens if a user is offline, sends a message, and at the exact same time, their friend sends them a message. When they come back online, how do you resolve the order of messages in the chat?"

## 6. The Ideal Discussion
> *"Relying on client-side timestamps is dangerous because device clocks can drift. I would implement a hybrid ordering system. 
> 
> The server assigns a strictly monotonic `sequence_id` (or uses Vector Clocks/Lamport Timestamps) to every message it processes. When the client reconnects, it pulls the latest sequence. 
> 
> For UI rendering, I will display the `pending` local message at the bottom of the feed using its local timestamp as a placeholder. Once it syncs and receives its official `sequence_id` from the server, the list is re-sorted based on the server's sequence. This ensures eventual consistency across all devices."*
