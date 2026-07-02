# Mock Interview: Code Review - The Sneaky Retain Cycle

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

## 5. Driving the LLM

In a vibe-coding review round, you don't just spot the bug — you make the LLM fix it *without collateral damage*:

> **Fix (specific, not "fix it"):** "This closure creates a retain cycle: the VC retains the viewModel, the viewModel retains `onDataLoaded`, and the closure captures `self` strongly. Rewrite with `[weak self]` and a `guard let self` at the top. Separately, the closure runs on whatever thread `fetchData` completes on — route the UI mutations through the main actor. Do not restructure the class; two minimal changes."

> **Review hook:** "Explain why `guard let self else { return }` is the right unwrap here rather than optional-chaining every line — what's the behavioral difference if the VC is deallocated mid-callback?"

> **Regression guard:** "Write a Swift Testing case that asserts deallocation: create the VC in an autorelease scope, hold it `weak`, trigger `fetchData`, drop the strong reference, and `#expect(weakVC == nil)` after the callback fires."

**What you're watching for:** the LLM "fixing" the leak by making `viewModel` weak instead (breaks ownership — the VC *should* own its viewModel), sprinkling `DispatchQueue.main.async` inside the closure body when annotating the callback contract (`@MainActor` closure property) is cleaner, or rewriting the whole class into Combine/async patterns you didn't ask for — the Chapter 17 architecture-destroying reflex.

## 6. The Follow-Up (Mid-Interview Extension)
**Interviewer:** "Suppose a teammate 'fixes' it with `[unowned self]` and it passes QA. Ship it? And while you're in the file: convert this callback API to async/await — does the leak class disappear?"

## 7. The Ideal Discussion
> *"No ship. `weak` becomes `nil` safely; `unowned` is a promise the referent outlives the closure, enforced by a crash. Here the promise is false: a 5-second fetch plus a back-tap at 2 seconds means the VC deallocates, the callback fires into dead memory, and we crash — in exactly the conditions (slow network) QA rarely tests. `unowned` is for closures whose lifetime is structurally bounded by the referent, like a lazy property's initializer; a network callback is the textbook opposite.
> 
> Converting to async/await changes the *shape* but not the discipline. `let data = try await viewModel.fetchData()` inside a `Task` still captures `self` — the difference is the capture is temporary (released when the Task finishes) rather than a permanent cycle through a stored property, so it degrades from 'leak forever' to 'VC lingers until the request completes.' The remaining fix is the same idea in new clothes: `.task { }` on the SwiftUI side or storing the Task and cancelling in `deinit`/`viewDidDisappear`, so a dismissed screen cancels its work instead of keeping itself alive to finish a fetch nobody will see."*
