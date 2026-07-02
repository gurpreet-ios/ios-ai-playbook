# Chapter 32: Security & Privacy

> "AI-generated code is trained on the average of the internet, and the average of the internet stores tokens in UserDefaults."

Security on iOS in the AI era is two distinct problems. First, the classic one, amplified: models reproduce the insecure defaults of their training data at generation speed. Second, the new one: your *development workflow* now includes agents that read your repo, your logs, and your environment — and everything they read can end up in a prompt, a transcript, or a diff. This chapter covers both: securing what the AI writes, and not leaking what the AI reads.

## 1. The Insecure Defaults the AI Will Ship

Prompt an LLM for "login with token persistence" and, unconstrained, you will get some assortment of: tokens in `UserDefaults`, credentials in `print()` statements, a hand-rolled `URLSession` that disables ATS "for testing", and string-interpolated API keys. None of this is malice — it is statistics. The defenses are the ones this book keeps arriving at: **rules files state the policy, review prompts audit against it.**

The policy layer that belongs in `.cursorrules`/`CLAUDE.md` verbatim:

```markdown
## Security Rules (non-negotiable)
- Secrets (tokens, keys, credentials) live in the Keychain. NEVER in
  UserDefaults, plist files, or source code. NEVER logged, even at .debug.
- App Transport Security stays on. Never add NSAllowsArbitraryLoads.
- All user-identifying data written to disk goes through our encrypted
  store or Data Protection (.completeFileProtection).
- No new third-party dependencies without explicit approval in the PR.
```

### The Keychain, Prompted Correctly

The Keychain's C API is exactly the boilerplate AI should write — but specify the security-relevant attributes, or the model will pick permissive ones:

> *"Generate a `KeychainStore` (protocol + implementation) for auth tokens: `kSecClassGenericPassword`, `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly` (background refresh must work, but no iCloud/backup migration), throwing typed errors on OSStatus failures. No caching layer in front — reads go to the Keychain every time. Swift Testing suite included."*

The attribute is the review point: `WhenUnlocked` breaks background sessions, anything without `ThisDeviceOnly` migrates to new devices via backup, and the AI left to default will choose whatever its training data used most.

### Transport

ATS stays on; certificate pinning (via `URLSession` challenge handling or network extensions) is a *decision* with an operational cost — pinned certs rotate, and a botched rotation bricks your networking with no instant fix (Chapter 31's rollback reality). Record it as an ADR either way, so an agent can't "add security" by pasting pinning code that will expire in production.

## 2. Privacy as a Build Artifact

Apple's privacy enforcement is now mechanical, which means it is CI-checkable — perfect agent territory.

- **Privacy manifests (`PrivacyInfo.xcprivacy`)** declare data collection and **required-reason API** usage (`UserDefaults` access, file timestamps, boot time, disk space, active keyboards). Miss a declaration and App Store Connect rejects the upload — a Chapter 31 release-train delay, minimum.
- **Third-party SDKs** on Apple's list ship their own manifests and signatures; your build inherits their declarations.
- **Privacy nutrition labels** must match what the binary actually does; drift accumulates one innocent PR at a time.

The audit belongs in the release checklist, run by the agent (`prompts/security/privacy-manifest-audit.md`):

> *"Diff this release's merged changes against `PrivacyInfo.xcprivacy`: (1) list every new usage of required-reason APIs and check each has a declared reason code; (2) list every new data type persisted or transmitted and check it against the manifest's collection declarations and the App Store privacy labels; (3) flag any new SDK without its own privacy manifest. Output: table with file:line evidence, verdict per row."*

Data minimization is the design-level half: the best manifest entry is the one you don't need. When Chapter 34's on-device models can do the job, the data never leaves the device and the declaration question evaporates — privacy posture as an architecture choice, not a compliance chore.

## 3. The New Attack Surface: Your Agent's Context

The workflow itself now leaks. Three channels, all real:

**Secrets into context.** An agent debugging "why is auth failing" will happily `cat .env`, read the staging credentials, and include them in its reasoning — which lands in a transcript, possibly in a pasted GitHub issue, possibly in a vendor's logs. Rules:

- Real secrets don't live in the repo or its environment files at all (CI-injected; `.env` is for non-secret config). What isn't there can't be read.
- Deny-list what agents may read: modern agent harnesses support permission rules — exclude `*.p8`, `*.p12`, keychain exports, `fastlane/.env*`.
- **Transcripts are artifacts.** Treat a pasted agent session like a log file: scan before sharing. Tokens survive in scrollback.

**Secrets into code.** The AI pattern-matches `let apiKey = "sk_live_..."` from its training data whenever a key is the shortest path to "working." Two mechanical gates: a secret scanner (gitleaks or equivalent) in the Chapter 30 stack as gate 0, and the rules-file prohibition above so it's never generated in the first place.

**Poisoned inputs.** Everything an agent ingests is an instruction channel: a crash log with a malicious string, a scraped doc page, an MCP tool result. That's Chapter 35's territory — here, one rule suffices: *agent context is untrusted input*, and agents with write access get the same input-validation paranoia you'd apply to a form field.

## 4. The Security Review as a Prompt System

Chapter 14 established specialized audit passes; security is the pass with the highest stakes-to-attention ratio, so it gets a standing prompt (`prompts/security/ios-security-audit.md`) run on every PR touching auth, storage, networking, or logging:

> *"Act as an iOS security reviewer (OWASP MASVS lens). Audit this diff for: (1) secrets or tokens in code, UserDefaults, logs, or analytics events; (2) Keychain items with accessibility broader than the documented requirement; (3) ATS exceptions or TLS-validation changes; (4) user data written to disk without protection class; (5) injection sinks — WKWebView `evaluateJavaScript` with interpolated input, predicate/SQL strings built by concatenation; (6) new permissions or entitlements and whether the feature actually requires them. Cite file:line for every finding; classify blocking vs advisory."*

Two disciplines make it real: findings are triaged like human review comments (an agent's "advisory" can be your "blocking" — the model doesn't know your threat model), and the audit runs on the *diff*, so it scales with change rate rather than codebase size.

## 5. The Senior Frame

Security review resists the "AI reviews AI" endgame more than any other audit, because the ground truth lives outside the code: *should* this feature see contacts at all? Is this analytics event a liability? The model can flag the mechanism; the threat model is yours. Same shape as everything in this book — the machine does the sweep, you own the judgment — but here the asymmetry is sharpest, because the cost of a miss is a headline, and headlines don't have a phased rollout.
