---
title: "Chapter 17: Reviewing AI-Generated Code"
---

> "Trust the LLM to write the syntax. Never trust it to define the architecture."

Reviewing AI-generated code requires a completely different mental model than reviewing human-generated code. Humans usually make localized mistakes (a typo, a missed edge case). AI makes *systemic* mistakes. It will confidently invent an entirely new dependency injection framework if it thinks it will solve the problem.

This chapter teaches you how to review the code your AI agents produce.

---

## 1. The Common Hallucinations

AI models are probabilistic prediction engines. If they lack context, they will guess. 

**What to look for:**
- **Phantom APIs:** The AI uses a method that doesn't exist in the current version of the SDK. (e.g., using iOS 17 features when your target is iOS 15).
- **Made-up Dependencies:** The AI assumes you have `Alamofire` or `RxSwift` installed and writes code using their syntax.
- **Lost Context Variables:** The AI references a variable it deleted three steps ago in the prompt chain.

**How to review:**
*Always run a strict compiler build before you even look at the diff.* If it compiles, the phantom APIs are ruled out.

## 2. Over-Abstraction

Humans get tired. AI does not. If you ask an AI to "build a generic networking layer," it might generate 14 protocols, 6 wrapper classes, and a custom type-erased enum just to make a single GET request.

**What to look for:**
- Interfaces that only have one implementation.
- Generics with 3+ constrained types for simple data fetching.

**How to review:**
Ask yourself: *"Would a senior engineer at my company actually write this by hand?"* If the answer is no, reject the code and prompt the AI to simplify: *"Remove the generics. Hardcode this for the `User` model only. We do not need this level of abstraction yet."*

## 3. Architecture Drift

This is the most dangerous flaw. Because AI models are trained on the internet, they default to the "average" internet solution (which is usually a Massive View Controller or a tightly coupled singleton).

**What to look for:**
- A SwiftUI View that suddenly contains database write logic.
- A ViewModel that imports `UIKit`.
- State that is managed via `UserDefaults` instead of your established `Redux` store.

**How to review:**
Do not manually fix this. If you manually fix architecture drift, you become the junior developer cleaning up after the AI. Instead, use a Context Anchor: *"You drifted from our architecture. Review `adrs/004-state-management.md` and rewrite this file to comply."*

## 4. Unused States & "Dead Code"

AI is hesitant to delete code unless explicitly told to. During iterative generation, it will often leave behind obsolete `@State` properties or old helper functions.

**What to look for:**
- Variables that are declared and mutated but never read.
- View modifiers that cancel each other out.

**How to review:**
Use an LLM to review the LLM. 
> *"Act as a merciless code reviewer. Analyze this file and highlight any variables, states, or functions that are completely unused or redundant."*

## 5. The "Happy Path" Bias

AI writes the perfect code for the perfect scenario. It rarely considers what happens when the user goes into a tunnel on a 3G connection while the database is locked.

**What to look for:**
- Empty `catch` blocks (`catch { print(error) }`).
- Missing loading states in the UI.
- No timeout handling on network calls.

**How to review:**
Force the adversarial mindset. 
> *"I am reviewing this code. Assume the network takes 15 seconds to respond, and the user hits the 'Save' button 4 times rapidly. How does this code break? Fix it."*

---

By shifting your focus from syntax errors to architectural integrity, you can safely shepherd massive volumes of AI-generated code into production without sacrificing stability.
