---
title: "Chapter 10: System Architecture"
---

> "AI can write functions. It cannot write systems. You must define the boundaries."

If the Presentation layer is how the application looks, the System Architecture is how the application survives. It dictates how data is fetched, how modules communicate, and how business rules are protected from UI framework churn.

When working with AI, System Architecture is your ultimate leverage. By giving the AI clear interfaces and isolated modules, you bound its context and eliminate hallucinations.

---

## 1. Clean Architecture

### Definition
Introduced by Uncle Bob, Clean Architecture separates software into concentric layers (Domain, UseCases, Interface Adapters, Frameworks). The defining rule is the **Dependency Rule**: dependencies must only point *inward* toward the Domain.

### When to Use
- Complex enterprise applications that will live for 5+ years.
- When the business logic is complex and must be decoupled from UI frameworks (e.g., migrating from UIKit to SwiftUI).

### When NOT to Use
- Prototyping or highly UI-driven apps with no complex business rules.

### Tradeoffs
- **Pros:** Ultimate testability; you can test the entire business logic without launching a UI or mocking a database.
- **Cons:** High cognitive overhead and file bloat (you often need DTOs, Domain Entities, and ViewModels mapping to the same concept).

### Interview Answer
> *"Clean Architecture is the gold standard for separating business rules from infrastructure. The Dependency Rule ensures that my core logic doesn't care if we use CoreData or SwiftData. The tradeoff is the mapping boilerplate across boundaries, which I mitigate by having AI generate my DTO-to-Domain mappers."*

### AI Prompts
- **Scaffolding:** `prompts/architecture/clean-architecture-scaffold.md`
- **Review:** *"Audit this UseCase. Flag any import of UI frameworks (UIKit/SwiftUI). Ensure it only depends on Repository interfaces, not concrete implementations."*

---

## 2. Feature Modules (Modular Architecture)

### Definition
Instead of organizing code by layer (e.g., all ViewModels in one folder), code is organized by Feature (e.g., `SearchFeature`, `CheckoutFeature`). These features are often isolated into separate physical frameworks (Swift Packages or Gradle modules).

### When to Use
- Large codebases with multiple engineers.
- When build times are becoming a bottleneck.

### When NOT to Use
- Small apps where the overhead of managing module dependencies outweighs the build-time benefits.

### Tradeoffs
- **Pros:** Drastically reduces build times; prevents features from tangling together (spaghetti code).
- **Cons:** Requires a strict dependency injection strategy to allow features to navigate to one another without circular dependencies.

### Interview Answer
> *"I always push for Feature Modules in teams of 3 or more. By isolating features into Swift Packages, we get enforced access control—you literally cannot import a private internal class from another feature. It also forces us to define clear API contracts for how features communicate."*

### AI Prompts
- **Scaffolding:** *"Generate a new Swift Package for the `OnboardingFeature`. Include a public API file, and keep all UI and logic `internal`."*

---

## 3. The Repository Pattern

### Definition
Abstracts data access logic behind an interface. The rest of the app asks the Repository for a `User`, and the Repository decides whether to fetch it from the Network, the Disk, or memory.

### When to Use
- When you need caching.
- When integrating with external APIs.

### When NOT to Use
- If the app just writes directly to a local DB with no remote syncing (though even then, it's cheap insurance).

### Tradeoffs
- **Pros:** Hides the complexity of data orchestration; makes the UI layer completely agnostic to networking.
- **Cons:** Can become a dumping ground for all data-related methods if not scoped correctly.

### Interview Answer
> *"The Repository pattern is essential for any app that works offline. It allows the ViewModel to simply say 'give me the user', while the Repository handles the complexity of checking the cache, firing a network request, and saving the result back to disk."*

### AI Prompts
- **Scaffolding:** *"Implement a `UserRepository` conforming to `UserRepositoryProtocol`. It must fetch from `NetworkClient` first, fallback to `DiskCache`, and handle all mapping from DTOs to Domain entities."*

---

## 4. Coordinator Pattern

### Definition
Extracts navigation logic out of the View and ViewModel into a dedicated `Coordinator` class. 

### When to Use
- When screens need to be reusable in different flows (e.g., a "Profile" screen accessed from Settings and from a Chat).
- When using UIKit.

### When NOT to Use
- Simple, linear SwiftUI apps (SwiftUI's `NavigationStack` with `NavigationPath` often reduces the need for heavy UIKit-style Coordinators).

### Tradeoffs
- **Pros:** Massive reusability of views; deep-linking becomes trivial.
- **Cons:** Managing the Coordinator hierarchy can get complex and leak memory if delegates aren't weak.

### Interview Answer
> *"Coordinators solve the massive View problem by taking over routing. In UIKit, they are mandatory. In SwiftUI, I adapt them into `Router` objects that manage a `NavigationPath`, keeping the Views completely ignorant of where they go next."*

---

## 5. Advanced Patterns: DDD, CQRS, Hexagonal

For Senior/Staff roles, you must be familiar with backend-derived patterns, even on mobile.

* **Domain-Driven Design (DDD):** Focusing on the core domain logic and ubiquitous language. Useful when business logic is highly complex (e.g., FinTech).
* **CQRS (Command Query Responsibility Segregation):** Separating read operations (Queries) from write operations (Commands). Extremely useful in complex offline-sync scenarios where reading from a local DB is fundamentally different than writing to a server.
* **Hexagonal Architecture (Ports and Adapters):** Similar to Clean Architecture, focusing on the application core communicating with the outside world via Ports (Interfaces) and Adapters (Implementations).

### AI Prompts for Advanced Systems
- **Scaffolding:** *"Generate a CQRS architecture for the `OrderService`. Define the `Command` models for creating orders, and the `Query` models for fetching order history."*
