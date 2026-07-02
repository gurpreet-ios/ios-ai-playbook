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

## The Audit Workflow, End to End

Here is the full loop on a real screen — the Now Playing view from the Part 3 spine app ([`sample-apps/music-interview-app`](../sample-apps/music-interview-app)). The shipped version is the *after*; this is how you get there from what the AI hands you first.

### Step 0: The "Before" — What the AI Generates Unprompted

```swift
// ❌ The first draft: visually perfect, semantically empty
VStack(spacing: 40) {
    RoundedRectangle(cornerRadius: 24)                    // album art
        .fill(Color.secondary.opacity(0.2))

    Text(track?.title ?? "Not Playing")
        .font(.system(size: 28, weight: .bold))           // hardcoded size

    HStack(spacing: 50) {
        Button { … } label: { Image(systemName: "backward.fill") }
        Button { … } label: {
            Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
        }
        Button { … } label: { Image(systemName: "forward.fill") }
    }
}
```

Turn on VoiceOver and swipe through it. The experience, verbatim: *"Button. Button. Button."* Three identical announcements for previous/play/next, an album art image that doesn't exist to the screen reader, and a title that ignores the user's text-size setting. Nothing here is a *bug* by the compiler's standards — which is why this survives every automated gate except the ones in this chapter.

### Step 1: The Static Audit

Feed the file to the review prompt from the previous section (`prompts/accessibility/wcag-audit.md`). A well-anchored model returns a findings table, not vibes:

| Element | Issue | Fix |
| :--- | :--- | :--- |
| Album art `RoundedRectangle` | No label, no `.isImage` trait — invisible or noise to VoiceOver | Label derived from track title |
| Title `Text` | `.font(.system(size: 28))` breaks Dynamic Type | Semantic `.title` + `.bold()` |
| All three transport buttons | Icon-only: announce as "Button" | Explicit `accessibilityLabel` |
| Play/pause button | Label must track state | Conditional label "Play"/"Pause" |
| All buttons when no track | Tappable but do nothing | `.disabled(currentTrack == nil)` — free trait update |

### Step 2: The "After" — Apply and Read the Diff

```swift
// ✅ As shipped in Sources/Views/NowPlayingView.swift
RoundedRectangle(cornerRadius: 24)
    .fill(Color.secondary.opacity(0.2))
    .accessibilityLabel(viewModel.currentTrack.map { "Album Art for \($0.title)" }
                        ?? "No Album Art")
    .accessibilityAddTraits(.isImage)

Text(viewModel.currentTrack?.title ?? "Not Playing")
    .font(.title)                    // semantic → scales with Dynamic Type
    .fontWeight(.bold)

Button {
    Task { await viewModel.togglePlayPause() }
} label: {
    Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
}
.disabled(viewModel.currentTrack == nil)
.accessibilityLabel(viewModel.isPlaying ? "Pause" : "Play")
```

The same VoiceOver swipe now reads: *"Album Art for Karma Police, image. Karma Police. Radiohead. Previous Track, button. Pause, button. Next Track, button."* Note the play/pause label is **state-derived** — a static "Play" label on a button currently showing the pause icon is worse than no label, and it's precisely the kind of half-fix an AI produces when your prompt says "add accessibility labels" instead of "labels must reflect state."

### Step 3: Verify on the Rendered Screen

Source review can't see rendered truth (contrast in dark mode, hit-target sizes, clipped text at AX sizes). Two checks:

- **Manual, 60 seconds:** Accessibility Inspector's audit on the running simulator, then one pass at `AX5` text size — does the layout survive 200%+ text without truncating the title into uselessness? (`.lineLimit(1)` plus huge text is where "after" screens quietly fail.)
- **Automated, forever:** the runtime audit as a regression gate:

```swift
func testNowPlayingAccessibility() throws {
    let app = XCUIApplication()
    app.launch()
    app.tabBars.buttons["Now Playing"].tap()
    try app.performAccessibilityAudit()   // labels, contrast, hit targets, Dynamic Type
}
```

### Step 4: Feed the Lesson Back

Close the loop the same way every audit in this book closes: the findings become rules so the *next* generation starts correct. The five findings above compress to two rules-file lines — semantic fonts only; every icon-only control gets a state-aware label — and those two lines are why the follow-up screens in this app came back accessible on the first prompt.

---

By forcing the AI to think about Accessibility *before* generating code — and wiring the runtime audit into CI so regressions can't land — you save hours of retroactive manual auditing and build truly inclusive products at scale.
