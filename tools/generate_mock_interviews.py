import os

interviews = {
    "architecture/offline-first-chat.md": """# Mock Interview: Offline-First Chat System

## 1. The Prompt
**Interviewer:** "Design the architecture for a WhatsApp-style chat application. Users must be able to read and send messages even when they have no internet connection. When connection is restored, messages should sync."

## 2. Expected Reasoning
The interviewer is testing your ability to handle complex state synchronization, conflict resolution, and separation of concerns. They want to see if you instinctively separate the local database from the network layer using a Repository pattern or CQRS.

## 3. The Poor Answer
> *"I would use SwiftUI and Firebase. When the user hits send, I'll write it to Firestore. Firestore has offline support built-in so it will just work automatically. I'll bind the UI directly to a Firestore snapshot listener."*

**Why it's poor:** It relies entirely on a third-party framework's "magic" without demonstrating architectural understanding. If asked to use a custom backend, the candidate will fail.

## 4. The Great Answer
> *"I'll structure this using a local-first architecture. The local database (e.g., SwiftData or SQLite) is the single source of truth for the UI.
> 
> When the user sends a message, it is written immediately to the local database with a status of `pending`. The UI updates instantly. 
> 
> Concurrently, a background synchronization engine picks up `pending` messages and attempts to send them to the server. If it succeeds, it updates the local status to `sent`. If it fails, it queues them for retry using exponential backoff.
> 
> For receiving messages, I'd use a WebSocket or Server-Sent Events (SSE) connection that writes incoming payloads directly to the local database, which then triggers a reactive UI update via Observation."*

## 5. The Follow-Up
**Interviewer:** "What happens if a user is offline, sends a message, and at the exact same time, their friend sends them a message. When they come back online, how do you resolve the order of messages in the chat?"

## 6. The Ideal Discussion
> *"Relying on client-side timestamps is dangerous because device clocks can drift. I would implement a hybrid ordering system. 
> 
> The server assigns a strictly monotonic `sequence_id` (or uses Vector Clocks/Lamport Timestamps) to every message it processes. When the client reconnects, it pulls the latest sequence. 
> 
> For UI rendering, I will display the `pending` local message at the bottom of the feed using its local timestamp as a placeholder. Once it syncs and receives its official `sequence_id` from the server, the list is re-sorted based on the server's sequence. This ensures eventual consistency across all devices."*
""",
    "machine-coding/rate-limiter.md": """# Mock Interview: Rate Limiter

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

## 5. The Follow-Up
**Interviewer:** "The sliding window log works, but storing thousands of timestamps could be a memory issue if the limit was 10,000 requests per minute instead of 5 per second. How would you optimize the memory?"

## 6. The Ideal Discussion
> *"You're right. To optimize memory for high volumes, I would switch to the Token Bucket algorithm. 
> 
> Instead of storing every timestamp, the actor only needs to store two values: `availableTokens` (an integer) and `lastRefillTime` (a Date).
> 
> When a request comes in, we calculate the time elapsed since `lastRefillTime`. We multiply that elapsed time by the refill rate to see how many new tokens to add to `availableTokens` (capping at the maximum bucket size). 
> 
> If `availableTokens > 0`, we decrement it and allow the request. This reduces the memory footprint to O(1) regardless of the rate limit volume."*
""",
    "code-review/retain-cycle.md": """# Mock Interview: Code Review - The Sneaky Retain Cycle

## 1. The Prompt
**Interviewer:** "Please review this Swift code. It's a simple ViewController fetching data. Do you see any issues?"
```swift
class ProfileViewController: UIViewController {
    var viewModel = ProfileViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.onDataLoaded = { data in 
            self.title = data.userName
            self.view.backgroundColor = .green
        }
        viewModel.fetchData()
    }
}
```

## 2. Expected Reasoning
The interviewer is looking for two things: Can you spot the memory leak (retain cycle), and do you understand *why* it leaks?

## 3. The Poor Answer
> *"It looks mostly fine. I'd probably just add `[weak self]` in the closure so it doesn't leak. Also, the background color should probably be set in a separate function for clean code."*

**Why it's poor:** It spots the fix (`[weak self]`), but it doesn't explain the mechanism, and it focuses on trivial things like extracting the background color instead of addressing the thread safety.

## 4. The Great Answer
> *"There are two critical issues here. 
> 
> First, there is a strong retain cycle. `ProfileViewController` holds a strong reference to `viewModel`. The `viewModel` holds a strong reference to the `onDataLoaded` closure. That closure explicitly captures `self` (the ViewController) strongly. Neither the view controller nor the view model will ever be deallocated, causing a memory leak. I would fix this by adding `[weak self]` in the capture list.
> 
> Second, there is a thread-safety issue. Assuming `viewModel.fetchData()` performs a network request on a background thread, the `onDataLoaded` closure will likely be executed on that same background thread. Updating `self.title` and `self.view.backgroundColor` from a background thread will cause a Main Thread Checker violation and potential UI crashes. I would wrap the closure body in `DispatchQueue.main.async` or ensure the ViewModel routes the callback to the MainActor."*

## 5. The Follow-Up
**Interviewer:** "Excellent. Let's say we fix the retain cycle with `[unowned self]`. What is the difference between `weak` and `unowned`, and when is it safe to use `unowned` here?"

## 6. The Ideal Discussion
> *"`weak` makes the reference an Optional, safely becoming `nil` if the object is deallocated. `unowned` assumes the reference will always exist; it is non-optional but will trigger a fatal crash if accessed after the object is deallocated.
> 
> In this specific case, using `unowned` is extremely dangerous. If the network request takes 5 seconds, and the user taps the 'Back' button after 2 seconds, the `ProfileViewController` will be deallocated. When the network request finishes and calls `onDataLoaded`, it will try to access the `unowned self`, which is now dead memory, crashing the app. I would strictly use `[weak self]` here."*
"""
}

base_dir = "/Users/gurpreet029/Documents/antigravity/epic-volta/ai-engineering-playbook"
playbooks_dir = os.path.join(base_dir, "interview-playbooks")

# Create README
readme_content = """# The AI-Native Interview Playbook

This directory contains highly structured mock interviews. They are designed to help you prepare for Senior/Staff Engineering interviews at top-tier companies.

## Structure of a Mock Interview
1. **The Prompt:** The ambiguous question.
2. **Expected Reasoning:** What the interviewer is testing.
3. **The Poor Answer:** The common pitfall.
4. **The Great Answer:** The Senior response.
5. **The Follow-Up:** The stress-test.
6. **The Ideal Discussion:** Nailing the tradeoff analysis.

Practice these out loud.
"""
os.makedirs(playbooks_dir, exist_ok=True)
with open(os.path.join(playbooks_dir, "README.md"), "w") as f:
    f.write(readme_content)

# Write Mock Interviews
for filepath, content in interviews.items():
    full_path = os.path.join(playbooks_dir, filepath)
    os.makedirs(os.path.dirname(full_path), exist_ok=True)
    with open(full_path, "w") as f:
        f.write(content.strip() + "\n")
    print(f"Created {full_path}")

print("Successfully generated mock interviews.")
