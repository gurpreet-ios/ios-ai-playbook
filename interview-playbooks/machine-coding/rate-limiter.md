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
