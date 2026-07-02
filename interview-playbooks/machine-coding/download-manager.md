# Mock Interview: Download Manager

## 1. The Prompt
**Interviewer:** "Build a download manager for a podcast app: users queue episodes, downloads continue when the app is backgrounded, show progress, and can be paused and resumed. Drive the LLM."

## 2. Expected Reasoning
This is a platform-knowledge question wearing a machine-coding costume. The layers:
1. **Background `URLSession`** — knowing that `URLSession.shared.data(from:)` dies with the app, and that background downloads require a session created with `URLSessionConfiguration.background(withIdentifier:)`, which hands work to a *system daemon* that outlives your process.
2. **The delegate boundary** — background sessions speak delegate callbacks, not async/await. Bridging that cleanly (delegate → `AsyncStream` of events) is the concurrency test.
3. **Resume data** — pause/resume isn't start/stop; `cancel(byProducingResumeData:)` and re-creating tasks from that data.
4. **Persistence** — the queue must survive relaunch, because the OS may relaunch you *into the background* to deliver completed downloads.

## 3. The Poor Answer
> *"I'll loop over the queue with `try await URLSession.shared.data(from: url)` inside a `Task`, write each file to Documents, and publish progress by wrapping the bytes counter. Pause means cancelling the Task; resume restarts the download."*

**Why it's poor:** Everything dies the moment the user backgrounds the app — the one requirement stated explicitly. In-memory `data(from:)` loads a 200MB episode into RAM instead of streaming to disk. "Resume restarts" throws away hundreds of MB of progress. No relaunch story at all.

## 4. The Great Answer
> *"The core is a background `URLSession` with a stable identifier. Download tasks are handed to the OS daemon, so they run with the app suspended or killed. That forces the architecture: the manager is a singleton-ish actor owning the session, because the session's delegate must be reattached on relaunch — the OS calls `application(_:handleEventsForBackgroundURLSessionEvents:)` and expects the same identifier to reconnect.
>
> The delegate is a small `NSObject` that translates callbacks into an `AsyncStream<DownloadEvent>` (progress, finished-at-tempURL, failed-with-resumeData). The actor consumes the stream and maintains the queue state; the UI observes a `@MainActor` projection of it.
>
> Pause is `cancel(byProducingResumeData:)`; the resume data blob is persisted with the queue entry. Resume creates a new task from it. The queue itself — episode ID, URL, state, resume data — persists in SwiftData, keyed so relaunch can reconcile: on startup, ask the session for its live tasks (`session.tasks`) and match them against persisted state.
>
> One trap I'd call out: in `didFinishDownloadingTo`, the temp file must be moved *synchronously in that callback* — the file is deleted when the callback returns."*

## 5. Driving the LLM

> **Plan:** "Podcast download manager: background downloads, pause/resume with resume data, progress UI, queue survives relaunch. Before code: explain what a background URLSession changes architecturally versus `data(from:)` — who owns the work, what happens on app kill, and how the app reconnects on relaunch. No code yet."

> **Generate (piece 1):** "The delegate bridge only: an `NSObject` `URLSessionDownloadDelegate` that emits an `AsyncStream<DownloadEvent>`. Events: `.progress(id, fraction)`, `.finished(id, tempURL)`, `.failed(id, resumeData: Data?)`. The temp file must be moved to its final location synchronously inside `didFinishDownloadingTo` — add a comment saying why."

> **Generate (piece 2):** "Now the `DownloadManager` actor: `enqueue(episode:)`, `pause(id:)`, `resume(id:)`, `cancel(id:)`. State machine per item: queued → downloading → paused(resumeData) → finished/failed. Max 3 concurrent; the rest wait in queue order."

> **Review hook:** "Two questions before I accept: (1) where does the resume data live if the user pauses and then force-quits? (2) on relaunch, how do we reconcile a download the daemon finished while we were dead?"

**What you're watching for:** the LLM quietly using `URLSession.shared`, moving the temp file inside a `Task { }` (it's gone by then), treating pause as plain `cancel()`, or inventing a `@Published` progress dictionary on the actor that the UI can't legally touch.

## 6. The Follow-Up (Mid-Interview Extension)
**Interviewer:** "Product asks for Wi-Fi-only downloads as a setting, and a progress ring on the app icon via a widget. What changes?"

## 7. The Ideal Discussion
> *"Wi-Fi-only is one line at the right layer and a policy question at the wrong one: `allowsCellularAccess = false` on the session configuration — but changing it doesn't affect tasks already running, so toggling the setting means deciding whether in-flight cellular downloads pause (I'd say yes: produce resume data, re-enqueue) or finish. I'd surface that decision to product rather than guess.
>
> The widget is a process-boundary problem, which is Chapter 13 territory: the widget can't observe the actor. The manager writes coarse progress (episode ID, fraction, updated-at) to the shared App Group container, and the app nudges `WidgetCenter` to reload timelines — throttled, because timeline reloads are budgeted. Per-second progress updates belong in the app; the widget gets 'downloading, 60%' granularity.
>
> If they push on testing: the delegate bridge is the seam. Inject a fake event stream and the whole state machine — including the pause-then-force-quit path — is testable without touching the network."*
