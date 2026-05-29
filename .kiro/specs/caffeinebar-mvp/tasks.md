# Implementation Plan: CaffeineBar MVP

## Overview

This plan implements the CaffeineBar macOS menu bar utility across 7 phases (matching the 7-day build schedule). Each task is assigned to the owning agent from AGENTS.md and references specific requirement IDs. The implementation language is Swift/SwiftUI throughout.

## Tasks

- [x] 1. Phase 1 — Scaffold & Core State (Day 1)

  - [x] 1.1 Create Xcode project with Info.plist and entitlements
    - Create CaffeineBar Xcode project targeting macOS 13.0 (Ventura)
    - Set `LSUIElement = true` in Info.plist
    - Set `MACOSX_DEPLOYMENT_TARGET = 13.0`
    - Create `CaffeineBar.entitlements` with Hardened Runtime, `com.apple.security.network.client`, `com.apple.security.device.audio-input`
    - Add Sparkle as Swift Package dependency with `SUFeedURL` in Info.plist
    - **Owner: Build & Release Agent**
    - _Requirements: 44, 45, 46, 47, 48, 50_

  - [x] 1.2 Implement CupStore model with UserDefaults persistence
    - Create `Model/CupStore.swift` as `@Observable` class
    - Implement all persisted fields: `todayCount`, `todayTimestamps`, `lastResetDate`, `streakDays`, `personalRecord`, `totalDaysLogged`, `resetHour`, `bedtime`, `metabolismProfile`, `isMuted`, `officeMode`, `autoMuteOnCalls`, `installedSoundPacks`, `selectedSoundPack`, `dailyHistory`, `dataVersion`
    - All keys use `caffeinebar.` prefix
    - Set `caffeinebar.dataVersion = 1` from first build
    - Set `autoMuteOnCalls` default to `true`
    - Wrap every write in `NSProcessInfo.shared.performActivity(.userInitiated)`
    - Implement `DayRecord` Codable struct
    - Implement `MetabolismProfile` enum (fast=5h, normal=5.5h, slow=6h)
    - **Owner: Core Engine Agent**
    - _Requirements: 15, 32, 33, 35_

  - [x] 1.3 Implement logCup() and undoLastCup() with bounded undo
    - `logCup()` increments `todayCount`, appends timestamp, updates `personalRecord`
    - `undoLastCup()` decrements count, removes last timestamp
    - Bound undo history to 50 entries via ring buffer
    - **Owner: Core Engine Agent**
    - _Requirements: 3.1, 4.3, 4.5, 6.4_

  - [x] 1.4 Register MenuBarExtra entry point
    - Create `CaffeineBarApp.swift` with `@main` App struct
    - Register `MenuBarExtra` with `.window` style
    - Inject `CupStore` and `LicenseManager` into environment
    - **Owner: Lead Architect (Orchestrator)**
    - _Requirements: 46_

n  - [x]* 1.5 Write property tests for CupStore core operations
    - **Property 2: Log action increments count and appends timestamp**
    - **Property 3: Undo is the left-inverse of log**
    - **Property 5: Undo buffer is bounded**
    - **Property 8: Personal record is monotonically non-decreasing**
    - **Property 17: Persistence round-trip**
    - **Property 18: UserDefaults key prefix invariant**
    - **Validates: Requirements 3.1, 4.3, 4.5, 6.4, 32, 33**
    - **Owner: QA & Accessibility Agent**

- [x] 2. Phase 1 Checkpoint
  - Ensure all tests pass, ask the user if questions arise.

- [x] 3. Phase 2 — Core Popover UI & Logging (Day 2)

  - [x] 3.1 Build MenuBarExtraView popover structure
    - Fixed width 260pt, dynamic height
    - Background: `.ultraThinMaterial`
    - Hero cup count: `.system(size: 44, weight: .heavy, design: .rounded)` with `.dynamicTypeSize(...accessibility3)`
    - "+1 Coffee" button: `.borderedProminent`, `.controlSize(.large)`
    - Today's timestamps in `.system(.caption, design: .monospaced)`
    - Settings gear in bottom-right corner
    - **Owner: SwiftUI Frontend Agent**
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6_

  - [x] 3.2 Implement one-click logging flow
    - Wire "+1 Coffee" button to `CupStore.logCup()`
    - Dismiss popover after log (default behavior)
    - Add "keep popover open after log" preference support
    - No confirmation dialog or modal
    - **Owner: SwiftUI Frontend Agent**
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5_

  - [x] 3.3 Implement Undo affordance with ⌘+Z
    - Show "Undo last coffee" when `todayCount > 0`
    - Hide undo when `todayCount == 0`
    - Wire ⌘+Z keyboard shortcut
    - **Owner: SwiftUI Frontend Agent**
    - _Requirements: 4.1, 4.2, 4.3, 4.4_

  - [x] 3.4 Implement today's timestamps display and empty state
    - Display timestamps list for today's logs
    - Empty state: low-opacity `cup.and.saucer.fill` SF Symbol + "Engine cold. Log your first cup."
    - Hide empty state when `todayCount > 0`
    - **Owner: SwiftUI Frontend Agent**
    - _Requirements: 8.1, 8.2_

  - [x] 3.5 Write property test for undo visibility invariant
    - **Property 4: Undo visibility invariant**
    - **Validates: Requirements 4.1, 4.2**
    - **Owner: QA & Accessibility Agent**

- [x] 4. Phase 3 — Icon Escalation & Daily Reset (Day 3)

  - [x] 4.1 Implement IconRenderer with 6 escalation states
    - Create `View/IconRenderer.swift` with static methods
    - Map: 0→outline cup/gray, 1→filled cup, 2→filled+steam, 3→filled+lightning, 4→filled+exclamation/warning, 5+→skull/danger
    - All icons as SF Symbols rendered as template images
    - Shape conveys state primarily; color is secondary
    - Dynamic `accessibilityLabel` per state
    - **Owner: SwiftUI Frontend Agent**
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7, 1.8, 27.1_

  - [x] 4.2 Create Asset Catalog color tokens
    - Define `status.empty`, `status.active`, `status.warning`, `status.danger` in Assets.xcassets
    - Each with Light, Dark, and Increased Contrast variants
    - `status.warning` light = `#D97706` (≥3:1 contrast on white)
    - `status.danger` light = `#D70015`
    - No hardcoded hex color literals in Swift source
    - **Owner: SwiftUI Frontend Agent**
    - _Requirements: 26.1, 26.2, 26.3, 26.4_

  - [x] 4.3 Implement timezone-safe daily reset logic
    - `evaluateReset()` using `Calendar.current.startOfDay(for:)` + resetHour
    - Guard with `lastResetDate < boundary` for exactly-once semantics
    - Handle DST spring-forward and fall-back correctly
    - Archive prior day count to `dailyHistory`
    - Update streak: increment if prior count > 0, reset to 0 otherwise
    - Update `totalDaysLogged` on non-zero days
    - Reset `todayCount = 0`, clear `todayTimestamps`, set `lastResetDate`
    - Schedule next check at boundary
    - **Owner: Core Engine Agent**
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 6.1, 6.2, 6.3_

  - [x] 4.4 Add custom reset hour in SettingsView
    - Picker for reset hour 0–23
    - Display streak stats: `streakDays`, `personalRecord`, `totalDaysLogged`
    - Display "Streaks are per macOS user account; iCloud sync coming in Ultra."
    - **Owner: SwiftUI Frontend Agent**
    - _Requirements: 5.2, 6.5, 37.2_

  - [x] 4.5 Implement migration trigger for >1000 entries
    - When `dailyHistory.count > 1000`, schedule background migration
    - Migration runs on background queue, never blocks UI
    - **Owner: Core Engine Agent**
    - _Requirements: 36.1, 36.2_

  - [x] 4.6 Write property tests for daily reset and streak logic
    - **Property 6: Daily reset fires exactly once per logical day**
    - **Property 7: Streak logic on daily reset**
    - **Validates: Requirements 5.1, 5.2, 5.3, 5.4, 6.2, 6.3**
    - **Owner: QA & Accessibility Agent**

  - [x] 4.7 Write unit tests for timezone/DST reset
    - Test November DST end transition (fall-back)
    - Test March DST start transition (spring-forward)
    - Test in America/Los_Angeles, Asia/Kolkata, Europe/London
    - Assert exactly one reset per logical day
    - **Owner: QA & Accessibility Agent**
    - _Requirements: 54.1, 54.2, 54.3_

  - [x] 4.8 Write property test for escalation state mapping
    - **Property 1: Escalation state mapping is total and deterministic**
    - **Validates: Requirements 1.2, 1.3, 1.4, 1.5, 1.6, 1.7**
    - **Owner: QA & Accessibility Agent**

- [x] 5. Phase 3 Checkpoint
  - Ensure all tests pass, ask the user if questions arise.

- [x] 6. Phase 4 — Sound Engine & Call Detection (Day 4)

  - [x] 6.1 Implement SoundEngine with single-instance AVAudioPlayer recycling
    - Create `Engine/SoundEngine.swift`
    - Maintain at most one active `AVAudioPlayer` instance
    - Before new allocation: `stop()` prior, set to `nil`
    - Use `[weak self]` in every completion handler
    - Lazy-load `.m4a` assets on first play (never at launch)
    - Log errors via `os_log` on asset failure; never crash
    - **Owner: Audio & Media Agent**
    - _Requirements: 9.3, 12.1, 12.2, 12.3, 13.1, 13.2_

  - [x] 6.2 Bundle sound assets and implement cup-to-sound mapping
    - Bundle all `.m4a` files in `Sounds/` directory (≤2MB total)
    - Cup 1 → "soft chime", Cup 2 → "approving ding", Cup 3 → "hmm voice"
    - Cup 4 → "stethoscope concern" (Pro only)
    - Cup 5 → "ambulance siren" (Pro only)
    - Cup 6+ → rotating chaos pool (Pro only)
    - Gate cups 4+ on `LicenseManager.resolvedTier >= .pro`
    - **Owner: Audio & Media Agent**
    - _Requirements: 9.1, 9.2, 10.1, 10.2, 10.3, 10.4, 10.5, 10.6_

  - [x] 6.3 Implement CallDetector with bundle ID + CoreAudio detection
    - Create `Engine/CallDetector.swift`
    - Scan `NSWorkspace.shared.runningApplications` for `us.zoom.xos`, `com.apple.FaceTime`
    - Query CoreAudio `AudioObjectGetPropertyData` for active input streams
    - Poll on 2-second timer, cache result
    - Suppress audio when call active (icon still updates)
    - **Owner: Core Engine Agent**
    - _Requirements: 14.1, 14.2, 14.3_

  - [x] 6.4 Implement Meeting Mode (right-click context menu)
    - Create `Engine/MeetingMode.swift`
    - Add "Meeting Mode" toggle to MenuBarIcon right-click context menu
    - Suppress all audio while active
    - Display small dot badge on MenuBarIcon when active
    - **Owner: Core Engine Agent**
    - _Requirements: 16.1, 16.2, 16.3_

  - [x] 6.5 Implement Office Mode (volume cap + haptic)
    - Create `Engine/OfficeMode.swift`
    - Add toggle in SettingsView
    - When active (non-haptic): clamp volume to 50% of system volume
    - When active (haptic-only): invoke `NSHapticFeedbackManager` instead of audio
    - **Owner: Core Engine Agent**
    - _Requirements: 17.1, 17.2, 17.3_

  - [x] 6.6 Implement mute toggle and auto-mute defaults
    - Add mute toggle in SettingsView
    - When muted: suppress all audio, icon still updates
    - `autoMuteOnCalls` defaults ON on first launch
    - Add auto-mute toggle in SettingsView
    - **Owner: SwiftUI Frontend Agent**
    - _Requirements: 11.1, 11.2, 11.3, 11.4, 15.1, 15.2_

  - [x] 6.7 Write property tests for sound engine behavior
    - **Property 9: Cup-to-sound mapping respects tier gating**
    - **Property 10: Audio suppression under mute conditions**
    - **Property 11: Single AVAudioPlayer invariant**
    - **Property 15: Office mode volume constraint**
    - **Validates: Requirements 10, 11, 12, 14.3, 16.2, 17.2, 17.3**
    - **Owner: QA & Accessibility Agent**

  - [x] 6.8 Write property test for call detection logic
    - **Property 12: Call detection logic**
    - **Validates: Requirements 14.1, 14.2**
    - **Owner: QA & Accessibility Agent**

- [x] 7. Phase 4 Checkpoint
  - Ensure all tests pass, ask the user if questions arise.

- [x] 8. Phase 5 — Pro Features (Day 5)

  - [x] 8.1 Implement HalfLifeClock view and computation
    - Create `View/HalfLifeClock.swift`
    - Compute clearance: `lastLog + halfLife × 6` (97% elimination)
    - Half-life: Fast=5h, Normal=5.5h, Slow=6h
    - Display as wall-clock time: "Caffeine clears your system at 9:47 PM"
    - VoiceOver label: "Caffeine clears your system at {time}"
    - Only visible when `resolvedTier >= .pro` AND `todayCount > 0`
    - **Owner: SwiftUI Frontend Agent**
    - _Requirements: 18.1, 18.2, 18.3, 18.4_

  - [x] 8.2 Implement cut-off time reminder and bedtime config
    - Add bedtime picker in SettingsView (time-of-day value)
    - When clearanceTime > bedtime: apply `status.warning` amber tint to icon
    - Post notification "That's your problem tonight." on late log
    - Only active for Pro/Ultra tier
    - **Owner: SwiftUI Frontend Agent**
    - _Requirements: 19.1, 19.2, 19.3_

  - [x] 8.3 Implement WeeklyGraphView with Swift Charts
    - Create `View/WeeklyGraphView.swift`
    - 7-day `BarMark` chart from `dailyHistory`
    - Hover tooltip via `.chartOverlay` showing date + count
    - Bars exceeding cut-off threshold in `status.warning` color
    - Only visible when `resolvedTier >= .pro`
    - **Owner: SwiftUI Frontend Agent**
    - _Requirements: 20.1, 20.2, 20.3_

  - [x] 8.4 Implement SoundPackRegistry and sound pack selector
    - Create `Engine/SoundPackRegistry.swift`
    - Register 4 bundled packs: "Your Mom", "Gordon Ramsay", "NASA Mission Control", "The Accountant"
    - Add sound pack selector in SettingsView (Pro-gated)
    - When `selectedSoundPack` changes, SoundEngine uses new pack assets
    - **Owner: Audio & Media Agent**
    - _Requirements: 21.1, 21.2, 21.3_

  - [x] 8.5 Implement Free tier upsell notification at Cup 4
    - Post native macOS notification: "Cup 4. Something is about to happen. Unlock CaffeineBar Pro to find out."
    - Fire only when `tier == .free` AND `cupCount == 4`
    - At most once per logical day
    - **Owner: SwiftUI Frontend Agent**
    - _Requirements: 22.1, 22.2_

  - [x] 8.6 Implement Pro-feature blur gate
    - HalfLifeClock and WeeklyGraphView: `.overlay(.ultraThinMaterial)` + "Unlock Pro" CTA when Free
    - ShareCard control hidden behind Pro gate
    - Never delete or hide logged data based on tier
    - On tier upgrade: remove blur without restart
    - **Owner: SwiftUI Frontend Agent**
    - _Requirements: 23.1, 23.2, 23.3_

  - [x] 8.7 Write property tests for Pro features
    - **Property 13: Half-life clearance time computation**
    - **Property 14: Cut-off warning fires correctly**
    - **Property 24: Upsell notification fires correctly**
    - **Property 25: Sound pack selection routes correctly**
    - **Validates: Requirements 18.1, 18.2, 19.2, 19.3, 22.1, 22.2, 21.2, 21.3**
    - **Owner: QA & Accessibility Agent**

  - [x] 8.8 Write unit tests for half-life math
    - Test Fast/Normal/Slow profiles
    - Test zero-cup edge case (no clearance time)
    - Test pre-midnight log (clearance on next calendar day)
    - **Owner: QA & Accessibility Agent**
    - _Requirements: 55.1, 55.2, 55.3_

- [x] 9. Phase 5 Checkpoint
  - Ensure all tests pass, ask the user if questions arise.

- [x] 10. Phase 6 — Licensing, Settings & Share (Day 6)

  - [x] 10.1 Implement LicenseManager with Keychain storage
    - Create `Licensing/LicenseManager.swift` as `@Observable`
    - Define `LicenseTier` enum: `.free`, `.pro`, `.ultra` (Comparable)
    - Store license key in Keychain only (`kSecClassGenericPassword`)
    - Service: `app.caffeinebar.license`, Account: `polar.sh`
    - Access: `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` + bundle-scoped ACL
    - License key NEVER in UserDefaults or plaintext
    - **Owner: Security & Licensing Agent**
    - _Requirements: 34.1, 34.2, 34.3, 38.3, 39.1_

  - [x] 10.2 Implement client-side signature verification
    - Embed hardcoded public key in bundle
    - Parse license key as JSON payload
    - Verify ECDSA signature via `SecKeyVerifySignature`
    - On success: store in Keychain, set `resolvedTier`
    - On failure: return `.invalidSignature`, tier stays `.free`
    - **Owner: Security & Licensing Agent**
    - _Requirements: 40.1, 40.2, 40.3_

  - [x] 10.3 Implement offline validation cache with graceful degradation
    - Cache positive validation for 30 days
    - Weekly background re-check
    - On revocation/expiry: degrade to `.free`
    - Degradation NEVER deletes data
    - `resolvedTier` is `@Observable` — views react immediately, no restart
    - **Owner: Security & Licensing Agent**
    - _Requirements: 41.1, 41.2, 41.3, 41.4_

  - [x] 10.4 Implement PriceVariant build flag
    - Create `Licensing/PriceVariant.swift`
    - Build flag: `PRICE_VARIANT` = "7.99" or "9.99"
    - Display matching price in SettingsView
    - Persist local conversion-event count per variant
    - **Owner: Security & Licensing Agent**
    - _Requirements: 42.1, 42.2, 42.3, 42.4_

  - [x] 10.5 Build complete SettingsView
    - Reset hour picker (0–23)
    - Bedtime picker (time-of-day)
    - Metabolism profile picker ("Fast metabolizer" / "Normal metabolizer" / "Slow metabolizer")
    - Mute toggle
    - Office Mode toggle + haptic sub-option
    - Auto-mute on calls toggle
    - Sound pack selector (Pro-gated)
    - License key entry field
    - Price display ($7.99 or $9.99 per priceVariant)
    - Streak stats display
    - "Streaks are per macOS user account" copy
    - Privacy policy link
    - **Owner: SwiftUI Frontend Agent**
    - _Requirements: 5.2, 6.5, 11.4, 15.2, 17.1, 18.3, 19.1, 21.2, 37.2, 38.3, 38.4, 42.2, 42.3, 43.1_

  - [x] 10.6 Implement ShareCardView
    - Create `View/ShareCardView.swift`
    - Offscreen render via `ImageRenderer` at native scale
    - Include: cup count, streakDays, personalRecord, `caffeinebar.app` watermark
    - Write PNG to `NSPasteboard.general`
    - Hidden behind Pro gate for Free users
    - **Owner: SwiftUI Frontend Agent**
    - _Requirements: 7.1, 7.2, 7.3, 7.4_

  - [x] 10.7 Implement privacy policy in-app view
    - In-app privacy policy view accessible from SettingsView
    - State: no telemetry, all data local, only network call is license check
    - Host same text at stable URL on caffeinebar.app
    - **Owner: SwiftUI Frontend Agent**
    - _Requirements: 43.1, 43.2, 43.3_

  - [x] 10.8 Write property tests for licensing
    - **Property 16: Tier gating never deletes data**
    - **Property 19: License key exclusion from UserDefaults**
    - **Property 20: Signature verification correctness**
    - **Property 21: Offline cache validity**
    - **Property 22: Price variant display consistency**
    - **Validates: Requirements 23.2, 34, 40, 41, 42**
    - **Owner: QA & Accessibility Agent**

  - [x] 10.9 Write unit tests for license signature verification
    - Valid key signed with correct private key → resolves tier
    - Malformed payload → rejected
    - Wrong private key → rejected
    - Offline cache > 30 days → expired
    - **Owner: QA & Accessibility Agent**
    - _Requirements: 56.1, 56.2, 56.3, 56.4_

- [x] 11. Phase 6 Checkpoint
  - Ensure all tests pass, ask the user if questions arise.

- [x] 12. Phase 7 — Accessibility, Build & QA (Day 7)

  - [x] 12.1 Implement Dynamic Type support
    - Hero count with `.dynamicTypeSize(...accessibility3)`
    - At `.accessibility1+`: re-flow horizontal rows to vertical stacks
    - Fixed 260pt width, height grows
    - Use `@Environment(\.dynamicTypeSize)` with conditional layout
    - **Owner: SwiftUI Frontend Agent**
    - _Requirements: 24.1, 24.2, 24.3_

  - [x] 12.2 Implement Reduce Motion compliance
    - Check `@Environment(\.accessibilityReduceMotion)`
    - Cup 4 shake → bold-stroke fade-in
    - Cup 5+ pulse → static 5% red material overlay
    - Count odometer → cross-fade transition
    - **Owner: SwiftUI Frontend Agent**
    - _Requirements: 25.1, 25.2, 25.3_

  - [x] 12.3 Implement color independence and Increased Contrast
    - Icon shape is primary signal (Outline→Filled→Steam→Lightning→Exclamation→Skull)
    - When `@Environment(\.colorSchemeContrast) == .increased`: 1pt solid border on status chips
    - Body text ≥ 4.5:1 contrast on `.ultraThinMaterial` in Light and Dark
    - **Owner: SwiftUI Frontend Agent**
    - _Requirements: 26.5, 27.1, 27.2_

  - [x] 12.4 Implement Full Keyboard Access
    - ⌘+1 or Space → log cup
    - ⌘+Z → undo
    - Esc → dismiss popover
    - Native macOS focus rings via `@FocusState`
    - Tab order: +1 Coffee → Undo → history items → Settings gear
    - **Owner: SwiftUI Frontend Agent**
    - _Requirements: 28.1, 28.2, 28.3, 28.4, 28.5_

  - [x] 12.5 Implement VoiceOver semantic groups and labels
    - Group hero-count, log-history, settings with `.accessibilityElement(children: .contain)`
    - MenuBarIcon `accessibilityLabel`: "CaffeineBar. {N} cups logged. {state}."
    - HalfLifeClock label: "Caffeine clears your system at {time}"
    - History list landmark: "Today's Log History"
    - Each timestamp: "Cup {N} at {time}"
    - **Owner: SwiftUI Frontend Agent**
    - _Requirements: 29.1, 29.2, 29.3, 29.4_

  - [x] 12.6 Declare accessibility nutrition labels
    - Distribution metadata: VoiceOver, Full Keyboard Access, Increase Contrast, Reduce Motion, Dynamic Type
    - Ensure behavioral requirements behind each label are satisfied
    - **Owner: SwiftUI Frontend Agent**
    - _Requirements: 30.1, 30.2_

  - [x] 12.7 Write popover-vs-menu HIG justification document
    - Document justification for using `MenuBarExtraStyle.window` (popover) instead of standard menu
    - Cite HalfLifeClock, WeeklyGraphView, sound pack selector, license-key entry as complexity drivers
    - Include in notarization submission package
    - **Owner: QA & Accessibility Agent**
    - _Requirements: 31.1_

  - [x] 12.8 Create GitHub Actions CI workflow
    - `.github/workflows/release.yml`
    - Trigger on tag push matching `v*`
    - Build with `xcodebuild`
    - Code-sign with Hardened Runtime
    - Submit to Apple Notarization service via `xcrun notarytool`
    - Fail run on non-success status
    - Staple notarization ticket
    - Upload `.dmg` artifact
    - **Owner: Build & Release Agent**
    - _Requirements: 51.1, 51.2_

  - [x] 12.9 Integrate Sparkle for in-app updates
    - Link Sparkle as Swift Package dependency
    - Set `SUFeedURL` to `https://caffeinebar.app/appcast.xml`
    - Update checks on launch + every 24 hours
    - Prompt user for install with release notes
    - **Owner: Build & Release Agent**
    - _Requirements: 50.1, 50.2_

  - [x] 12.10 Notarization rehearsal on clean VM
    - Execute on clean macOS VM with no developer certificates
    - ≥3 days before launch
    - Verify `.dmg` opens without Gatekeeper warnings
    - Any entitlement change after rehearsal voids it
    - **Owner: Build & Release Agent**
    - _Requirements: 52.1, 52.2_

  - [x] 12.11 Write SoundEngine soak test (1000+ logs, Instruments Leaks)
    - Simulate 1000+ sequential `logCup()` calls with sound playback
    - Run under Instruments Leaks template
    - Pass: zero `AVAudioPlayer` instances retained beyond playback cycle
    - Fail: any leaked player instance
    - **Owner: QA & Accessibility Agent**
    - _Requirements: 57.1, 57.2_

  - [x] 12.12 Write unit tests for Office Mode and Meeting Mode
    - Test volume clamping at 50% system volume
    - Test haptic routing when haptic-only selected
    - Test Meeting Mode suppression
    - **Owner: QA & Accessibility Agent**
    - _Requirements: 16, 17_

- [x] 13. Final Checkpoint — All tests pass, accessibility audit complete
  - Ensure all unit tests and property tests pass
  - Ensure Accessibility Inspector audit covers all 6 escalation states × Light/Dark/Increased Contrast
  - Ensure WCAG AA contrast verified for all text-on-surface pairings
  - Ensure manual call-mute verification (FaceTime + Zoom + Google Meet)
  - Ensure `xcrun notarytool submit ... --wait` returns `Accepted`
  - Ask the user if questions arise.
  - _Requirements: 58, 59, 60_

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation after each phase
- Property tests validate universal correctness properties from the design document
- Unit tests validate specific examples and edge cases
- Owning agents are assigned per the AGENTS.md topology
- The implementation language is Swift/SwiftUI throughout (macOS 13+)
- Sound copyright provenance (Req 53) is an operational task retained off-repo by the Launch Operator
- Manual QA gates (Reqs 58, 59, 60) are release blockers executed by the QA & Accessibility Agent

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1.1", "1.2"] },
    { "id": 1, "tasks": ["1.3", "1.4"] },
    { "id": 2, "tasks": ["1.5", "3.1"] },
    { "id": 3, "tasks": ["3.2", "3.3", "3.4"] },
    { "id": 4, "tasks": ["3.5", "4.1", "4.2", "4.3"] },
    { "id": 5, "tasks": ["4.4", "4.5", "4.6", "4.7", "4.8"] },
    { "id": 6, "tasks": ["6.1", "6.2", "6.3", "6.4", "6.5"] },
    { "id": 7, "tasks": ["6.6", "6.7", "6.8"] },
    { "id": 8, "tasks": ["8.1", "8.2", "8.3", "8.4"] },
    { "id": 9, "tasks": ["8.5", "8.6", "8.7", "8.8"] },
    { "id": 10, "tasks": ["10.1", "10.2"] },
    { "id": 11, "tasks": ["10.3", "10.4", "10.5", "10.6", "10.7"] },
    { "id": 12, "tasks": ["10.8", "10.9"] },
    { "id": 13, "tasks": ["12.1", "12.2", "12.3", "12.4", "12.5", "12.6"] },
    { "id": 14, "tasks": ["12.7", "12.8", "12.9"] },
    { "id": 15, "tasks": ["12.10", "12.11", "12.12"] }
  ]
}
```
