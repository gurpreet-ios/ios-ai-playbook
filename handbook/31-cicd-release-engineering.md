# Chapter 31: CI/CD & Release Engineering

> "On the backend you can roll back in ninety seconds. On iOS, your worst bug ships to the App Store review queue, then to a million phones, and there is no undo button. Release engineering *is* risk engineering."

AI accelerates everything upstream of the release — generation, review, verification. It accelerates nothing about App Review, phased rollout, or a certificate expiring on a Saturday. This chapter covers the iOS delivery pipeline with the AI-era emphasis: which parts an agent can own, which parts it must never touch unsupervised, and how the **no-instant-rollback reality** changes what "safe to merge" means.

## 1. Code Signing: The Part the AI Cannot Guess

Signing is the most common CI failure and the worst match for LLM assistance, because the failure lives in *state the model cannot see*: certificates in a keychain, provisioning profiles in an Apple Developer account, entitlements in a build setting. An agent asked to "fix codesigning" without that state will hallucinate plist edits with total confidence.

The senior setup makes signing boring:

- **One shared distribution identity**, managed centrally — fastlane `match` (certificates in an encrypted repo) or Xcode Cloud's managed signing. Individual engineers never touch distribution certs.
- **CI signs from a clean keychain** created per-build, imported from secrets, deleted after. No state accretes on runners.
- **Entitlements live in the repo** and change only via reviewed PR — they are exactly the kind of file an agent will "helpfully" modify to make a capability work (push, App Groups), and each such change is App-Store-visible surface.

Where AI *does* help: explaining. `security find-identity -v -p codesigning` output plus the failing log into a chat beats deciphering `errSecInternalComponent` folklore by hand. **Explain-then-human-applies** is the signing rule; agents don't get keychain write access.

## 2. The Pipeline: Lanes an Agent Can Drive

Whether you use fastlane, Xcode Cloud, or raw `xcodebuild`, the shape is the same — and it must be **runnable from the terminal**, because that's what makes it drivable by agents (Chapter 20) and debuggable by humans:

```
PR pipeline (every push):        verify (Ch 30 stack) → build unsigned
Merge pipeline (main):           verify → build signed → upload to TestFlight (internal ring)
Release pipeline (tag):          verify → build → TestFlight external ring → submit for review
```

Rules that keep this sane at AI velocity:

- **The archive is built once.** The binary that went through TestFlight is bit-identical to the one submitted; rebuilding "the same thing" for release is how untested code ships.
- **Version/build numbers are automated** (`agvtool` or a lane), never hand-edited — hand-edited build numbers are the classic "works locally, TestFlight rejects the upload" hour-waster.
- **Agents own the red-to-green loop on the PR pipeline** — they can iterate on compile/test failures autonomously. Agents do **not** trigger the release pipeline; a tag pushed by a human is the boundary. An agent with release-trigger access is one prompt-injection away (Chapter 35) from shipping.

macOS runner economics apply throughout: every round trip costs 15–25 minutes of expensive queue. This is why the Chapter 30 stack front-loads the cheap gates, and why an agent that fixes its own build failures *before* pushing pays for itself immediately.

## 3. TestFlight: The Ring System

Treat TestFlight as staged exposure, not a checkbox:

1. **Internal ring** (team, up to 100 App Store Connect users) — every merge to main lands here automatically, same-day. This ring exists to catch the "works in simulator, dies on device" class.
2. **External ring** (up to 10,000 invited users) — release candidates only. Requires a lightweight beta review; budget a day.
3. **The soak**: a release candidate soaks in the external ring with MetricKit/crash dashboards (Chapter 33) watched for a fixed window — 48–72 hours — before submission. The soak is non-negotiable *because* rollback doesn't exist; it is your last cheap exit.

## 4. App Review: Engineering Around a Human Queue

App Review is a 1–3 day human process with tail risk (rejections, holidays, resubmission loops). Engineering consequences:

- **The release train, not the release push.** A fixed cadence (weekly or biweekly) with a cut date; features that miss the cut ride the next train. Trains decouple "merged" from "shipped" — essential when agents inflate merge volume.
- **Review-proofing is a checklist, not a vibe:** demo account credentials current, purchase flows testable, privacy labels/manifest matching actual data use (Chapter 32), no dormant flagged features visible in review builds. An LLM is genuinely good at auditing release notes and metadata against guideline text — cheap prompt, real rejections avoided.
- **Expedited review exists** for genuine emergencies, and works maybe twice a year. It is not a strategy.

## 5. No Instant Rollback: Design for It

The defining constraint of the platform: once a build is out, you cannot pull it back — you can only stop *further* rollout and ship a fix through the same 1–3 day pipe. So safety mechanisms move **into the binary**:

- **Phased release** (7-day automatic ramp: 1% → 2% → 5% → 10% → 20% → 50% → 100%) is on for every release, and someone owns the dashboard during the ramp. Pausing at 5% turns a catastrophe into an incident.
- **Feature flags for anything risky**, defaulting *off*, flippable server-side without a release. The flag check is trivial; the discipline is the rule that **new AI-generated subsystems ship dark** — merged, flagged off, enabled progressively after field data, not before.
- **Kill switches for dependencies**: the new sync engine, the new image pipeline — anything that replaced a working system keeps the old path callable for one release cycle behind a remote flag. Deleting the old path is a *next-train* decision.
- **Forced-upgrade plumbing** (a minimum-supported-version endpoint) built *before* you need it. The day you ship a data-corrupting bug is not the day to design it.

The AI-era point: agents make it cheap to build flag plumbing, kill switches, and the forced-upgrade path — the safety infrastructure teams historically skipped because it was boring boilerplate. Prompt for it once, own it forever:

> *"Add a remote feature-flag layer: a `FeatureFlags` service fetched at launch with a 24h cache and hardcoded defaults for offline-first startup. Every flag is an enum case with a default. Generate the kill-switch flag for `SyncEngine` — when off, the app uses `LegacySyncEngine` — and a Swift Testing suite proving both paths construct."*

## 6. The Release Checklist as a Prompt System

The pre-submission checklist is a living document the agent runs, not a wiki page humans forget (Chapter 22's philosophy):

> *"Run the release audit for build 342: (1) confirm version/build monotonicity against App Store Connect; (2) diff the privacy manifest against new API usage in this release's merged PRs; (3) verify all feature flags added this cycle default off and list them with owners; (4) check the crash-free rate and hitch p95 of the current external-ring build against the last release's soak numbers; (5) draft release notes from the merged PR titles, humanized. Output a go/no-go table with evidence per row."*

Every row is mechanical; the *go/no-go call* is yours. That division — machine assembles the evidence, human owns the irreversible action — is this chapter's entire thesis, and it is the same division you'll see again at the agent-security boundary in Chapter 35.
