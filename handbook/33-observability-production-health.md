# Chapter 33: Observability & Production Health

> "The crash reporter shows nothing' and 'the users see crashes' are both true. If your telemetry can't hold those two facts at once, you don't have observability — you have a dashboard."

Chapters 15 and 16 debugged what you could reproduce. Production health is the other half: knowing what a million devices are experiencing when you can't attach Instruments to any of them. The AI-era twist runs in both directions — agents generate more code than you can hand-instrument, *and* an LLM turns out to be the best crash-log reading partner you've ever had, provided you feed it evidence instead of vibes.

## 1. The Reporter Blindspot (Start Here)

The debugging playbook's central taxonomy (`interview-playbooks/debugging/crash-on-older-devices.md`) is an observability requirement, not just interview material. Third-party crash reporters catch *exceptions*. They largely miss:

- **Jetsam** — memory-pressure kills. No crash callback fires; users call it a crash.
- **Watchdog kills** (`0x8badf00d`) — main thread blocked past the launch/foreground budget.
- **Hangs** — the app didn't die, it just stopped responding; the reporter has nothing to report.

If your only telemetry is a crash reporter, entire failure classes are invisible until they surface as one-star reviews — the slowest, most public alerting channel in software. **MetricKit closes the blindspot** and is first-party, free, and privacy-clean:

```swift
final class TelemetrySubscriber: NSObject, MXMetricManagerSubscriber {
    func didReceive(_ payloads: [MXDiagnosticPayload]) {
        for payload in payloads {
            upload(payload.crashDiagnostics)      // incl. exception + termination reasons
            upload(payload.hangDiagnostics)        // main-thread stalls with backtraces
            upload(payload.diskWriteExceptionDiagnostics)
            // memory: MXMetricPayload carries peak footprint + pressure events
        }
    }
    func didReceive(_ payloads: [MXMetricPayload]) {
        // Daily rollups: launch times, hang rate, memory peaks, battery, hitch rate
        uploadDaily(payloads)
    }
}
```

Register it at launch, ship the payloads to your backend, and you now see the kills the reporter can't. This subscriber is twenty minutes of agent work — prompt for it in your next session and the blindspot is closed permanently.

## 2. The Four Signals Worth Paging On

Resist dashboard sprawl. Four numbers, segmented by **device class and app version** (the segmentation is where the diagnosis lives — Chapter 16's "older devices only" clue was a segmentation, not a metric):

| Signal | Source | Why it pages |
| :--- | :--- | :--- |
| Crash-free sessions % | Reporter + MetricKit termination data | The headline number; MetricKit adds the kills reporters miss |
| Hang rate (p95) | `MXHangDiagnostic` / Xcode Organizer | "App feels broken" with a backtrace attached |
| Cold launch time (p90) | `MXAppLaunchMetric` | Watchdog margin erosion — the Ch 16 migration crash was visible here *before* it killed |
| Peak memory by device class | `MXMetricPayload` | Jetsam risk on the devices you don't demo on |

Each gets a per-release budget (Chapter 30's gate 6 is the same numbers, pre-release), watched during the phased rollout (Chapter 31). A release that moves a signal against its budget pauses the ramp — that's the whole feedback loop, and every piece of it is mechanical except the pause decision.

## 3. Structured Logging and Signposts: Instrumentation the AI Writes

Unified logging (`os.Logger`) and `os_signpost` intervals are classic AI-boilerplate wins — tedious to write, mechanical to specify, and transformative when a production trace arrives:

> *"Instrument `SyncEngine` with `os.Logger` (subsystem `com.app.sync`, category per operation): log state transitions at `.info`, failures at `.error` with the error — never the payload (privacy: user data is `.private` by default and stays that way). Add `os_signpost` intervals around `fetchTracks`, `upsert`, and `downloadTrackFile` so Instruments can attribute sync time. No logging inside per-item loops."*

The two review points, because the AI gets both wrong by default: **privacy annotations** (interpolated values are redacted unless marked `%{public}` — the model will mark things public to be "helpful"; make it justify each), and **volume** (log state changes, not iterations — an agent instrumenting a loop can hitch the very scroll you're trying to observe).

## 4. AI-Assisted Crash Triage

Here the direction reverses: instead of instrumenting code the AI wrote, you're pointing the AI at evidence production sent back. An LLM is exceptionally good at crash logs — it has read more of them than any human alive — *if* you run the Chapter 16 discipline (hypothesis, evidence, bounded fix) instead of pasting and praying:

> *"Here is a symbolicated crash log and the MetricKit diagnostic from the same session. (1) Classify the termination: exception, jetsam, or watchdog — cite the fields that decide it. (2) Given the top 10 frames, state your best hypothesis and your confidence. (3) List what evidence would change your mind. Do NOT propose a code fix yet."*

The staged prompt matters: classification before hypothesis, hypothesis before fix, and an explicit invitation to express uncertainty — the anti-sycophancy hook from the debugging playbooks, because a model that commits early to your framing will defend it against the evidence.

Two force multipliers:

- **Symbolicate before prompting.** Address soup wastes the model; dSYM-resolved frames are what it reasons over. Symbolication is pipeline work (Chapter 31's lanes), not per-incident heroics.
- **Triage clusters, not instances.** Group by top frame, feed the LLM one representative per cluster plus the cluster's device/version histogram. "90% of this cluster is iPhone 12 on the new build" *is* the hypothesis, machine-assembled.

## 5. The Observability Review

One more standing audit for the Chapter 14 rotation — because agents ship features, and features ship blind by default:

> *"Review this PR for production observability: (1) if this feature fails in the field, what log line or metric tells us — name it, or flag the gap; (2) any new failure path that swallows errors (`try?`, empty catch) without telemetry; (3) any logging of user content or identifiers that violates the privacy rules; (4) long-running operations lacking signpost intervals. For each gap, propose the minimal instrumentation — not a logging framework."*

"If this fails, how do we know?" is the review question that costs one sentence in a PR and saves a week of blind debugging six months later.

## 6. The Loop, Closed

Assembled: MetricKit + reporter feed four budgeted signals → phased rollout watches them per release → regressions pause the ramp → clustered diagnostics with LLM triage turn field evidence into hypotheses → Chapter 16's method turns hypotheses into fixes → every fix lands with its regression test (Chapter 26) and, now, its telemetry (this chapter) — so the same failure can neither return silently nor happen loudly without a page.

That is observability in the AI era: the machine watches the fleet, the model reads the evidence, and you — as everywhere in this book — own the two decisions that matter: *what gets a budget, and when to stop the train.*
