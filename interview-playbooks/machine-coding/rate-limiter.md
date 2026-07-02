# Mock Interview: Rate Limiter

## 1. The Prompt
**Interviewer:** "Implement a rate limiter class in Swift that allows a maximum of 5 requests per second. It should be thread-safe. You can't use third-party libraries."

## 2. Expected Reasoning
The interviewer is testing your knowledge of Swift Concurrency, specifically `actor` isolation, and algorithmic thinking (Token Bucket or Leaky Bucket algorithms vs. a simple timestamp array).

## 3. The Poor Answer
> *"I'll make a singleton class. I'll keep a `var count = 0`. When a request comes in, I check if `count < 5`. If it is, I increment it. Then I'll use `DispatchQueue.main.asyncAfter(1.0)` to reset the count to 0."*

**Why it's poor:** It is not thread-safe (race condition on `count`). Resetting the count every second creates a "burst" loophole where you could do 5 requests at 0.99s and 5 requests at 1.01s, allowing 10 requests in 20ms.

## 4. The Great Answer
> *"I will use a Swift `actor` to guarantee thread safety without manual locks. For the algorithm, I'll use a Token Bucket or a rolling window. 
> 
> A simple and effective approach is a sliding window log. Inside the actor, I'll store an array of `Date` timestamps for every successful request. 
> 
> When a new request comes in, the actor filters out any timestamps older than 1 second from the array. If the remaining array count is less than 5, I append the current timestamp and return `true` (allow). If it's 5 or more, I return `false` (block)."*

## 5. Driving the LLM

The prompt sequence for this question in a live vibe-coding session:

> **Plan:** "We need a thread-safe rate limiter in Swift 6: max 5 requests per second, no third-party libraries. Before writing any code, compare a sliding-window log against a token bucket for this use case — memory, burst behavior, precision — and recommend one. Do not generate code yet."

> **Generate:** "Implement the sliding-window version as a Swift `actor` called `RateLimiter`. Public API: `func allow() -> Bool`. Store timestamps in a private array; prune anything older than 1 second on each call. No locks, no `DispatchQueue` — the actor is the synchronization."

> **Review hook:** "Before I accept this: walk me through what happens when two Tasks call `allow()` at the same instant. Where exactly does the serialization happen?"

> **Test:** "Write a Swift Testing suite: one test proving 5 requests pass and the 6th is rejected, and one test that fires 100 concurrent `allow()` calls from a TaskGroup and asserts no more than 5 succeed per window."

**What you're watching for in the output:** the LLM reaching for `DispatchQueue.sync` or `NSLock` inside the actor (redundant), using `Timer` to "reset" counts (the burst loophole from the Poor Answer), or writing tests that `Task.sleep` and hope.

## 6. The Follow-Up (Mid-Interview Extension)
**Interviewer:** "Two extensions. First: storing thousands of timestamps could be a memory issue if the limit was 10,000 requests per minute instead of 5 per second — optimize the memory. Second: callers now want to *wait* for the next available slot instead of being rejected. Change the API."

## 7. The Ideal Discussion
> *"For memory, I'd switch to the Token Bucket algorithm. Instead of storing every timestamp, the actor stores two values: `availableTokens` and `lastRefillTime`. On each request we compute the elapsed time, refill proportionally (capped at bucket size), and decrement if a token is available. That's O(1) memory regardless of volume.
> 
> For waiting instead of rejecting, I'd change the API from `allow() -> Bool` to `func acquire() async`. Inside the actor, if no token is available, compute the time until the next refill and `try await Task.sleep(for:)` — then re-check, because another caller may have taken the token while we slept; this needs a loop, not an `if`. Two things I'd flag before asking the LLM to write it: first, sleeping inside the actor method does **not** block the actor — the actor is re-entrant across suspension points, which is exactly what we want but also what the re-check loop must account for. Second, `acquire()` must support cancellation: if the caller's Task is cancelled while waiting, `Task.sleep` throws and we should propagate, not swallow, that error."*
