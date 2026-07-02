# Mock Interview: Debugging — Crash on Older Devices

*(Question Type 2: unfamiliar codebase, vague symptom. This one tests triage discipline — "crash" is four different problems wearing one word.)*

## 1. The Prompt
**Interviewer:** "Reviews say: 'crashes constantly on my iPhone', all from older devices. Our crash reporter shows nothing unusual. Repo, a sample crash log from Xcode Organizer, and an LLM are yours."

## 2. Expected Reasoning
The single sentence "crash reporter shows nothing" is the whole question. A senior candidate knows the taxonomy of "crash" on iOS and that **most of them never reach a crash reporter**:
1. **Real crashes** (exceptions, force-unwraps) — reporter catches these. Reporter is quiet → probably not this.
2. **Jetsam / memory-pressure kills** — the OS terminates the app; no crash callback fires. Users call it a crash. Older devices have less RAM → fits the symptom *exactly*.
3. **Watchdog kills** (`0x8badf00d`) — main thread blocked too long at launch/foreground; slower chips blow the budget flagships pass. Also invisible to most reporters.
4. **Availability crashes** — newer API on older OS; would show in the reporter, so lower-ranked here.

The evaluated skill: reading the *shape* of the evidence (which reporter, which devices, what the Organizer log's termination reason says) before reading any code.

## 3. The Poor Answer
> *"If it crashes on older devices it's probably an iOS version issue — I'll ask the LLM to scan for APIs newer than our deployment target and wrap them in `#available`. Also I'll add more `guard let` around the force-unwraps. Then we wait for the next release to see if reviews improve."*

**Why it's poor:** It skips the evidence entirely — availability crashes would *appear in the crash reporter*, which is silent. "Scan and wrap everything" is shotgun surgery, and "wait for reviews" is a two-week feedback loop when the Organizer log in hand would answer the question in five minutes.

## 4. The Great Answer
> *"'Reporter is quiet but users see crashes' narrows this to the kill types reporters miss: jetsam and watchdog. Older-devices-only fits both — less RAM, slower cores.
>
> Evidence first: the Organizer crash log's termination reason. Jetsam logs show memory-pressure termination (and Xcode's Organizer surfaces disk-write and hang reports separately); watchdog kills show `0x8badf00d` with the main thread pinned in the backtrace. MetricKit's `MXCrashDiagnostic` and hang/memory payloads give the same taxonomy from the field.
>
> If it's jetsam, the code question becomes 'what's our peak footprint on a 2–3GB device?' — suspects: full-resolution image decodes, unbounded caches, everything-loaded-at-once data layers. If it's watchdog, the question is 'what runs on the main thread at launch?' — synchronous DB migrations, disk I/O in `App.init`, blocking network in the first render.
>
> Either way I state the hypothesis, confirm it in code with the LLM's map, fix the smallest cause, and — critically — define the metric that proves it in the field: MetricKit memory-peak and hang-rate percentiles by device class, not review sentiment."*

## 5. Driving the LLM

> **Read the evidence:** "Here's the raw Organizer crash log. Classify the termination: exception, jetsam, or watchdog — cite the fields (termination reason, exception code, main-thread backtrace) that decide it, and state your confidence. If the log is ambiguous, list what additional diagnostic (MetricKit payload type) would disambiguate."

> **Map the suspect surface:** *(assuming jetsam)* "Map this codebase's memory behavior: every place we decode images (and at what resolution), every cache and its eviction policy or lack of one, anything that loads collections unbounded. Table: location, worst-case footprint driver, bounded or unbounded."

> **Rank and confirm:** "Given a 2GB device budget, rank those by likely contribution to a memory kill during normal browsing. For your top pick, walk the allocation path and estimate the math — e.g., 12-megapixel JPEGs decoded full-res for 160pt cells at ~4 bytes/pixel."

> **Fix (bounded):** "Fix the top-ranked cause only: downsample at decode to target pixel size, set `totalCostLimit` on the caches with byte-cost accounting, and respond to memory-pressure notifications by purging. Everything else goes on the filed-not-fixed list."

> **Verify + guard:** "Describe verification on a low-RAM device or simulated memory pressure: Allocations track through a scripted browse, before/after peak. Then wire a MetricKit subscriber so jetsam and hang diagnostics reach our telemetry — the reporter blindspot is the reason this bug lived long enough to hit reviews."

**What you're watching for:** the LLM conflating jetsam with leaks (a leak *grows*; a footprint spike kills instantly — different fixes), recommending `autoreleasepool` incantations without an allocation theory, or "fixing" watchdog symptoms by moving the migration to a detached task with no coordination — trading a kill for a race.

## 6. The Follow-Up (Mid-Interview Extension)
**Interviewer:** "The Organizer log actually says `0x8badf00d` — watchdog at launch, not memory. And it only fires on first launch after an app update. Re-plan in two minutes."

## 7. The Ideal Discussion
> *"Good — that re-scopes everything: watchdog at first-launch-after-update means the main thread exceeds the launch budget doing something *update-specific*, and the classic suspect is a synchronous store migration: new schema version ships, migration runs inline on first launch, old devices churn through it slower than the watchdog allows. Second-tier suspects: cache rebuilds after invalidation-by-version, or a 'what's new' asset preload.
>
> Confirm: the backtrace's main-thread frames — if they're in SwiftData/Core Data migration machinery, done. The fix is architectural, not cosmetic: launch must render *something* within the budget, so heavy migration moves off the critical path — lightweight/staged migration where the store supports it, or a migration screen: first frame renders immediately, migration runs off-main with progress, the full UI gates on completion. What you must never do is leave 'usually fast enough' migration inline and hope — watchdog budgets are a hard contract, and older hardware is where 'usually' goes to die.
>
> And the field-proof loop closes the same way as before: MetricKit launch-time and hang diagnostics segmented by device class and app version, so the *next* migration regression shows up in a dashboard, not in one-star reviews."*
