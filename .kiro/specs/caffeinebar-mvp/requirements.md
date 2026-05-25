# Requirements Document

## Introduction

CaffeineBar is a native macOS menu bar utility that lets a user log each coffee with one click, displays a live cup count as the menu bar icon throughout the day, and plays escalating sound effects as intake climbs from a soft chime at Cup 1 to a full ambulance siren at Cup 5+. The product follows a deliberate "Path B" positioning: funny enough to be viral, useful enough to be sticky. It is neither a pure comedy app nor a clinical wellness tracker. The escalation is the joke, and pairing the joke with genuinely useful utility (a caffeine half-life clock, a cut-off-time reminder, a weekly intake graph) is what turns a viral spike into a long tail of daily use.

This spec — **caffeinebar-mvp** — covers the **MVP product build only**: the 7-day shippable, notarized, direct-download `.dmg` that ships the menu bar app with full Free and Pro tiers, the four bundled sound packs, the call-aware audio engine, the accessibility surface required to pass an Accessibility Inspector audit, and the Polar.sh licensing flow. It is the first of three companion specs.

Out of scope for this spec (covered by companion specs):

- Marketing, launch-week scheduling, creator seeding, ambulance reel production, Product Hunt assets, paid-ad strategy, post-launch growth analytics → **caffeinebar-launch**
- iCloud sync across Macs, Apple Health write integration, Apple Shortcuts integration, annual Wrapped card, custom sound import, Mac App Store distribution → **caffeinebar-ultra**

Every requirement below is the work that must be complete to ship a notarized `.dmg` that an end user can download from caffeinebar.app, install, log a coffee with, hear an ambulance at Cup 5, share a streak card from, and pay $9.99 to unlock Pro features inside.

## Glossary

- **CaffeineBar**: The complete macOS menu bar application being specified. Used as the system noun when a requirement applies to the app as a whole.
- **MenuBarIcon**: The 16×16pt template image rendered into the macOS system menu bar. The icon's shape and tint represent the current Escalation State.
- **Popover**: The 260pt-wide SwiftUI surface that opens when the user clicks the MenuBarIcon. Renders the hero count, +1 Coffee button, Undo affordance, today's timestamps, and the settings gear.
- **MenuBarExtra**: The native SwiftUI API (introduced in macOS 13 Ventura) that registers an app as a menu bar extra and hosts the Popover.
- **CupStore**: The single observable state container that holds today's cup count, today's timestamps, streak data, and user preferences. Persisted to UserDefaults.
- **SoundEngine**: The component that wraps AVAudioPlayer to load sound assets lazily and play the escalation sound mapped to the current Cup count.
- **CallDetector**: The component that decides whether an active audio call is in progress by combining bundle-ID detection (Zoom, FaceTime) with a CoreAudio active-input-stream heuristic.
- **LicenseManager**: The component that validates a Polar.sh-issued license payload, stores the key in the macOS Keychain, and gates Pro features.
- **ShareCard**: The offscreen-rendered PNG image of the user's streak summary, copied to NSPasteboard.general.
- **WeeklyGraphView**: The Swift Charts 7-day bar chart shown inside the Popover for Pro users.
- **HalfLifeClock**: The live clearance countdown shown in the Popover for Pro users, calculated from the most recent log timestamp and the user's Metabolic Profile.
- **SettingsView**: The native macOS form that hosts reset hour, bedtime, mute, Office Mode, sound pack selector, license entry, and metabolism-profile controls.
- **Cup count**: The integer number of coffees the user has logged on the current day, where "current day" is defined by the user's configured reset hour.
- **Escalation State**: One of six visual states (Cup 0 / 1 / 2 / 3 / 4 / 5+) determined by the current Cup count. Each state has a distinct icon shape and a distinct tint.
- **Metabolic Profile**: A user-selected enum (Fast / Normal / Slow) that maps to a caffeine half-life of 5h / 5.5h / 6h respectively. Drives the HalfLifeClock and Cut-off Window calculations.
- **Cut-off Window**: The interval of time before the user's configured bedtime during which logging a new cup will result in caffeine remaining in the system at bedtime, computed from the Metabolic Profile.
- **Half-life clock**: See HalfLifeClock above.
- **Office Mode**: A SettingsView toggle that caps audio output at 50% of system volume or routes feedback to NSHapticFeedbackManager only, preserving icon escalation.
- **Meeting Mode**: A manual mute override that the user can toggle from the right-click context menu on the MenuBarIcon. Independent of CallDetector.
- **Pro tier**: The $9.99 one-time purchase tier that unlocks Cup 4+ sounds, all four sound packs, the HalfLifeClock, the cut-off reminder, the WeeklyGraphView, and the ShareCard.
- **Ultra tier**: The $14.99 one-time purchase tier that acts as a price anchor at MVP. Its post-MVP feature set (iCloud sync, Apple Health write, Apple Shortcuts, Wrapped, custom sound import) is out of scope for this spec.
- **Polar.sh**: The third-party indie payment processor used to sell the app. Issues a cryptographically signed license payload via webhook on purchase.
- **Notarization**: Apple's automated malware scan and signing service for software distributed outside the Mac App Store. Required for Gatekeeper to allow the `.dmg` to launch without warnings on end-user Macs.
- **Hardened Runtime**: The macOS code-signing option that opts the binary into a stricter set of runtime protections required for Notarization.
- **EARS**: Easy Approach to Requirements Syntax. The acceptance criteria pattern set used in this document (Ubiquitous, Event-driven, State-driven, Unwanted-event, Optional-feature, and Complex).
- **DataVersion**: An integer field stored in UserDefaults under `caffeinebar.dataVersion`, currently `1`, used to drive future on-disk schema migrations without blocking the UI.
- **CIPipeline**: The GitHub Actions workflow that builds, signs, and submits the binary to the Apple Notarization service on every git tag push.

---

## Requirements

## Section A — Core Product / Functional

### Requirement 1: Menu bar icon escalation states

**User Story:** As a daily macOS user, I want the menu bar icon to visually represent my current cup count at a glance, so that I always know where I stand on caffeine without opening the popover.

#### Acceptance Criteria

1. THE CaffeineBar SHALL render the MenuBarIcon at 16×16pt using SF Symbols and template images.
2. WHEN the Cup count is 0, THE MenuBarIcon SHALL display an outline coffee cup glyph in the macOS system gray template tint.
3. WHEN the Cup count is 1, THE MenuBarIcon SHALL display a filled coffee cup glyph.
4. WHEN the Cup count is 2, THE MenuBarIcon SHALL display a filled coffee cup with one steam line glyph.
5. WHEN the Cup count is 3, THE MenuBarIcon SHALL display a filled coffee cup with a lightning bolt glyph.
6. WHEN the Cup count is 4, THE MenuBarIcon SHALL display a filled coffee cup with an exclamation mark glyph and apply the `status.warning` Asset Catalog tint.
7. WHEN the Cup count is 5 or greater, THE MenuBarIcon SHALL display a skull-and-crossbones glyph and apply the `status.danger` Asset Catalog tint.
8. THE MenuBarIcon SHALL render correctly in light menu bar mode, dark menu bar mode, and translucent-wallpaper menu bar mode using template image rendering.

### Requirement 2: Popover UI structure

**User Story:** As a user clicking the menu bar icon, I want a fast, native-feeling popover that shows my count and lets me log immediately, so that interacting with CaffeineBar feels indistinguishable from a built-in macOS Control Center module.

#### Acceptance Criteria

1. WHEN the user clicks the MenuBarIcon, THE CaffeineBar SHALL open the Popover at a fixed width of 260pt using the native macOS spring open animation provided by MenuBarExtra.
2. THE Popover SHALL render its background using SwiftUI `.ultraThinMaterial`.
3. THE Popover SHALL display the hero Cup count using `.system(size: 44, weight: .heavy, design: .rounded)`.
4. THE Popover SHALL display a `.borderedProminent` "+1 Coffee" button with `.controlSize(.large)`.
5. THE Popover SHALL display today's log timestamps in `.system(.caption, design: .monospaced)`.
6. THE Popover SHALL display a settings gear control in its bottom-right corner that opens the SettingsView.

### Requirement 3: One-click logging

**User Story:** As a user grabbing my third coffee of the morning, I want logging to take exactly one click with no confirmation dialog, so that the act of logging is faster than the act of taking a sip.

#### Acceptance Criteria

1. WHEN the user clicks the "+1 Coffee" button in the Popover, THE CupStore SHALL increment the Cup count by 1 and append the current timestamp to today's timestamps.
2. WHEN the Cup count changes, THE MenuBarIcon SHALL update to reflect the new Escalation State within 100ms of the click.
3. WHEN a log action completes, THE Popover SHALL dismiss automatically.
4. WHERE the user has enabled the "keep popover open after log" preference in SettingsView, THE Popover SHALL remain open after a log action.
5. THE CaffeineBar SHALL NOT present any confirmation dialog, modal sheet, or interstitial during the log action.

### Requirement 4: Undo last log

**User Story:** As a user who clicked "+1 Coffee" by accident, I want a one-click undo with a keyboard shortcut, so that miscounts never become permanent.

#### Acceptance Criteria

1. WHILE the Cup count is greater than 0, THE Popover SHALL display a visible "Undo last coffee" affordance.
2. WHILE the Cup count is 0, THE Popover SHALL hide the Undo affordance.
3. WHEN the user activates the Undo affordance, THE CupStore SHALL decrement the Cup count by 1 and remove the most recent timestamp from today's timestamps.
4. WHEN the Popover has keyboard focus and the user presses ⌘+Z, THE CaffeineBar SHALL perform the same Undo action as activating the Undo affordance.
5. THE CupStore SHALL bound the Undo history depth to a maximum of 50 entries to prevent unbounded memory growth from repeated logging.

### Requirement 5: Daily reset

**User Story:** As a user crossing midnight or a daylight-saving boundary, I want the Cup count to reset reliably and exactly once per logical day, so that my history and streak are never corrupted by timezone math.

#### Acceptance Criteria

1. THE CupStore SHALL compute the start of the current day using `Calendar.current.startOfDay(for:)` shifted by the user-configured reset hour.
2. THE CupStore SHALL default the reset hour to 0 (local midnight) and SHALL allow the user to configure it from 0 through 23 in SettingsView.
3. WHEN the wall clock crosses the configured reset hour, THE CupStore SHALL reset the Cup count to 0 and SHALL persist the prior day's count in history.
4. IF a daylight saving time transition occurs between two reset evaluations, THEN THE CupStore SHALL fire the daily reset exactly once and SHALL NOT skip or duplicate a reset.
5. WHEN the daily reset fires AND the Cup count was greater than 0 immediately before the reset, THE SoundEngine SHALL play the "good night" chime asset.

### Requirement 6: Streak tracking

**User Story:** As a returning user, I want my logging streak and personal record persisted locally, so that the app rewards continued use without me having to log into anything.

#### Acceptance Criteria

1. THE CupStore SHALL persist `streakDays` (current consecutive days with at least one log), `personalRecord` (highest single-day Cup count ever observed), and `totalDaysLogged` (cumulative count of days with at least one log).
2. WHEN the daily reset fires AND the prior day's Cup count was greater than 0, THE CupStore SHALL increment `streakDays` and `totalDaysLogged` by 1.
3. WHEN the daily reset fires AND the prior day's Cup count was 0, THE CupStore SHALL reset `streakDays` to 0.
4. WHEN a log action results in a Cup count greater than the current `personalRecord`, THE CupStore SHALL update `personalRecord` to the new Cup count.
5. THE SettingsView SHALL surface `streakDays`, `personalRecord`, and `totalDaysLogged`, and THE Popover SHALL NOT display these values.

### Requirement 7: Shareable streak card

**User Story:** As a user who loves my streak, I want a one-click way to copy a high-DPI image of my stats to the clipboard, so that I can paste it directly into X, Slack, or iMessage.

#### Acceptance Criteria

1. WHEN the user activates the "Share streak card" control, THE ShareCardView SHALL render itself offscreen via `ImageRenderer` at the screen's native scale to produce a high-DPI PNG.
2. THE ShareCardView SHALL include the current Cup count, current `streakDays`, current `personalRecord`, and a `caffeinebar.app` watermark on the rendered image.
3. WHEN the rendered PNG is produced, THE CaffeineBar SHALL write the image to `NSPasteboard.general`.
4. WHERE the LicenseManager reports a Free tier, THE ShareCardView control SHALL be hidden in the Popover and surfaced only behind the Pro upsell.

### Requirement 8: Empty state copy

**User Story:** As a first-time user opening the popover before logging any coffee, I want a friendly, on-brand empty state, so that the app's personality lands before the count does.

#### Acceptance Criteria

1. WHILE the Cup count is 0, THE Popover SHALL display a low-opacity SF Symbol `cup.and.saucer.fill` and the copy "Engine cold. Log your first cup."
2. WHILE the Cup count is greater than 0, THE Popover SHALL hide the empty-state visual.

---

## Section B — Escalation Sound System

### Requirement 9: Bundled sound assets

**User Story:** As a user with no internet on a flight, I want every escalation sound to play offline, so that the comedy works wherever my Mac goes.

#### Acceptance Criteria

1. THE CaffeineBar SHALL bundle all sound assets as `.m4a` files inside the application bundle.
2. THE total size of all bundled sound assets SHALL be less than or equal to 2 megabytes.
3. THE SoundEngine SHALL load each sound asset lazily on first play via AVAudioPlayer and SHALL NOT preload sound assets at app launch.

### Requirement 10: Cup-to-sound mapping

**User Story:** As a user, I want each cup to trigger an audibly escalating sound, so that the comedy curve from "nice start" to "active emergency" is felt on every log.

#### Acceptance Criteria

1. WHEN a log action results in a Cup count of 1, THE SoundEngine SHALL play the "soft chime" asset.
2. WHEN a log action results in a Cup count of 2, THE SoundEngine SHALL play the "approving ding" asset.
3. WHEN a log action results in a Cup count of 3, THE SoundEngine SHALL play the "hmm voice" asset.
4. WHEN a log action results in a Cup count of 4 AND the LicenseManager reports a Pro or Ultra tier, THE SoundEngine SHALL play the "stethoscope concern" asset.
5. WHEN a log action results in a Cup count of 5 AND the LicenseManager reports a Pro or Ultra tier, THE SoundEngine SHALL play the "ambulance siren" asset.
6. WHEN a log action results in a Cup count of 6 or greater AND the LicenseManager reports a Pro or Ultra tier, THE SoundEngine SHALL select the next asset from the rotating chaos pool (siren, airhorn, dial-up modem, Wilhelm scream).

### Requirement 11: Volume and mute behavior

**User Story:** As a user in a quiet office, I want a single toggle that silences sound without disabling the visual escalation, so that I can still see my count while everyone else can't hear it.

#### Acceptance Criteria

1. THE SoundEngine SHALL play all assets at the user's current macOS system output volume by default.
2. WHILE `isMuted` is true in the CupStore, THE SoundEngine SHALL NOT play any sound asset on log.
3. WHILE `isMuted` is true in the CupStore, THE MenuBarIcon SHALL continue to update through the full set of Escalation States.
4. THE SettingsView SHALL provide a toggle that sets `isMuted` to true or false.

### Requirement 12: AVAudioPlayer memory safety

**User Story:** As a user who logs hundreds of cups over months of use, I want the audio engine to stay leak-free, so that the app never balloons in memory or starts to misfire after a long session.

#### Acceptance Criteria

1. THE SoundEngine SHALL maintain at most one active AVAudioPlayer instance at a time.
2. WHEN a new sound is requested AND a prior AVAudioPlayer instance exists, THE SoundEngine SHALL invoke `stop()` on the prior instance and SHALL set the prior reference to nil before allocating the new instance.
3. THE SoundEngine SHALL use `[weak self]` in every AVAudioPlayer completion-handler closure to prevent retain cycles.

### Requirement 13: Sound asset failure handling

**User Story:** As a user with a corrupted sound file or a missing asset, I want the app to keep working visually and never crash, so that a broken `.m4a` is invisible to my workflow.

#### Acceptance Criteria

1. IF the SoundEngine fails to load a sound asset, THEN THE SoundEngine SHALL log the error to the system console and SHALL NOT raise a user-visible error.
2. IF the SoundEngine fails to play a sound asset, THEN THE CupStore SHALL still increment the Cup count and THE MenuBarIcon SHALL still update to the new Escalation State.

---

## Section C — Active Call Detection and Office Mode

### Requirement 14: Active-call auto-mute detection

**User Story:** As a user on a Zoom call who just hit cup 5, I do not want CaffeineBar to broadcast an ambulance siren to my client, so that the most likely 1-star review trigger never happens.

#### Acceptance Criteria

1. THE CallDetector SHALL inspect `NSWorkspace.shared.runningApplications` and SHALL flag a call as active when the bundle identifier `us.zoom.xos` or `com.apple.FaceTime` is among the running applications and is frontmost or recently active.
2. THE CallDetector SHALL query CoreAudio for active default-input-device streams and SHALL flag a call as active when an input stream is currently capturing audio, even if no native call app bundle is detected.
3. WHILE the CallDetector reports an active call, THE SoundEngine SHALL suppress audio playback while continuing to update the MenuBarIcon Escalation State.

### Requirement 15: Auto-mute defaults to ON

**User Story:** As a new user installing CaffeineBar without reading the settings, I want call auto-mute to be on by default, so that the safe behavior is the default behavior.

#### Acceptance Criteria

1. WHEN the CaffeineBar is launched for the first time on a given macOS user account, THE CupStore SHALL initialize `autoMuteOnCalls` to true.
2. THE SettingsView SHALL provide a toggle that allows the user to set `autoMuteOnCalls` to false.

### Requirement 16: Manual Meeting Mode override

**User Story:** As a user about to walk into a recorded podcast, I want a one-action manual mute that does not depend on call detection, so that I can guarantee silence even when CallDetector is wrong.

#### Acceptance Criteria

1. WHEN the user right-clicks the MenuBarIcon, THE CaffeineBar SHALL display a context menu containing a "Meeting Mode" toggle.
2. WHEN the user activates the "Meeting Mode" toggle, THE SoundEngine SHALL suppress audio playback for all log actions until "Meeting Mode" is toggled off.
3. WHILE Meeting Mode is active, THE MenuBarIcon SHALL display a visual indicator (a small dot badge) so that the user can verify the mute is in effect.

### Requirement 17: Office Mode

**User Story:** As a user in a shared open-plan office, I want a quieter alternative to full mute that still gives me audible-or-haptic feedback, so that I keep the comedy at half volume instead of losing it entirely.

#### Acceptance Criteria

1. THE SettingsView SHALL provide a toggle that sets `officeMode` to true or false.
2. WHILE `officeMode` is true AND the haptic-only sub-option is not selected, THE SoundEngine SHALL clamp playback gain such that the effective output volume does not exceed 50% of the macOS system output volume.
3. WHILE `officeMode` is true AND the haptic-only sub-option is selected, THE SoundEngine SHALL invoke `NSHapticFeedbackManager` instead of playing audio assets on log actions.

---

## Section D — Pro Tier Features (in-MVP, gated by license)

### Requirement 18: Caffeine half-life clock

**User Story:** As a Pro user planning my afternoon, I want a live countdown of when my caffeine will clear, so that I can decide whether one more cup is going to wreck my sleep.

#### Acceptance Criteria

1. WHILE the LicenseManager reports a Pro or Ultra tier AND the Cup count is greater than 0, THE Popover SHALL display the HalfLifeClock with the projected wall-clock time at which 100% of the most recent dose will have cleared the user's system.
2. THE HalfLifeClock SHALL compute clearance time using a half-life of 5 hours WHERE Metabolic Profile is Fast, 5.5 hours WHERE Metabolic Profile is Normal, and 6 hours WHERE Metabolic Profile is Slow.
3. THE SettingsView SHALL allow the user to select the Metabolic Profile from the labeled options "Fast metabolizer", "Normal metabolizer", and "Slow metabolizer", and SHALL NOT expose raw hour values to the user.
4. THE HalfLifeClock SHALL display its result as a wall-clock time string (e.g. "Caffeine clears your system at 9:47 PM") and SHALL NOT display raw hours remaining.

### Requirement 19: Cut-off time reminder

**User Story:** As a Pro user with a target bedtime, I want CaffeineBar to warn me as I approach the cut-off and to call out late logs with a deadpan one-liner, so that the joke and the utility land at the same moment.

#### Acceptance Criteria

1. THE SettingsView SHALL allow the user to configure a target bedtime as a time-of-day value.
2. WHILE the current wall-clock time is within the Cut-off Window AND the LicenseManager reports a Pro or Ultra tier, THE MenuBarIcon SHALL apply the `status.warning` amber tint regardless of Cup count.
3. WHEN a log action occurs AND the resulting clearance time computed by the HalfLifeClock is later than the configured bedtime AND the LicenseManager reports a Pro or Ultra tier, THE CaffeineBar SHALL post a native macOS user notification with the body copy "That's your problem tonight."

### Requirement 20: Weekly caffeine graph

**User Story:** As a Pro user trying to spot patterns in my week, I want a small native bar chart of the last 7 days inside the popover, so that I can see my cycle without leaving the menu bar surface.

#### Acceptance Criteria

1. WHILE the LicenseManager reports a Pro or Ultra tier, THE Popover SHALL render the WeeklyGraphView using native Swift Charts as a 7-day bar chart of daily Cup counts ending on the current logical day.
2. WHEN the user hovers over a bar in the WeeklyGraphView, THE WeeklyGraphView SHALL display a native macOS tooltip containing the date and the exact Cup count for that day.
3. WHERE the daily Cup count for any day in the 7-day window exceeded the cut-off threshold for that day, THE WeeklyGraphView SHALL render that bar in the `status.warning` Asset Catalog color.

### Requirement 21: Bundled sound packs

**User Story:** As a Pro user who has heard the default sounds for two weeks, I want to switch the entire escalation set to a different themed pack, so that the joke refreshes itself without me waiting for a content drop.

#### Acceptance Criteria

1. THE CaffeineBar SHALL bundle four sound packs in the application bundle: "Your Mom", "Gordon Ramsay", "NASA Mission Control", and "The Accountant".
2. WHILE the LicenseManager reports a Pro or Ultra tier, THE SettingsView SHALL allow the user to set `selectedSoundPack` to any of the four bundled packs.
3. WHEN `selectedSoundPack` changes, THE SoundEngine SHALL use the assets from the newly selected pack for all subsequent log actions.

### Requirement 22: Free tier upsell at Cup 4

**User Story:** As a Free user who just logged my fourth coffee, I want a single teaser notification that hints at what Pro unlocks, so that the upsell rides the comedy beat instead of breaking it.

#### Acceptance Criteria

1. WHEN a log action results in a Cup count of 4 AND the LicenseManager reports the Free tier, THE CaffeineBar SHALL post a native macOS user notification with the body copy "Cup 4. Something is about to happen. Unlock CaffeineBar Pro to find out."
2. THE CaffeineBar SHALL post the upsell notification at most once per logical day.

### Requirement 23: Free tier Pro-feature degradation

**User Story:** As a Free user, I want to see the Pro features blurred behind an unlock prompt instead of hidden, so that I understand what I am buying — and I want to be sure my own logged data is never deleted by the gate.

#### Acceptance Criteria

1. WHILE the LicenseManager reports the Free tier, THE Popover SHALL render the HalfLifeClock and the WeeklyGraphView with a `.overlay(.ultraThinMaterial)` blur and an "Unlock Pro" call-to-action button.
2. THE CaffeineBar SHALL NOT delete, hide, or otherwise restrict access to any Cup count, timestamp, streak value, or historical day record based on license tier.
3. WHEN the LicenseManager transitions from Free to Pro or Ultra, THE Popover SHALL remove the blur overlay and reveal the previously gated views without requiring an app restart.

---

## Section E — Accessibility and HIG (Ship-Blockers)

### Requirement 24: Dynamic Type support

**User Story:** As a user who runs my Mac at an enlarged text size, I want CaffeineBar's hero count and surrounding controls to scale with my system text size, so that I can read it the same way I read every other macOS app.

#### Acceptance Criteria

1. THE Popover SHALL declare its hero count text using `.system(size: 44, weight: .heavy)` with `.dynamicTypeSize(...DynamicTypeSize.accessibility3)`.
2. WHILE the active Dynamic Type size is `.accessibility1` or larger, THE Popover SHALL re-flow horizontal rows of controls into vertical stacks.
3. THE Popover SHALL maintain a fixed width of 260pt across all Dynamic Type sizes and SHALL allow its height to grow.

### Requirement 25: Reduce Motion compliance

**User Story:** As a user with motion sensitivity, I want shake and pulse animations disabled when I have Reduce Motion turned on, so that CaffeineBar respects my system-wide setting.

#### Acceptance Criteria

1. WHILE `@Environment(\.accessibilityReduceMotion)` is true, THE Popover SHALL replace the Cup 4 horizontal shake animation with a bold-stroke fade-in.
2. WHILE `@Environment(\.accessibilityReduceMotion)` is true, THE Popover SHALL replace the Cup 5+ pulse animation with a static red 5% material overlay.
3. WHILE `@Environment(\.accessibilityReduceMotion)` is true, THE Popover SHALL replace the count odometer-roll animation with a cross-fade transition.

### Requirement 26: WCAG AA contrast

**User Story:** As a user reading CaffeineBar in bright sunlight or with low vision, I want every text-on-surface and icon-on-tint pairing to meet WCAG AA contrast, so that the app is legible without me squinting.

#### Acceptance Criteria

1. THE CaffeineBar SHALL define `status.empty`, `status.active`, `status.warning`, and `status.danger` as semantic Asset Catalog colors with explicit Light, Dark, and Increased Contrast variants.
2. THE CaffeineBar SHALL NOT contain any hardcoded hex color literal in Swift source code outside the Asset Catalog.
3. THE light-mode value of `status.warning` SHALL be `#D97706` and SHALL achieve a contrast ratio of at least 3:1 against a pure white background.
4. THE light-mode value of `status.danger` SHALL be `#D70015`.
5. THE body text color on the Popover surface SHALL achieve a contrast ratio of at least 4.5:1 against the resolved `.ultraThinMaterial` background in both Light and Dark modes.

### Requirement 27: Color independence

**User Story:** As a colorblind user, I want to identify each Escalation State by icon shape, so that I am never relying on tint to know my Cup count.

#### Acceptance Criteria

1. THE MenuBarIcon SHALL convey the current Escalation State primarily through icon shape (Outline → Filled → Steam → Lightning → Exclamation → Skull) and secondarily through tint.
2. WHILE `@Environment(\.colorSchemeContrast) == .increased`, THE Popover SHALL render a 1pt solid border around every status chip.

### Requirement 28: Full Keyboard Access

**User Story:** As a keyboard-first user, I want to log, undo, and dismiss without ever touching the trackpad, so that CaffeineBar fits into a keyboard-driven workflow.

#### Acceptance Criteria

1. WHEN the Popover has keyboard focus, THE CaffeineBar SHALL accept ⌘+1 or Spacebar as a binding for the "+1 Coffee" action.
2. WHEN the Popover has keyboard focus, THE CaffeineBar SHALL accept ⌘+Z as a binding for the Undo action.
3. WHEN the user presses Esc while the Popover is open, THE Popover SHALL dismiss.
4. THE Popover SHALL render native macOS focus rings on every interactive control via `FocusState`.
5. THE Popover SHALL define the keyboard tab order as: "+1 Coffee" → Undo → today's history items → Settings gear.

### Requirement 29: VoiceOver semantic structure and labels

**User Story:** As a VoiceOver user, I want CaffeineBar to read out my count, my history, and my half-life clock in plain language, so that I get the same information sighted users get.

#### Acceptance Criteria

1. THE Popover SHALL group its hero-count region, its log-history region, and its settings region using `.accessibilityElement(children: .contain)`.
2. WHEN the Cup count changes, THE MenuBarIcon SHALL update its `accessibilityLabel` to a count-specific string (e.g. "CaffeineBar. 4 cups logged. Warning: Approaching cut-off.").
3. WHILE the LicenseManager reports a Pro or Ultra tier AND the Cup count is greater than 0, THE HalfLifeClock SHALL expose an `accessibilityLabel` of the form "Caffeine clears your system at 9:47 PM".
4. THE today's-history list SHALL expose a landmark `accessibilityLabel` of "Today's Log History".

### Requirement 30: Accessibility nutrition labels declared

**User Story:** As a discerning Mac user reading the app's distribution page before downloading, I want to see which accessibility features the app supports, so that I can trust the app on day one.

#### Acceptance Criteria

1. THE CaffeineBar distribution metadata SHALL declare support for VoiceOver, Full Keyboard Access, Increase Contrast, Reduce Motion, and Dynamic Type.
2. THE CaffeineBar SHALL satisfy the behavioral requirements behind every declared accessibility nutrition label (Requirements 24, 25, 26, 27, 28, 29).

### Requirement 31: Popover-vs-menu HIG justification documented

**User Story:** As a notarization reviewer, I want a written justification for using a popover instead of a standard menu, so that the choice is not flagged as over-engineering.

#### Acceptance Criteria

1. THE Notarization submission package SHALL include a written justification for using a popover (`MenuBarExtraStyle.window`) instead of a standard system menu, citing the HalfLifeClock, the WeeklyGraphView, the sound pack selector, and the license-key entry as the complexity drivers.

---

## Section F — State and Persistence

### Requirement 32: UserDefaults schema and versioning

**User Story:** As an engineer extending the app post-MVP, I want every persisted key to share a stable namespace and to carry a version field from day one, so that future schema migrations are safe.

#### Acceptance Criteria

1. THE CupStore SHALL persist every key using the prefix `caffeinebar.` (e.g. `caffeinebar.todayCount`).
2. THE CupStore SHALL persist a `caffeinebar.dataVersion` field with the value `1` from the first build shipped.

### Requirement 33: Persisted fields complete

**User Story:** As a returning user across launches and reboots, I want every preference and every count to survive a relaunch, so that no state is ever silently lost.

#### Acceptance Criteria

1. THE CupStore SHALL persist all of the following fields in UserDefaults under the `caffeinebar.` namespace: `todayCount`, `todayTimestamps`, `lastResetDate`, `streakDays`, `personalRecord`, `totalDaysLogged`, `resetHour`, `bedtime`, `metabolismProfile`, `isMuted`, `officeMode`, `autoMuteOnCalls`, `installedSoundPacks`, and `selectedSoundPack`.

### Requirement 34: License key in Keychain only

**User Story:** As a paying user, I want my license key kept in the macOS Keychain, so that it is never sitting in plaintext inside a UserDefaults plist.

#### Acceptance Criteria

1. THE LicenseManager SHALL store the user's Polar.sh license key in the macOS Keychain using Keychain Services.
2. THE CaffeineBar SHALL NOT persist the license key in UserDefaults.
3. THE CaffeineBar SHALL NOT persist the license key in any plaintext file inside the application support directory.

### Requirement 35: Critical write protection

**User Story:** As a user who closes my MacBook lid the second after I log a cup, I want the write to complete before the OS suspends me, so that my count is never lost to a half-finished write.

#### Acceptance Criteria

1. WHEN the CupStore commits a change to UserDefaults, THE CupStore SHALL wrap the write inside `NSProcessInfo.shared.performActivity` with a `.userInitiated` activity option.

### Requirement 36: Migration path pre-architected

**User Story:** As an engineer in three months when streaks have grown large, I want a defined trigger for moving off UserDefaults onto SQLite or Core Data, so that I am not retrofitting a migration on a hot-day production crash.

#### Acceptance Criteria

1. WHILE the cumulative count of stored log entries is greater than 1000, THE CupStore SHALL schedule a background migration to a SQLite or Core Data backing store.
2. THE scheduled background migration SHALL NOT block any UI thread or any Popover render path.

### Requirement 37: Single-user-per-account limitation acknowledged

**User Story:** As a user sharing a Mac with my partner under separate macOS accounts, I want CaffeineBar to be honest that streaks are per account at MVP, so that I am not surprised when my data does not appear in their account.

#### Acceptance Criteria

1. THE CupStore SHALL store all data under the current macOS user account's UserDefaults and SHALL NOT share data across macOS user accounts on the same Mac.
2. THE SettingsView SHALL display the explanatory copy "Streaks are per macOS user account; iCloud sync coming in Ultra."

---

## Section G — Licensing and Monetization (in-MVP)

### Requirement 38: Polar.sh purchase flow

**User Story:** As a user clicking "Buy Pro" on the landing page, I want a Polar.sh checkout to issue me a license key that I can paste back into the app, so that purchase to unlock takes under two minutes.

#### Acceptance Criteria

1. THE CaffeineBar landing page on caffeinebar.app SHALL link to a Polar.sh checkout for the Pro tier at $9.99 and a checkout for the Ultra tier at $14.99.
2. WHEN a Polar.sh purchase completes, THE Polar.sh webhook SHALL generate a license key payload signed with the CaffeineBar private key.
3. WHEN the user pastes a license key into the SettingsView license-entry field, THE LicenseManager SHALL validate the signature and SHALL update the resolved license tier accordingly.
4. THE SettingsView SHALL display the published prices "$9.99 — Pro" and "$14.99 — Ultra" so that the Ultra tier is visible as a price anchor at MVP.

### Requirement 39: Keychain storage of license key

**User Story:** As a user upgrading my Mac, I want my license to follow my Keychain, so that I do not have to re-enter the key on a fresh install.

#### Acceptance Criteria

1. WHEN the LicenseManager successfully validates a license key, THE LicenseManager SHALL persist the key into the macOS Keychain using Keychain Services with an access control list scoped to CaffeineBar.

### Requirement 40: Client-side cryptographic signature verification

**User Story:** As an indie developer who does not want to run an auth server, I want license validation to be a pure client-side signature check, so that piracy resistance does not depend on uptime.

#### Acceptance Criteria

1. THE LicenseManager SHALL embed a hardcoded public key inside the application bundle.
2. WHEN the LicenseManager evaluates a license key, THE LicenseManager SHALL verify the signature on the license payload against the embedded public key.
3. IF signature verification fails, THEN THE LicenseManager SHALL reject the license key and SHALL keep the resolved tier at Free.

### Requirement 41: Offline validation cache with graceful degradation

**User Story:** As a paid user on a long flight, I want the app to keep working without an internet connection, and I want to know what happens if my license is later revoked.

#### Acceptance Criteria

1. THE LicenseManager SHALL maintain an offline validation cache that retains a positive validation result for up to 30 days from the last successful online re-check.
2. THE LicenseManager SHALL perform a background online re-check at most once per week.
3. IF the LicenseManager observes a revoked or expired license during an online re-check, THEN THE LicenseManager SHALL transition the resolved tier to Free.
4. WHEN the LicenseManager transitions a user from Pro or Ultra to Free, THE CaffeineBar SHALL NOT delete, lock, or hide any logged Cup count, timestamp, streak value, or history record.

### Requirement 42: A/B price test framework

**User Story:** As the launch decision-maker, I want a build flag that toggles the displayed checkout price between $7.99 and $9.99, so that I can pre-launch test conversion before committing to a price.

#### Acceptance Criteria

1. THE CaffeineBar SHALL expose a `priceVariant` build flag that selects between the values "7.99" and "9.99".
2. WHEN `priceVariant` is "7.99", THE SettingsView SHALL display "$7.99 — Pro" and the landing-page checkout link SHALL point at the $7.99 Polar.sh checkout.
3. WHEN `priceVariant` is "9.99", THE SettingsView SHALL display "$9.99 — Pro" and the landing-page checkout link SHALL point at the $9.99 Polar.sh checkout.
4. THE CaffeineBar SHALL persist a local conversion-event count for each `priceVariant` value to support a pre-launch decision.

### Requirement 43: Privacy policy declared

**User Story:** As a privacy-conscious user, I want a clear, in-app and on-website statement that the app collects no telemetry and only contacts the network for license checks, so that I can trust the binary I just downloaded.

#### Acceptance Criteria

1. THE SettingsView SHALL link to an in-app privacy policy view.
2. THE caffeinebar.app website SHALL host the same privacy policy text at a stable URL.
3. THE privacy policy SHALL state that CaffeineBar collects no telemetry, that all logged data is stored locally on the user's Mac, and that the only outbound network call made by the app is the license-validation check to Polar.sh.

---

## Section H — Build, Distribution, and Compliance

### Requirement 44: macOS 13 Ventura minimum deployment target

**User Story:** As an engineer scoping API usage, I want a single hard floor for OS support, so that MenuBarExtra and Swift Charts are guaranteed available.

#### Acceptance Criteria

1. THE CaffeineBar Xcode project SHALL declare `MACOSX_DEPLOYMENT_TARGET = 13.0`.

### Requirement 45: Native Swift and SwiftUI only

**User Story:** As a user opening the app, I want it to feel and behave like a native macOS utility, so that it never has the lag, font, or scroll feel of an Electron container.

#### Acceptance Criteria

1. THE CaffeineBar SHALL be implemented using Swift and SwiftUI only.
2. THE CaffeineBar SHALL NOT include Electron, any embedded WKWebView used for primary UI, or any third-party non-Apple UI framework.

### Requirement 46: LSUIElement true

**User Story:** As a menu-bar-only utility user, I want CaffeineBar to never appear in the Dock or in the Cmd-Tab switcher, so that it stays invisible until I want it.

#### Acceptance Criteria

1. THE CaffeineBar `Info.plist` SHALL declare `LSUIElement = true`.

### Requirement 47: Binary size constraint

**User Story:** As a user on a metered connection, I want the download to be small, so that the first install is fast and feels respectful of my disk.

#### Acceptance Criteria

1. THE shipped CaffeineBar application bundle SHALL have a total size of less than 5 megabytes.

### Requirement 48: Hardened runtime entitlements declared

**User Story:** As an engineer preparing for notarization, I want only the minimum set of entitlements declared, so that Apple's automated checks pass and the app's attack surface is small.

#### Acceptance Criteria

1. THE CaffeineBar build SHALL enable the Hardened Runtime.
2. THE CaffeineBar entitlements file SHALL declare `com.apple.security.network.client` to permit the license-validation network call.
3. THE CaffeineBar entitlements file SHALL declare the audio-playback entitlements required for AVAudioPlayer playback in a sandboxed or hardened context.

### Requirement 49: Notarized .dmg distribution

**User Story:** As a user downloading from caffeinebar.app, I want to double-click a notarized `.dmg` and have macOS Gatekeeper let it through without warnings, so that install friction is zero.

#### Acceptance Criteria

1. THE CaffeineBar SHALL ship as a notarized `.dmg` distributed via direct download from caffeinebar.app at MVP.
2. THE CaffeineBar SHALL NOT be submitted to the Mac App Store at MVP.

### Requirement 50: Sparkle in-app updates

**User Story:** As a user who installed CaffeineBar last month, I want the app to tell me when a new version is available and to install it for me, so that I do not have to revisit the website.

#### Acceptance Criteria

1. THE CaffeineBar SHALL integrate the Sparkle framework for in-app update checks.
2. WHEN Sparkle detects a newer published version, THE CaffeineBar SHALL prompt the user to install the update.

### Requirement 51: GitHub Actions CIPipeline

**User Story:** As an engineer cutting a release, I want a tag push to produce a signed and notarized binary without me touching a build machine, so that releases are reproducible.

#### Acceptance Criteria

1. WHEN a git tag matching the release-tag pattern is pushed to the CaffeineBar repository, THE CIPipeline SHALL build, code-sign, and submit the resulting binary to Apple's Notarization service.
2. THE CIPipeline SHALL fail the run IF code-signing or notarization submission returns a non-success status.

### Requirement 52: Pre-submit notarization test

**User Story:** As the launch owner three days from launch day, I want a notarization rehearsal on a clean Mac, so that day-of surprises do not block ship.

#### Acceptance Criteria

1. THE CaffeineBar release process SHALL execute a notarization submission against a clean macOS virtual machine that has no developer certificates installed at least 3 days before the public launch date.
2. IF the pre-submit notarization test fails, THEN THE release process SHALL block the public launch until the failure is resolved.

### Requirement 53: Sound copyright provenance retained

**User Story:** As the studio of record for the comedy voice talent, I want session recordings retained as proof of original IP, so that any future infringement claim has documentary evidence.

#### Acceptance Criteria

1. THE CaffeineBar project SHALL retain the original voice-talent session recordings used to produce the bundled sound assets in a versioned, off-repository archive.

---

## Section I — Quality, Testing, and Verification

### Requirement 54: Timezone and DST reset unit tests

**User Story:** As an engineer who has been burned by `Calendar` math before, I want explicit tests for timezone and DST transitions, so that the November and March boundaries do not break the daily reset.

#### Acceptance Criteria

1. THE CaffeineBarTests SHALL include unit tests that exercise the daily-reset logic across the November DST end transition and the March DST start transition.
2. THE CaffeineBarTests SHALL include unit tests that exercise the daily-reset logic in at least the time zones America/Los_Angeles, Asia/Kolkata, and Europe/London.
3. THE daily-reset unit tests SHALL assert that exactly one reset fires per logical day across each tested transition.

### Requirement 55: Caffeine half-life math unit tests

**User Story:** As an engineer who built the half-life clock, I want unit tests covering all metabolic profiles and edge inputs, so that the clock never lies to a Pro user.

#### Acceptance Criteria

1. THE CaffeineBarTests SHALL include unit tests for the HalfLifeClock under each Metabolic Profile (Fast, Normal, Slow).
2. THE CaffeineBarTests SHALL include a unit test that asserts the HalfLifeClock returns no clearance time WHEN the Cup count is 0.
3. THE CaffeineBarTests SHALL include a unit test that asserts the HalfLifeClock returns a clearance time on the next calendar day WHEN the most recent log occurred shortly before midnight.

### Requirement 56: License signature verification unit tests

**User Story:** As the security owner, I want unit tests that prove forged or expired keys cannot unlock Pro, so that the tier gate is provably correct.

#### Acceptance Criteria

1. THE CaffeineBarTests SHALL include a unit test that a license key signed with the correct private key validates and resolves to the encoded tier.
2. THE CaffeineBarTests SHALL include a unit test that a malformed license payload is rejected.
3. THE CaffeineBarTests SHALL include a unit test that a license key signed with an incorrect private key is rejected.
4. THE CaffeineBarTests SHALL include a unit test that an offline-cache entry older than 30 days is treated as expired.

### Requirement 57: Memory diagnostics under soak

**User Story:** As an engineer worried about AVAudioPlayer leaks, I want a soak test that proves memory stability under heavy logging, so that long sessions never balloon RAM.

#### Acceptance Criteria

1. THE CaffeineBar release process SHALL include a soak test that simulates at least 1000 sequential log actions while running under the Instruments Leaks tool.
2. THE soak test SHALL fail the release IF the Instruments Leaks tool reports any AVAudioPlayer instance retained beyond a single playback cycle.

### Requirement 58: Manual Accessibility Inspector audit

**User Story:** As the QA owner, I want a manual Accessibility Inspector pass on every Escalation State and every appearance mode, so that the accessibility nutrition labels we declared are honest.

#### Acceptance Criteria

1. THE CaffeineBar release process SHALL execute a manual Accessibility Inspector audit covering all six Escalation States in Light mode, Dark mode, and Increased Contrast mode.
2. THE Accessibility Inspector audit SHALL verify that every text-on-surface contrast pairing meets WCAG AA.
3. THE Accessibility Inspector audit SHALL verify that every interactive control in the Popover exposes a non-empty VoiceOver label.

### Requirement 59: Manual call-mute verification

**User Story:** As the QA owner, I want to confirm by hand that the auto-mute actually mutes during a real call, so that the most catastrophic failure mode (ambulance-during-Zoom) cannot ship.

#### Acceptance Criteria

1. THE CaffeineBar release process SHALL include a manual verification in which a FaceTime call, a Zoom call, and a Google Meet call in a browser are each started in turn and a Cup is logged during each.
2. THE manual call-mute verification SHALL confirm that the SoundEngine suppressed audio during each of the three call types.
3. THE manual call-mute verification SHALL confirm that the MenuBarIcon Escalation State updated correctly during each of the three call types.

### Requirement 60: Notarytool succeeds before final ship

**User Story:** As the release owner, I want `xcrun notarytool` to return success on the final `.dmg` before I publish the download link, so that no end user sees a Gatekeeper warning.

#### Acceptance Criteria

1. WHEN the CaffeineBar `.dmg` is uploaded for the public release, THE release process SHALL run `xcrun notarytool submit ... --wait` against the final `.dmg` and SHALL require a `status: Accepted` result before the download link on caffeinebar.app is published.

---

## Companion Specs

This requirements document covers the MVP product build only. The following companion specs cover work that is intentionally out of scope here and will be authored separately:

- **caffeinebar-launch** — Marketing strategy, pre-launch creator seeding (15 micro-creators), the ambulance reel as the core viral asset, Reels/X/Reddit/Product Hunt launch-week schedule, A/B price-test launch-day decision, Show HN follow-up, paid-ad timing rules, and post-launch growth analytics.
- **caffeinebar-ultra** — The post-MVP $14.99 Ultra tier feature set: iCloud sync of streak and history data across multiple Macs, Apple Health caffeine write integration, Apple Shortcuts integration for "Log coffee" voice commands, the December annual Wrapped card launch moment, custom sound import, and any Mac App Store distribution work that follows from those features.
