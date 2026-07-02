# Chapter 26: AI-Driven Testing & TDD

> "The most powerful use-case for AI in software engineering is not writing feature code; it is writing the scaffolding that proves the feature code works."

Testing has historically been the most neglected part of software development because it demands massive amounts of boilerplate — mocks, stubs, spies, setup and teardown. AI eliminates that bottleneck completely. But it introduces a new problem that is worse than no tests: **plausible tests that verify nothing**. When the same model writes both the code and the tests, the tests inherit the code's assumptions — including its bugs.

This chapter covers both halves: using AI to generate the testing infrastructure at speed, and auditing what it generates so your green checkmarks actually mean something. Code examples run against the Part 3 spine app ([`sample-apps/music-interview-app`](../sample-apps/music-interview-app)), whose test suite ships in the repo.

---

## 1. The Framework Baseline: Swift Testing First

All new test code uses **Swift Testing** (`import Testing`). Keep `XCTest` for legacy suites and for what Swift Testing doesn't cover (UI automation via `XCUITest`, performance tests).

The API surface you and the AI need:

| Construct | Replaces (XCTest) | Notes |
| :--- | :--- | :--- |
| `@Test func …` | `func testFoo()` | Any name; `async` and `throws` just work |
| `#expect(a == b)` | `XCTAssertEqual` | One macro for all comparisons; failure output shows sub-expressions |
| `#require(x)` | `XCTUnwrap` / `XCTSkip` | Unwraps or aborts the test; use for preconditions |
| `@Suite struct …` | `XCTestCase` subclass | Value type; fresh instance per test = free test isolation |
| `@Test(arguments: […])` | manual loops | Parameterized tests; each argument reports separately |
| `#expect(throws: SomeError.self)` | `XCTAssertThrowsError` | Typed error assertions |
| `confirmation(…)` | `expectation`/`wait` | For callbacks that fire during an async operation |
| `.enabled(if:)`, `.timeLimit(…)` | runtime `XCTSkip` | Traits on `@Test`/`@Suite` |

Swift Testing is concurrency-native — an `async` test function simply `await`s, and `@MainActor` suites compose with strict concurrency instead of fighting it. Just as important for our purposes: the macro API has far less ceremony for the AI to hallucinate.

You must constrain the AI explicitly, because a decade of XCTest tutorials dominates its training data:

> *"Write the tests using Swift Testing (`import Testing`, `@Test`, `#expect`, `#require`). Do NOT use XCTest, `XCTAssert*`, `expectation(description:)`, or `Task.sleep` as a synchronization mechanism."*

---

## 2. The Role Shift: You Write the Contract, AI Writes the Ceremony

When AI generates most of the feature code, tests change jobs. They are no longer "verification you write after" — they are **the one artifact you must read line-by-line**, because they are the executable statement of what you asked for. A useful rule for the AI era:

- **Feature code:** AI writes, you review at the architecture level (Chapter 14).
- **Test intent** — the test *names* and the *assertions*: you own these. They are the contract.
- **Test ceremony** — mocks, fixtures, setup: AI writes, you spot-check.

If you delegate the assertions, you have delegated the definition of correct — and the model will happily define correct as "whatever the implementation currently does."

---

## 3. Mock Generation: The Spy Pattern

If you followed the architecture chapters (protocol-injected dependencies everywhere), mocking is mechanical — which is exactly what AI is for. The prompt (`prompts/testing/generate-mock.md`):

> *"Generate a spy for this protocol. For every method: a `[name]CallCount`, a `[name]Arguments` array recording inputs, and a settable `[name]Result` for the return/throw. Conform to the protocol exactly — do not add convenience methods the protocol doesn't have."*

Fed `AudioEngineProtocol` from MusicApp, that produces:

```swift
final class AudioEngineSpy: AudioEngineProtocol {
    private(set) var playCallCount = 0
    private(set) var playArguments: [URL] = []
    private(set) var pauseCallCount = 0

    let playbackStateStream: AsyncStream<PlaybackState>
    private let stateContinuation: AsyncStream<PlaybackState>.Continuation

    init() {
        (playbackStateStream, stateContinuation) = AsyncStream.makeStream()
    }

    func play(url: URL) async {
        playCallCount += 1
        playArguments.append(url)
    }
    func pause() async { pauseCallCount += 1 }
    func resume() async {}
    func stop() async {}

    // Test-side control: simulate the engine reporting a state change.
    func emit(_ state: PlaybackState) { stateContinuation.yield(state) }
}
```

Note the last method: a good spy for a *streaming* dependency needs a way for the test to drive the stream. The AI will not think of `emit(_:)` unless your prompt mentions that the protocol exposes an `AsyncStream` the test must control.

---

## 4. AI-Assisted TDD: The Names-First Workflow

TDD pairs unusually well with AI because failing tests are the highest-quality prompt that exists — they are executable, unambiguous, and the model cannot argue with them.

The workflow, on a real MusicApp behavior (queue navigation):

**Step 1 — You write the intent as empty tests.** No bodies, just names. This is the part that requires judgment, so it is the part you don't delegate:

```swift
@MainActor
@Suite("PlayerViewModel queue navigation")
struct PlayerQueueTests {
    @Test("playNext advances to the following track in the queue")
    func playNextAdvances() async throws { }

    @Test("playNext at the end of the queue is a no-op, not a wrap-around")
    func playNextAtEndDoesNothing() async throws { }

    @Test("playing a track prefers the offline file URL over the stream URL")
    func playPrefersOfflineURL() async throws { }
}
```

**Step 2 — AI fills the bodies.** *"Implement these test bodies using `AudioEngineSpy`. Arrange with a three-track queue. Assert on `currentTrack` and on the spy's `playArguments`."*

**Step 3 — AI implements against the failures.** For new features you reverse it: *"Here are the failing tests. Modify `PlayerViewModel` until they pass. Do not modify the tests."* That last sentence is not decoration — an unconstrained agent's cheapest path to green is editing the assertion, and agents find cheap paths. (The full three-phase workflow: `prompts/testing/names-first-tdd.md`.)

The third test above is worth pausing on: `playPrefersOfflineURL` encodes a *business rule* (offline-first playback) that lives in one expression in the implementation (`track.offlineFileURL ?? track.streamURL`). If someone — human or model — later "simplifies" that expression, this named test is the only thing standing between the refactor and a silent regression of the app's core offline promise.

---

## 5. The Tautological-Test Audit

Here is the failure mode that makes AI-generated tests dangerous. All three of these are real shapes the model produces, all three pass forever, and none of them test anything:

**The mirror** — asserts the mock returns what the mock was told to return:

```swift
@Test func fetchTracks() async throws {
    let stub = StubNetworkClient(tracks: [someDTO])
    let repo = TrackRepository(networkClient: stub, modelContext: context)
    let tracks = try await repo.fetchTracks()
    #expect(tracks.count == 1)   // ✅ green — but only the stub was measured
}
```

Looks fine. Now delete the entire `upsert` persistence logic from the repository and run it again: still green, because the count came from the stub, not from the store. The behavior worth testing — *DTOs are persisted, idempotently* — needs an assertion against the `ModelContext` itself. Compare the shipped test in [`Tests/TrackRepositoryTests.swift`](../sample-apps/music-interview-app/Tests/TrackRepositoryTests.swift), which calls `fetchTracks()` **twice** and asserts the store holds exactly one row: that second call is what makes it a test of upsert rather than a test of the stub.

**The implementation echo** — the test re-derives the expected value using the same logic as the code:

```swift
@Test func formatsDuration() {
    let seconds = 245.0
    let expected = "\(Int(seconds) / 60):\(String(format: "%02d", Int(seconds) % 60))"
    #expect(formatDuration(seconds) == expected)   // same algorithm, twice
}
```

If the algorithm is wrong, it is wrong identically on both sides. The fix is embarrassingly simple: hardcode the answer (`#expect(formatDuration(245) == "4:05")`). Hardcoded expected values are a *feature* of good tests.

**The vacuous async test** — awaits something, asserts nothing that could fail, or sleeps and hopes:

```swift
@Test func observesState() async throws {
    let vm = PlayerViewModel(audioEngine: spy)
    try await Task.sleep(for: .milliseconds(100))   // 🚩 flake generator
    #expect(vm.playbackState != nil)                 // 🚩 non-optional: can't fail
}
```

### The Audit Workflow

Run this on every AI-generated test file — it takes two minutes and it is the highest-leverage review in this book:

1. **The deletion test (poor man's mutation testing).** Pick the core behavior, break it deliberately (`return []`, flip the guard, delete the save), run the suite. **A test file that stays green while the feature is broken is worse than no tests — revert it.** You can make the AI do this: *"For each test, name the single line of production code that, if deleted, makes it fail. If you cannot name one, flag the test as tautological."*
2. **The stub-vs-subject check.** For each assertion ask: is the asserted value produced by the *code under test*, or did it travel unmodified from the stub? (The mirror, above.)
3. **The hardcoding check.** Expected values must be literals, not computed by test-side logic. (The echo.)
4. **The synchronization check.** Any `Task.sleep` used as a wait is a bug; async coordination goes through `confirmation`, awaited calls, or test-controlled continuations like `AudioEngineSpy.emit`. (The vacuous test.)

The review prompt that packages this (`prompts/testing/tautology-audit.md`):

> *"Audit this test file for tautological tests. For each test, state: (1) the production behavior it verifies, (2) the line of production code that would make it fail if deleted, (3) whether any expected value is computed with the same logic as the implementation, (4) whether any assertion measures a stub rather than the subject. Output a table with a KEEP / REWRITE / DELETE verdict per test."*

---

## 6. Testing Async Streams Without Sleeping

MusicApp's `PlayerViewModel` observes `AudioEngineProtocol.playbackStateStream`. The AI's default test for this sleeps and polls. The correct pattern drives the stream from the test side and awaits the observable consequence:

```swift
@Test("engine state changes propagate to playbackState")
func statePropagates() async throws {
    let spy = AudioEngineSpy()
    let vm = PlayerViewModel(audioEngine: spy)

    spy.emit(.playing)

    // Await the consequence, not a timer: poll the @MainActor property
    // via a bounded async loop rather than a blind sleep.
    for _ in 0..<100 where vm.playbackState != .playing {
        await Task.yield()
    }
    #expect(vm.playbackState == .playing)
    vm.cleanup()   // cancel the observation task — leak-free tests
}
```

Bounded yields instead of wall-clock sleeps: the test passes as fast as the scheduler allows and fails deterministically when propagation breaks, instead of flaking under CI load. (When the subject exposes a callback rather than observable state, reach for `confirmation` — that is exactly what it exists for.)

---

## 7. The Regression Rule

Chapter 16 ends its crash investigation by adding `TrackRepositoryTests` — a test that constructs the *real object graph* (in-memory `ModelContainer`, real repository, stub network) so the composition-root wiring bug can never silently return. Generalize that into a standing team rule, and put it in your rules file so the agent follows it unprompted:

> **Every production bug closes with a test that fails on the pre-fix code.** Ask the AI: *"Write the test first, run it against the unfixed code, show me the failure output, then apply the fix and show it passing."* The failure output is the proof the test is load-bearing.

This is also the cheapest way to grow a meaningful suite: bug-derived tests are never tautological, because each one is anchored to a failure that actually happened.

---

## 8. Wiring It Into the Loop

- **Local:** the agent runs `swift test` (or `xcodebuild test` for simulator-bound code) after every generation — Chapter 20's loop. Code that doesn't pass its own tests never reaches your review.
- **CI:** the same commands gate the merge. For UI-level confidence, add snapshot tests for stable screens and `performAccessibilityAudit()` (Chapter 25) as a regression gate.
- **Prompts:** `prompts/testing/generate-mock.md`, `prompts/testing/tautology-audit.md`.

The through-line: AI makes tests cheap to *write*, which means the scarce skill is no longer writing them — it is knowing which green checkmarks are lies. The deletion test settles that in two minutes, and no amount of generated ceremony survives it.
