# CaffeineBar Master Plan

> **Version 1.0 — July 5, 2026.** Single source of truth for product, design, audio, monetization, launch, and multi-year roadmap. Supersedes scattered decisions in Improvement_plan.md where they conflict. Companion docs: [CaffeineBar_PRD_v1.2.md](CaffeineBar_PRD_v1.2.md), [competitor-profiles/_summary.md](../competitor-profiles/_summary.md).

**North star:** The only macOS menu bar coffee counter — funny enough to share, useful enough to keep.

**One-line pitch:** *"HiCoffee tells you your caffeine half-life. CaffeineBar calls you an ambulance at cup 5."*

**Core strategic bets:**
1. The menu bar surface is an uncontested niche (validated by competitor research).
2. Consequences, not counting, are the product — the half-life engine predicting sleep impact is the 10x feature.
3. The ambulance moment is the marketing budget; voice packs are the reason to pay.
4. One-time pricing for individuals; recurring revenue comes later from Teams, not from taxing individuals.

**Guiding principles (apply to every task below):**
- Logging a cup must never take more than 1 second or 1 interaction.
- Every mechanic rewards *logging*, never *drinking more*. No dark patterns.
- One obsessively-crafted animation beats ten adequate ones.
- `reduceMotion`, VoiceOver, and Dynamic Type support are non-negotiable on every new UI.
- No celebrity names or sound-alike voices anywhere in the product (legal).

---

## Phase 0 — Launch Blockers (Weeks 1–2, ship before any marketing)

### 0.1 Real sound assets (replace all dummies)

**Budget: ≤ $500 total. Sources locked by license research (July 2026).**

| Asset group | Source | Cost | License requirement |
|---|---|---|---|
| Ambulance, sirens, chaos, NASA radio chatter | ElevenLabs SFX (Starter plan, 1 month) | ~$5 | Paid plan only — free tier has NO commercial license |
| Voice packs ("Your Mom", "Angry Chef") | Fiverr/Voices.com voice actor | $200–400 | Full commercial buyout in gig terms, in writing |
| Foley (pours, slurps, cup clinks) | Self-recorded (iPhone mic) | $0 | Owned outright |
| Filler SFX (dings, whooshes) | Pixabay (no attribution) or ZapSplat | $0 | Verify per-file; avoid Freesound NC-licensed files |

**Acceptance criteria:**
- [ ] Zero placeholder/dummy audio files remain in the bundle (`grep`/audit `SoundPackRegistry.swift` manifest vs. bundled files).
- [ ] Every shipped audio file has a documented source + license line in a new `CaffeineBar/Resources/Sounds/LICENSES.md`.
- [ ] All four launch packs play end-to-end through `SoundEngine` for cups 1–6 with no missing-asset fallbacks logged.
- [ ] Voice-actor buyout contracts saved outside the repo; referenced by filename in LICENSES.md.
- [ ] Peak loudness normalized across packs (±2 LU) so pack-switching doesn't blast users.

### 0.2 Legal rename — celebrity pack

- [ ] "Gordon Ramsay" pack renamed to **"Angry Chef"** in `SoundPackRegistry.swift`, PRD, landing page, and all marketing assets.
- [ ] Voice performance is an original comedic persona, not an imitation of any real person (brief the voice actor in writing).
- [ ] Repo-wide search for "Ramsay" returns zero hits.

### 0.3 Pricing finalization

**Decision: ship at $9.99 Pro / $14.99 Ultra. Kill the $7.99 A/B test.** Rationale: at launch volumes (~hundreds of conversions) the test can't reach significance in the 48h window; $9.99 sits under the HiCoffee lifetime anchor already; each cohort requires a separate build.

- [ ] `PriceVariant.current` fixed at `"9.99"`; A/B resolution logic removed or marked dormant with a `ponytail:`-style comment.
- [ ] **Launch-week promo instead:** Polar.sh coupon for $6.99 launch week, strike-through shown on landing page + Settings upsell. Expires day 8 automatically.
- [ ] Ultra positioned as anchor: Settings/upsell UI always shows both tiers side-by-side with Pro visually recommended.

### 0.4 Launch assets & distribution

- [ ] The ambulance GIF: 8-second screen recording, cup 4 → cup 5, icon siren sweep visible, works with sound OFF (on-screen caption "☕️ CUP 5. EMERGENCY SERVICES NOTIFIED."). This asset gates everything else.
- [ ] 15 creators DM'd with free Pro key + GIF (list from PRD §6). Sent ≥7 days before Product Hunt.
- [ ] Landing page hero first sentence contains "coffee cup counter" (brand-confusion mitigation vs. the Caffeine sleep-prevention app). `landing-page/` exists — verify copy.
- [ ] Notarized .dmg passes Gatekeeper on a clean Mac (rehearsal per [NOTARIZATION_REHEARSAL.md](NOTARIZATION_REHEARSAL.md)).
- [ ] Product Hunt listing queued; tagline leads with the ambulance behavior, not the category name.

**Phase 0 exit gate:** all four sections green. Do not seed creators with dummy sounds.

---

## Phase 1 — Friction & Habit Loop (Weeks 2–4)

The trigger already exists in the real world (the user's coffee). Our job: make the action instant and the reward variable.

### 1.1 Global hotkey logging

**Files:** new `Sources/Engine/HotkeyManager.swift`; modify `CaffeineBarApp.swift`, `SettingsView.swift` (rebinding UI).

- [ ] Default ⌃⌥C logs one cup from anywhere in macOS, no popover shown.
- [ ] Feedback without popover: icon plays gulp animation + the log sound; a transient count bubble is acceptable but optional.
- [ ] Hotkey is rebindable and disableable in Settings.
- [ ] Works while another app is full-screen.
- [ ] Sandboxed-safe implementation (app is sandboxed since commit 10b04c6 — verify the chosen API works under sandbox before building UI).

### 1.2 Scroll-to-log on menu bar icon

**Files:** modify `Sources/CaffeineBarApp.swift` / icon hosting view, `Sources/Model/CupStore.swift`.

- [ ] Scroll up on the menu bar icon = log one cup; scroll down = undo (mirrors `store.undo()` semantics exactly).
- [ ] Debounced: one continuous scroll gesture = one action, never 2+.
- [ ] Discoverable: mentioned once in onboarding coach mark and in Settings.

### 1.3 Onboarding under 30 seconds

**Files:** new `Sources/View/OnboardingCoachMark.swift`; modify `CaffeineBarApp.swift`.

- [ ] First launch: icon appears, single coach-mark popover ("Click to log your first cup") — no account, no forms, no permission prompts.
- [ ] First-ever log plays the best-sounding effect in the app (curated, not random).
- [ ] Notification permission requested only when the first feature needing it activates (cut-off reminder or smart nudge), never at first launch.
- [ ] Coach mark never appears again after first log (persisted flag in `UserDefaults`).
- [ ] Stopwatch test: fresh install → first logged cup ≤ 30 seconds including DMG mount.

### 1.4 Variable micro-rewards (cups 1–3 must pay off)

**Files:** new `Sources/Engine/DelightEngine.swift`; modify `MenuBarExtraView.swift`, `CupStore.swift`.

- [ ] Every log produces a micro-payoff (animation + sound), including cups 1–3 which are currently silent.
- [ ] ~1 in 7 logs (randomized, seeded per-day so it can't be farmed by undo/redo) triggers a *rare* variant: alternate animation, one-line roast text ("Third cup before noon. Bold."), or hidden sound variant.
- [ ] Fixed easter eggs fire deterministically: log at exactly 11:11, log on user's birthday (if set, optional), 100th lifetime cup (confetti), first log before 6 a.m. ("Why are you awake" achievement), zero-cup day ends with a gentle "decaf detected?" note next morning.
- [ ] Roast-line copy bank ≥ 30 lines at launch, stored in a plist/JSON so packs can extend it.
- [ ] All rewards respect `reduceMotion` (fall back to opacity fades) and are VoiceOver-announced.
- [ ] Anti-gaming: undo removes the reward state; re-logging the same cup index the same day never re-rolls a rare reward.

### 1.5 Streaks with grace ("streak freeze")

**Files:** modify `Sources/Model/CupStore.swift` (streak model), `MenuBarExtraView.swift`, `ShareCardView.swift`.

- [ ] Streak = consecutive days with ≥1 logged cup (rewards logging, not volume — never displays "drink more to keep your streak").
- [ ] One automatic streak freeze per calendar week: a single missed day is absorbed, shown as a "❄️ freeze used" day, streak continues.
- [ ] Two missed days in a week = streak resets, with a kind message, never shame copy.
- [ ] Streak state survives app restart, clock changes, and timezone travel (test: log in IST, set clock to PST, streak unchanged).
- [ ] Streak + freeze status visible on ShareCard.

### 1.6 Smart nudge (one per day, max)

**Files:** extend `Sources/Engine/CutOffReminder.swift` scheduling infra; new logic in `DelightEngine.swift` or a small `HabitNudge.swift`.

- [ ] If the user logged a cup within the same ±45-min window on ≥5 of the last 7 days and today's window passes with no log → icon shows subtle steam animation; at most ONE optional notification.
- [ ] Hard cap: one nudge notification per day, zero if notifications denied, fully disableable in Settings (default ON for icon animation, OFF for notification).
- [ ] Nudge never fires after the user's configured cut-off time (don't nudge people toward late caffeine — this is the ethical line and also the brand).

**Phase 1 exit gate:** D7 retention of new installs ≥ 40% (see KPIs, §Metrics).

---

## Phase 2 — Signature Design: Living Icon & Motion Craft (Weeks 4–8)

Identity thesis: **the menu bar icon is alive.** HIG compliance is the floor (already strong: material popover, Dynamic Type reflow, keyboard focus order, reduced motion). This phase buys memorability.

### 2.1 The living icon (escalation as character)

**Files:** rework `Sources/View/IconRenderer.swift`; `StatusColors.swift`.

- [ ] Six icon states express personality through *state*, not a face: cup 0 = empty/still · cup 1 = gentle steam wisp · cup 2 = fuller, steady steam · cup 3 = slight lean/tilt · cup 4 = visible vibration (micro-shake ≤1pt, ≤4Hz) · cup 5+ = panic: rapid micro-shake + red pulse.
- [ ] Idle animations are subtle enough to pass a "menu bar neighbor test": at normal glance distance the bar doesn't look broken or distracting; animation duty cycle ≤ 20% (animate, rest, animate).
- [ ] `reduceMotion` replaces all movement with static state variants + color only.
- [ ] Template-image behavior preserved for cups 0–3 (correct dark/light rendering); tinted states 4+ verified in both appearances and with Increase Contrast on.
- [ ] Energy audit: icon animation at any state uses ~0% CPU when popover closed except during a state transition (timer-driven frames only during transitions, CVDisplayLink/timeline paused at rest).

### 2.2 The gulp — one signature animation, obsessively crafted

**Files:** `IconRenderer.swift`, `MenuBarExtraView.swift`.

- [ ] On every log: cup squash-and-stretch, liquid level rises to the new state, one steam puff. Spring physics (`.spring(response: 0.35, dampingFraction: 0.6)` as starting values — tune by feel), never linear/ease curves.
- [ ] Total duration ≤ 600ms; interruptible (rapid double-log queues cleanly, no visual glitch).
- [ ] The gulp is synchronized with the log sound onset (±50ms).
- [ ] Plays identically from popover button, hotkey, and scroll-log.
- [ ] Bar for done: a 10-second screen recording of just the gulp is something you'd post. If it isn't, keep tuning.

### 2.3 Hero number odometer

**Files:** `MenuBarExtraView.swift` (`heroCountText`).

- [ ] Cup count uses `contentTransition(.numericText())` rolling-digit transition on every change (log and undo, correct direction each way).
- [ ] Color escalation logic (existing `heroCountColor`) animates smoothly with the digit roll.

### 2.4 Proprietary palette

**Files:** `StatusColors.swift`, asset catalog; landing page CSS.

- [ ] One brand accent — a warm **crema** tone — defined once and used in: popover accents, ShareCard, app icon, landing page. Escalation ramp: espresso brown → crema cream → warning amber → danger red.
- [ ] Semantic system colors remain for status meaning (warning/danger); crema is additive brand, not a replacement — all existing contrast ratios (≥4.5:1 text) still pass in light, dark, and increased-contrast modes.
- [ ] Landing page and app use identical hex values (single source: a small design-tokens file checked into repo).

### 2.5 ShareCard as poster + siren sync

**Files:** `Sources/View/ShareCardView.swift`; `IconRenderer.swift` (siren sweep).

- [ ] ShareCard redesigned as an *object* (vintage coffee-bag label / ticket-stub art direction), not a stats dashboard. Contains: streak, today count, escalation state name, subtle branding + `caffeinebar.app`.
- [ ] Exports at 2x/3x PNG, looks correct in dark and light message bubbles (opaque background).
- [ ] Cup-5 siren: icon runs a red/blue alternating tint sweep for 10 seconds, synced with the ambulance audio; visible and legible in a muted screen recording. Notification copy: "☕️ CUP 5. EMERGENCY SERVICES NOTIFIED."
- [ ] `reduceMotion`: sweep becomes two slow alternating color fades.

**Phase 2 exit gate:** the ambulance GIF re-recorded with final motion + sound replaces the Phase 0 version in all marketing.

---

## Phase 3 — 10x Features: From Counter to Predictor (Weeks 8–12)

The strategic move: counting is commodity; **consequences are the product**. All arithmetic already exists in the half-life engine (`HalfLifeClock`, metabolism model from commit 2ca9d5a).

### 3.1 Sleep Forecast (the killer feature)

**Files:** new `Sources/Engine/SleepForecast.swift`; modify `MenuBarExtraView.swift` (pre-log preview), `SettingsView.swift` (bedtime already exists via cut-off config).

- [ ] Before/at logging, the popover shows the consequence: *"This cup ≈ 62mg still in your blood at 11:00pm. Expected sleep delay: ~40 min."* Computed from the personalized metabolism model + configured bedtime.
- [ ] Numbers update live as the half-life clock ticks; consistent with `HalfLifeClock` display (same model, no divergent math).
- [ ] Copy is honest about being an estimate ("≈", "expected") — no medical claims anywhere (App Review + ethics).
- [ ] Unit tests: known inputs (dose, time, half-life profile) → expected mg-at-bedtime within ±1mg; DST boundary day doesn't corrupt the forecast.
- [ ] Free tier: shows the mg number, blurs the sleep-delay line with the Pro gate (`ProGateOverlay`) — the consequence preview is the #1 Pro conversion driver, gate accordingly.

### 3.2 Crash Detector

**Files:** `SleepForecast.swift` (shared model), `CutOffReminder.swift` notification infra.

- [ ] Optional notification at predicted crash time: "Your 9am cup wears off in ~25 min. Brace." One per crash event, coalesced when cups overlap.
- [ ] Default OFF; enabled from Settings; Pro feature.
- [ ] Never fires within 1 hour of configured bedtime.

### 3.3 Delight inventory completion

- [ ] All Phase 1.4 easter eggs shipped and QA'd.
- [ ] Achievements surface in a small trophy row (popover tab 2 or Settings), each with VoiceOver labels; no leaderboard, no social comparison (solo product; competition mechanics deferred to Teams where they're opt-in and squad-level).

**Phase 3 exit gate:** free→Pro conversion measurably improves after Sleep Forecast ships (target: ≥1.5× the pre-3.1 weekly conversion rate; measured via Polar.sh sales vs. download counts — no in-app tracking added).

---

## Phase 4 — Wrapped (build in October–November, ship December 1, 2026)

- [ ] Full-year recap card: total cups, most caffeinated day/weekday, longest streak, hours above 200mg, escalation-state pie, roast-grade copy ("Your most caffeinated day was a Tuesday. Of course it was.").
- [ ] Ultra feature; free users see a locked preview of their own real numbers (blurred) — the strongest Ultra conversion moment of the year.
- [ ] Requires ≥ 30 days of data; degrades gracefully ("Your first year starts now") for newer users.
- [ ] Shareable as PNG in the ShareCard art direction; every card footer carries `caffeinebar.app`.
- [ ] **Second Product Hunt launch** ("CaffeineBar Wrapped") queued for the first week of December.

---

## Phase 5 — iOS + Watch Companion (2027 H1)

Rationale: the caffeine-tracker market is iOS-first (competitor data: category leader has 812 ratings on iOS; the Mac is our beachhead, not our ceiling).

Scope gate (decide in January 2027, only if Mac D30 retention ≥ 25% and ≥ 5,000 installs):
- [ ] iOS app with feature parity on: logging, streaks, half-life clock, Sleep Forecast, ShareCard.
- [ ] Watch complication = the living cup icon (the identity travels).
- [ ] CloudKit sync (Ultra) bridges Mac ↔ iOS — the first real Ultra differentiator.
- [ ] HealthKit caffeine write (already Ultra-scoped in PRD).
- [ ] Pricing: universal purchase; existing Pro/Ultra honored cross-platform.

---

## Phase 6 — CaffeineBar for Teams (2027 H2) — the recurring-revenue door

Thesis: the comedy compounds socially. Offices are where cup-5 sirens become culture.

Scope gate (decide only after iOS ships and combined MAU ≥ 15,000):
- [ ] Slack app: team channel gets shared ambulance moments, weekly team leaderboard (squad-level, opt-in, celebrates *logging consistency* not volume — anti-pattern guard), team Wrapped.
- [ ] Admin dashboard: seat management, billing.
- [ ] Pricing: $2–3/seat/month (per-seat is the correct value metric here — value scales with team size). 14-day free team trial, no card.
- [ ] Requires backend (licensing server exists via Polar.sh; Slack app needs a small hosted service — first infrastructure spend of the project, budget accordingly).

---

## Monetization Structure (locked decisions)

| Tier | Price | Contents |
|---|---|---|
| Free | $0 | Logging, count, icon states (all 6 visible — the skull sells Pro), basic sounds cups 1–3, cup-4 teaser notification |
| **Pro** | **$9.99 one-time** | Full escalation sounds, all 4 packs, streaks, ShareCard, half-life clock, **Sleep Forecast**, Crash Detector, cut-off reminder, weekly graph |
| Ultra | $14.99 one-time | Pro + CloudKit sync, HealthKit write, Shortcuts, **Wrapped**, custom sound import |
| Seasonal packs | $2.99 each (free w/ Ultra) | Halloween, holiday, "Monday" pack — post-launch content drops, the trust-respecting recurring-ish revenue |
| Teams (2027) | $2–3/seat/mo | Slack integration, team leaderboard, team Wrapped |

Rules: never convert existing one-time buyers to subscription; Ultra's job is anchoring Pro until Phase 5 gives it real differentiation (sync).

---

## Forecasts

All scenarios assume the PRD launch plan executes (Product Hunt + 15 creators + landing page). Method: funnel arithmetic from PRD traffic estimates and category benchmarks — treat as planning ranges, not promises.

### Year 1 (launch → June 2027)

| | Conservative | Base | Upside |
|---|---|---|---|
| Launch-window visitors | 5,000 | 12,000 | 25,000 (creator post hits) |
| Visitor→install | 15% | 20% | 25% |
| Installs (launch + tail ×2.5) | ~1,900 | ~6,000 | ~15,600 |
| Install→Pro conversion | 3% | 5% | 8% (Sleep Forecast effect) |
| Pro sales | ~57 | ~300 | ~1,250 |
| Ultra attach (of paid) | 10% | 15% | 20% |
| Seasonal-pack revenue | ~$50 | ~$400 | ~$2,500 |
| **Year-1 revenue** | **~$700** | **~$3,700** | **~$16,500** |

Wrapped (December) is modeled inside the tail multiplier; historically a strong recap moment can double a month's installs — if December installs < 1.5× November, Wrapped's shareability failed and needs a redesign before year 2.

### Years 2–3 (with iOS + Teams, gated as above)

| Stream | 2027 (Y2) | 2028 (Y3) |
|---|---|---|
| Mac one-time (steady state) | $5–15K | $5–12K |
| iOS one-time (market is 20–50× Mac category volume; capture pessimistically) | $10–40K | $20–60K |
| Seasonal packs | $1–4K | $2–6K |
| Teams ARR (Y3: 50–300 companies × ~20 seats × $2/mo) | $0–10K (pilot) | $24–144K |
| **Total** | **$16–69K** | **$51–222K** |

**Honest read:** the $1M outcome is a 3–4 year compounding path that requires the Teams tier working, not a year-1 Mac-app outcome. Year 1's real deliverables are (a) $3–15K, (b) 5–15K users, (c) a creator/dev audience, and (d) proof of the viral loop — those four assets are what fund the decision gates for Phases 5–6. Kill criteria are as important as targets: if base-case year 1 misses by >70% (< ~$1K revenue, < 1,500 installs), do not build iOS — write the postmortem, keep the app in maintenance, and take the audience to the next product.

### Cost forecast (year 1)

Sounds ≤ $500 · Apple Developer $99 · domain/landing hosting ≤ $100 · optional Reddit ad test $100 (only after conversion proven) · **total ≤ $800.** Break-even at ~80 Pro sales — inside the conservative-to-base range. Infrastructure cost stays $0 until Teams (Polar.sh takes a cut, no servers).

---

## Metrics & KPIs (measure without creepy tracking)

Privacy stance: no third-party analytics SDK in the Mac app. Measure via: Polar.sh sales data, landing-page analytics (server-side), download counts, and *local-only* counters (like the existing `PriceVariant.conversionCount` pattern) surfaced only in aggregate if a user opts into sharing diagnostics.

| KPI | Target | Source |
|---|---|---|
| Activation: install → first log | ≥ 80% within first day | local flag, opt-in diagnostics |
| D7 retention (still logging) | ≥ 40% | local, opt-in |
| D30 retention | ≥ 25% (Phase 5 gate) | local, opt-in |
| Free→Pro conversion | 3–5%; ≥1.5× uplift after Sleep Forecast | Polar.sh ÷ downloads |
| ShareCard exports / MAU / month | ≥ 10% | local, opt-in |
| Refund rate | < 5% (novelty wear-off alarm if higher) | Polar.sh |
| December Wrapped install spike | ≥ 1.5× November | download counts |

---

## Risk Register (top 6)

| Risk | Likelihood | Mitigation |
|---|---|---|
| Novelty wears off week 2 → refunds/uninstalls | High | Phase 1 habit loop + Phase 3 utility are the counterweight; watch refund rate KPI |
| Brand confusion with "Caffeine" sleep app | Medium | "coffee cup counter" in first sentence everywhere; ambulance-first taglines |
| Celebrity-voice legal exposure | Was high | Eliminated by 0.2 (rename + original personas) — do not regress in marketing copy |
| CaffeineMate ships a real Mac app | Medium | Our moats: menu bar surface, CallDetector/Meeting/Office modes, comedy, Sleep Forecast pre-log preview |
| Global hotkey/scroll APIs fight the sandbox | Medium | Spike 1.1 technically *first*; fall back to Shortcuts-based logging if blocked |
| Solo-dev burnout across 6 phases | High | Phases 5–6 have explicit data gates — permission to stop is built into the plan |

---

## Decision Log

| Date | Decision | Rationale |
|---|---|---|
| 2026-07-05 | Kill $7.99 A/B test; ship $9.99 + launch-week $6.99 coupon | No statistical power at launch volume; urgency lever is worth more |
| 2026-07-05 | Rename Gordon Ramsay pack → "Angry Chef", original persona | Right-of-publicity liability; App Review risk |
| 2026-07-05 | One-time pricing for individuals, forever; recurring only via Teams | Value metric doesn't scale monthly for solo use; subscription would poison trust |
| 2026-07-05 | Sound budget ≤ $500: ElevenLabs paid tier + Fiverr VO + self-foley | Commercial licenses verified; VO is highest-ROI spend |
| 2026-07-05 | Sleep Forecast is the flagship Pro feature and conversion driver | Moves product from counter (commodity) to predictor (10x) |
| 2026-07-05 | iOS gate: D30 ≥ 25% AND ≥ 5,000 installs (decide Jan 2027) | Don't multiply platforms before retention is proven |
| 2026-07-05 | Teams gate: iOS shipped AND MAU ≥ 15,000 | Recurring revenue needs an audience first |

---

*Review cadence: revisit this doc at each phase exit gate and at every decision-log gate date. Update forecasts with actuals after launch week — the first real conversion number replaces every estimate above.*
