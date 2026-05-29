# CaffeineBar — Accessibility Nutrition Labels

CaffeineBar declares support for the following macOS accessibility features.
Each label is backed by behavioral requirements verified through the app's
test suite and Accessibility Inspector audits.

## Declared Accessibility Features

### ✅ VoiceOver

CaffeineBar is fully navigable with VoiceOver enabled.

- The menu bar icon announces: "CaffeineBar. {N} cups logged. {state}."
- The popover groups content into semantic regions (Hero Status, Log History,
  Pro Features, Actions) using `.accessibilityElement(children: .contain)`.
- Today's Log History is exposed as a landmark with label "Today's Log History".
- Each timestamp reads: "Cup {N} at {time}".
- The HalfLifeClock announces: "Caffeine clears your system at {time}".
- All interactive controls have descriptive labels and hints.

**Backed by:** Requirements 29.1, 29.2, 29.3, 29.4

### ✅ Full Keyboard Access

Every control in the popover is reachable and operable via keyboard alone.

- ⌘+1 or Space → Log a cup
- ⌘+Z → Undo last cup
- Esc → Dismiss popover
- Tab order: +1 Coffee → Undo → History items → Settings gear
- Native macOS focus rings are rendered on all interactive controls via
  `@FocusState`.

**Backed by:** Requirements 28.1, 28.2, 28.3, 28.4, 28.5

### ✅ Increase Contrast

CaffeineBar responds to the system Increased Contrast setting.

- All color tokens (status.empty, status.active, status.warning, status.danger)
  provide Light, Dark, and Increased Contrast variants in the Asset Catalog.
- When Increased Contrast is active, status chips render with a 1pt solid border.
- Body text maintains ≥ 4.5:1 contrast ratio on `.ultraThinMaterial` in both
  Light and Dark modes.
- Icon shape is the primary signal for escalation state; color is secondary.

**Backed by:** Requirements 26.1, 26.2, 26.3, 26.4, 26.5, 27.1, 27.2

### ✅ Reduce Motion

CaffeineBar respects the system Reduce Motion preference.

- Cup 4 warning: horizontal shake → bold-stroke fade-in
- Cup 5+ emergency: pulse scale animation → static 5% red material overlay
- Count increment: odometer roll → cross-fade transition
- All animated views check `@Environment(\.accessibilityReduceMotion)` and
  apply `.animation(nil)` with the appropriate fallback visual.

**Backed by:** Requirements 25.1, 25.2, 25.3

### ✅ Dynamic Type

CaffeineBar supports the full range of Dynamic Type sizes including
accessibility sizes.

- Hero cup count uses `.dynamicTypeSize(...accessibility3)` to scale up to
  the maximum accessibility size.
- At `.accessibility1` and above, horizontal rows re-flow to vertical stacks.
- The popover width remains fixed at 260pt; height grows to accommodate
  larger text.
- All text uses system fonts that respond to Dynamic Type settings.

**Backed by:** Requirements 24.1, 24.2, 24.3

---

## Verification

These accessibility nutrition labels are verified through:

1. **Automated tests** — Property-based and unit tests validate accessibility
   label content, focus order, and layout behavior.
2. **Accessibility Inspector audit** — Manual audit covering all 6 escalation
   states × Light/Dark/Increased Contrast modes (Requirement 58).
3. **Info.plist declaration** — `NSAccessibilitySupportedFeatures` array in
   the app bundle declares all five features.

## Distribution Metadata

For App Store Connect (if/when MAS distribution is enabled), these same five
features are declared in the Accessibility section of the app's metadata page.

For the direct-download `.dmg` distributed via caffeinebar.app, the features
are declared in:
- The app's `Info.plist` (`NSAccessibilitySupportedFeatures` key)
- This documentation file (bundled with the source)
- The caffeinebar.app download page accessibility section
