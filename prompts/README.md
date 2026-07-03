# Prompt Library

This directory contains production-ready Prompt Systems. These are not casual conversational prompts; they are engineered workflows designed to execute specific tasks with high determinism.

Two invariants hold across the library: **every prompt referenced by a chapter exists here**, and **every prompt here is taught by a chapter** (the Chapter column below). If you add a prompt, wire it into the chapter that teaches its skill.

Eight of the highest-leverage prompts also ship as installable **Agent Skills** in [`skills/`](../skills/README.md) — same workflows, packaged in the `SKILL.md` format so the agent triggers them itself. Chapter 19c teaches the conversion.

## Anatomy of a Production Prompt

Every prompt follows the same format (Chapter 4's pillars, operationalized):
1. **Persona** — the lens through which the LLM operates.
2. **Context Anchors** — where to inject files/ADRs.
3. **Task Definition** — the specific action.
4. **Constraints** — what *not* to do (where the AI's training-data defaults are wrong).
5. **Output Schema** — the exact expected format.

## Index

### `/discovery` — understanding existing codebases
| Prompt | Does | Chapter |
| :-- | :-- | :-- |
| [legacy-code-archaeology](discovery/legacy-code-archaeology.md) | Maps responsibilities and risks in inherited code | 16 |
| [database-schema-extraction](discovery/database-schema-extraction.md) | SwiftData/Core Data model graph → ER diagram + migration risks | 12 |

### `/planning` — breaking down requirements
| Prompt | Does | Chapter |
| :-- | :-- | :-- |
| [feature-breakdown](planning/feature-breakdown.md) | Feature → milestones for a prompt chain | 8 |

### `/architecture` — scaffolding with the decisions pre-made
| Prompt | Does | Chapter |
| :-- | :-- | :-- |
| [mvvm-scaffold](architecture/mvvm-scaffold.md) | `@Observable` ViewModel + View per ADR-002 | 9 |
| [ios-tca-feature](architecture/ios-tca-feature.md) | Modern TCA feature (`@Reducer`, `@Dependency`) | 9 |
| [clean-architecture-scaffold](architecture/clean-architecture-scaffold.md) | UseCase/Repository layering | 10 |
| [swiftpm-modularization](architecture/swiftpm-modularization.md) | Cycle-proof target split (graph before manifest) | 10 |
| [router-scaffold](architecture/router-scaffold.md) | Route enum + Router; kills inline NavigationLinks | 11 |
| [offline-repository](architecture/offline-repository.md) | SwiftData + network-actor repository with upsert | 12 |
| [widget-app-group](architecture/widget-app-group.md) | Widget across the process boundary, snapshot DTO | 13 |
| [rest-api-contract](architecture/rest-api-contract.md) | The API contract the client actually needs | 12 |
| [app-intents-surface](architecture/app-intents-surface.md) | App verbs as intents + entities (the OS tool schema) | 34 |

### `/review` — rigorous auditing
| Prompt | Does | Chapter |
| :-- | :-- | :-- |
| [adr-drift-audit](review/adr-drift-audit.md) | Diff vs ADRs → anchor-prompt rewrite instructions | 14 |
| [mvvm-audit](review/mvvm-audit.md) | ViewModel boundary violations | 9 |
| [swift-concurrency-audit](review/swift-concurrency-audit.md) | MainActor/Sendable violations | 12 |
| [ios-lifecycle-audit](review/ios-lifecycle-audit.md) | Task cancellation, observer cleanup | 15 |
| [dead-code-audit](review/dead-code-audit.md) | Generation residue: unused state, orphans | 14 |
| [edge-case-probe](review/edge-case-probe.md) | The 7-row happy-path breaker | 24 |
| [observability-review](review/observability-review.md) | "If this fails, how do we know?" | 33 |
| [security-owasp-audit](review/security-owasp-audit.md) | OWASP-lens PR audit | 14, 32 |

### `/performance` — evidence-scoped fixes
| Prompt | Does | Chapter |
| :-- | :-- | :-- |
| [render-isolation-audit](performance/render-isolation-audit.md) | Read-map + over-render findings | 11, 15 |
| [main-thread-audit](performance/main-thread-audit.md) | Sync work on the render path | 15 |
| [image-pipeline-fix](performance/image-pipeline-fix.md) | Downsample + bounded cache per ADR-009 | 15 |
| [memory-leak-detector](performance/memory-leak-detector.md) | Retain-cycle sweep in closures | 15 |
| [database-query-optimizer](performance/database-query-optimizer.md) | SwiftData fetch placement/shape | 12, 15 |

### `/debugging` — hypothesis discipline
| Prompt | Does | Chapter |
| :-- | :-- | :-- |
| [codebase-orientation](debugging/codebase-orientation.md) | The mental model of unfamiliar territory before any symptom-chasing | 16, 18 |
| [codebase-mapping](debugging/codebase-mapping.md) | The neutral map before any hypothesis | 16 |
| [hypothesis-first-debug](debugging/hypothesis-first-debug.md) | Ranked hypotheses + anti-sycophancy hook | 16 |
| [crash-triage](debugging/crash-triage.md) | Classify termination before hypothesizing | 33 |

### `/testing` — falsifiable green
| Prompt | Does | Chapter |
| :-- | :-- | :-- |
| [generate-mock](testing/generate-mock.md) | Spy-pattern mock from a protocol | 26 |
| [names-first-tdd](testing/names-first-tdd.md) | Human names → AI bodies → AI implementation | 26 |
| [tautology-audit](testing/tautology-audit.md) | Kills tests that can never fail | 26, 30 |
| [snapshot-suite](testing/snapshot-suite.md) | Deterministic snapshot coverage | 30 |

### `/accessibility`
| Prompt | Does | Chapter |
| :-- | :-- | :-- |
| [wcag-audit](accessibility/wcag-audit.md) | Static a11y audit with fix diff | 25 |

### `/security`
| Prompt | Does | Chapter |
| :-- | :-- | :-- |
| [ios-security-audit](security/ios-security-audit.md) | MASVS-lens diff audit | 32 |
| [privacy-manifest-audit](security/privacy-manifest-audit.md) | Manifest vs actual API/data usage | 31, 32 |
| [keychain-store](security/keychain-store.md) | Keychain wrapper, attributes pinned | 32 |

### `/release`
| Prompt | Does | Chapter |
| :-- | :-- | :-- |
| [release-audit](release/release-audit.md) | Go/no-go evidence table (never says GO) | 31 |
| [feature-flag-scaffold](release/feature-flag-scaffold.md) | Flags + kill switches for no-rollback reality | 31 |

### `/refactoring`
| Prompt | Does | Chapter |
| :-- | :-- | :-- |
| [legacy-to-modern-migration](refactoring/legacy-to-modern-migration.md) | UIKit/Combine era → SwiftUI/Observation | 11 |

### `/documentation`
| Prompt | Does | Chapter |
| :-- | :-- | :-- |
| [adr-generator](documentation/adr-generator.md) | Decision discussion → one-page ADR | 22 |
| [pr-description-generator](documentation/pr-description-generator.md) | Diff → PR body for humans and review agents | 14, 22 |
