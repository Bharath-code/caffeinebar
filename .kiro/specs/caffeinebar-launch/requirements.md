# Requirements Document

## Introduction

This spec — **caffeinebar-launch** — covers the **launch program for CaffeineBar**: every non-product workstream that has to be in place to take the app from a notarized `.dmg` to a publicly traded conversation. It runs from Day -7 (asset production and creator seeding) through Day 1 (Product Hunt + multi-channel post) into the first 90 days of organic growth, paid-ad gating, success-metric tracking, and brand-risk mitigation.

This is the second of three companion specs:

- **caffeinebar-mvp** — The MVP product build. Covers the menu bar app itself, the Pro tier features, the bundled sound packs, the Polar.sh license flow, the call-aware audio engine, the accessibility audit, and the notarized `.dmg` distribution. It is referenced by this spec where launch artefacts (privacy policy URL, download link, license key flow) depend on it.
- **caffeinebar-launch** — *This document.* The pre-launch, launch-week, and 90-day growth playbook.
- **caffeinebar-ultra** — The post-MVP Ultra tier build (iCloud sync, Apple Health write, Apple Shortcuts, custom sound import, December Wrapped, Mac App Store distribution decision). Referenced by this spec only where launch decisions are explicitly deferred to Ultra (e.g. Apple Health marketing copy at MVP launch is forbidden because the integration itself lives in caffeinebar-ultra).

This document is **intentionally exhaustive within its scope**. It is the operating manual the founder runs from on launch week and the first 90 days; it is not a marketing strategy doc. Out of scope for this spec: any product feature requirement, code-level implementation detail, accessibility audit, notarization workflow, and any Ultra-tier feature.

Every requirement below uses EARS syntax. The system noun varies by requirement and is always defined in the Glossary — for marketing artefacts it is the artefact itself ("THE Ambulance reel SHALL...") and for process gates it is the operating role ("THE Launch operator SHALL...").

## Glossary

- **Launch operator**: The single human (the founder) executing the launch program against this document. Used as the system noun whenever a requirement is a manual operating step rather than a property of an artefact.
- **CaffeineBar**: The macOS menu bar app whose product surface is specified in **caffeinebar-mvp**. Referenced here only as the subject of marketing artefacts and as the destination of paid traffic.
- **Ambulance reel**: The 8–12 second screen recording of logging Cup 5, the ambulance siren firing, and the skull icon appearing in the MenuBarIcon. The single core viral asset for the entire launch program. Recorded on a real MacBook in natural light, no voiceover, no text overlay.
- **Recording method**: The end-to-end production pipeline for the Ambulance reel: QuickTime Player screen capture, iMovie trim, deliberately raw and unpolished output. Staged-looking demos convert worse than genuine reactions, so the requirement is to keep the asset rough.
- **Validation gate**: A pre-publication go/no-go check the Launch operator runs against an artefact before it ships. Specifically the "first-playback laugh test" for the Ambulance reel.
- **Aspect ratio variants**: The three rendered versions of the Ambulance reel — vertical 9:16 (Reels/TikTok), square 1:1 (X), and horizontal 16:9 (YouTube Shorts).
- **Asset lock**: The point in time after which an artefact's content is frozen. The Ambulance reel must reach asset lock at least 7 days before launch day.
- **Landing page**: The public web page hosted at `caffeinebar.app`. Hosts the hero copy, the embedded Ambulance reel, the pricing block, the email waitlist form, the Polar.sh checkout link, and a link to the privacy policy.
- **Hero copy**: The first headline sentence of the Landing page above the fold. Subject to the literal-phrase gate that mitigates name confusion with the existing "Caffeine" / "Caffeinated" sleep-prevention apps.
- **Waitlist form**: The email capture control on the Landing page, active before launch day and remaining live thereafter.
- **Polar.sh checkout link**: The HTTPS URL on `polar.sh` that initiates a CaffeineBar Pro or Ultra purchase. Wired into the Landing page pricing block. The license-key issuance behaviour itself is specified in **caffeinebar-mvp**; this document only specifies that the link is wired and pointed at the active price variant.
- **Typo redirect**: The `coffeebar.app` domain registered and configured to issue an HTTP 301 redirect to `caffeinebar.app`, intended to absorb traffic from users who mistype the brand.
- **Creator seeding**: The Day -7 outreach campaign in which the Launch operator sends a direct message to a curated list of micro-creators with a free Pro license key and the Ambulance reel attached, with no script and no demand for posting.
- **Micro-creator**: A creator with a follower count between 5,000 and 50,000 in the developer-setup, macOS-productivity, or indie-hacker build-in-public niches. Used in Creator seeding because micro-creators outperform mega-influencers on conversion for niche products.
- **Mega-influencer**: A creator with a follower count above 500,000. Excluded from Creator seeding by policy.
- **Creator tracker**: The local spreadsheet or note in which the Launch operator records, per seeded creator, the date contacted, whether they replied, and whether they posted organically.
- **Pre-launch teaser**: The single Day -1 X post from `@git-scope`, intentionally vague, that signals to the warm audience that something is shipping the next day. The teaser must not reveal the ambulance mechanic.
- **Product Hunt**: The third-party launch platform on which the CaffeineBar listing goes live at 12:01 AM PST on Day 1. The PH listing is the primary discovery surface for Day 1 traffic.
- **PH tagline**: The one-line tagline of the Product Hunt listing. Subject to a content gate that requires it to lead with the ambulance behaviour, not the category name "coffee tracker", as a name-confusion mitigation.
- **Office-hours engagement window**: The defined block of time during which the Launch operator commits to replying to every comment on every channel within 1 hour. Active on Day 1 from 12:01 AM PST through 11:59 PM PST.
- **Show HN**: The Day 3 or Day 4 Hacker News submission, framed as a technical build story (Swift, MenuBarExtra API), not a sales pitch. Title prefixed `Show HN:` per Hacker News convention.
- **Backup channel**: The pre-prepared `r/programming` "dev log" thread, kept ready in case the primary `r/macapps`, `r/SaaS`, or `r/IndieHackers` posts are removed for self-promotion-rule violations.
- **A/B price test**: The launch-time pricing experiment in which 50% of Landing-page traffic is shown a Pro price of $7.99 and 50% is shown a Pro price of $9.99. Resolved at +48 hours by the price-test decision rule.
- **Price-test decision rule**: At +48 hours post-launch, if the conversion rate of the $7.99 variant minus the conversion rate of the $9.99 variant is less than 5 percentage points, the Launch operator ships at $9.99. Otherwise the operator holds at $7.99 for 14 more days and re-evaluates.
- **Anti-ICP**: The set of audiences and positionings explicitly disallowed in launch copy. Specifically: wellness, sleep-prevention, clinical caffeine-management, or "drink less" messaging.
- **About page**: A public page on `caffeinebar.app` whose sole purpose is to differentiate CaffeineBar from the existing "Caffeine" sleep-prevention app in plain language.
- **Paid spend gate**: The process gate that prevents any paid advertising spend until a 7-day organic conversion baseline has been recorded above 5%.
- **Organic conversion baseline**: The rolling conversion rate from Landing-page visit to Pro purchase, computed across the most recent 7 days, with no contribution from paid traffic.
- **Cup-4+ trigger rate**: The fraction of active users on a given day whose Cup count reached 4 or higher at any point that day. Target ≥35%. Defined in Improvement_plan.md §Success Metrics Refinement.
- **Pro paid conversion**: The fraction of users who hit Cup 4 in any session and subsequently purchased the Pro tier. Target ≥25%.
- **Ambulance share rate**: The fraction of Cup-5 events that result in the user generating a public social share (e.g. a `#CaffeineBar` post). Target ≥15%.
- **Day-7 retention**: The fraction of users who logged at least one cup on Day 1 and also logged at least one cup on Day 7. Target ≥45%.
- **Accessibility-feature-usage rate**: The fraction of users who have enabled at least one of the accessibility-related preferences (high-contrast mode, increased contrast variant, Reduce Motion compliance reliance). Target ≥8%.
- **Leading indicator**: A metric the Launch operator reviews on a weekly cadence to predict whether the 30-day and 90-day PRD targets will be met. Distinct from the headline PRD §1.4 metrics which are reviewed at the 30-day and 90-day cutoffs.
- **30-day target set**: The PRD §1.4 metrics evaluated at Day 30 — 300 installs, 100 DAU, 40 paid conversions, $500 revenue, 20 `#CaffeineBar` social posts.
- **90-day target set**: The PRD §1.4 metrics evaluated at Day 90 — 2,000 installs, 800 DAU, 300 paid conversions, $4,000 revenue, 200 `#CaffeineBar` social posts.
- **Recap post**: The public revenue-and-retention post the Launch operator publishes on LinkedIn and X at Day 30 and Day 90.
- **Trademark search**: The pre-launch USPTO and TESS lookup for the literal mark "CaffeineBar" in the macOS-app trademark class, completed and recorded before the public launch.
- **Sound provenance archive**: The off-repository, secured store of voice-talent contracts, signed releases, and original session recordings for every voice asset that ships in marketing material.

---

## Requirements

## Section A — Core Viral Asset Production

### Requirement 1: Ambulance reel content and recording specification

**User Story:** As the Launch operator, I want a single core viral asset captured to a strict, repeatable spec, so that every downstream channel posts the same proven 8–12 second clip rather than improvising new angles per platform.

#### Acceptance Criteria

1. THE Ambulance reel SHALL have a duration between 8 seconds and 12 seconds, inclusive.
2. THE Ambulance reel SHALL depict, in this order, the user logging Cup 5 in the Popover, the ambulance siren firing, and the skull MenuBarIcon appearing in the macOS menu bar.
3. THE Ambulance reel SHALL be recorded on a real, non-virtualized MacBook in natural light without studio lighting.
4. THE Ambulance reel SHALL contain no voiceover audio track.
5. THE Ambulance reel SHALL contain no on-screen text overlay, lower third, caption track, or watermark.
6. THE Ambulance reel SHALL preserve the original ambulance siren audio at the system output volume captured during recording.

### Requirement 2: Recording method and tooling

**User Story:** As the Launch operator, I want the recording pipeline locked to QuickTime plus iMovie trim, so that the asset stays deliberately rough and looks like a screen recording a friend would send.

#### Acceptance Criteria

1. THE Launch operator SHALL capture the Ambulance reel using QuickTime Player's screen recording feature.
2. THE Launch operator SHALL trim the captured recording using iMovie.
3. THE Launch operator SHALL NOT apply third-party motion graphics, transitions, color grading, or post-production effects to the Ambulance reel.
4. THE Launch operator SHALL NOT re-record the Ambulance reel in a studio environment or with a hardware capture rig.

### Requirement 3: Validation gate — first-playback laugh test

**User Story:** As the Launch operator, I want a hard internal gate that vetoes the launch angle if the asset does not work on me, so that I do not invest a launch week behind a reel that does not land.

#### Acceptance Criteria

1. WHEN the first cut of the Ambulance reel is complete, THE Launch operator SHALL play it back from the start one time.
2. IF the Launch operator does not laugh during that first playback, THEN THE Launch operator SHALL rework the launch angle and re-record the Ambulance reel before producing any further launch artefacts.
3. THE Launch operator SHALL NOT proceed to producing the aspect-ratio variants, the Landing page hero embed, or any creator outreach until the validation gate has been passed.

### Requirement 4: Aspect ratio variants

**User Story:** As the Launch operator, I want three rendered variants of the locked reel, so that each social platform receives a copy that fits its preview surface natively.

#### Acceptance Criteria

1. THE Launch operator SHALL produce a 9:16 vertical variant of the Ambulance reel for Instagram Reels and TikTok.
2. THE Launch operator SHALL produce a 1:1 square variant of the Ambulance reel for X.
3. THE Launch operator SHALL produce a 16:9 horizontal variant of the Ambulance reel for YouTube Shorts.
4. THE three aspect-ratio variants SHALL be derived from the same locked source recording and SHALL NOT be re-recorded per platform.

### Requirement 5: Asset lock deadline

**User Story:** As the Launch operator, I want the Ambulance reel finalised seven days before launch day, so that creators receive the seeding kit with enough lead time to post on Day 1.

#### Acceptance Criteria

1. THE Ambulance reel SHALL reach asset lock at least 7 calendar days before launch day.
2. WHILE the Ambulance reel is at asset lock, THE Launch operator SHALL NOT alter the source recording, the trim points, or the aspect-ratio variants.
3. IF a substantive content change to the Ambulance reel is required after asset lock, THEN THE Launch operator SHALL postpone launch day until 7 calendar days after the new asset lock.

---

## Section B — Landing Page (caffeinebar.app)

### Requirement 6: Hero copy literal-phrase gate

**User Story:** As a visitor who searched "caffeine mac app" and might have meant the sleep-prevention tool, I want the first sentence of the landing page to be unambiguous about what this product is, so that I leave fast if it is not what I want and stay if it is.

#### Acceptance Criteria

1. THE Landing page SHALL display the literal phrase "coffee cup counter" within the first sentence of its hero copy.
2. THE Landing page hero copy SHALL render above the fold at a viewport width of 1280px and at common mobile viewport widths (375px, 390px, 414px).
3. THE Landing page SHALL NOT use the words "wellness", "sleep", "sleep prevention", "stay awake", or "energy drink" in its hero copy.

### Requirement 7: Hero embed of the Ambulance reel

**User Story:** As a visitor landing above the fold, I want the ambulance moment to play automatically and silently, so that I get the joke without having to click anything and without scaring my colleagues.

#### Acceptance Criteria

1. THE Landing page hero SHALL embed the 16:9 horizontal variant of the Ambulance reel.
2. THE embedded Ambulance reel SHALL autoplay on page load.
3. THE embedded Ambulance reel SHALL be muted by default.
4. THE embedded Ambulance reel SHALL loop continuously.
5. WHEN the visitor clicks the embedded Ambulance reel, THE Landing page SHALL unmute the audio track.

### Requirement 8: Pricing block

**User Story:** As a visitor ready to buy, I want pricing displayed clearly with both tiers visible, so that I can make a decision without scrolling through marketing.

#### Acceptance Criteria

1. THE Landing page SHALL display a Pro tier price.
2. WHILE the A/B price test is active AND the visitor is bucketed to the high variant, THE Landing page SHALL display the Pro tier price as `$9.99`.
3. WHILE the A/B price test is active AND the visitor is bucketed to the low variant, THE Landing page SHALL display the Pro tier price as `$7.99`.
4. THE Landing page SHALL display the Ultra tier price as `$14.99`.
5. THE Landing page SHALL label both prices as "one-time" and SHALL NOT use the words "subscription", "monthly", or "per month".

### Requirement 9: Email waitlist capture

**User Story:** As a visitor who arrives before launch day, I want to leave an email address, so that I am notified when the app ships and the founder owns a pre-launch audience that does not depend on platform algorithms.

#### Acceptance Criteria

1. THE Landing page SHALL display the Waitlist form above the fold.
2. THE Waitlist form SHALL be live and accepting submissions before launch day.
3. THE Waitlist form SHALL collect at minimum a single email-address field.
4. WHEN a visitor submits the Waitlist form, THE Landing page SHALL display a confirmation message acknowledging the submission.
5. THE Waitlist form SHALL remain live on launch day and thereafter.

### Requirement 10: Polar.sh checkout wiring

**User Story:** As a visitor who clicks "Buy Pro", I want to land directly on a working checkout for the price I was just shown, so that the purchase intent does not decay during a redirect chase.

#### Acceptance Criteria

1. THE Landing page pricing block SHALL link the Pro tier price to a Polar.sh checkout link configured for the active A/B price variant served to the visitor.
2. THE Landing page pricing block SHALL link the Ultra tier price to a Polar.sh checkout link configured for the Ultra tier.
3. WHEN the A/B price test resolves, THE Launch operator SHALL update the Pro tier checkout link to point at the single resolved-price Polar.sh checkout.

### Requirement 11: Privacy policy and download link live before launch

**User Story:** As a visitor on launch day, I want a working download link and a discoverable privacy policy, so that I can install the app and Polar.sh has the legal page it requires for checkout.

#### Acceptance Criteria

1. THE Landing page SHALL link to a privacy policy hosted at a stable `caffeinebar.app` URL.
2. THE Landing page SHALL link to the notarized `.dmg` of CaffeineBar as the download artefact.
3. THE privacy policy and the download link SHALL be live and reachable from the Landing page no later than 24 hours before launch day.

### Requirement 12: Typo redirect domain

**User Story:** As a visitor who typed `coffeebar.app` because they misheard the brand, I want to land on `caffeinebar.app` automatically, so that no traffic is lost to the typo.

#### Acceptance Criteria

1. THE Launch operator SHALL register the domain `coffeebar.app` and SHALL maintain it as an asset of the Launch operator.
2. THE `coffeebar.app` domain SHALL respond to all HTTP and HTTPS requests with an HTTP 301 redirect to the corresponding path on `caffeinebar.app`.
3. THE 301 redirect from `coffeebar.app` SHALL be live no later than 24 hours before launch day.

---

## Section C — Pre-Launch Creator Seeding (Day -7)

### Requirement 13: Creator selection — fifteen micro-creators

**User Story:** As the Launch operator, I want a curated list of fifteen micro-creators in three niches, so that the seeding budget hits high-conversion audiences and avoids wasted licenses.

#### Acceptance Criteria

1. THE Launch operator SHALL identify exactly 15 micro-creators for Creator seeding.
2. Each identified Micro-creator SHALL have a follower count of at least 5,000 and at most 50,000 on the creator's primary platform.
3. THE 15 Micro-creators SHALL be distributed across three niches: developer-setup creators, macOS-productivity creators, and indie-hacker build-in-public creators.
4. THE Launch operator SHALL NOT include any Mega-influencer in the Creator seeding list.
5. THE Launch operator SHALL complete identification of all 15 Micro-creators no later than Day -7.

### Requirement 14: Direct-message contents

**User Story:** As a seeded creator, I want a free Pro license key and the reel attached to the message, so that I can install the app, see the joke, and decide to post without any back-and-forth.

#### Acceptance Criteria

1. WHEN the Launch operator sends a Creator seeding direct message to a Micro-creator, THE direct message SHALL include exactly one Pro tier license key valid for the Micro-creator's machine.
2. WHEN the Launch operator sends a Creator seeding direct message to a Micro-creator, THE direct message SHALL include the aspect-ratio variant of the Ambulance reel matching the Micro-creator's primary platform.
3. WHEN the Launch operator sends a Creator seeding direct message to a Micro-creator, THE direct message SHALL include the Landing page URL `caffeinebar.app`.

### Requirement 15: No script policy

**User Story:** As a seeded creator, I want to post in my own voice or not at all, so that the audience trusts the recommendation as authentic.

#### Acceptance Criteria

1. THE Creator seeding direct message SHALL NOT contain a script, suggested caption, hashtag list, or required posting copy.
2. THE Creator seeding direct message SHALL NOT contain a posting deadline or any obligation to post.
3. THE Launch operator SHALL NOT condition the validity of the Pro license key on the Micro-creator posting any content.

### Requirement 16: Mega-influencer exclusion

**User Story:** As the Launch operator, I want the seeding list capped at micro-creators by policy, so that I do not chase low-conversion celebrity reach when a niche product needs niche credibility.

#### Acceptance Criteria

1. WHILE Creator seeding is active, THE Launch operator SHALL NOT contact any creator with a follower count above 500,000 on the creator's primary platform for the purpose of Creator seeding.
2. IF a Mega-influencer voluntarily reaches out to the Launch operator regarding CaffeineBar, THEN THE Launch operator MAY respond outside the Creator seeding program but SHALL NOT count that response against the 15-creator Creator seeding target.

### Requirement 17: Creator response and posting tracker

**User Story:** As the Launch operator, I want a per-creator log of who replied and who posted, so that on Day 3 I know exactly which accounts to retweet and which to follow up with.

#### Acceptance Criteria

1. THE Launch operator SHALL maintain a Creator tracker for the 15 seeded Micro-creators.
2. THE Creator tracker SHALL record, for each Micro-creator, the date contacted, whether the Micro-creator replied, and whether the Micro-creator posted organic content referencing CaffeineBar.
3. THE Launch operator SHALL update the Creator tracker daily from Day -7 through Day 14.

---

## Section D — Pre-Launch Teaser (Day -1)

### Requirement 18: Single teaser post on X

**User Story:** As a follower of `@git-scope`, I want a single vague signal that something is shipping tomorrow, so that I am primed to amplify Day 1 without knowing what it is.

#### Acceptance Criteria

1. THE Launch operator SHALL publish exactly one Pre-launch teaser post from the `@git-scope` X account on Day -1.
2. THE Pre-launch teaser post SHALL contain copy in the spirit of "shipping something ridiculous tomorrow".
3. THE Launch operator SHALL NOT publish any other CaffeineBar-related post from `@git-scope` between the Pre-launch teaser and the Day 1 launch post.

### Requirement 19: Pre-launch teaser content gate — no ambulance reveal

**User Story:** As a Day 1 viewer of the Ambulance reel, I want the punchline to be brand new to me, so that the laugh on first viewing is real.

#### Acceptance Criteria

1. THE Pre-launch teaser post SHALL NOT mention the word "ambulance".
2. THE Pre-launch teaser post SHALL NOT mention the words "siren", "skull", "Cup 5", or "Cup five".
3. THE Pre-launch teaser post SHALL NOT include any frame, still image, or audio clip from the Ambulance reel.
4. THE Pre-launch teaser post SHALL NOT include the literal phrase "coffee cup counter".

### Requirement 20: Existing community notification

**User Story:** As a member of the existing git-scope community (newsletter, X audience), I want a heads-up that a Product Hunt launch is coming, so that I can vote and comment in the first 30 minutes when it matters most.

#### Acceptance Criteria

1. THE Launch operator SHALL notify the existing git-scope newsletter audience on Day -1 to expect a Product Hunt launch on Day 1.
2. THE Launch operator SHALL notify the existing git-scope X audience on Day -1 to expect a Product Hunt launch on Day 1.
3. THE Day -1 community notifications SHALL NOT reveal the ambulance mechanic and SHALL comply with Requirement 19.

### Requirement 21: Product Hunt submission timing

**User Story:** As the Launch operator, I want the Product Hunt listing submitted the night before so it goes live the moment Day 1 starts in PST, so that I capture the entire PH-PST traffic day.

#### Acceptance Criteria

1. THE Launch operator SHALL submit the CaffeineBar Product Hunt listing at 11:30 PM PST on Day -1.
2. THE Product Hunt listing SHALL be configured to go live at 12:01 AM PST on Day 1.

---

## Section E — Launch Day (Day 1, Tuesday)

### Requirement 22: Product Hunt listing live and tagline gate

**User Story:** As a Product Hunt visitor scanning the leaderboard, I want the tagline to lead with the joke not the category, so that name confusion with the "Caffeine" sleep-prevention app does not steal my click.

#### Acceptance Criteria

1. THE Product Hunt listing SHALL go live at 12:01 AM PST on Day 1.
2. THE PH tagline SHALL describe the ambulance behaviour as the leading idea (e.g. "Your Mac calls an ambulance at cup 5").
3. THE PH tagline SHALL NOT lead with the words "coffee tracker", "caffeine tracker", or "caffeine app".
4. THE PH tagline SHALL NOT contain the words "wellness" or "sleep".

### Requirement 23: Simultaneous social posting of the Ambulance reel

**User Story:** As the Launch operator, I want the reel hitting Reels, X, and TikTok at the same moment as PH goes live, so that the algorithms light up together and cross-platform reposts feed each other.

#### Acceptance Criteria

1. THE Launch operator SHALL publish the 9:16 vertical variant of the Ambulance reel to Instagram Reels on Day 1.
2. THE Launch operator SHALL publish the 1:1 square variant of the Ambulance reel to X on Day 1.
3. THE Launch operator SHALL publish the 9:16 vertical variant of the Ambulance reel to TikTok on Day 1.
4. THE three Day 1 social posts SHALL each link to `caffeinebar.app` either in the post body or in the first pinned comment.

### Requirement 24: Reddit posting on three subreddits

**User Story:** As a Reddit visitor on r/macapps, I want to read a post that sounds like a developer telling a story not a marketer running a campaign, so that I do not flag it for self-promotion.

#### Acceptance Criteria

1. THE Launch operator SHALL publish one post to `r/macapps` on Day 1.
2. THE Launch operator SHALL publish one post to `r/SaaS` on Day 1.
3. THE Launch operator SHALL publish one post to `r/IndieHackers` on Day 1.
4. Each Day 1 Reddit post SHALL be framed in the first person as "I built this because I couldn't find it" and SHALL NOT be framed as a direct sales pitch.

### Requirement 25: Warm-audience upvote and comment recruitment

**User Story:** As the Launch operator, I want ten committed voters and commenters in the first thirty minutes, so that the PH listing gains the early momentum that drives later organic reach.

#### Acceptance Criteria

1. THE Launch operator SHALL recruit at least 10 git-scope community members ahead of Day 1 to upvote the CaffeineBar Product Hunt listing within the first 30 minutes after it goes live.
2. THE Launch operator SHALL recruit those community members ahead of Day 1 to leave at least one substantive comment each on the Product Hunt listing within the first 30 minutes after it goes live.
3. THE Launch operator SHALL NOT offer monetary compensation in exchange for upvotes or comments.

### Requirement 26: Office-hours engagement window

**User Story:** As a launch-day commenter on any channel, I want a real reply from the founder within an hour, so that the human-touch signal compounds into more comments.

#### Acceptance Criteria

1. WHILE the Office-hours engagement window is active, THE Launch operator SHALL reply to every public comment received on the Product Hunt listing within 1 hour of the comment being posted.
2. WHILE the Office-hours engagement window is active, THE Launch operator SHALL reply to every public comment received on the Day 1 X, Instagram Reels, and TikTok posts within 1 hour of the comment being posted.
3. WHILE the Office-hours engagement window is active, THE Launch operator SHALL reply to every public comment received on the Day 1 Reddit posts within 1 hour of the comment being posted.
4. THE Office-hours engagement window SHALL run from 12:01 AM PST on Day 1 through 11:59 PM PST on Day 1.

### Requirement 27: Social-post peak scheduling at 9 AM PST

**User Story:** As the Launch operator, I want the highest-effort social pushes scheduled to peak when PH traffic peaks, so that the click-through funnels stack instead of competing.

#### Acceptance Criteria

1. THE Launch operator SHALL schedule a follow-up Day 1 push of the Ambulance reel and the PH listing on X to publish at 9:00 AM PST.
2. THE Launch operator SHALL schedule a follow-up Day 1 push of the Ambulance reel on Instagram Reels to publish at 9:00 AM PST.
3. THE 12:01 AM PST PH go-live and the 9:00 AM PST social peak SHALL both occur on Day 1 and SHALL NOT be merged into a single posting moment.

### Requirement 28: Reddit self-promotion engagement window

**User Story:** As a moderator of r/macapps, I want the founder to participate as a community member before mentioning prices, so that I do not have to remove the post under the self-promotion rule.

#### Acceptance Criteria

1. WHILE the first 48 hours after each Day 1 Reddit post are in progress, THE Launch operator SHALL engage in the comment threads in a non-sales manner and SHALL NOT mention the Pro tier price, the Ultra tier price, or any discount in any thread.
2. AFTER 48 hours have elapsed since each Day 1 Reddit post, THE Launch operator MAY mention the Pro tier price and the Ultra tier price in subsequent replies on the same thread.

---

## Section F — Post-Launch Days 2 to 4

### Requirement 29: Day 2 — first 24-hour revenue screenshot

**User Story:** As the Launch operator, I want the 24-hour revenue posted with specific numbers, so that the proof-of-traction becomes its own content.

#### Acceptance Criteria

1. THE Launch operator SHALL publish on Day 2 a single X post containing a screenshot of CaffeineBar's first 24-hour revenue.
2. THE Day 2 revenue post SHALL state the specific dollar revenue figure for the first 24 hours.
3. THE Day 2 revenue post SHALL state the specific install count for the first 24 hours.
4. THE Day 2 revenue post SHALL NOT use vague language such as "thousands of dollars" or "lots of installs" in place of the specific figures.

### Requirement 30: Day 2 — public creator discount activation

**User Story:** As a viewer who saw the reel and now wants to participate, I want a clear public mechanism to earn a free sound pack by posting my own ambulance moment, so that the viral loop has a concrete entry point on Day 2.

#### Acceptance Criteria

1. THE Launch operator SHALL publish on Day 2 a public post announcing that any user who shares a `#CaffeineBar` ambulance moment will receive a free sound pack via direct message.
2. WHEN a user publicly posts content tagged `#CaffeineBar` on Day 2 or later, THE Launch operator SHALL direct-message that user a redemption code or a direct download for one of the four bundled sound packs within 48 hours of the user's post.

### Requirement 31: Day 3 or Day 4 — Show HN submission

**User Story:** As a Hacker News reader, I want to read about the Swift / MenuBarExtra build choices not a sales pitch, so that I can engage with the technical story.

#### Acceptance Criteria

1. THE Launch operator SHALL publish a Show HN submission on Hacker News on Day 3 or Day 4.
2. THE Show HN title SHALL begin with the prefix `Show HN:`.
3. THE Show HN submission body SHALL describe the technical build (Swift, SwiftUI, MenuBarExtra API) and SHALL NOT be framed as a sales pitch.
4. THE Show HN submission SHALL link to `caffeinebar.app` and SHALL NOT link directly to a Polar.sh checkout link.

### Requirement 32: Day 3 to Day 4 — personal retweet of every creator post

**User Story:** As a creator who posted a `#CaffeineBar` moment, I want the founder to retweet it personally within an hour, so that my audience sees official acknowledgement and the signal reaches the founder's audience too.

#### Acceptance Criteria

1. WHEN a creator publishes a public post containing the hashtag `#CaffeineBar` on Day 3 or Day 4, THE Launch operator SHALL retweet or quote-retweet that post from the founder's primary X account within 1 hour of the creator's post.

### Requirement 33: Day 3 to Day 4 — A/B price-test resolution and content moment

**User Story:** As the Launch operator, I want a clear arithmetic rule for resolving the price test, and I want the resolution itself published as content if the test passes the threshold, so that the price change becomes its own news cycle.

#### Acceptance Criteria

1. AT exactly +48 hours after the Day 1 launch moment, THE Launch operator SHALL evaluate the A/B price test using the Price-test decision rule.
2. WHEN the conversion rate observed at $7.99 minus the conversion rate observed at $9.99 is strictly less than 5 percentage points, THE Launch operator SHALL ship CaffeineBar Pro at $9.99 and SHALL update the Landing page pricing block to display $9.99 only.
3. WHEN the conversion rate observed at $7.99 minus the conversion rate observed at $9.99 is greater than or equal to 5 percentage points, THE Launch operator SHALL hold the Pro tier price at $7.99 for 14 additional calendar days and SHALL re-evaluate the price test at that 14-day mark.
4. WHEN the Launch operator raises the Pro tier price from $7.99 to $9.99 under Requirement 33-2, THE Launch operator SHALL publish a public X post announcing the price increase and framing it as a "It's working — raising the price" content moment.

### Requirement 34: Backup distribution channel — r/programming dev log

**User Story:** As the Launch operator, I want a pre-prepared backup post on r/programming, so that if the primary subreddit threads are removed for self-promotion, the day's distribution does not collapse.

#### Acceptance Criteria

1. THE Launch operator SHALL prepare, no later than Day -1, a Backup channel post draft for `r/programming` framed as a "dev log" of the CaffeineBar build journey.
2. IF any of the Day 1 Reddit posts on `r/macapps`, `r/SaaS`, or `r/IndieHackers` is removed by moderators for self-promotion-rule violation, THEN THE Launch operator SHALL publish the prepared `r/programming` Backup channel post within 24 hours of the removal.
3. THE Backup channel post SHALL be framed around the build journey (Swift, MenuBarExtra, the 7-day build) and SHALL NOT be framed as a direct sales pitch.

---

## Section G — Week 2 and Beyond Engagement

### Requirement 35: Week 2 — second sound-pack content moment

**User Story:** As an audience member who saw the launch reel two weeks ago, I want a fresh news cycle around a sound pack highlight, so that the second wave of coverage has its own hook.

#### Acceptance Criteria

1. THE Launch operator SHALL publish a second-cycle content moment in Week 2 highlighting one of the bundled sound packs (e.g. "Your Mom Pack").
2. THE Week 2 content moment SHALL include a video or audio clip of the highlighted sound pack's escalation set.
3. THE Week 2 content moment SHALL be published on at least Instagram Reels and X.

### Requirement 36: Week 2 — seven-day revenue total on LinkedIn

**User Story:** As a LinkedIn audience member, I want a candid build-and-ship recap with real numbers, so that the post reads as a peer story and not a humblebrag.

#### Acceptance Criteria

1. THE Launch operator SHALL publish a single LinkedIn post in Week 2 containing the 7-day total revenue for CaffeineBar.
2. THE Week 2 LinkedIn post SHALL be framed in the spirit of "I built a silly Mac app. Here's what happened."
3. THE Week 2 LinkedIn post SHALL state the specific 7-day revenue figure and SHALL NOT use rounded or vague figures.

### Requirement 37: Weekly cadence of user-ambulance-moment posts

**User Story:** As the Launch operator, I want a steady drumbeat of user-generated ambulance moment posts, so that the brand stays in the timeline between major drops.

#### Acceptance Criteria

1. STARTING in Week 2, THE Launch operator SHALL publish at least one X post per calendar week highlighting a user-submitted ambulance moment.
2. THE weekly user-ambulance-moment posts SHALL credit the original creator of the user-submitted content.

### Requirement 38: Paid-ad timing gate — never before Day 14

**User Story:** As the Launch operator, I want paid ads forbidden until Day 14, so that organic conversion is proven before any spend decisions.

#### Acceptance Criteria

1. THE Launch operator SHALL NOT spend any budget on paid advertising for CaffeineBar before Day 14.
2. WHEN Day 14 has elapsed AND the Paid spend gate has been satisfied, THE Launch operator MAY initiate a Reddit ads test in `r/macapps` and `r/productivity` capped at an initial budget between $50 and $100, inclusive.

---

## Section H — Paid Advertising Constraints (Risk Mitigation)

### Requirement 39: No paid ads at launch — organic-only baseline

**User Story:** As the Launch operator, I want a hard rule that there is zero paid ad spend at launch, so that the conversion-rate signal we measure is purely organic.

#### Acceptance Criteria

1. THE Launch operator SHALL NOT run any paid ad placement on any platform for CaffeineBar between Day -7 and Day 14.
2. WHILE the Organic conversion baseline has not been recorded above 5% across a continuous 7-day window, THE Launch operator SHALL NOT initiate paid ad spend on any platform.

### Requirement 40: Meta and Instagram ads — amplification only

**User Story:** As the Launch operator, I want Meta and Instagram ad spend restricted to amplifying organic posts that are already converting, so that the platform with the worst native CPC for productivity apps does not bleed budget on cold acquisition.

#### Acceptance Criteria

1. THE Launch operator SHALL NOT run a Meta or Instagram ad campaign that targets cold audiences for CaffeineBar.
2. WHERE an organic Instagram or X post has already achieved a measured Pro paid conversion rate above the Organic conversion baseline threshold of 5%, THE Launch operator MAY use Meta or Instagram paid amplification of that specific post.

### Requirement 41: Reddit ads — capped post-Day-14 test only

**User Story:** As the Launch operator, I want Reddit ad spend strictly capped to a post-Day-14 test in two named subreddits, so that the first paid experiment cannot exceed $100.

#### Acceptance Criteria

1. THE Launch operator SHALL NOT spend on Reddit ads before Day 14.
2. WHEN the Launch operator initiates Reddit ad spend on or after Day 14, THE Launch operator SHALL cap the initial test budget at no more than $100 total across `r/macapps` and `r/productivity` combined.
3. THE Launch operator SHALL NOT target subreddits other than `r/macapps` and `r/productivity` during the initial Reddit ads test.

### Requirement 42: Google Ads and Apple Search Ads — disallowed at launch

**User Story:** As the Launch operator, I want Google Ads and ASA explicitly off the table at launch, so that I do not pay for keywords that have zero search volume.

#### Acceptance Criteria

1. THE Launch operator SHALL NOT spend on Google Ads for CaffeineBar between Day -7 and Day 180.
2. THE Launch operator SHALL NOT spend on Apple Search Ads for CaffeineBar between Day -7 and Day 180.
3. AT Day 180, THE Launch operator SHALL re-evaluate Google Ads and Apple Search Ads on the basis of measured branded-search volume.

### Requirement 43: Paid spend gate — process control

**User Story:** As the Launch operator, I want every dollar of paid spend to pass through a single 7-day organic baseline gate, so that we never run paid acquisition against an unproven funnel.

#### Acceptance Criteria

1. THE Launch operator SHALL NOT initiate any paid ad spend on any platform until the Organic conversion baseline has been recorded above 5% across a continuous 7-day window.
2. THE Launch operator SHALL retain a written record of the 7-day Organic conversion baseline window (start date, end date, observed conversion rate) for every paid spend decision.

---

## Section I — Success Metrics and Tracking

### Requirement 44: PRD §1.4 baseline metric tracking

**User Story:** As the Launch operator, I want the PRD's headline 30-day and 90-day numbers tracked exactly as specified in the PRD, so that the public targets and the internal targets do not drift.

#### Acceptance Criteria

1. THE Launch operator SHALL track the following 30-day target set: 300 installs, 100 daily active users, 40 Pro paid conversions, $500 revenue, 20 `#CaffeineBar` social posts.
2. THE Launch operator SHALL track the following 90-day target set: 2,000 installs, 800 daily active users, 300 Pro paid conversions, $4,000 revenue, 200 `#CaffeineBar` social posts.
3. THE Launch operator SHALL evaluate the 30-day target set at Day 30 and SHALL evaluate the 90-day target set at Day 90.

### Requirement 45: Leading indicator targets

**User Story:** As the Launch operator, I want a fixed set of leading indicators with explicit targets, so that the weekly review is the same conversation every week.

#### Acceptance Criteria

1. THE Launch operator SHALL track Cup-4+ trigger rate weekly, with a target of greater than or equal to 35% of active users.
2. THE Launch operator SHALL track Pro paid conversion among users who hit Cup 4 weekly, with a target of greater than or equal to 25%.
3. THE Launch operator SHALL track Ambulance share rate weekly, with a target of greater than or equal to 15% of Cup-5 events shared publicly.
4. THE Launch operator SHALL track Day-7 retention weekly, with a target of greater than or equal to 45%.
5. THE Launch operator SHALL track Accessibility-feature-usage rate weekly, with a target of greater than or equal to 8%.

### Requirement 46: Weekly review cadence

**User Story:** As the Launch operator, I want a fixed weekly review of leading indicators and targets, so that drift on any one indicator is caught within seven days.

#### Acceptance Criteria

1. THE Launch operator SHALL conduct a leading-indicator review once per calendar week, on the same weekday each week.
2. THE weekly leading-indicator review SHALL compare the latest measured value of each Leading indicator from Requirement 45 against its target.
3. WHEN any Leading indicator is below its target for two consecutive weekly reviews, THE Launch operator SHALL document a specific corrective action against that Leading indicator before the third weekly review.

### Requirement 47: Privacy-preserving analytics framework boundary

**User Story:** As the Launch operator, I want the launch spec to defer the analytics data-flow design to the MVP spec, so that there is exactly one source of truth for what data is collected and how.

#### Acceptance Criteria

1. THE Launch operator SHALL rely on the privacy-preserving, opt-in usage analytics framework specified in the **caffeinebar-mvp** Privacy Policy requirement as the single source of truth for what data is collected, how it is collected, and what consent surface the user sees.
2. THE Launch operator SHALL NOT introduce a separate analytics pipeline in the launch program that collects user data outside the framework specified in **caffeinebar-mvp**.
3. THE Launch operator SHALL track the metric thresholds and weekly review cadence in this document (Requirements 44 through 46) using the data exposed by the **caffeinebar-mvp** analytics framework.

### Requirement 48: A/B price-test decision rule encoding

**User Story:** As the Launch operator, I want the A/B price test decision rule restated as a single explicit, arithmetically testable acceptance criterion, so that it cannot be subjectively interpreted on Day 3.

#### Acceptance Criteria

1. AT exactly +48 hours after the Day 1 launch moment, THE Launch operator SHALL compute the value `(conversion rate at $7.99) − (conversion rate at $9.99)` expressed in percentage points.
2. WHEN the computed value is strictly less than 5 percentage points, THE Launch operator SHALL set the Pro tier price to $9.99 going forward.
3. WHEN the computed value is greater than or equal to 5 percentage points, THE Launch operator SHALL hold the Pro tier price at $7.99 for 14 additional calendar days and SHALL re-run the same computation at the end of that 14-day window.

---

## Section J — Name Confusion and Brand Risk Mitigation

### Requirement 49: Hero-copy gate (cross-reference)

**User Story:** As the Launch operator, I want the Section J brand-risk frame to explicitly reference the Section B hero-copy gate, so that the mitigation lives in exactly one normative place.

#### Acceptance Criteria

1. THE name-confusion mitigation for Landing page hero copy SHALL be the literal-phrase requirement defined in Requirement 6, and Requirement 6 SHALL be considered the single normative source for that mitigation.

### Requirement 50: Product Hunt tagline gate (cross-reference)

**User Story:** As the Launch operator, I want the Section J brand-risk frame to explicitly reference the Section E PH tagline gate, so that the mitigation lives in exactly one normative place.

#### Acceptance Criteria

1. THE name-confusion mitigation for the Product Hunt tagline SHALL be the leading-with-ambulance-behaviour requirement defined in Requirement 22, and Requirement 22 SHALL be considered the single normative source for that mitigation.

### Requirement 51: Anti-ICP positioning constraint

**User Story:** As a wellness-anxious visitor, I want CaffeineBar's launch copy to not target me, so that the product never gets confused with a sleep-prevention or quit-caffeine tool.

#### Acceptance Criteria

1. THE Launch operator SHALL NOT position CaffeineBar as a wellness tool in any launch artefact.
2. THE Launch operator SHALL NOT position CaffeineBar as a sleep-prevention tool in any launch artefact.
3. THE Launch operator SHALL NOT use the words "wellness", "sleep prevention", "quit caffeine", "cut down", or "drink less" in the Landing page copy, the Product Hunt listing, the Day 1 social posts, or the Show HN submission.

### Requirement 52: About page differentiation from "Caffeine"

**User Story:** As a visitor who has actually used the "Caffeine" sleep-prevention app, I want a dedicated public page that explains in plain language how CaffeineBar is different, so that I can decide quickly whether this product is the one I am looking for.

#### Acceptance Criteria

1. THE Landing page SHALL link to a publicly accessible About page hosted at a stable `caffeinebar.app` URL.
2. THE About page SHALL describe in plain language how CaffeineBar differs from the "Caffeine" sleep-prevention macOS app.
3. THE About page SHALL state explicitly that CaffeineBar does not prevent the Mac from sleeping.
4. THE About page SHALL be live and reachable from the Landing page no later than 24 hours before launch day.

---

## Section K — Compliance and Legal

### Requirement 53: Privacy policy stable URL hosting

**User Story:** As the Polar.sh checkout integration, I want the privacy policy hosted at a stable URL on the brand domain, so that the checkout meets its third-party-processor compliance requirement.

#### Acceptance Criteria

1. THE Launch operator SHALL host the CaffeineBar privacy policy at a stable URL on the `caffeinebar.app` domain.
2. THE privacy policy URL SHALL remain live and reachable for the entire 90-day window covered by this spec.
3. THE Launch operator SHALL provide the privacy policy URL to Polar.sh as part of the Polar.sh integration setup.

### Requirement 54: Apple Health write integration deferral

**User Story:** As a visitor reading launch copy, I do not want to see Apple Health claims that the MVP cannot back up, so that the launch does not promise a feature that lives in the Ultra tier.

#### Acceptance Criteria

1. THE Launch operator SHALL NOT include any Apple Health write-integration claim in any launch artefact.
2. THE Launch operator SHALL NOT use the words "Apple Health", "HealthKit", or "logs to Health" in the Landing page copy, the Product Hunt listing, the Day 1 social posts, the Show HN submission, or the Day 30 / Day 90 recap posts.
3. THE launch artefacts SHALL defer any Apple Health write-integration messaging to the **caffeinebar-ultra** spec.

### Requirement 55: Sound copyright provenance archive

**User Story:** As the Launch operator, I want voice-talent contracts and original session recordings retained off-repository before any sound asset ships in marketing material, so that copyright provenance is defensible if challenged.

#### Acceptance Criteria

1. THE Launch operator SHALL maintain a Sound provenance archive for every voice-acted sound asset that ships in any launch artefact.
2. THE Sound provenance archive SHALL contain, for each voice-acted asset, the signed voice-talent contract, the talent release, and the original session recording.
3. THE Sound provenance archive SHALL be stored off the public source-code repository in a private, access-controlled location.
4. THE Launch operator SHALL complete provenance archival for a given voice-acted asset before that asset ships in any public-facing marketing material.

### Requirement 56: Trademark search

**User Story:** As the Launch operator, I want a recorded trademark search before the public launch, so that the brand is not contested on Day 2.

#### Acceptance Criteria

1. THE Launch operator SHALL perform a USPTO TESS trademark search for the literal mark "CaffeineBar" in the macOS-app trademark class before launch day.
2. THE Launch operator SHALL retain a dated record of the Trademark search result.
3. IF the Trademark search reveals a registered trademark conflict on the literal mark "CaffeineBar" in a relevant class, THEN THE Launch operator SHALL postpone the public launch until the conflict is resolved.

---

## Section L — Day 30 and Day 90 Recap and Iteration

### Requirement 57: Day 30 — public revenue and retention recap

**User Story:** As a LinkedIn and X audience member at the 30-day mark, I want a candid public recap with real numbers, so that the build-in-public arc has a clean second checkpoint.

#### Acceptance Criteria

1. THE Launch operator SHALL publish a Recap post on LinkedIn at Day 30 containing the cumulative revenue and the 30-day retention figure for CaffeineBar.
2. THE Launch operator SHALL publish a Recap post on X at Day 30 containing the cumulative revenue and the 30-day retention figure for CaffeineBar.
3. THE Day 30 Recap posts SHALL state specific dollar and percentage figures and SHALL NOT use vague or rounded substitutes.

### Requirement 58: Day 30 — leading-indicator review and escalation-curve trigger

**User Story:** As the Launch operator, I want a hard arithmetic trigger for reconsidering the escalation curve at Day 30, so that a weak Cup-4 trigger rate forces a product conversation rather than getting normalised.

#### Acceptance Criteria

1. AT Day 30, THE Launch operator SHALL evaluate every Leading indicator defined in Requirement 45 against its target.
2. WHEN the Cup-4+ trigger rate measured at Day 30 is strictly less than 25%, THE Launch operator SHALL open a written reconsideration of the escalation curve before any further launch artefact is produced.
3. THE Day 30 reconsideration record SHALL describe the proposed change to the escalation curve or the explicit decision to keep the curve unchanged.

### Requirement 59: Day 90 — Mac App Store distribution decision deferred

**User Story:** As the Launch operator, I want the Day 90 Mac App Store distribution decision explicitly deferred to the Ultra spec when the unlock requires Ultra-tier features, so that the launch program does not silently absorb work that belongs elsewhere.

#### Acceptance Criteria

1. AT Day 90, THE Launch operator SHALL evaluate whether to initiate Mac App Store distribution for CaffeineBar based on the cumulative revenue trajectory.
2. WHERE the Mac App Store distribution path requires Ultra-tier features (iCloud sync, Apple Health write, Apple Shortcuts, custom sound import) to be in place, THE Launch operator SHALL defer the Mac App Store distribution decision to the **caffeinebar-ultra** spec.
3. THE Launch operator SHALL retain a dated record of the Day 90 Mac App Store distribution decision.

### Requirement 60: Day 90 — third Product Hunt launch moment deferred

**User Story:** As the Launch operator, I want the December Wrapped Product Hunt drop explicitly deferred to the Ultra spec, so that this document does not own a launch moment that depends on a feature it does not specify.

#### Acceptance Criteria

1. THE Launch operator SHALL defer the December "Wrapped" Product Hunt launch moment to the **caffeinebar-ultra** spec.
2. THE launch program defined in this document SHALL NOT include the Wrapped Product Hunt launch moment within its 90-day scope.
