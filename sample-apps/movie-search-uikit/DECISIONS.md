# Decision Log — Movie Search (UIKit · MVVM-C)

Every architectural call made during the interview, in the order it came up.
Each entry is a mini-ADR (same format as the repo-level [`adrs/`](../../adrs/)),
plus the one-liner actually said to the interviewer — because in an AI-native
interview, *stating the decision out loud while the agent generates* is how you
prove the architecture is yours and not the model's default.

---

## D1: UIKit with fully programmatic layout — no SwiftUI, no storyboards

**Status:** Accepted (interviewer constraint, then reinforced by choice)

**Context:** The brief mandated UIKit — the team's production app is a
decade-old UIKit codebase. That still leaves storyboards vs XIBs vs code.

**Decision:** Programmatic Auto Layout via anchors, everywhere. `init(coder:)`
is marked unavailable in every view.

**Consequences:** Everything is reviewable in the diff (an AI-generated
storyboard XML blob is unreviewable), initializer injection works without
`instantiateViewController` gymnastics, and there are no merge-conflict-prone
XML files. Cost: more layout boilerplate — acceptable, since the AI types it.

**Said to the interviewer:** "Code-only layout — partly for DI through inits,
mostly because I can't code-review a storyboard."

---

## D2: Coordinator pattern for all navigation

**Status:** Accepted

**Context:** MVVM answers *where logic lives* but not *who navigates*. The
default failure mode is ViewControllers pushing ViewControllers, which welds
every screen to its successor. (Same forces as repo ADR 007, UIKit edition.)

**Decision:** Coordinators own screen creation and every push. ViewModels
expose navigation *intent* as closures (`onMovieSelected`); coordinators
fulfil them. `pushViewController` appears only inside `Coordinators/`.

**Consequences:** Screens are reusable in any flow and the whole navigation
graph reads top-to-bottom in two small files. Cost: indirection tax on a
two-screen app — paid deliberately, because the interview explicitly asked
for the pattern and the app is sized to grow (favorites list, filters).

**Said to the interviewer:** "ViewControllers don't know what selection means.
They report it; the coordinator decides."

---

## D3: `Box<Value>` closure binding — no Combine, no RxSwift, no `@Observable`

**Status:** Accepted

**Context:** UIKit MVVM needs change notification. Candidates: Combine
(Apple-native but we'd committed to zero reactive frameworks — see repo ADR
003 — and its debugging story in an interview is a liability), RxSwift
(third-party, banned by the zero-dependency rule), `@Observable` (built for
SwiftUI view invalidation; in UIKit you'd hand-roll `withObservationTracking`
loops), KVO (stringly, `NSObject`-bound).

**Decision:** A 15-line `@MainActor final class Box<Value>` with a single
listener closure that fires on `didSet` and immediately on `bind`.

**Consequences:** The entire binding "framework" is explainable in one breath
and debuggable with a breakpoint. Limitations accepted: one listener per box
(exactly the 1-VM-1-VC shape of this app) and no operators — the debounce
lives in the ViewModel as a cancellable `Task`, arguably clearer anyway.

**Said to the interviewer:** "I'd rather own fifteen lines completely than
import a framework I can only mostly explain under pressure."

---

## D4: Diffable data source over `reloadData`

**Status:** Accepted

**Context:** Search results change wholesale on every keystroke's response.
Manual `performBatchUpdates` index math is the classic
`NSInternalInconsistencyException` factory; `reloadData` flickers and drops
selection.

**Decision:** `UICollectionViewDiffableDataSource<Section, Movie>` over a
compositional list layout, with `Movie: Hashable` as the item identifier.
Snapshots are rebuilt from `SearchState` — never mutated incrementally.

**Consequences:** Animated diffs for free and an entire bug class (index
drift) made unrepresentable. Cost: iOS 13+ only (irrelevant at our iOS 17
target) and item identity is only as good as `Movie`'s `Hashable` — fine,
it's a value type keyed by a stable `id`.

**Said to the interviewer:** "State → snapshot → screen. The collection view
is a pure function of `SearchState`."

---

## D5: Protocol-based initializer DI from a single composition root

**Status:** Accepted

**Context:** Everything must be stubbable in tests within the hour. Options:
a DI framework (dependency, banned), singletons (`.shared` — untestable,
hidden edges), or manual protocol injection.

**Decision:** Every cross-layer edge is a protocol (`MovieRepositoryProtocol`,
`ImageLoading`, `FavoritesStoreProtocol`, `NetworkClientProtocol`). Concrete
types are constructed in exactly one place: `AppDependencies.live()`.

**Consequences:** The test target stubs any layer with a five-line struct; the
whole object graph is one readable function. Cost: dependencies thread through
coordinator inits by hand — visible plumbing, which in an interview is a
feature, not a cost.

**Said to the interviewer:** "No DI framework — the graph is small enough that
one `live()` function *is* the framework."

---

## D6: Services are `actor`s; everything touching UIKit is `@MainActor`

**Status:** Accepted

**Context:** Swift 6 strict concurrency is on (repo ADR 013). `NetworkClient`
has a decoder and future auth state; `ImageLoader` has a cache and an
in-flight table hit by every visible cell simultaneously.

**Decision:** Both services are `actor`s. ViewModels, coordinators, the
favorites store, and `Box` are `@MainActor`. Models are `Sendable` values.

**Consequences:** Data races are compile errors, and the isolation annotations
double as architecture documentation (main-actor = UI-adjacent, actor =
shared infrastructure). Cost: an `await` hop per service call — invisible
next to network latency.

**Said to the interviewer:** "The compiler enforces the threading model, so we
don't have to remember it."

---

## D7: Favorites = movie IDs in `UserDefaults`. No CoreData, no SwiftData

**Status:** Accepted

**Context:** "Favorites" could mean a full offline store (CoreData/SwiftData
entity per movie, sync rules, migrations) or a bookmark. The catalogue is
server data; the time-box is one hour.

**Decision:** `Set<Int>` of movie IDs behind `FavoritesStoreProtocol`, persisted
as an array in `UserDefaults`, injectable suite for tests.

**Consequences:** Zero schema, zero migration risk, and the protocol seam means
graduating to SwiftData later is a one-file swap invisible to ViewModels.
Cost: a favorites *list screen* would need to re-fetch movies by ID — named
out loud as the accepted trade-off and first extension point.

**Said to the interviewer:** "UserDefaults is not a database, and I'm storing
IDs, not objects. If you extend the brief to an offline favorites screen,
this store's protocol is where SwiftData plugs in."

---

## D8: Debounced search owned by the ViewModel as a cancellable `Task`

**Status:** Accepted

**Context:** Search-as-you-type must not fire a request per keystroke, and a
slow response for "du" must never overwrite the results for "dune". Combine's
`.debounce` is out (D3). A `Timer` is the pre-async-await reflex.

**Decision:** `searchTextDidChange` cancels the previous stored `Task`, starts
a new one that sleeps `debounceInterval` and re-checks `Task.isCancelled`
both after the sleep **and** after the repository `await` before writing state.
The interval is injected (`.zero` in tests); the task is `private(set)` so
tests await it.

**Consequences:** Debounce, request de-duplication, and stale-response
protection in ~15 lines with no scheduler types. The exposed task is a small
testability concession — documented as such.

**Said to the interviewer:** "The cancellation check *after* the await is the
line that matters — that's the stale-response race."

---

## D9: Coordinator memory contract — strong children, weak parents, weak closures

**Status:** Accepted

**Context:** The coordinator pattern's known failure modes are leak-shaped:
nobody retains the root coordinator (black screen at launch), or
parent ↔ child / ViewModel ↔ coordinator retain cycles.

**Decision:** `SceneDelegate` holds the root coordinator strongly (the tree's
anchor). Parents own children via `childCoordinators: [Coordinator]`; children
hold `weak var parent`; finished flows are released through
`childDidFinish(_:)` (identity comparison). Every ViewModel closure a
coordinator fulfils captures `[weak self]`.

**Consequences:** Ownership follows the navigation hierarchy, so a flow's
memory dies with the flow. Cost: the bookkeeping is manual — which is exactly
why it's written down as a rule the AI is held to in review, not left to the
generation.

**Said to the interviewer:** "One strong edge, always downward. Everything
pointing up is weak."
