# DESIGN SYSTEM: CaffeineBar
**Version:** 2.0 (HIG & Accessibility Aligned)
**Platform:** macOS 13+ (Ventura and above)
**Framework:** SwiftUI

## 1. Design Philosophy & macOS Alignment
CaffeineBar follows a **"Native Utility to Unhinged Companion"** narrative. It leverages precise, native macOS design patterns to build trust, then subverts them with deadpan, escalating humor. 

**Core HIG Principles Applied:**
*   **Deference:** The UI defers to the user's content (the data/count). We use native vibrancy and materials instead of heavy drop shadows or custom opaque backgrounds.
*   **Consistency:** Uses system-standard corner radii, spacing grids, and semantic colors to feel like a built-in Apple Control Center module.
*   **Accessibility First:** Full support for Dynamic Type, Reduce Motion, High Contrast, and VoiceOver. Color is *never* the sole indicator of state.

---

## 2. Color System & Semantic Theming
*Hardcoded hex values are banned in SwiftUI implementation. All colors must map to macOS Semantic Colors or custom Asset Catalog colors with Light/Dark/High Contrast variants to guarantee WCAG AA compliance (4.5:1 for normal text, 3:1 for large text/icons).*

### 2.1 Surface & Materials (Vibrancy)
Instead of hardcoded RGBA glass, CaffeineBar uses native SwiftUI Materials to automatically adapt to the user's wallpaper and Dark/Light mode.
*   **Popover Background:** `.ultraThinMaterial` (Provides native macOS vibrancy and blur).
*   **Dividers:** `Color.secondary.opacity(0.2)` or native `Divider()`.

### 2.2 Semantic Status Colors (The Escalation Palette)
These colors drive the "Metabolic State" narrative. They are mapped to Asset Catalogs with specific Dark Mode adjustments to prevent eye strain and ensure contrast.

| Semantic Token | Light Mode | Dark Mode | Usage & HIG Alignment |
| :--- | :--- | :--- | :--- |
| `status.empty` | `#8E8E93` (System Gray) | `#98989D` | Cup 0. Inactive, cold state. |
| `status.active` | `#007AFF` (System Blue) | `#0A84FF` | Cups 1-3. Standard macOS primary action color. |
| `status.warning` | `#D97706` (Amber-600)* | `#FF9F0A` (System Orange) | Cup 4. *Light mode darkened from #FF9500 to pass WCAG AA contrast on white.* |
| `status.danger` | `#D70015` (Red-700)* | `#FF453A` (System Red) | Cup 5+. *Light mode darkened for text/icon contrast compliance.* |
| `text.primary` | `#1D1D1F` (Near Black) | `#FFFFFF` (White) | Main count, primary labels. |
| `text.secondary` | `#6E6E73` (System Gray 2) | `#98989D` | Timestamps, metadata. |

### 2.3 High Contrast & Color Blindness Support
*   **Rule:** Color is secondary to iconography. A colorblind user must understand the escalation purely through the icon shape (Outline → Filled → Steam → Lightning → Exclamation → Skull).
*   **High Contrast Mode:** When `@Environment(\.colorSchemeContrast) == .increased`, status colors shift to pure Black/White/Yellow/Red with 1pt solid borders around status chips.

---

## 3. Typography & Dynamic Type
*Custom fonts (Metropolis) are restricted to the Share Card (PNG export) for branding. The core app UI uses **SF Pro** and **SF Mono** to guarantee native legibility, Dynamic Type scaling, and perfect menu bar integration.*

### 3.1 Type Scale (SwiftUI Semantic Fonts)
| Element | SwiftUI Font Token | Weight | Design | Fallback / Notes |
| :--- | :--- | :--- | :--- | :--- |
| **Hero Count** | `.system(size: 44, weight: .heavy)` | Heavy | Rounded | Scales up to `accessibility3`. Wraps gracefully if user sets huge text. |
| **Headline** | `.headline` | Semibold | Default | Settings titles, section headers. |
| **Body / Actions** | `.body` | Regular | Default | "+1 Coffee" button text, descriptions. |
| **Timestamps** | `.system(.caption, design: .monospaced)` | Regular | Monospaced | Evokes a "log file" aesthetic natively using SF Mono. |
| **Labels / Badges** | `.caption2` | Bold | Default | "PRO" badges, streak counts. |

### 3.2 Dynamic Type Rules
*   The popover width is fixed at `260px` (standard macOS menu bar popover width).
*   If Dynamic Type exceeds `.accessibility1`, the Hero Count scales down slightly in weight to prevent clipping, and the layout shifts from horizontal rows to vertical stacks.

---

## 4. Layout, Spacing & Grid
Follows the native macOS **8-point grid system**.

*   **Popover Dimensions:** `260px` width. Height is dynamic based on content (approx `320px` base).
*   **Padding:** `16px` outer edge padding.
*   **Stack Spacing:** `12px` between major sections (Hero, Log, Footer). `4px` between related items (e.g., timestamp and undo).
*   **Corner Radii:** 
    *   Buttons / Controls: `6px` (macOS standard control radius).
    *   Popover Window: Handled natively by `MenuBarExtra` (system standard).
    *   Status Chips: `4px`.

---

## 5. Iconography & State Escalation
Icons are rendered as **Template Images** (`NSImage` with `.isTemplate = true` or SwiftUI `Image(...).renderingMode(.template)`) so macOS automatically handles the menu bar's Light/Dark/Translucent wallpaper contrast.

| Cup | Menu Bar Icon (16x16pt) | Popover Visual State | Animation / Haptics |
| :--- | :--- | :--- | :--- |
| **0** | Outline Coffee Cup | Gray text, empty state message. | None. |
| **1** | Filled Coffee Cup | Blue tint. | Soft fade-in. |
| **2** | Filled + 1 Steam Line | Blue tint. | Soft fade-in. |
| **3** | Filled + Lightning Bolt | Blue tint. | Slight scale bump (1.05x). |
| **4** | Filled + Exclamation | **Amber tint**. Warning chip appears. | Shake animation (respects Reduce Motion). |
| **5+** | **Skull & Crossbones** | **Red tint**. Background material gets 5% red overlay. | **Pulse** (respects Reduce Motion). |

---

## 6. Components & Interactions

### 6.1 Primary Action ("+1 Coffee")
*   **Style:** `.borderedProminent` with `.controlSize(.large)`.
*   **Color:** `Color.accentColor` (System Blue).
*   **Keyboard Shortcut:** `⌘ + 1` or `Spacebar` when popover is focused.
*   **Interaction:** Click triggers immediate state update, sound, and popover dismiss (configurable to stay open in settings).

### 6.2 Secondary Action ("Undo")
*   **Style:** `.borderless` or plain text button.
*   **Color:** `Color.secondary`.
*   **Keyboard Shortcut:** `⌘ + Z`.
*   **Behavior:** Only visible if `todayCount > 0`. Fades out gracefully when count hits 0.

### 6.3 Focus & Keyboard Navigation
*   **Focus Rings:** Native macOS blue focus rings (`FocusState`) for all interactive elements.
*   **Tab Order:** `+1 Coffee` → `Undo` → `History Items` → `Settings Gear`.
*   **Dismissal:** `Esc` key immediately closes the popover.

### 6.4 The Chart (Pro Feature)
*   **Framework:** Native `Swift Charts`.
*   **Style:** Minimalist bar chart. No grid lines. 
*   **Colors:** Bars are `Color.secondary.opacity(0.3)`. Days exceeding the cut-off limit are highlighted in `status.warning`.
*   **Interaction:** Hovering a bar shows a native macOS tooltip with the exact date and count.

---

## 7. Motion & Animation (Accessibility Aware)
All animations must check `@Environment(\.accessibilityReduceMotion)`.

| Trigger | Standard Animation | Reduce Motion Fallback |
| :--- | :--- | :--- |
| **Logging a Cup** | Count rolls up (odometer style). Icon scales 1.1x and settles. | Count cross-fades. Icon updates instantly. |
| **Cup 4 Warning** | Exclamation icon shakes horizontally (2 cycles). | Exclamation icon fades in with a bold stroke. |
| **Cup 5+ Emergency** | Skull icon pulses (scales 1.0 to 1.2) once. Popover border flashes red. | Skull icon appears instantly. Popover background shifts to static 5% red tint. |
| **Popover Open** | Native macOS spring animation (handled by OS). | Native macOS spring animation. |

---

## 8. Accessibility & Inclusion (VoiceOver)

### 8.1 Semantic Grouping
The popover is divided into `accessibilityElement(children: .contain)` groups to help VoiceOver users navigate logically.

```swift
// Example SwiftUI Accessibility Implementation
VStack {
    // Group 1: Status & Action
    VStack { ... }
    .accessibilityElement(children: .combine)
    .accessibilityLabel("3 cups logged today. Coffee level: Normal.")
    .accessibilityHint("Double tap to log another coffee.")
    
    // Group 2: History
    List { ... }
    .accessibilityLabel("Today's Log History")
}
### 8.2 VoiceOver Specific Labels
Menu Bar Icon: Must dynamically update its accessibility label.
Cup 0: "CaffeineBar. No coffee logged today."
Cup 4: "CaffeineBar. 4 cups logged. Warning: Approaching cut-off."
Cup 5: "CaffeineBar. 5 cups logged. Emergency state."
Undo Button: "Undo last coffee log."
Half-Life Clock (Pro): "Caffeine clears your system at 9:47 PM."

### 8.3 App Store Accessibility Labels
When submitting to the App Store (or listing on the website), declare support for:
✅ VoiceOver
✅ Full Keyboard Access
✅ Increase Contrast
✅ Reduce Motion
✅ Dynamic Type
## 9. Edge Cases & Error States
Empty State (Cup 0): Instead of a blank space, show a subtle, low-opacity SF Symbol (cup.and.saucer.fill) with the text: "Engine cold. Log your first cup."
Missing Sound Asset: If a sound file fails to load, the UI must not crash or show an alert. It fails silently, logs the error to the console, and proceeds with the visual update.
License Revoked/Expired: The UI gracefully downgrades. Pro features (Chart, Half-life) blur out with a native .overlay(.ultraThinMaterial) and a "Unlock Pro" button. Existing logged data is never hidden or deleted.
