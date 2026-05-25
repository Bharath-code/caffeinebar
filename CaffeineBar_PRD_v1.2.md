**PRODUCT REQUIREMENTS DOCUMENT**

**CaffeineBar**

*Tracks your coffee. Judges your coffee. Fears your coffee.*

| Version | Status | Author | Date |
| :---- | :---- | :---- | :---- |
| 1.2 | Draft | Bharath | May 2026 |

# **1\. Product Overview**

| ONE-LINE PITCH CaffeineBar is a macOS menu bar app that lets you log each coffee with one click, shows your cup count as an icon all day, and plays increasingly unhinged sound effects as your intake climbs past cup 3 — escalating from gentle concern to a full ambulance by cup 5\. |
| :---- |

CaffeineBar lives at the intersection of utility and comedy. It is a real coffee tracker — simple, instant, always visible — wrapped in a personality that makes it a conversation starter every time someone glances at your screen.

The product follows the SlapMac playbook: absurdly simple concept, hardware (or in this case, a menu bar icon) used in a way no one expects, and a demo that writes itself. 'My Mac called an ambulance when I had my fifth coffee' is a tweet. That tweet is the acquisition funnel.

## **1.1  The problem**

People have no passive awareness of how much coffee they're drinking. They don't count cups — they just reach for the next one. CaffeineBar makes the count impossible to ignore by putting it in the menu bar all day, every day.

## **1.2  The SlapMac-style insight**

The app doesn't moralize. It doesn't tell you to stop. It just escalates. Calm at cup 1\. Politely concerned at cup 3\. Genuinely alarmed at cup 4\. Fully panicking at cup 5\. The escalation is the joke, and the joke is the viral loop.

## **1.3  Product strategy — funny AND useful (Path B)**

A deliberate strategic choice was made in planning: CaffeineBar is not a pure comedy app (Path A) and not a serious habit-change app (Path C). It is Path B — funny enough to be viral, useful enough to be sticky.

| Path A — pure comedy | Path B — our choice | Path C — serious wellness |
| :---- | :---- | :---- |
| Viral at launch, uninstalled in 2 weeks | Viral at launch, daily utility keeps it installed | No viral potential, competes with HiCoffee/CoffeeWatch |
| Revenue: one-time spike | Revenue: spike \+ long tail | Revenue: slow build, high churn |
| Joke gets old in 2-3 weeks | Joke lands harder because it's also true | No joke — no personality moat |

The positioning sentence that captures this: CaffeineBar doesn't tell you to drink less coffee. It just makes sure you know exactly what you're doing to yourself — with sound effects.

Critically, Path B does not mean becoming serious. The cut-off notification is not 'You have exceeded your recommended daily caffeine intake.' It is 'That's your problem tonight.' Same joke. Now it is also useful. The habit change happens as a side effect, not a goal — people change behaviour when they laugh at themselves, not when they are lectured.

## **1.4  Success metrics (MVP, 30/90 days)**

| Metric | 30-day target | 90-day target |
| :---- | :---- | :---- |
| App downloads / installs | 300 | 2,000 |
| Daily active users | 100 | 800 |
| Paid conversions (full unlock) | 40 | 300 |
| Revenue | $500 | $4,000 |
| Social posts tagged \#CaffeineBar | 20 | 200 |

# **2\. Target User**

## **2.1  Primary ICP**

Developers, designers, indie hackers, and remote knowledge workers aged 22–40 who:

* Drink 2–5+ coffees a day and have no real idea of the exact count

* Work from a MacBook for 6–10 hours daily — menu bar is always visible

* Post relatable dev/productivity humor on X, Threads, or LinkedIn

* Will buy a $2.99 app in 8 seconds if it makes them laugh

* Already have at least one silly menu bar app (Lungo, Navi, etc.)

## **2.2  Secondary ICP**

Productivity content creators (YouTube, newsletter, TikTok/Reels) who showcase their Mac setup. CaffeineBar gives them a recurring visual gag in every screen recording.

## **2.3  Anti-ICP**

* Health-anxious users who want to genuinely cut caffeine — this is not a wellness app

* Windows / Linux users (macOS only, at least for MVP)

* People who drink no coffee — the entire product premise collapses

# **3\. Core Features**

## **3.1  Menu bar icon — always-on cup counter**

The menu bar icon is the entire product surface. It updates instantly on every log action. Design:

* Cups 0: coffee cup outline, grey (empty state)

* Cup 1: filled cup icon

* Cup 2: filled cup with steam lines

* Cup 3: cup with small lightning bolt (energy mode)

* Cup 4: cup with exclamation mark, icon tinted amber

* Cup 5+: cup with skull, icon tinted red — pulses once on log

Icon set delivered as SF Symbols overrides where possible, with custom NSImage fallback for non-system icons. All icons render correctly at 16×16pt in both light and dark menu bar modes.

## **3.2  One-click logging**

Clicking the menu bar icon opens a minimal popover — not a full window. The popover contains:

* A large '+1 Coffee' button — single click, no confirmation

* Today's cup count displayed large (e.g. '3 cups')

* A small 'undo last' link below the count

* A thin horizontal rule, then today's log timestamps (e.g. '9:14 am  •  11:02 am  •  1:47 pm')

* A settings gear in the bottom-right corner

The popover closes immediately after logging. The icon updates within 100ms. No friction, no confirmation dialogs.

## **3.3  The escalation sound system**

The core comedy mechanic. Every cup logged triggers a sound that escalates in alarm level:

| Cup | Sound | Description | Vibe |
| :---- | :---- | :---- | :---- |
| 1 | Soft chime | Pleasant coffee shop ambient sound, 1 second | Nice start to the day |
| 2 | Gentle approving ding | Upbeat, positive affirmation tone | You're doing fine |
| 3 | Hmm sound | A soft 'hmm, okay' voice clip — curious, not alarmed | Mild concern begins |
| 4 | Physician stethoscope | Doctor 'now let's have a look here' voice clip, slightly worried | Concern escalates |
| 5 | Ambulance siren | Full 2-second ambulance wail — plays at system volume | Active emergency |
| 6+ | Rotating chaos | Cycles: siren \+ airhorn \+ dial-up modem screech \+ Wilhelm scream | Beyond help |

All sounds are bundled in the app — no network dependency. Each sound is ≤3 seconds. System volume respected. Users can mute sounds in settings without losing the icon escalation.

## **3.4  Daily reset**

* Count resets to 0 at midnight local time — or a custom reset hour set in preferences (e.g. 5am for early risers)

* A gentle 'good night' chime plays at reset if the app is running and count was \> 0

* Yesterday's count is retained in history for the streak feature

## **3.5  Streak tracking**

Retained in local storage. Shown in the settings/about panel, not the main popover (keeps the main UI clean).

* 'Days logged': total days you've opened the app and logged at least one cup

* 'Personal record': highest single-day cup count ever

* 'Current streak': consecutive days logged (resets if you don't open the app at all that day)

* A shareable streak card — same share mechanic as ScrollShame: renders as PNG, one-tap clipboard copy

# **4\. Monetization**

## **4.1  Pricing tiers**

| Tier | What you get | Price |
| :---- | :---- | :---- |
| Free | Cup logging, menu bar icon (cups 1-3 only), calm sounds cups 1-3, today's count \+ timestamps, undo | $0 forever |
| Pro | Everything in Free \+ full escalation sounds (cups 4-6+), ALL sound packs included, all 6 icon states, streak tracking, shareable card, caffeine half-life clock, cut-off time reminder, weekly caffeine graph | $9.99 one-time |
| Ultra | Everything in Pro \+ iCloud sync (multi-Mac), Apple Health write, Apple Shortcuts integration, annual Wrapped card, custom sound import | $14.99 one-time |

Two tiers only, no DLC complexity. The free tier does the viral work; Pro closes the sale. The ambulance and chaos sounds remain behind the Pro gate. Free users who hit cup 4+ see a teaser notification: 'Cup 4\. Something is about to happen. Unlock CaffeineBar Pro to find out.' The Ultra tier acts as an anchor price that makes Pro look like the obvious choice.

All sound packs are bundled into Pro rather than sold as separate DLC. At $9.99 this feels generous — 'everything forever' is a stronger conversion message than piecemeal $0.99 packs.

## **4.2  The three Pro features that earn the $9.99**

### **Caffeine half-life clock**

Shows exactly when today's last cup will clear your system — a live countdown in the popover. Caffeine has a half-life of roughly 5-6 hours; the app calculates clearance time from the last log timestamp with a configurable sensitivity setting. 'Your last coffee clears at 9:47pm.' This single feature shifts CaffeineBar from joke app to joke app I actually rely on every afternoon. Build time: approximately 2-3 hours.

### **Cut-off time reminder**

User sets their target bedtime in settings. The app calculates the latest they can log a coffee and still sleep (based on half-life). Two behaviors trigger:

* Menu bar icon gets a subtle amber tint as you approach the cut-off window

* A native macOS notification fires if a cup is logged after the cut-off: 'That's your problem tonight.'

Real utility with zero database complexity — pure date arithmetic on the last log timestamp.

### **Weekly caffeine graph**

A 7-day bar chart rendered in the popover using SwiftUI Charts (native, zero third-party dependency). Shows cups per day for the current week. Increases daily popover opens, gives the app a reason to exist beyond the joke, and feeds the streak mechanic with a visual history layer.

## **4.3  Sound packs (bundled in Pro)**

All four packs ship with Pro at launch. Each pack replaces the full escalation sound set:

* 'Your Mom Pack' — warm, escalating maternal concern ('Honey, that's your fourth coffee...')

* 'Gordon Ramsay Pack' — escalating chef outrage about your caffeine choices

* 'NASA Mission Control Pack' — calm, technical, then increasingly alarmed crew comms

* 'The Accountant Pack' — translates each cup into billable hours lost to jitteriness

## **4.4  Revenue rationale and math**

At $9.99 one-time the impulse-buy window stays open. Nobody budgets for a coffee tracker, but $9.99 is still a sub-10-second decision for a developer who recognizes themselves in the pitch. The ambulance gif closes the sale before the price is even a consideration.

Revenue comparison at 300 conversions: $2.99 model yields \~$900. $9.99 Pro model yields \~$3,000. Same audience, same marketing effort, 3x revenue. The utility features (half-life clock, cut-off reminder) are what make a developer pause at $9.99 and say 'actually this is useful' instead of 'that's a lot for a sound effect.'

Billing: Polar.sh for payment processing. License key stored in macOS Keychain. No backend auth server required — license validation is client-side with a signed key check.

# **5\. Go-To-Market & Viral Strategy**

## **5.1  The SlapMac blueprint — what actually worked**

SlapMac is the closest comparable product and the clearest template. Its real results (verified March 2026):

| Metric | Result |
| :---- | :---- |
| Instagram organic views | \~4 million — from a single reel of the terminal command, zero ad spend |
| X / Twitter reposts | 10M+ views from organic reposts — not from Tonino posting directly |
| Reddit r/SaaS | 147K views, \~1K upvotes — top post of the week |
| Week 1 revenue | $5,000 — 2,000+ licenses sold, 30,000+ downloads |
| Time from idea to paid app | 48 hours — validated with a reel first, built after the reaction confirmed demand |
| Ad spend | $0 |

Key lesson: Tonino posted a reel of the raw terminal command before building anything. 79,400 likes told him to build the app. He shipped in 48 hours before the attention faded. The product did not pitch journalists or influencers — the concept sold itself in one sentence.

## **5.2  CaffeineBar's core marketing asset**

Everything flows from one video: a screen recording of logging cup 5, the ambulance playing at full volume, the skull icon in the menu bar. This is the entire marketing asset. It must be recorded before launch week begins and before any copy is written. If this video does not make the recorder laugh, the launch angle needs rethinking.

* Duration: 8-12 seconds maximum — the ambulance fires and the video ends

* Format: vertical 9:16 for Reels/TikTok, square 1:1 for X, horizontal 16:9 for YouTube Shorts

* No voiceover, no text overlay — the sound is the punchline

* Record on a real MacBook in natural light — staged demos feel fake

## **5.3  Channel strategy — ranked by priority**

| Tier | Channel | Expected reach | Why |
| :---- | :---- | :---- | :---- |
| 1 — do first | Instagram Reels \+ X | 10K to 1M+ (unpredictable) | SlapMac proof: one reel \= 4M views. The ambulance GIF is built for this format. |
| 1 — do first | Reddit (r/macapps, r/SaaS, r/IndieHackers) | 5K to 150K per post | r/macapps has 172K members actively hunting exactly this. SlapMac got top post on r/SaaS. |
| 1 — launch day | Product Hunt | 5K to 20K visitors | SlapMac got 453 upvotes, \#1 product. CaffeineBar has identical energy. |
| 1 — pre-launch | Creator seeding (15 developers) | 3-5 organic posts | DM with free Pro key \+ GIF. No script. One good creator post \= 3 months of organic posting. |
| 2 — week 2+ | X build-in-public | Git-scope audience | Revenue screenshots, user ambulance moments, dev logs. Warm existing audience. |
| 2 — week 2+ | LinkedIn | 5K to 100K impressions | 'I built a silly Mac app in 7 days — here's the revenue.' Post at 30 days with real numbers. |
| 3 — later | Hacker News (Show HN) | Front page \= 10K visitors | Technical angle: Swift, MenuBarExtra API. HN can be harsh on silly apps — frame the build, not the product. |

## **5.4  Paid advertising — honest assessment**

Do not run paid ads at launch. The organic opportunity is too large and the conversion math does not work until organic has proven the conversion rate.

* Meta / Instagram ads: CPC for productivity apps runs $2-5. At $9.99 with 10% conversion you pay $20-50 per sale — negative ROI. Use only to boost an organic post that is already working.

* Reddit ads: Lower CPC (\~$0.75-1.50). r/macapps and r/productivity targeting. Worth a $50-100 test in month 2 after organic proves conversion.

* Google / ASA: Nobody searches 'coffee cup counter mac' yet. Zero search volume at launch. Revisit at month 6 when brand searches appear.

* Rule: organic first, ads only to amplify what is already working — never to replace organic traction that has not yet been proven.

## **5.5  The viral mechanic — product-level loop**

The ambulance at cup 5 is the product's own PR. Nobody who hears it in a shared office or on a call will not ask 'what was that?' That question is zero-cost word of mouth that repeats every day across every active user. Design implication: make cup 5 loud enough that nearby people notice. The social embarrassment is the distribution channel.

Three compounding loops built into the product:

* Ambient loop: ambulance plays in non-private settings → nearby people ask → they install → they become new trigger events

* Weekly card loop: shareable report card every Monday → user posts it → new audience sees caffeinebar.app watermark → installs

* Creator discount loop: post \#CaffeineBar moment → get free sound pack DM → creates more content → extends reach

## **5.6  Launch week — day-by-day**

| When | Action |
| :---- | :---- |
| Day \-7 | Record ambulance GIF / reel — the core asset. DM 15 creators with free Pro key \+ GIF. Set up caffeinebar.app landing page. Queue Product Hunt listing. |
| Day \-1 | Post teaser on X from git-scope account: 'shipping something ridiculous tomorrow.' Notify git-scope community to expect a Product Hunt launch. |
| Day 1 (Tue) | PH goes live at 12:01am PST. Post ambulance reel on Reels \+ X simultaneously. Post on r/macapps, r/SaaS, r/IndieHackers. Reply to every comment within 1 hour all day. |
| Day 2 | Post first revenue screenshot on X. Specific numbers only — $X in 24 hours, X installs. Activate creator discount publicly: \#CaffeineBar post \= free sound pack DM. |
| Day 3-4 | Post on Hacker News Show HN. RT every creator \#CaffeineBar post personally. Consider raising price from $7.99 to $9.99 if demand is strong — SlapMac did $3 to $7 mid-launch and the price increase became its own content. |
| Week 2 | Drop Your Mom Pack DLC — second news cycle, second PH / Reddit post. Post 7-day revenue total on LinkedIn: 'I built a silly Mac app. Here is what happened.' |
| Month 2+ | Weekly X posts of user ambulance moments. Test $50-100 Reddit ads if conversion rate is proven. December: annual Wrapped card drop — third Product Hunt launch moment. |

## **5.7  CaffeineBar's unfair advantage over SlapMac**

Tonino started cold — no existing audience, no warm launch base. You have git-scope: real stars, real contributors, real followers who already trust your work. This means:

* Day-1 Product Hunt upvotes come from a warm audience, not a cold ask

* First X post of the ambulance goes to people who already know your build quality

* Creator DMs carry credibility — 'from the creator of git-scope' is a real signal

SlapMac proved the model works from zero. CaffeineBar starts above zero. That is the distribution advantage that makes the base case revenue projection conservative, not optimistic.

# **6\. Technical Architecture**

## **6.1  Platform**

* macOS 13 Ventura+ (minimum — needed for reliable menu bar popover APIs)

* Swift \+ SwiftUI (menubar extra via MenuBarExtra API, introduced macOS 13\)

* No Electron, no web views — native Swift only, keeping the binary under 5MB

* Notarized and distributed outside the Mac App Store (direct download) to avoid App Store review delays and 30% cut

## **6.2  App structure**

| Module | Responsibility |
| :---- | :---- |
| AppDelegate | App lifecycle, MenuBarExtra setup, daily reset timer |
| CupStore | Observable state: today's count, timestamps, streak data. Persisted via UserDefaults. |
| MenuBarView | SwiftUI view rendered in popover. Log button, count display, undo, timestamps. |
| SoundEngine | AVAudioPlayer wrapper. Loads sound assets, maps cup count to sound file, respects mute preference. |
| IconRenderer | Returns NSImage for each cup level. Handles light/dark menu bar modes via template images. |
| ShareCardView | SwiftUI view rendered offscreen to PNG via ImageRenderer. Today's stats \+ streak \+ watermark. |
| LicenseManager | Validates Polar.sh license key. Stores in Keychain. Unlocks full sound escalation \+ streak card. |
| SettingsView | Reset hour config, mute toggle, license key entry, sound pack selector. |

## **6.3  Data model**

Stored in UserDefaults (no Core Data needed at this scale):

* todayCount: Int — current cup count

* todayTimestamps: \[Date\] — log times for display in popover

* lastResetDate: Date — for midnight reset logic

* streakDays: Int — consecutive days with at least one log

* personalRecord: Int — highest single-day count

* totalDaysLogged: Int

* resetHour: Int — default 0 (midnight), user-configurable

* isMuted: Bool

* licenseKey: String (Keychain)

* installedSoundPacks: \[String\]

## **6.4  Sound assets**

Bundled in the app as .m4a files (compressed, low file size). Total sound bundle target: under 2MB. Loaded lazily via AVAudioPlayer — not preloaded at launch to keep startup instant.

## **6.5  Build & distribution**

* Xcode project, Swift Package Manager for any dependencies

* GitHub Actions CI: build \+ notarize on tag push

* Distributed as a .dmg via caffeinebar.app direct download

* Sparkle framework for in-app update checks

* Polar.sh webhook triggers license key generation on purchase

# **7\. MVP Scope (7-Day Build)**

## **7.1  In scope**

* Menu bar icon with 6 states (cups 0-5+)

* Popover: log button, count, undo, timestamps

* Full escalation sound system (cups 1-6+), all sounds bundled

* Midnight reset with custom hour option

* Streak tracking \+ personal record (local)

* Shareable streak card (PNG export to clipboard)

* Caffeine half-life clock (Pro) — live clearance countdown in popover

* Cut-off time reminder (Pro) — bedtime config, amber icon tint, notification on late log

* Weekly caffeine graph (Pro) — SwiftUI Charts 7-day bar chart in popover

* All four sound packs bundled (Pro) — Your Mom, Gordon Ramsay, NASA, The Accountant

* Polar.sh license key flow — Pro at $9.99, Ultra at $14.99

* Settings: mute, reset hour, bedtime, half-life sensitivity, sound pack selector, license entry

* Notarized .dmg for direct distribution

## **7.2  Out of scope for MVP (Ultra tier — post-launch)**

* iCloud sync for streak data across Macs

* Apple Health write integration

* Apple Shortcuts integration

* Annual Wrapped card (December drop)

* Custom sound import

* iOS companion app

* Mac App Store distribution (post-MVP if warranted)

## **7.3  7-day build schedule**

| Day | Deliverable |
| :---- | :---- |
| 1 | Xcode project scaffold, MenuBarExtra setup, basic popover renders, CupStore state |
| 2 | Log button works end-to-end: tap increments count, icon updates, timestamp appended, undo works |
| 3 | All 6 icon states, midnight reset timer, UserDefaults persistence, cut-off amber tint logic |
| 4 | SoundEngine complete — all escalation sounds \+ all 4 sound packs wired, mute pref, call-detection via NSWorkspace |
| 5 | Caffeine half-life clock, cut-off notification, SwiftUI Charts weekly graph, streak \+ personal record |
| 6 | ShareCardView PNG export, Polar.sh Pro \+ Ultra license flow, LicenseManager, Keychain, freemium gating |
| 7 | Notarize \+ .dmg build, landing page (caffeinebar.app), Product Hunt assets, seed creator DMs |

# **8\. Competitive Landscape**

## **8.1  Direct competitors**

None. No macOS menu bar app combines coffee cup tracking, escalating comedy sounds, and a viral share mechanic. This gap is confirmed by research — not assumed.

## **8.2  Naming risk — critical**

'Caffeine' and 'Caffeinated' already exist as macOS apps. Both are sleep-prevention tools (they prevent the Mac from sleeping) with a coffee cup icon. They are functionally unrelated to CaffeineBar but share the name space.

* Risk: user searches 'caffeine mac app' and finds the wrong product

* Mitigation: landing page headline must say 'coffee cup counter' in the first sentence — not just 'caffeine tracker'

* Mitigation: Product Hunt tagline leads with the ambulance behavior, not the category name

* Mitigation: App name 'CaffeineBar' is distinct enough — 'Bar' signals menu bar, differentiating from sleep tools

## **8.3  Adjacent products — researched**

| Product | Platform | Price | Why not a threat |
| :---- | :---- | :---- | :---- |
| HiCoffee | iOS / iPadOS only | Free \+ subscription | Tracks caffeine in milligrams with metabolism curves and Apple Watch. Clinical, serious, zero comedy. No macOS menu bar. |
| CoffeeWatch | iOS / Watch only | Free \+ IAP | Real-time caffeine mg and sleep risk scoring. Same problem as HiCoffee — iOS only, no personality, no viral mechanic. |
| Caffeine / Caffeinated | macOS | Free | Sleep-prevention tool only. Does not track cups. Name overlap is the only risk — see section 8.2. |
| Apple Health (iOS) | iOS only | Free (built-in) | Tracks caffeine as a health data point. Clinical, high-friction, no comedy, iOS only. Different job entirely. |
| SlapMac | macOS | $6.99 one-time | Same playbook, different input trigger. Validates the model: silly macOS app \+ sound effects \+ viral share \= real revenue. Not competing, confirming. |

## **8.4  The real competitive insight**

HiCoffee and CoffeeWatch are the closest functional competitors, and both are iOS-only, clinically serious, and track caffeine in milligrams. They are doing a completely different job: they are health management tools. CaffeineBar's job is to make you laugh at yourself while staying aware. These are not the same product and they do not compete for the same purchase decision.

The macOS menu bar comedy niche is genuinely empty. The gap between 'serious iOS caffeine tracker' and 'funny macOS cup counter' is where CaffeineBar lives, and no one is there.

## **8.5  Defensibility**

The moat is tonal, not technical. Logging logic takes a day to build. The escalation sound design, the specific deadpan copy ('That's your problem tonight'), and the personality of the product are what cannot be cloned quickly. A competitor can copy the feature list in a weekend; they cannot copy the voice.

The secondary moat is distribution: the creator community built around shared ambulance moments is a compounding asset that grows with every user who posts their cup-5 moment.

# **9\. Risks & Mitigations**

| Risk | Likelihood | Mitigation |
| :---- | :---- | :---- |
| Novelty wears off after one week | High | Streak mechanic creates daily return habit. Sound pack drops create re-engagement moments. Path B (funny \+ useful) prevents this — utility is the retention engine. |
| Sound plays during a client call (ambulance fires mid-meeting) | High | Auto-detect active call via NSWorkspace (Zoom, Meet, FaceTime) and mute during calls. This is a day of build work that prevents the most likely negative review trigger. |
| Name confusion with Caffeine / Caffeinated sleep-prevention apps | Medium | Landing page hero says 'coffee cup counter' in first sentence. Product Hunt tagline leads with the ambulance behavior. App name 'CaffeineBar' is distinct enough. |
| Low paid conversion — people happy with free tier | Medium | Ambulance sound gated in Pro. Cup 4 teaser: 'Something is about to happen. Unlock Pro to find out.' Delight the free user first — upsell after the 2nd weekly report. |
| No virality — ambulance reel does not spread | Medium | Seed 15 creators pre-launch. Post on all four platforms (Reels, X, Reddit, PH) simultaneously on day 1\. Multiple entry points outlast a single platform's algorithm. |
| Notarization / Gatekeeper rejection | Low-Medium | Allocate full Day 7 for notarization only. Use GitHub Actions notarize action (proven workflow). Test on a clean Mac before launch. |

# **10\. Open Questions**

## **Pre-build decisions**

* Should cup 3 escalation be silent (icon-only) or include a subtle audio cue? Recommendation: subtle audio — keeps the escalation curve smooth and sets up the paywall jump at cup 4\.

* Auto-mute during active calls: should this be on by default or opt-in? Recommendation: on by default. One ambulance during a client call is the most likely 1-star review trigger.

* Half-life default value: 5.5 hours is the scientific midpoint. Expose as 'slow / normal / fast metabolizer' in settings — not raw hours, which most users will not understand.

* Freemium gate: sounds only, or also dim icon states 4-6? Recommendation: gate sounds only. Seeing the skull icon for free is the hook that sells the Pro upgrade.

* Launch price: start at $7.99 or $9.99? Recommendation: launch at $7.99 and raise to $9.99 after 48 hours if demand is strong. SlapMac's $3 to $7 mid-launch worked — the price increase became its own content moment.

* Distribution: Polar.sh (recommended, aligned with indie dev community and git-scope audience) vs Gumroad. Polar has webhook support for license key generation and a 5% fee vs Gumroad's 10%.

## **Pre-launch marketing decisions**

* Which 15 creators to DM? Target: developer setup channels (5K-50K followers), macOS productivity accounts, indie hacker build-in-public accounts. Avoid mega-influencers — they have worse conversion rates than micro-creators for niche products.

* Should the pre-launch teaser post reveal the ambulance mechanic or stay vague? Recommendation: vague ('shipping something ridiculous') — preserve the surprise for the launch reel.

* Record ambulance reel on which app? Recommendation: QuickTime screen record \+ iMovie trim. Keep it raw and unpolished — staged-looking demos convert worse than genuine reactions.

## **Post-MVP**

* iCloud sync for streak data across Macs — useful for multi-Mac users, low build complexity.

* 'Decaf mode' — a toggle that counts herbal tea and other drinks. Widens ICP slightly.

* Annual Wrapped card in December — full-year caffeine report. Natural third Product Hunt launch moment.

* Shortcuts integration — cup logging via Apple Shortcuts. Good for press coverage (MacStories, 9to5Mac love Shortcuts content).

* Reddit ads test — $50-100 in r/macapps and r/productivity once organic has proven conversion rate. Do not run before this.

CaffeineBar PRD  |  v1.2  |  Bharath  |  May 2026