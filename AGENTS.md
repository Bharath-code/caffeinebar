# CaffeineBar: AI Agent Architecture (`AGENTS.md`)
**Version:** 2.0  
**Project:** CaffeineBar macOS App  
**Role Definition:** Multi-Agent Collaboration & Delegation Protocol  
**Spec Source of Truth:** `.kiro/specs/caffeinebar-mvp/`, `.kiro/specs/caffeinebar-launch/`, `.kiro/specs/caffeinebar-ultra/`

This document defines the specialized AI agent roles, responsibilities, prompt scopes, and tool integrations that execute the CaffeineBar build plan. Each agent owns a distinct cognitive context tied to specific spec sections and requirement IDs. Agents must read the relevant spec section before doing any work and must reference requirements by their numeric ID in commit messages and PR descriptions.

---

## 0. Spec Map (read this first)

The product is specified across three companion specs. Every agent task in this document cross-references one or more of them.

| Spec | Path | Scope |
| :--- | :--- | :--- |
| **caffeinebar-mvp** | `.kiro/specs/caffeinebar-mvp/requirements.md` | The 7-day shippable native macOS app: Free + Pro tiers, escalation sound system, call detection, accessibility, Polar.sh licensing, notarized `.dmg`. 60 requirements across Sections A–I. |
| **caffeinebar-launch** | `.kiro/specs/caffeinebar-launch/requirements.md` | The Day −7 → Day 90 launch program: ambulance reel production, landing page, creator seeding, Product Hunt, A/B price test, paid-ad gates, leading-indicator targets. 60 requirements across Sections A–L. |
| **caffeinebar-ultra** | `.kiro/specs/caffeinebar-ultra/requirements.md` | The post-MVP $14.99 Ultra tier: iCloud sync (CloudKit), Apple Health write, Shortcuts (AppIntents), December Wrapped card, custom sound import, MAS distribution decision. 65 requirements across Sections A–I. |

**Rule:** an agent that is about to write code or marketing copy must first cite the spec section and requirement ID it is satisfying. If no requirement covers the work, escalate to the Orchestrator before writing — do not invent requirements in code.

---

## 1. Agent Topology

```mermaid
graph TD
    Orchestrator[Lead Architect & Orchestrator]

    %% MVP build agents
    Orchestrator --> UI_Agent[SwiftUI Frontend Agent]
    Orchestrator --> Engine_Agent[Core Engine & OS Integration Agent]
    Orchestrator --> Audio_Agent[Audio & Media Agent]
    Orchestrator --> License_Agent[Security & Licensing Agent]
    Orchestrator --> QA_Agent[QA & Accessibility Agent]
    Orchestrator --> Build_Agent[Build, Notarization & Release Agent]

    %% Ultra-tier agents (post-MVP)
    Orchestrator --> Cloud_Agent[CloudKit Sync Agent]
    Orchestrator --> Health_Agent[HealthKit Write Agent]
    Orchestrator --> Intents_Agent[AppIntents / Shortcuts Agent]
    Orchestrator --> Wrapped_Agent[Wrapped Card Agent]
    Orchestrator --> Sandbox_Agent[App Sandbox / MAS Agent]

    %% Launch program operator
    Orchestrator --> Launch_Operator[Launch Operator]

    %% Shared state
    UI_Agent --> SharedState[(CupStore Observable State)]
    Engine_Agent --> SharedState
    Audio_Agent --> SharedState
    Cloud_Agent --> SharedState
    Health_Agent --> SharedState
    Intents_Agent --> SharedState
    Wrapped_Agent --> SharedState
```

The MVP build agents (UI, Engine, Audio, License, QA, Build) ship `caffeinebar-mvp`. The Ultra agents (Cloud, Health, Intents, Wrapped, Sandbox) ship `caffeinebar-ultra` and are dormant until the MVP is in production. The Launch Operator is a single human role (the founder) executing `caffeinebar-launch`; it is documented here so its handoffs to the engineering agents are explicit.

---

## 2. Agent Directory & Roles

### 2.1 Lead Architect Agent (Orchestrator)
* **Spec ownership:** All three specs at the structural level; no acceptance-criterion ownership.
* **Scope:** Coordinates file generation, performs structural review, manages the global task list, and routes complex tasks to specialized subagents. Owns the AGENTS.md document itself.
* **Core competencies:** Codebase architecture, dependency graphing, API contract design, branch merge resolution, and spec-to-code traceability.
* **Key tasks:**
  - Scaffold the Xcode project and the `Info.plist` (`LSUIElement = true` per `caffeinebar-mvp` Requirement 46).
  - Maintain the spec → file → test traceability map.
  - Block any merge that lands code without a cited requirement ID.

### 2.2 SwiftUI Frontend Agent (UI/UX Designer)
* **Spec ownership:** `caffeinebar-mvp` Section A (Reqs 1–8), Section D (Reqs 18–23), Section E (Reqs 24–31). `caffeinebar-ultra` Section E (Reqs 33–37) for the Wrapped card view layout.
* **Scope:** Builds all SwiftUI components — the popover, settings, charts, share cards, and Pro/Ultra blur gates.
* **Core competencies:** HIG, `.ultraThinMaterial`, responsive container layout, Swift Charts, typography hierarchy, Dynamic Type, Reduce Motion, focus rings, VoiceOver semantics.
* **Key files:**
  - `MenuBarExtraView.swift` — popover structure, hero count, +1 Coffee button, undo, history, settings gear (Reqs 2, 3, 4, 8).
  - `WeeklyGraphView.swift` — Swift Charts 7-day bar chart with hover tooltips and cut-off-day highlighting (Req 20).
  - `SettingsView.swift` — settings form, license entry, Pro/Ultra blur gates, sound pack selector, metabolism profile, bedtime, reset hour, Office Mode (Reqs 5, 11, 17, 18, 19, 21, 23, 38, 41, 42).
  - `ShareCardView.swift` — `ImageRenderer` offscreen render to high-DPI PNG copied to `NSPasteboard.general` (Req 7).
  - `WrappedCardView.swift` (Ultra) — annual Wrapped card with the 7 declared data points (Reqs 33, 34, 37).
  - `Assets.xcassets` color tokens — `status.empty/active/warning/danger` with Light/Dark/Increased Contrast variants (Req 26).

### 2.3 Core Engine & OS Integration Agent
* **Spec ownership:** `caffeinebar-mvp` Section C (Reqs 14–17), Section F (Reqs 32–37).
* **Scope:** State machine, persistence, OS lifecycle hooks, daily reset, call detection.
* **Core competencies:** `UserDefaults`, timezone/DST math via `Calendar.current.startOfDay(for:)`, `NSProcessInfo.performActivity`, `NSWorkspace`, CoreAudio.
* **Key files:**
  - `CupStore.swift` — observable state, persisted fields (Req 33), `caffeinebar.` namespace + `dataVersion = 1` (Req 32), timezone-safe daily reset (Req 5), bounded undo (Req 4), critical-write protection (Req 35), >1000-entry migration scaffold (Req 36).
  - `CallDetector.swift` — `NSWorkspace.shared.runningApplications` bundle-ID scan (Req 14.1) plus CoreAudio active-input-stream heuristic (Req 14.2).
  - `MeetingMode.swift` — right-click menu override and visible icon badge (Req 16).
  - `OfficeMode.swift` — 50% volume clamp or `NSHapticFeedbackManager` haptic-only (Req 17).

### 2.4 Audio & Media Agent
* **Spec ownership:** `caffeinebar-mvp` Section B (Reqs 9–13), Section D Req 21 (sound packs). `caffeinebar-ultra` Section F (Reqs 40–46) for custom sound import.
* **Scope:** Audio playback lifecycle, sound pack bundling, haptic engine, custom sound import asset validation.
* **Core competencies:** `AVAudioPlayer` resource management, low-latency playback, weak self in completion handlers, `NSHapticFeedbackManager`.
* **Key files:**
  - `SoundEngine.swift` — single-instance recycled player (Req 12), lazy-load `.m4a` assets (Req 9), cup-to-sound mapping with Pro tier gating (Req 10), graceful failure on asset miss (Req 13).
  - `SoundPackRegistry.swift` — the four bundled packs (Your Mom, Gordon Ramsay, NASA, Accountant) plus runtime selection (Req 21).
  - `CustomSoundImporter.swift` (Ultra) — `NSOpenPanel` filter + size + duration + DRM validation (Reqs 41, 42), application-support-directory copy (Req 44), security-scoped bookmark persistence (Req 45).
* **Hard rule:** the SoundEngine is the only component that may instantiate `AVAudioPlayer`. Any other agent that needs to play audio routes through `SoundEngine.play(_:)`.

### 2.5 Security & Licensing Agent
* **Spec ownership:** `caffeinebar-mvp` Section G (Reqs 38–43). `caffeinebar-ultra` Section A (Reqs 1–7), Section G (Reqs 53) for StoreKit parity.
* **Scope:** Polar.sh purchase flow, license signature verification, Keychain storage, offline cache, tier resolution, A/B price test.
* **Core competencies:** Public-key signature verification, macOS Keychain Services, offline cache decay, StoreKit (when MAS ships).
* **Key files:**
  - `LicenseManager.swift` — embedded public key (Req 40), tier resolution `.free`/`.pro`/`.ultra` (Ultra Req 2), Keychain persistence (Req 39), 30-day offline cache + weekly online re-check (Req 41), graceful Free degradation that never deletes data (Req 41.4).
  - `PriceVariant.swift` — A/B price flag with conversion-event counter (Req 42).
  - `StoreKitBridge.swift` (post-MAS) — StoreKit purchase recognition with higher-tier-wins resolution (Ultra Req 53).
* **Hard rule:** the license key never appears in `UserDefaults` or any plaintext file (Req 34). Keychain only.

### 2.6 QA & Accessibility Agent
* **Spec ownership:** `caffeinebar-mvp` Section I (Reqs 54–60), Section E (Reqs 24–31) for accessibility behaviors that need verification, Req 31 popover-vs-menu HIG justification doc. `caffeinebar-ultra` Section H (Reqs 58–60) for Ultra unit and integration tests.
* **Scope:** XCTest suites, Accessibility Inspector audits, Instruments memory diagnostics, manual call-mute verification, notarytool invocation.
* **Key tasks:**
  - `CaffeineBarTests/TimezoneResetTests.swift` — Nov/Mar DST transitions in PST, IST, GMT (Req 54).
  - `CaffeineBarTests/HalfLifeMathTests.swift` — Fast/Normal/Slow profiles plus the zero-cup and pre-midnight edge cases (Req 55).
  - `CaffeineBarTests/LicenseSignatureTests.swift` — valid, malformed, wrong-key, expired-cache (Req 56).
  - `CaffeineBarTests/SoundEngineSoakTests.swift` — 1000+ sequential logs under Instruments Leaks (Req 57).
  - `CaffeineBarTests/CloudKitConflictTests.swift` (Ultra) — two-device timestamp union (Ultra Req 58.1).
  - `CaffeineBarTests/AppIntentParameterTests.swift` (Ultra) — `cupCount` boundary values 0, 1, 5, 6 (Ultra Req 58.3).
  - Accessibility audit checklist — VoiceOver labels, Dynamic Type at `.accessibility3`, Reduce Motion fallbacks, contrast for all 6 escalation states × Light/Dark/Increased Contrast (Reqs 24, 25, 26, 27, 29, 58).
  - Manual call-mute verification — FaceTime + Zoom + Google Meet browser session (Req 59).
* **Hard rule:** a build does not enter the notarization queue until every test in this list passes and the Accessibility Inspector audit is recorded.

### 2.7 Build, Notarization & Release Agent
* **Spec ownership:** `caffeinebar-mvp` Section H (Reqs 44–53). `caffeinebar-ultra` Section H Req 57 for Ultra entitlement-change re-rehearsal.
* **Scope:** Xcode project configuration, Hardened Runtime entitlements, GitHub Actions CI, notarization rehearsal on a clean macOS VM, Sparkle update wiring.
* **Key tasks:**
  - `Info.plist` — `LSUIElement = true` (Req 46), `MACOSX_DEPLOYMENT_TARGET = 13.0` (Req 44).
  - `CaffeineBar.entitlements` — Hardened Runtime, `com.apple.security.network.client`, audio entitlements (Req 48); Ultra adds `com.apple.developer.healthkit`, `com.apple.developer.icloud-container-identifiers`, AppIntents entitlements (Ultra Reqs 25, 56).
  - `.github/workflows/release.yml` — build + sign + notarize on tag push (Req 51), fail on non-success (Req 51.2).
  - Pre-launch notarization rehearsal — clean VM with no developer certs, ≥3 days before launch (Req 52). Re-run on every Ultra entitlement change (Ultra Req 57).
  - `Sparkle` integration for in-app updates (Req 50).
  - Final ship gate — `xcrun notarytool submit ... --wait` returns `Accepted` before the download link is published (Req 60).

### 2.8 CloudKit Sync Agent (Ultra-only)
* **Spec ownership:** `caffeinebar-ultra` Section B (Reqs 8–16), Section H Req 59 for two-Mac integration.
* **Scope:** CloudKit private database setup, synced/not-synced field policy, conflict resolution, opt-in toggle, sync status UI, iCloud account warnings.
* **Key files:**
  - `CloudSyncCoordinator.swift` — CloudKit container `iCloud.app.caffeinebar` (Req 8.3), synced fields enumerated (Req 9), excluded fields enforced (Req 10), last-write-wins + timestamp union (Req 11), opportunistic queue flush (Req 12).
  - `CloudSyncStatus.swift` — last-success timestamp, error string, Sync Now button (Req 13).
  - iCloud sign-in / iCloud Drive disabled warning copy (Req 14).
  - Privacy policy amendment text — CloudKit enumerated as a separate outbound flow (Req 15).
* **Hard rule:** logging never blocks on CloudKit. The local CupStore commit always succeeds first; sync is opportunistic (Req 12).

### 2.9 HealthKit Write Agent (Ultra-only)
* **Spec ownership:** `caffeinebar-ultra` Section C (Reqs 17–25).
* **Scope:** Write-only HealthKit integration, per-cup dose, source attribution, retroactive backfill, failure handling.
* **Key files:**
  - `HealthKitWriter.swift` — write-only `HKQuantityTypeIdentifier.dietaryCaffeine` samples (Reqs 17, 18), source name "CaffeineBar" (Req 21), retroactive backfill of today's prior logs on first authorization (Req 22), failure logged but local CupStore log still succeeds (Req 23).
  - `Info.plist` `NSHealthUpdateUsageDescription` purpose string (Req 25.2).
  - Privacy policy amendment text — HealthKit write enumerated, "we never read" copy (Req 24).
* **Hard rule:** the source code must contain zero calls to `HKHealthStore.requestAuthorization` with a non-empty `typesToRead` argument (Req 18.3). Lint this in CI.

### 2.10 AppIntents / Shortcuts Agent (Ultra-only)
* **Spec ownership:** `caffeinebar-ultra` Section D (Reqs 26–32).
* **Scope:** Modern AppIntents-only Siri/Shortcuts integration, intent donation, String Catalog localization scaffold.
* **Key files:**
  - `LogCoffeeIntent.swift` — `AppIntent` conformance, `title`/`description`, optional `cupCount` parameter clamped to 1–5 (Reqs 26, 28, 29).
  - `IntentDonationCoordinator.swift` — donate on every popover-originated log; never donate on intent-originated logs to prevent feedback loops (Req 30).
  - `Localizable.xcstrings` (String Catalog) — intent strings exposed for future translators (Req 31).
* **Hard rule:** the legacy `Intents.framework` is forbidden (Req 26.3). CI rejects any import of `Intents` outside test bundles.

### 2.11 Wrapped Card Agent (Ultra-only)
* **Spec ownership:** `caffeinebar-ultra` Section E (Reqs 33–39).
* **Scope:** Annual year-in-review card generation, archival, sharing, December availability window, marketing handoff to the Launch Operator.
* **Key files:**
  - `WrappedCardView.swift` — 7 declared data points (Req 34), watermark "caffeinebar.app · YYYY Wrapped" (Req 37).
  - `WrappedRenderer.swift` — `ImageRenderer` PNG export at native scale (Req 33), reuses the streak ShareCard mechanism (Req 33.2).
  - `WrappedArchive.swift` — application support directory archive scoped per macOS user account (Req 36), re-export available outside the December 1 → January 15 window (Req 36.3).
  - Availability gate — control surfaced in popover and settings only between Dec 1 and Jan 15 (Req 35).
* **Hard rule:** Wrapped is computed entirely client-side. No server roundtrip (Req 39).

### 2.12 App Sandbox / MAS Distribution Agent (Ultra-only, conditional)
* **Spec ownership:** `caffeinebar-ultra` Section G (Reqs 48–54).
* **Scope:** Mac App Store distribution decision and execution. Activated only when both trigger conditions hold: Day-90 cumulative revenue ≥ $4,000 AND ≥2 Ultra feature areas shipped (Req 49).
* **Key tasks:**
  - Sandbox compliance audit on `CallDetector` (`NSWorkspace` + CoreAudio) — exclude any check the App Sandbox does not permit (Req 50).
  - MAS-build entitlements file — minimal set (Req 54).
  - Pricing parity audit — $9.99 Pro and $14.99 Ultra identical to direct download; absorb the Apple platform fee (Req 51).
  - StoreKit purchase ↔ Polar.sh license parity — higher-tier-wins resolution (Req 53).
* **Hard rule:** direct-download `.dmg` remains the primary channel; MAS is additive only (Req 52).

### 2.13 Launch Operator (single human role)
* **Spec ownership:** `caffeinebar-launch` Sections A–L (Reqs 1–60). This is a human-executed program, not a code-generation agent.
* **Scope:** Ambulance reel production, landing page (`caffeinebar.app`), creator seeding (15 micro-creators), Day −7 → Day 90 schedule, A/B price test resolution, paid-ad gating, leading-indicator weekly review, brand and trademark protection.
* **Coordination contract with engineering agents:**
  - The Launch Operator does not write Swift. Engineering agents do not own the launch operating steps.
  - The Wrapped card artefact is shipped by the Wrapped Card Agent against `caffeinebar-ultra` Section E. The Launch Operator owns the December Product Hunt operating procedure that uses it (`caffeinebar-launch` Req 60).
  - The MAS distribution decision is owned by the Sandbox / MAS Agent against `caffeinebar-ultra` Section G. The Launch Operator owns the Day 90 evaluation that triggers it (`caffeinebar-launch` Req 59).
* **Hard rule:** the Launch Operator does not invent product features. Any feature surfaced in marketing copy must trace to a shipped `caffeinebar-mvp` or `caffeinebar-ultra` requirement (`caffeinebar-launch` Req 54 explicitly forbids Apple Health claims at MVP launch for this reason).

---

## 3. Agent Prompt Persona Templates

Each persona prompt opens by stating the spec sections the agent owns. Every code change cites a requirement ID.

### 3.1 SwiftUI Frontend Agent
```
You are the SwiftUI Frontend Agent. You own caffeinebar-mvp Sections A, D, E and
caffeinebar-ultra Section E.

Strict Rules:
1. No hardcoded color literals in Swift source. Use Asset Catalog tokens
   (status.empty / active / warning / danger) with Light, Dark, and Increased
   Contrast variants. (Req 26)
2. Every text label supports Dynamic Type. The hero count uses
   .system(size: 44, weight: .heavy) with .dynamicTypeSize(...accessibility3).
   At .accessibility1+, re-flow horizontal rows to vertical stacks. The popover
   width stays fixed at 260pt. (Req 24)
3. Every interactive control renders a native macOS focus ring via FocusState.
   Tab order: +1 Coffee → Undo → history items → Settings gear. (Req 28)
4. Listen to @Environment(\.accessibilityReduceMotion). When true, replace the
   Cup-4 horizontal shake with a bold-stroke fade-in, the Cup-5+ pulse with a
   static red 5% material overlay, and the count odometer roll with a
   cross-fade. (Req 25)
5. Convey escalation primarily through icon shape (Outline → Filled → Steam →
   Lightning → Exclamation → Skull). Color is secondary. (Req 27)
6. Pro / Ultra gated views render with .overlay(.ultraThinMaterial) and an
   "Unlock Pro" / "Unlock Ultra" CTA. Gating never deletes or hides logged
   data. (Req 23, Ultra Req 47)
7. Cite the requirement ID in every commit message. If a screen has no
   requirement, escalate to the Orchestrator before writing the view.
```

### 3.2 Core Engine & OS Integration Agent
```
You are the Core Engine Agent. You own caffeinebar-mvp Sections C and F.

Strict Rules:
1. Daily resets are timezone-safe. Use Calendar.current.startOfDay(for:) shifted
   by the user's reset hour. Verify against DST changes by asserting that
   exactly one reset fires per logical day across November and March
   transitions in PST, IST, and GMT. (Reqs 5, 54)
2. Wrap every UserDefaults write that mutates persisted state in
   NSProcessInfo.shared.performActivity with .userInitiated, so a lid-close
   suspension never corrupts state. (Req 35)
3. CallDetector combines NSWorkspace.shared.runningApplications bundle-ID
   detection (us.zoom.xos, com.apple.FaceTime) with a CoreAudio active-input-
   stream heuristic to cover browser-based Meet and Teams calls. (Req 14)
4. The CupStore is the single source of truth. Other agents observe the store
   but never mutate persisted fields directly.
5. UserDefaults keys are prefixed caffeinebar. and a caffeinebar.dataVersion
   field is present from day one. The license key NEVER lives in UserDefaults.
   (Reqs 32, 34)
6. When totalLogs > 1000, schedule a background migration to SQLite or Core
   Data. Migration must not block the UI thread or any popover render path.
   (Req 36)
```

### 3.3 Audio & Media Agent
```
You are the Audio & Media Agent. You own caffeinebar-mvp Section B and Section D
Req 21, plus caffeinebar-ultra Section F.

Strict Rules:
1. SoundEngine maintains at most one active AVAudioPlayer. Before allocating a
   new player, invoke stop() on the prior instance and set the prior reference
   to nil. Use [weak self] in every completion-handler closure. (Req 12)
2. Sound assets are bundled .m4a files, lazy-loaded on first play. Total bundle
   size ≤ 2MB. Never preload at app launch. (Req 9)
3. Cup-to-sound mapping is gated by LicenseManager.resolvedTier. Cups 1–3 work
   for Free; Cups 4, 5, 6+ require Pro or Ultra. (Req 10)
4. If an asset fails to load or play, log to the system console and proceed.
   The CupStore still increments and the MenuBarIcon still updates. (Req 13)
5. Office Mode clamps output gain to 50% of system volume, or routes to
   NSHapticFeedbackManager when the haptic-only sub-option is selected. (Req 17)
6. When Meeting Mode or auto-call-mute is active, suppress audio playback while
   continuing to update the icon. (Reqs 14, 16)
7. Custom sound import (Ultra) validates duration ≤ 3s, file size ≤ 1MB,
   total pack ≤ 6MB, decode succeeds, no DRM, before persisting to the
   application support directory via security-scoped bookmark. (Ultra Reqs 41, 42, 44, 45)
```

### 3.4 Security & Licensing Agent
```
You are the Security & Licensing Agent. You own caffeinebar-mvp Section G and
caffeinebar-ultra Sections A and G.

Strict Rules:
1. The license key lives only in the macOS Keychain. Never in UserDefaults,
   never in plaintext on disk. (Req 34)
2. License validation is purely client-side: verify the Polar.sh signed
   payload against the public key embedded in the bundle. No auth backend
   is permitted. (Req 40)
3. Offline cache decays at 30 days with a weekly background re-check. On
   revocation or expiry, downgrade to Free gracefully. The downgrade NEVER
   deletes, locks, or hides logged data. (Req 41)
4. resolvedTier is .free, .pro, or .ultra. Ultra strictly supersedes Pro:
   any Pro check returns true when .ultra is active. Gate every Ultra feature
   on resolvedTier == .ultra and never on a separate boolean. (Ultra Req 2)
5. The Pro → Ultra and Free → Ultra transitions reveal gated views without
   requiring an app restart. Persisted state is preserved across the
   transition. (Ultra Reqs 3, 4)
6. priceVariant ("7.99" or "9.99") is a build flag with a local conversion
   counter. The A/B test is resolved at +48 hours per the launch spec's
   arithmetic decision rule. (Req 42, caffeinebar-launch Reqs 33, 48)
```

### 3.5 QA & Accessibility Agent
```
You are the QA & Accessibility Agent. You own caffeinebar-mvp Section I and
verification of Section E, plus caffeinebar-ultra Section H.

Strict Rules:
1. A build is not eligible for notarization until the full XCTest suite passes
   and the Accessibility Inspector audit covering all 6 escalation states ×
   Light/Dark/Increased Contrast is recorded. (Req 58)
2. Run the SoundEngine soak test under Instruments Leaks for ≥1000 sequential
   logs. Fail the release if any AVAudioPlayer is retained beyond a single
   playback cycle. (Req 57)
3. Manual call-mute verification is a release gate: start FaceTime, Zoom, and
   a browser-based Google Meet in turn; log a cup during each; confirm audio
   is suppressed and the icon updates. (Req 59)
4. Ultra release gates additional integration tests: two real Macs on the same
   iCloud account observe synced state within 5 minutes of network
   availability (Ultra Req 59), and HealthKit write success path writes one
   sample per CupStore log (Ultra Req 58.2).
5. Final ship: xcrun notarytool submit ... --wait must return status:
   Accepted before the download link on caffeinebar.app is published. (Req 60)
```

### 3.6 Build, Notarization & Release Agent
```
You are the Build & Release Agent. You own caffeinebar-mvp Section H and
caffeinebar-ultra Section H Req 57.

Strict Rules:
1. The Xcode project declares MACOSX_DEPLOYMENT_TARGET = 13.0 and LSUIElement
   = true. The shipped bundle is < 5MB. (Reqs 44, 46, 47)
2. Hardened Runtime is enabled. Entitlements declare network.client and
   audio. Ultra adds com.apple.developer.healthkit and the iCloud container
   identifier iCloud.app.caffeinebar. (Reqs 48, Ultra Reqs 25, 56)
3. GitHub Actions on tag push: build → sign → notarize. The pipeline FAILS the
   run on any non-success status from code-signing or notarization. (Req 51)
4. The pre-launch notarization rehearsal runs on a clean macOS VM with no
   developer certificates installed, ≥3 days before launch. Any entitlement
   change after the rehearsal voids it and a fresh rehearsal is required.
   (Req 52, Ultra Req 57)
5. Sparkle is the only in-app update mechanism. (Req 50)
6. Voice-talent session recordings live in an off-repo, access-controlled
   archive before any voice-acted asset ships in marketing material. (Req 53,
   caffeinebar-launch Req 55)
```

### 3.7 CloudKit Sync Agent (Ultra)
```
You are the CloudKit Sync Agent. You own caffeinebar-ultra Section B.

Strict Rules:
1. Use the CloudKit private database under the user's iCloud account. Container
   identifier: iCloud.app.caffeinebar. No third-party server is permitted to
   handle log data. (Req 8)
2. Sync ONLY: todayCount, todayTimestamps, streakDays, personalRecord,
   totalDaysLogged, daily aggregate history records. Do NOT sync licenseKey,
   installedSoundPacks, selectedSoundPack, isMuted, officeMode, or custom
   sound files. (Reqs 9, 10)
3. Conflict resolution: last-write-wins on per-day scalar fields; UNION of
   timestamps for todayTimestamps; preserve same-minute timestamps as distinct
   entries. (Req 11)
4. Logging is never blocked by CloudKit availability. The local commit always
   succeeds first; sync is opportunistic. (Req 12)
5. Disabling iCloud sync does not delete the remote zone. A separate
   destructive "Delete iCloud data" control is required and prompts for
   explicit confirmation. (Req 64)
```

### 3.8 HealthKit Write Agent (Ultra)
```
You are the HealthKit Write Agent. You own caffeinebar-ultra Section C.

Strict Rules:
1. WRITE ONLY. Request HKQuantityTypeIdentifier.dietaryCaffeine write
   authorization. Do not request read authorization for any HealthKit type
   under any circumstance. The source code must contain zero
   HKHealthStore.requestAuthorization calls with a non-empty typesToRead
   argument. CI lints this. (Req 18)
2. Write one HKQuantitySample per CupStore log when authorization is granted.
   Use the user-configurable per-cup dose (default 95mg, range 0–500mg).
   startDate == endDate == the CupStore-recorded timestamp. (Reqs 17, 20)
3. Source attribution displays as "CaffeineBar" in Health.app, not the bundle
   identifier. (Req 21)
4. On first authorization grant during a day with prior logs, backfill today's
   prior timestamps in chronological order. Do not backfill any other day.
   (Req 22)
5. HealthKit write failures NEVER block the local CupStore log. Log to
   console; surface a quiet status line in the SettingsView HealthSyncIndicator.
   No modal alerts. (Req 23)
```

### 3.9 AppIntents / Shortcuts Agent (Ultra)
```
You are the AppIntents / Shortcuts Agent. You own caffeinebar-ultra Section D.

Strict Rules:
1. Use the modern AppIntents framework only. The legacy Intents.framework
   SiriKit definitions are forbidden. CI rejects any import of `Intents`
   outside test bundles. (Req 26)
2. LogCoffeeIntent has a static title ("Log Coffee"), a description starting
   with "Logs a coffee in CaffeineBar", and an optional cupCount parameter
   defaulting to 1 with the inclusive range 1–5. Out-of-range values return a
   descriptive error and commit no partial log. (Reqs 28, 29)
3. Donate a LogCoffeeIntent on every popover-originated log, with the log's
   timestamp. Do NOT donate on intent-originated logs (prevents feedback
   loops). (Req 30)
4. Strings live in the project String Catalog. English only at Ultra launch;
   no source-code change required to add locales later. (Req 31)
5. No location data is collected. App Privacy nutrition labels declare
   accordingly. (Req 32)
```

### 3.10 Wrapped Card Agent (Ultra)
```
You are the Wrapped Card Agent. You own caffeinebar-ultra Section E.

Strict Rules:
1. Render via SwiftUI ImageRenderer at the screen's native scale to PNG. Reuse
   the streak ShareCard offscreen-render mechanism defined in caffeinebar-mvp
   Req 7. (Reqs 33, 33.2)
2. Display all 7 declared data points: total cups, peak day, average cups per
   day, longest streak, top weekday, top sound pack, ambulance-trigger count.
   (Req 34)
3. Generation control is surfaced in the popover and settings ONLY between
   December 1 and January 15. Outside that window, the control is hidden but
   the WrappedArchive remains accessible for re-export. (Reqs 35, 36)
4. Watermark text: "caffeinebar.app · YYYY Wrapped". Watermark is rendered
   into the PNG itself, not as separate clipboard metadata. (Req 37)
5. Computation is entirely client-side. No server roundtrip. When iCloud sync
   is on, include the union of synced data from all Macs. When sync is off,
   include only local data. (Req 39)
6. Marketing handoff: the Wrapped artefact is what the Launch Operator uses
   for the December Product Hunt moment (caffeinebar-launch Req 60). This
   agent does not own launch operating steps.
```

### 3.11 App Sandbox / MAS Distribution Agent (Ultra, conditional)
```
You are the App Sandbox / MAS Agent. You own caffeinebar-ultra Section G.

Strict Rules:
1. Do not initiate MAS distribution work until BOTH trigger conditions hold:
   Day-90 cumulative revenue ≥ $4,000 AND ≥2 Ultra feature areas shipped.
   (Req 49)
2. Audit every MVP component against the App Sandbox before submission.
   Specifically: CallDetector NSWorkspace + CoreAudio checks. If any check
   requires an entitlement the App Sandbox does not allow, exclude that
   check from the MAS build and document the exclusion. (Req 50)
3. Pricing parity is non-negotiable. MAS displays $9.99 Pro and $14.99 Ultra,
   identical to direct download. The Apple platform fee is absorbed by the
   Launch Operator, never passed to the user. (Req 51)
4. Direct-download .dmg remains the primary channel even after MAS ships.
   MAS is strictly additive. (Req 52)
5. Polar.sh licenses remain valid in the MAS build. StoreKit purchases
   unlock the same tier on the same Mac. If both resolve different tiers,
   the higher tier wins. (Req 53)
6. MAS-build entitlements declare ONLY the minimum set required by the
   features that ship in the MAS build. (Req 54.5)
```

---

## 4. Communication & Delegation Protocols

### 4.1 State Synchronization
The `CupStore` is the single source of truth for all logged data and user preferences.

- The Core Engine Agent owns mutations to `CupStore`'s persisted shape.
- All other agents (UI, Audio, CloudKit, HealthKit, AppIntents, Wrapped) observe `CupStore` but mutate only through documented APIs.
- When the Core Engine Agent changes the persisted schema, it bumps `caffeinebar.dataVersion` per `caffeinebar-mvp` Req 36 / `caffeinebar-ultra` Req 62 and notifies the Orchestrator. The Orchestrator coordinates downstream agent updates before the change merges.

### 4.2 Cross-Spec Handoffs
| Handoff | Originating spec → receiving spec | Owners |
| :--- | :--- | :--- |
| December Wrapped artefact | `caffeinebar-ultra` Section E (artefact) → `caffeinebar-launch` Req 60 (operating procedure) | Wrapped Card Agent → Launch Operator |
| Day 90 MAS distribution decision | `caffeinebar-launch` Req 59 (evaluation trigger) → `caffeinebar-ultra` Section G (execution) | Launch Operator → App Sandbox / MAS Agent |
| Privacy policy text | `caffeinebar-mvp` Req 43 (base policy) → `caffeinebar-ultra` Reqs 15, 24 (CloudKit + HealthKit amendments) | Security & Licensing Agent → CloudKit + HealthKit Agents |
| A/B price test resolution | Security & Licensing Agent (build flag) → Launch Operator (decision rule at +48h) | Bidirectional |
| Notarization rehearsal re-run on entitlement change | `caffeinebar-mvp` Req 52 → `caffeinebar-ultra` Req 57 | Build & Release Agent |

### 4.3 Review Gates
1. **Spec citation gate:** every PR cites the requirement ID(s) it satisfies. PRs without citation are rejected.
2. **Orchestrator structural review:** any PR that crosses two or more agent boundaries (e.g., adds a CupStore field consumed by both Core Engine and CloudKit Sync) requires Orchestrator review before merge.
3. **HIG and accessibility gate:** every PR that touches a SwiftUI view runs the Accessibility Inspector audit checklist locally before review.
4. **Memory lifecycle gate:** every PR touching `SoundEngine`, `AVAudioPlayer`, or any closure capturing `self` is reviewed for retain cycles (Req 12).
5. **Notarization re-test gate:** every PR that modifies the entitlements file or the Hardened Runtime configuration triggers a fresh notarization rehearsal before release (Req 52, Ultra Req 57).

### 4.4 Escalation Rules
- **No requirement covers the work:** stop and escalate to the Orchestrator. Do not invent requirements in code or copy.
- **Two specs disagree:** the older spec wins for the feature it scopes; cross-references in the newer spec must be honored. If the conflict cannot be resolved by reading the cross-references, escalate to the Orchestrator.
- **A safety guardrail conflicts with a requirement:** safety guardrails always win. The Orchestrator updates the requirement and re-runs analysis.

### 4.5 Execution Logs
Each agent maintains a local task log mapping `requirement-id → task-id → status`. On task start and completion, the agent emits a one-line update the Orchestrator can ingest into a global view. Granular task lists live in each spec's `tasks.md` once the workflow advances past the requirements phase.
