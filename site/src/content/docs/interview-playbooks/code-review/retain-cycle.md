---
title: "Mock Interview: Code Review - The Sneaky Retain Cycle"
---

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
