# 07 – App Composition Prompt

> Companion prompt document for `App/AppDependencies.swift`,
> `App/AppDelegate.swift`, and `App/SceneDelegate.swift`.

**Interview clock:** ~0:38 · **Time to type:** ~35 seconds

---

## What you say to the interviewer first

> "One composition root. Every concrete type in the app is constructed in
> exactly one file, so swapping the remote repository for a mock — or the whole
> graph for a test graph — is a one-line change. The delegates stay ceremonial."
> *(Decision #5 in DECISIONS.md.)*

---

## Prompt

```text
Create the App layer.

1. AppDependencies.swift
   @MainActor struct holding movieRepository: MovieRepositoryProtocol,
   imageLoader: ImageLoading, favoritesStore: FavoritesStoreProtocol.
   static func live() -> AppDependencies wiring NetworkClient(baseURL:
   https://api.example.com/v1) → RemoteMovieRepository, ImageLoader(),
   UserDefaultsFavoritesStore(). This must be the ONLY file that names
   concrete service/repository types together.

2. AppDelegate.swift
   @main final class, UIApplicationDelegate. didFinishLaunching returns
   true. configurationForConnecting returns a UISceneConfiguration with
   delegateClass = SceneDelegate.self (code-configured scene — no Info.plist
   manifest, the package stays self-contained).

3. SceneDelegate.swift
   UIWindowSceneDelegate. In willConnectTo: guard the UIWindowScene, build
   UIWindow(windowScene:), build AppCoordinator(window:dependencies:.live()),
   retain BOTH (window + coordinator) in stored properties, call
   coordinator.start(). No screen types in this file.
```

---

## Key Constraints Enforced

| # | Constraint | Why |
|---|-----------|-----|
| 1 | Single composition root | DI without a framework: the object graph is one readable function. |
| 2 | SceneDelegate retains the coordinator | The classic MVVM-C launch bug is a deallocated root coordinator and a black screen — the strong property IS the coordinator tree's root. |
| 3 | Delegates contain no wiring logic | Launch code paths stay testable through `AppDependencies` + `AppCoordinator`. |
| 4 | Scene configured in code | A Swift package has no Info.plist to declare the scene manifest in. |

---

## What to Review in the Output

- [ ] `SceneDelegate` has a stored `appCoordinator` property (not a local).
- [ ] `AppDependencies.live()` is the only call-site of `NetworkClient.init` outside tests.
- [ ] No `UIViewController` subtype is named anywhere in `App/`.
