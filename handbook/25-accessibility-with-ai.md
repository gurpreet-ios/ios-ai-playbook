# Chapter 25: Accessibility with AI

> "AI is incredibly fast at generating standard user interfaces. But by default, AI generates interfaces that exclude the roughly one in six people worldwide who live with a significant disability (WHO estimate). You must explicitly mandate accessibility in your prompts."

Accessibility (A11y) is not an afterthought—it is a fundamental requirement for any production iOS application. However, LLMs (Large Language Models) are heavily biased towards generating "visual only" code. If you ask an LLM to build a custom `AudioPlayer` button using a `ZStack` and some shapes, it will do exactly that, but VoiceOver users will only hear "Image."

As a Senior AI Engineer, it is your responsibility to constrain the AI to generate accessible code by default.

## The AI Accessibility Blindspot

When generating SwiftUI code, LLMs frequently omit:
1. **Dynamic Type:** Hardcoding `.font(.system(size: 16))` instead of using `.font(.body)`.
2. **VoiceOver Labels:** Failing to add `.accessibilityLabel("Play")` to custom buttons.
3. **Accessibility Traits:** Failing to mark custom interactive views with `.accessibilityAddTraits(.isButton)`.
4. **Color Contrast:** Using hardcoded hex colors that fail WCAG 2.1 contrast ratios in Dark Mode.

## The Strategy: "Accessibility First" Prompts

You must integrate A11y constraints into your global `.cursorrules` and your specific per-file prompts.

### 1. Global Context (`.cursorrules`)
Add this section to every project's system rules:

```markdown
## Accessibility (A11y) Requirement
Every SwiftUI view you generate must be fully accessible.
- Use Semantic Fonts (`.headline`, `.body`) for Dynamic Type. Do not hardcode font sizes.
- Any non-standard button or interactive element must have `.accessibilityLabel`, `.accessibilityHint`, and `.accessibilityAddTraits(.isButton)`.
- Use localized strings for all user-facing text and accessibility labels.
```

### 2. Specific Prompts
When generating a specific component, reinforce the requirement:

* **Junior Prompt:** "Create a custom toggle switch using a Capsule and a Circle." *(Result: Visually correct, completely invisible to VoiceOver).*
* **Senior Prompt:** "Create a custom toggle switch using a Capsule and a Circle. It must support VoiceOver. Bind the `.accessibilityValue` to 'On' or 'Off', add the `.isButton` trait, and ensure it responds to the `.accessibilityAction { }` modifier."

## Auditing AI Code for A11y

You cannot trust the AI to always remember these rules. Use the AI to audit its own code, or the code of your peers.

**Use this prompt for code review:**
> "Review this SwiftUI file specifically for Accessibility. Identify any missing `.accessibilityLabel` modifiers on images, any hardcoded font sizes that break Dynamic Type, and any interactive elements missing `.accessibilityAddTraits`. Provide a unified diff to fix these issues."

## Automating the Audit in UI Tests

Static review only catches what's visible in the source. Xcode also ships a runtime audit you can call from any XCUITest: `try app.performAccessibilityAudit()`. It inspects the *rendered* screen for missing labels, insufficient contrast, Dynamic Type clipping, and undersized touch targets — the same checks as the Accessibility Inspector, but runnable in CI.

This is the perfect AI pairing: the prompt above fixes the code, and this prompt turns accessibility into a regression gate:

> "Generate an XCUITest suite that launches the app, navigates to each top-level tab, and calls `performAccessibilityAudit()` on every screen. Where a third-party view triggers unfixable issues, use the audit's issue-filtering closure to exempt it — with a comment explaining why."

By forcing the AI to think about Accessibility *before* generating code — and wiring the runtime audit into CI so regressions can't land — you save hours of retroactive manual auditing and build truly inclusive products at scale.
