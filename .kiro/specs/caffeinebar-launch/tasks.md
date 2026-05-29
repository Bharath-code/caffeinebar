# Implementation Plan: CaffeineBar Launch Program

## Overview

This is the operational launch playbook for CaffeineBar — executed by the Launch Operator (founder) from Day -7 through Day 90. Each task is a discrete human action with a clear deliverable. Tasks reference specific requirement IDs from the caffeinebar-launch spec.

## Tasks

- [ ] 1. Phase 1: Pre-Launch Asset Production (Day -7)
  - [ ] 1.1 Record the Ambulance reel
    - Open CaffeineBar on a real MacBook in natural light, set cup count to 4
    - Use QuickTime Player screen recording to capture logging Cup 5 → ambulance siren → skull MenuBarIcon
    - Trim in iMovie to 8–12 seconds; no voiceover, no text overlay, no watermark, no post-production effects
    - Preserve original ambulance siren audio at system output volume
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 2.1, 2.2, 2.3, 2.4_

  - [ ] 1.2 Run the first-playback laugh test
    - Play the trimmed reel from the start exactly once
    - If you laugh → pass; proceed to variants
    - If you do not laugh → rework the launch angle and re-record from scratch (loop back to 1.1)
    - _Requirements: 3.1, 3.2, 3.3_

  - [ ] 1.3 Produce three aspect-ratio variants
    - 9:16 vertical (Instagram Reels / TikTok)
    - 1:1 square (X)
    - 16:9 horizontal (YouTube Shorts / Landing page)
    - All derived from the same locked source recording — no re-recording per platform
    - _Requirements: 4.1, 4.2, 4.3, 4.4_

  - [ ] 1.4 Declare asset lock
    - Freeze the source recording, trim points, and all three variants
    - Confirm asset lock is ≥7 calendar days before planned launch day
    - Any substantive change after this point postpones launch by 7 days from the new lock
    - _Requirements: 5.1, 5.2, 5.3_

- [ ] 2. Phase 2: Pre-Launch Infrastructure (Day -7 to Day -1)
  - [ ] 2.1 Build and deploy the landing page at caffeinebar.app
    - Hero copy: first sentence contains the literal phrase "coffee cup counter"; no wellness/sleep language
    - Hero embed: 16:9 Ambulance reel, autoplay, muted, looping, click-to-unmute
    - Waitlist form above the fold, accepting email submissions with confirmation message
    - Pricing block: Pro tier (A/B tested $7.99/$9.99) + Ultra ($14.99), both labeled "one-time", no subscription language
    - About page differentiating from "Caffeine" sleep-prevention app
    - Responsive: hero copy above fold at 1280px desktop and 375/390/414px mobile
    - _Requirements: 6.1, 6.2, 6.3, 7.1, 7.2, 7.3, 7.4, 7.5, 8.1, 8.2, 8.3, 8.4, 8.5, 9.1, 9.2, 9.3, 9.4, 9.5, 52.1, 52.2, 52.3, 52.4_

  - [ ] 2.2 Deploy the privacy policy at a stable caffeinebar.app URL
    - Must be live and reachable ≥24 hours before launch day
    - Provide the URL to Polar.sh as part of integration setup
    - _Requirements: 11.1, 53.1, 53.2, 53.3_

  - [ ] 2.3 Wire Polar.sh checkout links
    - Pro tier checkout link configured for the active A/B price variant per visitor bucket
    - Ultra tier checkout link configured for $14.99
    - Test both checkout flows manually end-to-end before launch
    - _Requirements: 10.1, 10.2_

  - [ ] 2.4 Configure the A/B price test
    - 50/50 visitor bucketing on first page load (cookie/localStorage persistence)
    - Low bucket shows $7.99 Pro; high bucket shows $9.99 Pro
    - Checkout link dynamically points to the bucketed Polar.sh product
    - Track conversion events per bucket
    - _Requirements: 8.2, 8.3, 48.1_

  - [ ] 2.5 Set up the coffeebar.app typo redirect
    - Register coffeebar.app domain
    - Configure HTTP 301 redirect from all coffeebar.app paths to corresponding caffeinebar.app paths
    - Must be live ≥24 hours before launch day
    - _Requirements: 12.1, 12.2, 12.3_

  - [ ] 2.6 Complete the USPTO TESS trademark search
    - Search for the literal mark "CaffeineBar" in the macOS-app trademark class
    - Retain a dated record of the search result
    - If conflict found → postpone launch until resolved
    - _Requirements: 56.1, 56.2, 56.3_

  - [ ] 2.7 Complete the sound provenance archive
    - For every voice-acted sound asset shipping in marketing material: file the signed voice-talent contract, talent release, and original session recording
    - Store off the public source-code repository in a private, access-controlled location
    - Must be complete before any voice asset ships in marketing
    - _Requirements: 55.1, 55.2, 55.3, 55.4_

  - [ ] 2.8 Ensure download link is live
    - Notarized .dmg accessible from the landing page
    - Must be live ≥24 hours before launch day
    - _Requirements: 11.2, 11.3_

- [ ] 3. Phase 3: Creator Seeding (Day -7)
  - [ ] 3.1 Identify 15 micro-creators
    - Exactly 15 creators, follower count 5,000–50,000 each
    - Distributed across three niches: developer-setup, macOS-productivity, indie-hacker build-in-public
    - No mega-influencers (>500K followers) under any circumstance
    - Complete identification by Day -7
    - _Requirements: 13.1, 13.2, 13.3, 13.4, 13.5, 16.1_

  - [ ] 3.2 Assemble 15 seeding kits
    - Each kit contains: one valid Pro license key + platform-matched aspect-ratio variant + caffeinebar.app URL
    - No script, no suggested caption, no hashtag list, no posting deadline, no obligation to post
    - License key validity never conditional on posting
    - _Requirements: 14.1, 14.2, 14.3, 15.1, 15.2, 15.3_

  - [ ] 3.3 Send 15 creator DMs
    - Direct message each micro-creator with their seeding kit
    - One DM per creator on their primary platform
    - _Requirements: 14.1, 14.2, 14.3_

  - [ ] 3.4 Initialize the Creator Tracker
    - Create a tracker with fields: creator_handle, platform, niche, follower_count, date_contacted, variant_sent, license_key_sent, replied, posted, post_url, retweeted
    - Log all 15 entries with date_contacted
    - Begin daily updates from Day -7 through Day 14
    - _Requirements: 17.1, 17.2, 17.3_

- [ ] 4. Phase 4: Pre-Launch Teaser (Day -1)
  - [ ] 4.1 Publish the Day -1 teaser post on X
    - Single post from @git-scope in the spirit of "shipping something ridiculous tomorrow"
    - Must NOT mention: ambulance, siren, skull, Cup 5, Cup five, or include any frame/audio from the reel
    - Must NOT include the literal phrase "coffee cup counter"
    - No other CaffeineBar-related posts between teaser and Day 1 launch
    - _Requirements: 18.1, 18.2, 18.3, 19.1, 19.2, 19.3, 19.4_

  - [ ] 4.2 Notify existing community (newsletter + X audience)
    - Notify git-scope newsletter audience to expect a PH launch on Day 1
    - Notify git-scope X audience to expect a PH launch on Day 1
    - Notifications must comply with Req 19 (no ambulance reveal)
    - _Requirements: 20.1, 20.2, 20.3_

  - [ ] 4.3 Submit the Product Hunt listing
    - Submit at 11:30 PM PST on Day -1
    - Configure to go live at 12:01 AM PST on Day 1
    - Tagline leads with ambulance behaviour (e.g. "Your Mac calls an ambulance at cup 5")
    - Tagline must NOT lead with "coffee tracker", "caffeine tracker", or "caffeine app"
    - No wellness/sleep language
    - _Requirements: 21.1, 21.2, 22.2, 22.3, 22.4_

  - [ ] 4.4 Recruit 10+ warm-audience voters
    - Confirm at least 10 git-scope community members committed to upvote + comment within first 30 minutes
    - No monetary compensation offered
    - _Requirements: 25.1, 25.2, 25.3_

  - [ ] 4.5 Prepare the r/programming backup post
    - Draft a "dev log" post about the CaffeineBar build journey (Swift, MenuBarExtra, 7-day build)
    - Ready to deploy within 24h if primary Reddit posts are removed
    - _Requirements: 34.1, 34.2, 34.3_

- [ ] 5. Phase 5: Launch Day (Day 1)
  - [ ] 5.1 Confirm Product Hunt listing is live at 12:01 AM PST
    - Manual check at 12:05 AM PST
    - If not live, contact PH support; social posts proceed regardless
    - _Requirements: 22.1_

  - [ ] 5.2 Publish simultaneous social posts
    - X: 1:1 square variant + PH link in post body
    - Instagram Reels: 9:16 vertical variant + caffeinebar.app link in pinned comment
    - TikTok: 9:16 vertical variant + caffeinebar.app link in pinned comment
    - _Requirements: 23.1, 23.2, 23.3, 23.4_

  - [ ] 5.3 Publish Reddit posts on three subreddits
    - r/macapps, r/SaaS, r/IndieHackers — one post each
    - First-person "I built this because I couldn't find it" framing
    - No price mentions in comment threads for first 48 hours
    - _Requirements: 24.1, 24.2, 24.3, 24.4, 28.1_

  - [ ] 5.4 Activate the office-hours engagement window
    - 12:01 AM PST through 11:59 PM PST on Day 1
    - Reply to every public comment on PH, X, Instagram, TikTok, and Reddit within 1 hour
    - _Requirements: 26.1, 26.2, 26.3, 26.4_

  - [ ] 5.5 Execute the 9 AM PST peak push
    - Follow-up X post: Ambulance reel + PH listing link at 9:00 AM PST
    - Follow-up Instagram Reels push at 9:00 AM PST
    - Must be a separate posting moment from the 12:01 AM go-live
    - _Requirements: 27.1, 27.2, 27.3_

- [ ] 6. Phase 6: Post-Launch Week (Day 2–7)
  - [ ] 6.1 Publish the Day 2 revenue screenshot
    - Single X post with screenshot of first 24-hour revenue
    - State specific dollar revenue figure and specific install count
    - No vague language ("thousands of dollars", "lots of installs")
    - _Requirements: 29.1, 29.2, 29.3, 29.4_

  - [ ] 6.2 Activate the public creator discount
    - Publish a Day 2 post announcing: any user who shares a #CaffeineBar ambulance moment gets a free sound pack via DM
    - Fulfill within 48 hours of each qualifying user post
    - _Requirements: 30.1, 30.2_

  - [ ] 6.3 Submit Show HN (Day 3 or Day 4)
    - Title begins with "Show HN:"
    - Body describes the technical build (Swift, SwiftUI, MenuBarExtra API)
    - Links to caffeinebar.app, never directly to checkout
    - No sales pitch language
    - _Requirements: 31.1, 31.2, 31.3, 31.4_

  - [ ] 6.4 Retweet every creator #CaffeineBar post within 1 hour
    - Monitor for creator posts on Day 3–4
    - Retweet or quote-retweet from founder's primary X account within 1 hour
    - _Requirements: 32.1_

  - [ ] 6.5 Resolve the A/B price test at +48 hours
    - Compute: CR($7.99) − CR($9.99) in percentage points
    - If Δ < 5pp → ship at $9.99, update landing page, publish "raising the price" X post
    - If Δ ≥ 5pp → hold at $7.99 for 14 more days, re-evaluate
    - Update Polar.sh checkout link to resolved price
    - _Requirements: 33.1, 33.2, 33.3, 33.4, 48.1, 48.2, 48.3, 10.3_

- [ ] 7. Phase 7: Growth Phase (Week 2–4)
  - [ ] 7.1 Publish the sound pack content moment (Week 2)
    - Highlight one bundled sound pack (e.g. "Your Mom Pack")
    - Include video/audio clip of the highlighted pack's escalation set
    - Publish on at least Instagram Reels and X
    - _Requirements: 35.1, 35.2, 35.3_

  - [ ] 7.2 Publish the LinkedIn 7-day revenue recap (Week 2)
    - Single LinkedIn post with specific 7-day total revenue figure
    - Framed as "I built a silly Mac app. Here's what happened."
    - No rounded or vague figures
    - _Requirements: 36.1, 36.2, 36.3_

  - [ ] 7.3 Begin weekly user-ambulance-moment posts (Week 2+)
    - At least one X post per calendar week highlighting a user-submitted ambulance moment
    - Credit the original creator
    - _Requirements: 37.1, 37.2_

  - [ ] 7.4 Evaluate the paid ad gate (Day 14+)
    - Check: has the organic conversion baseline exceeded 5% for 7 continuous days?
    - If YES → unlock Reddit ads test in r/macapps + r/productivity, budget ≤$100
    - If NO → continue organic only, re-check weekly
    - Retain written record of the 7-day baseline window for every spend decision
    - No Meta/IG cold acquisition ever; amplification only on posts already converting >5%
    - No Google Ads or Apple Search Ads until Day 180
    - _Requirements: 38.1, 38.2, 39.1, 39.2, 40.1, 40.2, 41.1, 41.2, 41.3, 42.1, 42.2, 43.1, 43.2_

- [ ] 8. Phase 8: Sustain Phase (Day 30–90)
  - [ ] 8.1 Publish the Day 30 recap posts
    - LinkedIn + X posts with cumulative revenue and 30-day retention figure
    - Specific dollar and percentage figures, no vague substitutes
    - _Requirements: 57.1, 57.2, 57.3_

  - [ ] 8.2 Conduct the Day 30 leading-indicator review
    - Evaluate all 5 leading indicators against targets (Cup-4+ ≥35%, Pro conversion ≥25%, Ambulance share ≥15%, Day-7 retention ≥45%, Accessibility usage ≥8%)
    - If Cup-4+ trigger rate < 25% → open written escalation curve reconsideration
    - Document proposed change or explicit decision to keep curve unchanged
    - _Requirements: 44.1, 45.1, 45.2, 45.3, 45.4, 45.5, 58.1, 58.2, 58.3_

  - [ ] 8.3 Conduct weekly leading-indicator reviews (Week 1–12)
    - Same weekday each week
    - Compare each indicator to its target
    - If any indicator below target for 2 consecutive weeks → document corrective action before third review
    - _Requirements: 46.1, 46.2, 46.3_

  - [ ] 8.4 Publish the Day 90 recap posts
    - LinkedIn + X posts with cumulative revenue and 90-day metrics
    - Evaluate the 90-day target set: 2,000 installs, 800 DAU, 300 conversions, $4,000 revenue, 200 #CaffeineBar posts
    - _Requirements: 44.2, 44.3_

  - [ ] 8.5 Execute the Day 90 MAS distribution decision
    - Evaluate whether to initiate Mac App Store distribution based on cumulative revenue trajectory
    - If MAS path requires Ultra-tier features → defer to caffeinebar-ultra spec
    - Retain a dated record of the decision
    - _Requirements: 59.1, 59.2, 59.3_

- [ ] 9. Final checkpoint
  - Verify all requirements (1–60) have been addressed across the 8 phases
  - Confirm the December Wrapped PH moment is explicitly deferred to caffeinebar-ultra (Req 60)
  - Archive the Creator Tracker, A/B test data, paid spend decision logs, and weekly indicator logs

## Notes

- This is a human-operated launch program, not a code project. The "system under test" is the Launch Operator following this checklist against external platforms.
- Each task references specific requirement IDs for traceability back to the caffeinebar-launch spec.
- The Launch Operator does not write Swift code. Engineering handoffs (privacy policy content, download link, license keys) come from the caffeinebar-mvp build agents.
- Property-based testing does not apply — verification is through checklists, gate reviews, and arithmetic decision rules.
- The December Wrapped PH moment (Req 60) and MAS distribution execution (if triggered) are deferred to caffeinebar-ultra.
- Anti-ICP vocabulary gates (Req 51) and Apple Health deferral (Req 54) apply to ALL tasks that produce public-facing copy.

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1.1"] },
    { "id": 1, "tasks": ["1.2"] },
    { "id": 2, "tasks": ["1.3"] },
    { "id": 3, "tasks": ["1.4", "2.6", "2.7"] },
    { "id": 4, "tasks": ["2.1", "2.2", "2.5", "2.8", "3.1"] },
    { "id": 5, "tasks": ["2.3", "2.4", "3.2"] },
    { "id": 6, "tasks": ["3.3", "3.4", "4.5"] },
    { "id": 7, "tasks": ["4.1", "4.2", "4.3", "4.4"] },
    { "id": 8, "tasks": ["5.1", "5.2", "5.3"] },
    { "id": 9, "tasks": ["5.4", "5.5"] },
    { "id": 10, "tasks": ["6.1", "6.2"] },
    { "id": 11, "tasks": ["6.3", "6.4", "6.5"] },
    { "id": 12, "tasks": ["7.1", "7.2", "7.3"] },
    { "id": 13, "tasks": ["7.4"] },
    { "id": 14, "tasks": ["8.1", "8.2", "8.3"] },
    { "id": 15, "tasks": ["8.4", "8.5"] }
  ]
}
```
