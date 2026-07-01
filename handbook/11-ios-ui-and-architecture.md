# Chapter 11: iOS UI and Architecture

> "SwiftUI is a state-driven framework. If you fight the state, you fight the framework. If your AI fights the state, it generates garbage."

When developing for iOS natively, the user interface layer has undergone a radical transformation from imperative (UIKit) to declarative (SwiftUI). 
For AI-native engineers, this shift is a massive advantage: LLMs are exceptionally good at writing declarative UI because the structure of the code perfectly mirrors the visual hierarchy.

---

## 1. SwiftUI

### Definition
Apple's modern, declarative framework for building user interfaces across all Apple platforms. It uses a struct-based hierarchy driven by data bindings.

### AI Prompting Strategy
When prompting an LLM to generate SwiftUI, you must enforce strict constraints to prevent it from hallucinating UIKit paradigms.
* **Bad Prompt:** "Build a settings screen."
* **Senior Prompt:** "Build a `SettingsView` in SwiftUI. Use `Form` and `Section` components. All state must be injected via `@Environment` or passed down as `@Binding`. Do NOT use `@State` internally unless the state is purely ephemeral (like a disclosure group's expanded state)."

### Tradeoffs
- **Pros:** Massively reduced boilerplate; AI can generate full screens with perfect preview fidelity in seconds.
- **Cons:** Complex view hierarchies can lead to massive recompilations if state isn't scoped correctly.

### Interview Answer
> *"I use SwiftUI for 95% of new development. Its declarative nature is perfect for rapid iteration and state-driven design. However, for ultra-complex text rendering or legacy integration, I still drop down to `UIViewRepresentable`."*

---

## 2. UIKit (Legacy Integration)

### Definition
Apple's original imperative UI framework. While largely superseded by SwiftUI for new views, it remains the foundation of iOS and is heavily present in legacy codebases.

### AI Prompting Strategy
When refactoring or interacting with UIKit, you must explicitly tell the AI about the memory management model (ARC).
* **Senior Prompt:** "Refactor this `UIViewController`. Extract the table view logic into a separate `UITableViewDataSource`. **CRITICAL:** Ensure all delegate references are `weak` to prevent retain cycles."

### Tradeoffs
- **Pros:** Unparalleled control over the rendering pipeline; vast ecosystem of libraries.
- **Cons:** Highly imperative, prone to Massive View Controller anti-patterns, and difficult for AI to reason about due to dispersed lifecycle methods (`viewDidLoad`, `viewDidAppear`).

---

## 3. Navigation

### Definition
Moving the user between screens. In SwiftUI, this evolved from `NavigationView` (deprecated) to `NavigationStack` and `NavigationSplitView`.

### Architecture: The Router Pattern
Do not let the AI scatter `NavigationLink` throughout your views. Force it to use a Router.
* **Architecture Rules:** Define a `enum Route: Hashable` and use a state-driven `NavigationPath` inside a router class.

### AI Prompting Strategy
* **Senior Prompt:** "Implement navigation for this flow using iOS 16+ `NavigationStack` and `NavigationPath`. Create a `Router` class (Observable) that manages the path. The views should NOT contain any hardcoded `NavigationLink` destinations; they should only call `router.navigate(to:)`."

---

## 4. Animation

### Definition
Fluid transitions between state changes. Apple platforms pride themselves on butter-smooth 120Hz animations.

### AI Prompting Strategy
AI models often default to jarring, linear animations or forget them entirely. You must specify the animation curve.
* **Senior Prompt:** "Animate the appearance of this subview. Do not use `.linear`. Use `.spring(response: 0.4, dampingFraction: 0.7)` for a natural Apple-like bounce. Ensure the transition uses `.opacity.combined(with: .scale)`."

### Code Review Focus
When auditing AI-generated animations, watch for:
1. Animating the wrong state properties (causing the whole screen to redraw).
2. Forgetting to use `.transaction { $0.animation = nil }` when you explicitly *want* an instant update.
