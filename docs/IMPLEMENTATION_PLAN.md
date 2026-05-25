# CaffeineBar: Final Implementation Plan
**Platform:** macOS 13+ (Ventura and above)  
**Framework:** SwiftUI (Native, no web views)  
**Target:** Menu-bar-only utility (`LSUIElement = true`)

---

## 1. Executive Summary & Design Philosophy
CaffeineBar is a "Path B" utility that balances viral comedy with genuine daily utility. The app tracks coffee logs via a menu bar extra and triggers increasingly unhinged audio effects as consumption rises (escalating from a gentle chime at Cup 1 to a full ambulance wail at Cup 5). 

We employ **"Intentional Minimalism"** paired with native macOS materials (`.ultraThinMaterial` and standard system corner radii/spacing) to ensure the app feels built-in, while maintaining an unhinged, escalating personality in its messaging and audio feedback.

---

## 2. macOS & Apple HIG Alignment Guidelines

### 2.1 Popover Windows vs. Standard Menus
* **Constraint:** Apple HIG recommends using standard system dropdown menus rather than custom popover windows unless the complexity of the interaction justifies it.
* **Justification:** CaffeineBar houses a weekly Swift Chart, a live caffeine half-life countdown, and log history in the popover. We will document these advanced interactive components in the notarization submission.
* **Fallback Strategy:** If flagged during App Store/notarization review, the app will fall back to a hybrid layout: standard menu for Free users, popover unlock for Pro users.

### 2.2 Visual and Color Accessibility
* **Color System:** Hardcoded hex codes are prohibited in code. All colors are mapped to semantic system colors (`Color.accentColor`, `Color.secondary`, `Color.primary`) or Asset Catalog tokens with custom Dark Mode and High Contrast overrides.
* **WCAG AA Contrast:** Light mode status colors are modified to ensure a contrast ratio of $\ge 4.5:1$ on light backgrounds (e.g., Amber status darkened from `#FF9500` to `#D97706`).
* **Color Independence:** Color is never the sole indicator of metabolic state. We use explicit iconography variations (Outline $\rightarrow$ Filled $\rightarrow$ Steam Lines $\rightarrow$ Lightning $\rightarrow$ Exclamation $\rightarrow$ Skull) to accompany color shifts.

### 2.3 Motion and Typography
* **Dynamic Type:** All UI text elements support Dynamic Type scaling. In accessibility font sizes, the hero count scales down gracefully and horizontal components wrap into vertical stacks to prevent clipping within the fixed `260px` popover width.
* **Reduce Motion Support:** All view animations check the `@Environment(\.accessibilityReduceMotion)` property. If enabled, animations such as the Cup 4 shake and the Cup 5+ pulse are disabled in favor of static state changes.

---

## 3. Architecture & File Structure

The project will be built as a native Xcode macOS project under the `/Users/bharath/Desktop/on-going-projects/caffeinebar` directory.

```
CaffeineBar/
├── CaffeineBarApp.swift       # App entry point, menu bar extra registration
├── Info.plist                 # Configures LSUIElement=true
├── Model/
│   └── CupStore.swift         # State store, UserDefaults persistence, reset logic
├── Engine/
│   ├── SoundEngine.swift      # AVAudioPlayer wrapper, memory safety, pro gating
│   ├── CallDetector.swift     # Zoom/FaceTime/Meet background activity detection
│   └── LicenseManager.swift   # Polar.sh license checks, Keychain storage
└── View/
    ├── MenuBarExtraView.swift # Primary popover UI container (260px wide)
    ├── WeeklyGraphView.swift  # Swift Charts 7-day visualization (Pro)
    ├── SettingsView.swift     # Reset hour, bedtime, license, sound pack settings
    └── ShareCardView.swift    # Clipboard share generator (ImageRenderer)
```

---

## 4. Component Technical Specifications

### 4.1 State & Persistence (`CupStore.swift`)
* **Storage:** Persisted in `UserDefaults` with key prefix `caffeinebar.`.
* **Fields:** `todayCount` (Int), `todayTimestamps` ([Date]), `streakDays` (Int), `personalRecord` (Int), `isMuted` (Bool), `resetHour` (Int), `bedtime` (Date), `metabolismProfile` (enum: fast/normal/slow), `licenseKey` (String).
* **Timezone Safety:** All daily resets are computed using `Calendar.current.startOfDay(for:)` relative to the current local timezone. Reset logic handles transition boundaries (Daylight Saving Time shifts) to avoid double resets or skipped days.
* **Write Protection:** Uses `NSProcessInfo.shared.performActivity` during critical disk writes to prevent OS suspension if the user closes their MacBook lid immediately after logging a cup.
* **Data Migration:** Features a `dataVersion` key (currently `1`). If log history grows larger than 1,000 entries, a background migration path to SQLite/Core Data is pre-architected.

### 4.2 Audio Engine & Call Detection (`SoundEngine.swift` & `CallDetector.swift`)
* **AVAudioPlayer Safety:** Prevents memory buildup by explicitly stopping, closing, and nil-ing out the current player instance before allocating a new sound. It uses `[weak self]` in completion handlers to eliminate retain cycles.
* **Pro Tier Gating:** Free users are restricted to standard chimes for cups 1-3. Cups 4+ (Ambulance/Chaos sound packs) require verification from the `LicenseManager`. If a free user hits cup 4, a teaser visual displays, inviting a Pro upgrade.
* **Office Mode & Volume Cap:** Settings toggle that caps alerts at 50% system volume or redirects alerts to macOS system haptic feedback (`NSHapticFeedbackManager`) instead of playing audio.
* **Call Mute Heuristic:** Monitors active native call processes (`us.zoom.xos`, `com.apple.FaceTime`) and checks if default CoreAudio input device streams are active (to catch web browser calls like Google Meet or Teams). When a call is active, audio is muted automatically. A manual "Meeting Mode" override is available in the right-click menu.

### 4.3 Interactive Views (`MenuBarExtraView.swift` & `WeeklyGraphView.swift`)
* **Vibrancy:** The popover uses SwiftUI's `.ultraThinMaterial` background to blend natively with the user's desktop wallpaper.
* **Interactive Controls:**
  * Prominent "+1 Coffee" button (`⌘+1` or Spacebar when popover is active).
  * "Undo last coffee" button (`⌘+Z`) that fades out when count reaches 0.
  * Settings Gear opening a sheet/popover containing standard macOS form controls.
* **Weekly Chart:** Uses native `Swift Charts` to plot a 7-day bar chart. Displays a custom tooltip on hover showing the date and cup count. Highlight-warns days that exceeded the user's bedtime cut-off threshold.
* **VoiceOver Landmarks:** Wrapped in semantic `AccessibilityGroup` elements with descriptive labels ("3 cups logged today", "Caffeine clears your system at 9:47 PM").

### 4.4 Licensing & Share System (`LicenseManager.swift` & `ShareCardView.swift`)
* **Keychain Storage:** License keys are stored securely using macOS Keychain services.
* **Offline Caching:** Licenses are cached locally for up to 30 days. Weekly online validation checks run in the background. If a validation check fails, the app degrades gracefully to the Free tier without deleting or blocking access to logged data.
* **Image Sharing:** `ShareCardView` renders offscreen using SwiftUI's `ImageRenderer` to generate a high-DPI PNG. This PNG contains the user's streak card and is copied directly to the NSPasteboard (`.general`).

---

## 5. Implementation Schedule (7 Days)

* **Day 1: Scaffold & Base System**
  - Initialize Xcode project, configure plist properties (`LSUIElement = true`).
  - Implement `CupStore` state model with `UserDefaults` persistence.
* **Day 2: Core Popover UI**
  - Implement popover structural layout, "+1 Coffee" action, and "Undo" mechanics.
  - Implement dynamic list of today's timestamps in monospaced SF Mono.
* **Day 3: State Escalation & Timezone Safety**
  - Code icon renderer (all 6 states) with template images to automatically scale light/dark modes.
  - Implement timezone-safe midnight reset logic and system sleep write locks.
* **Day 4: Audio Engine & Call Detection**
  - Implement `SoundEngine` with player recycling and weak retain checks.
  - Write call detector heuristics (bundle scanning + active mic stream checks).
  - Pack original sound assets (`.m4a`) into the bundle.
* **Day 5: Pro Charts & Half-Life Clock**
  - Implement half-life clock date calculations.
  - Integrate native `Swift Charts` for 7-day history representation.
  - Implement target bedtime cut-off warnings and notifications.
* **Day 6: Settings, License Management & Share Cards**
  - Integrate Keychain wrappers for license keys.
  - Implement offline cached validation checks.
  - Build offscreen `ImageRenderer` pasteboard copying tool.
  - Set up Settings UI with Pro visual blur gates.
* **Day 7: Notarization, Accessibility Audits & Distribution Build**
  - Verify VoiceOver paths and screen-reader accessibility groups.
  - Audit contrast ratios and Reduce Motion triggers.
  - Configure Xcode code signing entitlements.
  - Build, sign, and submit the final release `.dmg` for Apple notarization.

---

## 6. Verification & Testing Plan

### 6.1 Automated Testing Suite
* **Timezone Safety Tests:** Mock local time zones (e.g., transition through winter/summer DST changes) and verify reset behavior.
* **Caffeine Math Checks:** Validate half-life curves under fast/slow/normal settings against expected time windows.
* **License Verification Tests:** Verify cryptographically signed license keys using mock keys (valid, invalid, expired).
* **Memory Diagnostics:** Run continuous automated logging cycles under Instruments (Leaks tool) to confirm `AVAudioPlayer` recycling leaves no dangling player objects.

### 6.2 Manual Quality Assurance
* **Accessibility Inspections:** Open the macOS Accessibility Inspector and verify that contrast values for all states pass WCAG AA standards. Ensure elements have clear, audible VoiceOver descriptions.
* **Reduce Motion Audit:** Toggle "Reduce Motion" in System Settings. Verify that Cup 4 shake and Cup 5 pulse animations are bypassed.
* **Call Muting Verification:** Start a FaceTime/Zoom session. Verify that the app's audio logs are muted or trigger haptic alerts instead.
* **Notarization Check:** Run Apple's `notarytool` on the compiled DMG file to verify runtime hardening compliance:
  ```bash
  xcrun notarytool submit CaffeineBar.dmg --keychain-profile "Developer-Notarization" --wait
  ```
