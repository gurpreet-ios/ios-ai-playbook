# Chapter 9: Presentation Architecture

> "If you do not strictly define the boundaries of your presentation layer, the AI will invent its own."

AI models are stochastic. They do not naturally adhere to strict boundaries unless explicitly forced to. In this chapter, we explore the most common Presentation Architectures (the UI layer). For each pattern, we define the tradeoffs, how to answer interview questions about them, and crucially, how to prompt the AI to generate and review them.

---

## 1. MVVM (Model-View-ViewModel)

### Definition
MVVM separates the UI (View) from the business logic and state (ViewModel). The ViewModel exposes observable streams of data that the View binds to. It is the de facto standard for modern declarative frameworks like SwiftUI and Jetpack Compose.

### When to Use
- The default choice for 90% of modern mobile and web applications.
- When using reactive/declarative UI frameworks (SwiftUI, React, Compose).

### When NOT to Use
- Extremely simple CRUD screens where the ViewModel just passes data through.
- Massive, hyper-complex screens with dozens of independent state streams (can lead to "Massive ViewModel").

### Tradeoffs
- **Pros:** Excellent separation of concerns, highly testable, native support in modern SDKs.
- **Cons:** Can lead to massive ViewModels; routing/navigation is often awkwardly shoehorned into the ViewModel.

### Interview Answer
> *"I prefer MVVM for declarative frameworks because it perfectly aligns with data-binding. However, my main critique of vanilla MVVM is that it lacks a dedicated router, meaning navigation logic often bleeds into the view or the ViewModel. I usually solve this by combining MVVM with a Coordinator pattern."*

### AI Prompts
- **Scaffolding:** `prompts/architecture/mvvm-scaffold.md` 
  - *"Generate the ViewModel and View using MVVM. The ViewModel must be fully isolated on the MainActor, and all state must be marked `@Published` (or `@Observable`)."*
- **Review:** `prompts/review/mvvm-audit.md`
  - *"Review this ViewModel. Flag any UIKit/Foundation imports that belong in the View. Flag any missing `MainActor` annotations."*

---

## 2. MVI (Model-View-Intent)

### Definition
MVI builds on MVVM by enforcing a strictly unidirectional data flow. The View sends `Intents` to the Model/ViewModel, which processes them and emits a single, immutable `State` object back to the View.

### When to Use
- Applications with highly complex state machines (e.g., video editors, complex forms).
- When debugging state consistency is a primary concern.

### When NOT to Use
- Simple list-and-detail apps. The boilerplate of defining Actions, States, and Reducers will slow you down unnecessarily.

### Tradeoffs
- **Pros:** State is perfectly predictable; easy to reproduce bugs by replaying Intents.
- **Cons:** High boilerplate; minor UI updates (like typing in a text field) must route through the entire intent loop.

### Interview Answer
> *"MVI shines when state management becomes a nightmare. By forcing all changes through a single intent channel and rendering a single immutable state, you eliminate race conditions. The tradeoff is velocity—you write more boilerplate. I reserve MVI for core, high-complexity features."*

### AI Prompts
- **Scaffolding:** *"Implement this feature using MVI. Define `State` as a single struct. Define `Intent` as an enum. The ViewModel should have a single public `process(intent:)` function."*

---

## 3. VIPER (View-Interactor-Presenter-Entity-Router)

### Definition
VIPER is an implementation of Clean Architecture specifically for iOS. It separates logic into 5 distinct layers, completely isolating UI, business rules, and navigation.

### When to Use
- Massive enterprise applications (e.g., Uber, Banking apps) with 50+ engineers.
- When you need aggressive separation of concerns to prevent merge conflicts.

### When NOT to Use
- Small to medium apps.
- When using SwiftUI (VIPER was designed for UIKit and struggles with declarative state binding).

### Tradeoffs
- **Pros:** Maximum testability; every component has exactly one responsibility.
- **Cons:** Unbearable boilerplate. Creating a simple screen requires 5 files and 5 protocols.

### Interview Answer
> *"VIPER is fantastic for isolating domains in massive teams using UIKit. However, I believe it is largely obsolete for SwiftUI. The tight coupling of Presenter-to-View protocols fights against SwiftUI’s natural state-binding mechanisms."*

### AI Prompts
- **Scaffolding:** *"Generate a VIPER module for the Login feature. Create the 5 protocols and classes. Ensure the Router handles all navigation and the Interactor has zero knowledge of UIKit."*

---

## 4. Redux (TCA - The Composable Architecture)

### Definition
Derived from React, Redux (and its Swift equivalent, TCA) relies on a single global `Store`. The state is immutable and can only be changed by dispatching `Actions` to a pure function called a `Reducer`.

### When to Use
- Apps where global state needs to be accessed and mutated from many disparate screens.
- When you want unparalleled testability (testing reducers is literally just `state + action = new state`).

### When NOT to Use
- Rapid prototyping.
- Teams unfamiliar with functional programming concepts.

### Tradeoffs
- **Pros:** State predictability is flawless. Testing is trivial. Excellent ecosystem (like pointfreeco's TCA).
- **Cons:** Very steep learning curve. The global store can become a performance bottleneck if not modularized correctly.

### Interview Answer
> *"I am a huge proponent of Redux/TCA for apps with complex shared state. The ability to write exhaustive tests that verify not just state changes, but also asynchronous side effects, is unmatched. However, I avoid it if the team lacks functional programming experience, as the paradigm shift can severely hurt velocity."*

### AI Prompts
- **Scaffolding:** `prompts/architecture/ios-tca-feature.md`
  - *"Generate the State, Action, Environment, and Reducer for a TCA module."*
- **Review:** *"Audit this Reducer. Ensure no side-effects are performed outside of the `Effect` (or `run`) closure. Verify State is not mutated asynchronously."*

---

*In the next chapter, we will move beneath the UI layer and explore **System Architectures** like Clean, DDD, and Repository patterns.*
