# Chapter 24: Cheat Sheets

> Keep this open on your second monitor. 

This is the rapid-fire reference guide for AI-Native Engineering.

---

## 1. The Prompt Anatomy Cheat Sheet

Every senior prompt must contain these 4 elements:

1. **Role:** `You are a Principal iOS Engineer.`
2. **Context:** `Read @adrs/001-swiftdata.md and @adrs/002-observation.md.`
3. **Task:** `Implement the ProfileViewModel and ProfileView.`
4. **Constraint:** `You MUST use @MainActor. Do NOT import UIKit.`

---

## 2. The Context Engineering Cheat Sheet

If the AI hallucinates, you violated one of these rules:

- **Rule of Locality:** Keep the files you feed the AI small (under 500 lines). Extract large functions before prompting.
- **Rule of Anchoring:** Always inject an ADR or a strict Architecture rule file (`.cursorrules`).
- **Rule of Iteration:** Never ask for a whole feature at once. Ask for the Model, then the ViewModel, then the View.

---

## 3. The Debugging Heuristics Cheat Sheet

When the AI gives you a bug, don't just say "this crashed, fix it." Form a hypothesis first:

| Symptom | Probable Cause | AI Prompt Direction |
| :--- | :--- | :--- |
| **Crash on Navigation (SwiftUI)** | State mutated off Main Thread. | *"Audit this ViewModel for MainActor violations."* |
| **Memory usage steadily climbing** | Retain cycle in an async closure. | *"Check this network closure for strong `self` capture. Fix with `[weak self]`."* |
| **Stuttering / Dropped Frames** | Heavy synchronous work in `body`. | *"Extract the date formatting out of this View's body and cache it."* |
| **Offline data is stale** | Wrote to a background DB context. | *"Verify that the background ModelContext is saving and merging to the Main UI context."* |

---

## 4. The Agentic IDE Cheat Sheet (Cursor/Windsurf)

- **`Cmd+K` (Inline Edit):** Best for localized algorithmic fixes (e.g., *"Refactor this map/filter chain to be O(N)"*).
- **Composer / Flow:** Best for multi-file generation (e.g., *"Generate a Settings feature based on `@SettingsRFC.md`."*).
- **`.cursorrules` / `.windsurfrules`:** The most important file in your repository. It dictates the AI's default behavior.

---

## 5. The Interview Cheat Sheet

When asked a System Design or Machine Coding question:
1. **Define Constraints first:** DAU, Offline support, Security.
2. **Establish the boundaries:** "The View will only talk to the ViewModel. The ViewModel will only talk to the Repository."
3. **Analyze Tradeoffs openly:** "I am choosing SwiftData over CoreData for velocity, acknowledging we lose iOS 16 support."
4. **Embrace the Adversary:** "If the network drops exactly when this function runs, we have a corrupted state. Here is how I will wrap it in a transaction."
