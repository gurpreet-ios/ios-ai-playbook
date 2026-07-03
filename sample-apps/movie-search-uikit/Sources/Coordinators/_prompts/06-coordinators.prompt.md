# 06 – Coordinators Layer Prompt

> Companion prompt document for `Coordinators/Coordinator.swift`,
> `Coordinators/AppCoordinator.swift`, and
> `Coordinators/SearchCoordinator.swift`.

**Interview clock:** ~0:33 · **Time to type:** ~50 seconds

---

## What you say to the interviewer first

> "Coordinators are the reason ViewControllers stayed dumb: every screen is
> created and pushed in exactly one place, so the navigation graph is readable
> top to bottom in two small files. The memory contract is the part people get
> wrong, so I'll state it upfront: parents own children through an array,
> children hold parents weak, and childDidFinish releases a finished flow."
> *(Decisions #2 and #9 in DECISIONS.md.)*

---

## Prompt

```text
Create the Coordinators layer.

1. Coordinator.swift
   @MainActor protocol Coordinator: AnyObject with
   `var childCoordinators: [Coordinator] { get set }` and `func start()`.
   Protocol extension: childDidFinish(_ child:) removing by identity (===).

2. AppCoordinator.swift
   @MainActor final class owning the UIWindow, a UINavigationController
   (prefersLargeTitles), and AppDependencies (both injected via init —
   window from SceneDelegate, dependencies from the composition root).
   start(): install the nav controller as rootViewController,
   makeKeyAndVisible, then create SearchCoordinator, set its weak parent,
   append to childCoordinators, and start it.

3. SearchCoordinator.swift
   @MainActor final class with weak var parent: Coordinator?, injected
   UINavigationController and AppDependencies.
   - start(): build MovieSearchViewModel from the repository, fulfil its
     onMovieSelected closure with [weak self] showDetail(for:), build
     MovieSearchViewController, push unanimated (it's the root screen).
   - showDetail(for:): build MovieDetailViewModel (movie + favorites store),
     build MovieDetailViewController, push animated.

Rule: pushViewController for these screens may appear NOWHERE else in the
codebase, and no ViewController type may appear outside this layer and the
tests.
```

---

## Key Constraints Enforced

| # | Constraint | Why |
|---|-----------|-----|
| 1 | Screens created only in coordinators | The navigation graph has one home; screens are reusable in any flow. |
| 2 | `weak var parent` | Parent → child is the owning edge; a strong back-edge is a retain cycle. |
| 3 | `[weak self]` in ViewModel closures | ViewModel outlives navigation events; a strong capture cycles ViewModel ↔ Coordinator. |
| 4 | `childDidFinish` by identity | Coordinators are reference-typed flows; equality semantics don't apply. |
| 5 | Everything `@MainActor` | Coordinators drive UIKit navigation; isolation is non-negotiable. |

---

## What to Review in the Output

- [ ] `grep -rn "pushViewController" Sources/ | grep -v Coordinators` returns nothing.
- [ ] `grep -rn "ViewController(" Sources/ViewModels/` returns nothing.
- [ ] `parent` is `weak`; `childCoordinators` is the only strong coordinator edge.
- [ ] The root push is unanimated; the detail push is animated.
