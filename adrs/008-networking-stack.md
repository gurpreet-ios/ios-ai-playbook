# ADR 008: URLSession Actor + Repository over Networking Frameworks

## Status
Accepted

## Context
LLMs trained on a decade of tutorials default to Alamofire/Moya wrappers, closure-based completion handlers, or `URLSession` calls scattered through ViewModels. Meanwhile modern `URLSession` with async/await covers our needs without a dependency, and Swift 6 strict concurrency demands a deliberate isolation story for the network layer.

## Decision
Networking is a **`NetworkClient` actor** over plain `URLSession` async APIs, exposing domain methods (not generic `request()` soup) behind a protocol, returning `Codable, Sendable` **DTOs** — never `@Model` types. HTTP status mapping goes to a typed error enum. ViewModels never see the client: **repositories** (`@MainActor`, per ADR 001's persistence confinement) orchestrate client + store and are the only layer that maps DTO → domain. No third-party networking dependency without a new ADR.

## Consequences
**Positive:**
- Zero dependencies to audit (Ch 32/35 supply-chain surface stays closed).
- The actor gives data-race-free connection/token state under Swift 6.
- DTO boundary keeps `Sendable` violations structurally impossible (Ch 12).
- Protocol surface makes spy-based testing mechanical (Ch 26).

**Negative:**
- We hand-write conveniences frameworks provide (retry, multipart) — AI-generated on demand, reviewed once.
- DTO/domain duplication for simple payloads; accepted as the price of the boundary.

## AI Anchor Usage
Inject when generating anything that touches the network. Anchor phrases: *"Domain methods on the actor, DTOs out, no `URLSession` outside `NetworkClient`, no new networking dependencies."* Pair with ADR 001 when the data lands in SwiftData.
