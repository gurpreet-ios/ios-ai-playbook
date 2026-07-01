---
title: "ADR 001: SwiftData over CoreData"
---

## Status
Accepted

## Context
Our iOS application requires persistent local storage. Historically, this team has used CoreData. However, CoreData requires significant boilerplate (e.g., `NSManagedObject` subclasses, XML `.xcdatamodeld` files, and context merging logic). Furthermore, AI agents struggle to generate the XML schema files natively without using Xcode's UI tools.

## Decision
We will use **SwiftData** as our primary local persistence framework for all new iOS features, starting with iOS 17 as our minimum deployment target.

## Consequences
**Positive:**
- **AI Compatibility:** SwiftData uses the `@Model` macro in pure Swift. AI can generate entire database schemas flawlessly in a single text file.
- **Velocity:** Drastically reduced boilerplate compared to CoreData.
- **Safety:** Native integration with Swift concurrency and strict type safety.

**Negative:**
- **Backward Compatibility:** Drops support for iOS 16 and below.
- **Immaturity:** SwiftData is newer and may lack some of the extreme edge-case optimizations present in 15-year-old CoreData.

## AI Anchor Usage
Inject this ADR into any prompt that requires local database generation to prevent the AI from defaulting to CoreData.
