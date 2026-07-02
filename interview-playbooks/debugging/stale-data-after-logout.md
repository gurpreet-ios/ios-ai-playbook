# Mock Interview: Debugging — Stale Data After Logout

*(Question Type 2: unfamiliar codebase, vague symptom. This one tests state-ownership thinking — where can old data possibly live?)*

## 1. The Prompt
**Interviewer:** "Support ticket: 'I logged out, my colleague logged in on the same iPad, and she saw *my* drafts and my avatar for a few seconds.' Intermittent, can't repro reliably. Repo and LLM are yours."

## 2. Expected Reasoning
This is an *inventory* problem disguised as a bug hunt. Data survived a session boundary, so the winning move is enumerating every place session-scoped data can live, then auditing logout against that list:
1. In-memory singletons and caches (ViewModels, stores, `NSCache`)
2. Disk: SwiftData/Core Data stores, files, `UserDefaults`
3. `URLCache` (cached API responses replay for the next user!)
4. Keychain (survives even app *deletion*)
5. In-flight requests started under the old session that complete after logout
6. Widgets/extensions reading a shared App Group container

The "for a few seconds" detail is gold: it smells like an in-flight request or an in-memory cache serving one last hit before being refreshed — the interviewer wants to see you *use* that clue. Security framing earns senior points: this isn't jank, it's a data-exposure incident.

## 3. The Poor Answer
> *"Sounds like the profile ViewModel isn't getting reset. I'll find the logout function and add code to nil out the user object and pop to the login screen. If it's intermittent it's probably a race — maybe add a small delay before showing login."*

**Why it's poor:** Fixes one suspect without inventorying the rest (the drafts *and* the avatar leaked — two different subsystems). "Add a delay" is race-condition folklore. And treating it as UI jank rather than cross-user data exposure misses the actual severity.

## 4. The Great Answer
> *"First, severity: this is user A's data rendering for user B — a privacy incident, so the fix must be provably complete, not spot-fixed.
>
> The mechanism question is 'where can session data outlive logout?' I'll have the LLM build that inventory from the code rather than guess: every singleton, cache, store, and default keyed by (or implicitly containing) user data, plus what the logout path currently tears down. The diff between those two lists *is* the bug — likely several bugs.
>
> The 'few seconds' clue suggests at least one dynamic leak: an in-flight request authorized as user A completing after user B logs in, or an in-memory cache serving stale until its first refresh. So the fix has two shapes: a complete teardown (enumerable, testable) and a *generation token* — logout increments a session generation; responses and cache reads tagged with an old generation are discarded on arrival. That converts 'we hope we cancelled everything' into 'stale data is structurally unrenderable.'"*

## 5. Driving the LLM

> **Inventory:** "Search this codebase and list every place user-scoped data can persist or be cached: singletons holding models, `NSCache`/dictionaries, SwiftData or file storage, `UserDefaults` keys, `URLCache` config, Keychain items, App Group containers. Output a table: location, what it holds, session-scoped or device-scoped."

> **Audit the teardown:** "Now show me the logout implementation and diff it against that table: which entries does it clear, which does it miss? Don't fix anything yet."

> **Explain the clue:** "It reproduces as 'wrong data for a few seconds, then correct.' Which of the missed entries — plus any in-flight request paths — best explains *transient* staleness? Walk the timeline: logout at t0, login at t1, wrong avatar until t2."

> **Fix (two layers):** "Implement (1) a `SessionTeardown` type that clears every session-scoped entry from the table — one function, so the inventory and the teardown can't drift apart — and (2) a session-generation check: bump on logout; the network layer and caches drop any payload tagged with a stale generation. Show me both, smallest possible diff."

> **Regression guard:** "Write a Swift Testing case: populate every session-scoped store with sentinel data, run teardown, assert all cleared. This test should fail if someone adds a new session cache without registering it — tell me how you'd enforce that registration."

**What you're watching for:** the LLM clearing the obvious ViewModel and declaring victory, forgetting `URLCache` (almost everyone forgets `URLCache`), suggesting Keychain wipe for *device*-scoped items (breaking "remember this device"), or a teardown scattered across five call sites that will drift the first time someone adds a cache.

## 6. The Follow-Up (Mid-Interview Extension)
**Interviewer:** "Turns out the app also ships a home-screen widget showing the user's latest draft, and a Share Extension. Your teardown runs in the main app. Extend the fix."

## 7. The Ideal Discussion
> *"Process boundaries change the rules: the widget doesn't share my process, my memory, or my teardown call — it reads the App Group container on its own schedule. So logout must (1) clear the shared container's session-scoped payloads, (2) call `WidgetCenter.reloadAllTimelines()` so the widget re-renders from the now-empty store rather than showing its last snapshot — and the widget needs an explicit signed-out placeholder state, because 'no data' must render as 'logged out', not as a frozen stale draft. The extension follows the same rule via shared Keychain access groups: it authenticates per-invocation against the shared credential, so killing the credential *is* its teardown.
>
> The durable lesson I'd state to close: session state needs an *owner and a registry*. Every cache anyone adds registers a teardown handler in one place; logout iterates the registry; the sentinel test fails when registration is skipped. On top of that, the generation token remains the backstop for everything asynchronous — processes and requests you can't synchronously reach get filtered at render time. Defense in depth: enumerate what you can, invalidate-by-construction what you can't."*
