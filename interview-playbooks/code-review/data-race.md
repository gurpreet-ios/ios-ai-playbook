# Mock Interview: Code Review — The Hidden Data Race

## 1. The Prompt
**Interviewer:** "This cache came out of an AI agent's PR. It compiles on our current settings and the tests pass. Review it."

```swift
final class TokenCache: @unchecked Sendable {
    static let shared = TokenCache()
    private var tokens: [String: AuthToken] = [:]

    func token(for account: String) -> AuthToken? {
        tokens[account]
    }

    func store(_ token: AuthToken, for account: String) {
        tokens[account] = token
    }

    func refreshAll(using client: AuthClient) {
        for (account, token) in tokens where token.isExpired {
            Task {
                let fresh = try await client.refresh(token)
                self.tokens[account] = fresh
            }
        }
    }
}
```

## 2. Expected Reasoning
The interviewer is testing whether you understand that **`@unchecked Sendable` is a signed waiver, not a fix**. The class is mutated from arbitrary threads (`store` from callers, `tokens[account] = fresh` from detached-ish Tasks) with zero synchronization. "Tests pass" is part of the trap: data races are timing-dependent and invisible to happy-path tests. Bonus points for recognizing that this is *exactly* the class of bug AI agents introduce — the agent added `@unchecked Sendable` because the compiler complained, which silenced the diagnostic instead of fixing the problem.

## 3. The Poor Answer
> *"Looks reasonable — it's marked `Sendable` so it's safe to share, and the dictionary operations are simple. Maybe I'd add error handling to the `try await` since a failed refresh is silently dropped. Also `shared` singletons are bad practice, I'd use dependency injection."*

**Why it's poor:** It reads the `@unchecked Sendable` annotation as a *guarantee* when it's the opposite — an unchecked assertion. The dropped-error observation is correct but third-order. DI-vs-singleton is a style note on a correctness fire.

## 4. The Great Answer
> *"This is a data race factory with a waiver stapled to it.
>
> `@unchecked Sendable` tells the compiler 'trust me, I synchronized this internally' — and nothing here is synchronized. `tokens` is a plain dictionary mutated from any thread that calls `store`, and `refreshAll` spawns unstructured `Task`s that write back concurrently. Two simultaneous writes to a Swift `Dictionary` are undefined behavior — this crashes for real, intermittently, in the field, and the crash reports will point at random dictionary internals, not this file.
>
> There's also a logic race distinct from the memory race: `refreshAll` iterates a snapshot while writers mutate, and a token refreshed by one path can be clobbered by a stale write from another — check-then-act with no atomicity.
>
> The fix is to delete the waiver and make it an `actor`. Reads become `await`, which will annoy call sites — that annoyance is the compiler surfacing every place that was silently racing. `refreshAll` becomes a `TaskGroup` so the writes are actor-isolated and the errors propagate instead of vanishing. Under Swift 6 strict concurrency, the original code doesn't even compile without the `@unchecked` — which is precisely the diagnostic the author suppressed."*

## 5. Driving the LLM

> **Fix:** "Convert `TokenCache` to an `actor`. Remove `@unchecked Sendable`. `refreshAll` should use a `throwing TaskGroup` — collect per-account failures instead of discarding them. Keep the public API surface otherwise identical; I'll deal with call-site `await`s in a follow-up commit."

> **Review hook:** "Before showing code: state what happens under your version when `store` and `refreshAll` write the same account concurrently — which write wins and why is that now well-defined?"

> **Regression guard:** "Write a Swift Testing case that hammers the actor: 100 concurrent `store`s and a `refreshAll` in a TaskGroup, then assert the dictionary contains exactly the expected accounts. Run it with Thread Sanitizer in CI — and note that TSan on the *old* code is how we'd have caught this pre-merge."

**What you're watching for:** the LLM reaching for `NSLock`/`DispatchQueue(label:)` instead of an actor (legal but fights the language), keeping `@unchecked Sendable` on the actor (meaningless — actors are Sendable), or "fixing" `refreshAll` by making it `async` while still spawning unstructured Tasks inside.

## 6. The Follow-Up (Mid-Interview Extension)
**Interviewer:** "Your actor version ships. A week later the perf team complains: `token(for:)` is on the hot path of every network request, and now it's an `await` with actor-hop overhead. Extend the design without reintroducing the race."

## 7. The Ideal Discussion
> *"First I'd demand the measurement — actor hops are nanoseconds-to-microseconds; if requests are actually slower, the culprit is usually contention (everything serialized behind one actor), not the hop itself. Assuming real contention:
>
> Option one: shrink the critical section. The actor holds the dictionary, but hot-path reads go through an immutable snapshot the actor publishes on every mutation — readers grab the current snapshot with no actor hop at all. Copy-on-write dictionaries make the publish cheap, and a stale-by-microseconds token read is harmless because expiry is checked at use.
>
> Option two: if tokens are per-account and requests are per-account, split the one global actor into per-account isolation so unrelated requests stop queueing behind each other.
>
> What I would *not* do is resurrect `@unchecked Sendable` with a lock 'for performance' as the first move — that's trading a proven-safe design for the original bug class on the strength of a hunch. Measure, shrink the critical section, and only reach for manual synchronization with TSan and a benchmark standing guard."*
