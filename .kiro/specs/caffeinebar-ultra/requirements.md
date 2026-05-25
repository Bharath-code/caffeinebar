# Requirements Document

## Introduction

CaffeineBar Ultra is the **post-MVP feature build** that activates on top of the shipped MVP product when a user holds an Ultra-tier license. The Ultra tier is the $14.99 one-time purchase that, at MVP, exists only as a price anchor; this spec is the body of work that makes the anchor a real product. Ultra is strictly additive — every Pro feature continues to work, every Free feature continues to work, and Ultra layers on iCloud sync across multiple Macs, Apple Health write integration, Apple Shortcuts integration, an annual Wrapped card surfaced in December, custom sound import, and the framework needed to make a Mac App Store distribution decision at Day 90.

This spec — **caffeinebar-ultra** — covers the **Ultra-tier feature build only**. It is the third of three companion specs and is read alongside:

- **caffeinebar-mvp** — The MVP product build (Free + Pro tiers, Polar.sh licensing, accessibility, notarization, the call-aware audio engine, and the bundled sound packs). Every requirement in this document that depends on MVP behavior cross-references the relevant MVP requirement number; this document does not duplicate any MVP acceptance criterion.
- **caffeinebar-launch** — The launch program (pre-launch, launch week, and the 90-day operating playbook). The December Wrapped Product Hunt moment is explicitly deferred from `caffeinebar-launch` Requirement 60 to this spec, and the Day 90 Mac App Store distribution decision is explicitly deferred from `caffeinebar-launch` Requirement 59 to this spec.

Out of scope for this document:

- Anything in the MVP product surface (logging, escalation sound system, Pro tier features, Polar.sh license entry, accessibility audit, notarization rehearsal at MVP, hardened-runtime entitlements declared at MVP) → **caffeinebar-mvp**
- Anything in the launch operating program (creator seeding, ambulance reel production, Product Hunt assets, paid ad strategy, weekly stand-ups, Day -7 → Day 90 GTM workstream) → **caffeinebar-launch**

This spec is exhaustive within its scope: it drives the entire post-MVP feature build, the December Wrapped artefact, and the Mac App Store distribution decision framework. After Ultra ships against this document, the $14.99 tier delivers $14.99 of incremental value.

## Glossary

- **Ultra tier**: The $14.99 one-time purchase tier that unlocks every feature defined in this document. Strictly supersedes the Pro tier — every Pro entitlement remains active when Ultra is active.
- **CloudKit private database**: Apple's user-scoped private CloudKit container, synced across the user's Macs that share the same iCloud account. Used by CaffeineBar as the only sync backend; no third-party server participates.
- **HealthKit caffeine sample**: An `HKQuantitySample` with quantity type `HKQuantityTypeIdentifier.dietaryCaffeine`, written to Apple Health on every coffee log when Ultra is active and Health write authorization has been granted.
- **App Intent**: A type conforming to the `AppIntents` framework's `AppIntent` protocol. CaffeineBar's `LogCoffeeIntent` is an App Intent. Used by Siri, the Shortcuts app, the Action Button, and Spotlight.
- **AppIntents framework**: The modern Apple framework (introduced in iOS 16 / macOS 13) for declaring Shortcuts and Siri integrations. Replaces the legacy `Intents.framework` SiriKit definitions; CaffeineBar uses the modern framework only.
- **Wrapped card**: The annual year-in-review summary image generated and offered to the user from December 1 through January 15, rendered offscreen via `ImageRenderer` to a high-DPI PNG using the same mechanism as the Pro streak ShareCard defined in `caffeinebar-mvp` Requirement 7.
- **Custom sound pack**: A user-imported set of audio assets (one per Cup-1 through Cup-5+ escalation state) that replaces the bundled escalation sounds for Ultra users. Imported via NSOpenPanel, persisted in the application support directory, referenced by security-scoped bookmarks.
- **MAS (Mac App Store)**: Apple's curated distribution channel for macOS apps. CaffeineBar ships at MVP via direct `.dmg` download from caffeinebar.app; MAS distribution is a Day 90 decision evaluated under this spec.
- **App Sandbox**: The macOS sandboxing entitlement set required for Mac App Store distribution. Restricts app access to a narrow set of declared entitlements.
- **dataVersion**: The integer field stored in `UserDefaults` under `caffeinebar.dataVersion` defined in `caffeinebar-mvp` Requirement 32. Currently `1` at MVP; bumped to `2` only if Ultra ships a schema-breaking change.
- **Resolved tier**: The current effective license tier surfaced by the LicenseManager (defined in `caffeinebar-mvp` Section G). One of `.free`, `.pro`, or `.ultra`. Ultra strictly supersedes Pro.
- **Donated intent**: An `AppIntent` instance handed to the system via `IntentDonationManager` after a real user-initiated log, so that Siri Suggestions can surface CaffeineBar in the user's daily routine.
- **Security-scoped bookmark**: A `Data`-encoded reference to a file outside the app's bundle that survives app restarts and (when persisted with the appropriate flag) sandbox boundaries. Used by CaffeineBar to retain access to user-imported custom sound files across launches.
- **CallDetector**: The MVP component (defined in `caffeinebar-mvp` Section C) that decides whether an active audio call is in progress. Referenced here only as the upstream signal whose entitlements may change under Ultra's MAS-track sandbox audit.
- **CupStore**: The MVP observable state container (defined in `caffeinebar-mvp` Section F). Referenced here as the source of truth that the CloudKit sync layer wraps and the source of the data points that the Wrapped card aggregates.
- **LicenseManager**: The MVP licensing component (defined in `caffeinebar-mvp` Section G). Extended in this document to expose `resolvedTier == .ultra` and to gate every Ultra feature.
- **HealthSyncIndicator**: The quiet settings UI element introduced by this document that surfaces the most recent HealthKit write status without raising a modal alert.
- **CloudSyncStatus**: The settings UI element introduced by this document that surfaces the last successful CloudKit sync timestamp, the last sync error if any, and a manual "Sync now" affordance.
- **WrappedArchive**: The directory under the application support directory introduced by this document that retains every prior year's Wrapped PNG, scoped per macOS user account.

---

## Requirements

## Section A — Ultra Tier Licensing & Activation

### Requirement 1: Ultra Polar.sh checkout and signed Ultra license payload

**User Story:** As a user choosing the Ultra tier, I want a Polar.sh checkout for $14.99 that produces a license key distinct from the Pro key, so that the LicenseManager can recognize an Ultra entitlement at the cryptographic level.

#### Acceptance Criteria

1. THE caffeinebar.app landing page SHALL link to a Polar.sh checkout for the Ultra tier at $14.99.
2. WHEN a Polar.sh purchase of the Ultra tier completes, THE Polar.sh webhook SHALL generate a license key payload signed with the CaffeineBar private key and SHALL encode the tier value `ultra` in the signed payload.
3. THE Ultra tier signed payload SHALL be distinguishable from the Pro tier signed payload by the encoded tier value alone, with no other format change.
4. THE LicenseManager SHALL reuse the Polar.sh checkout, signing, and Keychain storage mechanism defined in `caffeinebar-mvp` Requirements 38, 39, and 40 without modification, except for recognizing the `ultra` tier value.

### Requirement 2: License tier resolution — Ultra strictly supersedes Pro

**User Story:** As an Ultra user, I want every Ultra-only feature gated by a single resolved-tier check, so that the gating is uniform and impossible to bypass by feature flag drift.

#### Acceptance Criteria

1. THE LicenseManager SHALL expose a `resolvedTier` property whose value is one of `.free`, `.pro`, or `.ultra`.
2. WHEN the LicenseManager validates an Ultra-tier signed payload via the cryptographic check defined in `caffeinebar-mvp` Requirement 40, THE LicenseManager SHALL set `resolvedTier` to `.ultra`.
3. WHILE `resolvedTier` is `.ultra`, THE LicenseManager SHALL also satisfy every license-gated check that requires Pro or higher (Ultra strictly supersedes Pro).
4. THE CaffeineBar SHALL gate every Ultra feature defined in this document on `resolvedTier == .ultra` and SHALL NOT gate any Ultra feature on a separate boolean flag.

### Requirement 3: Pro → Ultra in-app upgrade path without restart

**User Story:** As an existing Pro user upgrading to Ultra, I want to paste my new Ultra key into Settings and have the app transition immediately, so that I never have to relaunch and never lose state.

#### Acceptance Criteria

1. WHEN an existing Pro user pastes a valid Ultra-tier license key into the SettingsView license-entry field, THE LicenseManager SHALL transition `resolvedTier` from `.pro` to `.ultra` without requiring an app restart.
2. WHEN the LicenseManager transitions `resolvedTier` from `.pro` to `.ultra`, THE CupStore SHALL retain every persisted field defined in `caffeinebar-mvp` Requirement 33 unchanged.
3. WHEN the LicenseManager transitions `resolvedTier` from `.pro` to `.ultra`, THE Popover and the SettingsView SHALL reveal every previously gated Ultra surface within 1 second without any view dismissal or sheet presentation.

### Requirement 4: Free → Ultra direct purchase path

**User Story:** As a Free user who wants to skip Pro, I want to buy Ultra directly and have the app unlock both Pro and Ultra features at once, so that the upgrade path is one purchase, not two.

#### Acceptance Criteria

1. WHEN an existing Free user pastes a valid Ultra-tier license key into the SettingsView license-entry field, THE LicenseManager SHALL transition `resolvedTier` directly from `.free` to `.ultra` without an intermediate `.pro` step.
2. WHILE `resolvedTier` is `.ultra`, THE Popover SHALL render every Pro-tier feature surface defined in `caffeinebar-mvp` Section D as fully unlocked, without applying the Pro-tier blur gate defined in `caffeinebar-mvp` Requirement 23.

### Requirement 5: Offline cache and graceful degradation parity with Pro

**User Story:** As an Ultra user offline on a long flight, I want the same offline grace and same revocation behavior the Pro tier already gets, so that I am never punished for being on a plane.

#### Acceptance Criteria

1. THE LicenseManager SHALL apply the offline validation cache rules, the periodic online re-check cadence, and the graceful-degradation transition rules defined in `caffeinebar-mvp` Requirement 41 to the Ultra tier without modification.
2. IF the LicenseManager observes a revoked or expired Ultra-tier license during an online re-check, THEN THE LicenseManager SHALL transition `resolvedTier` to `.free` per `caffeinebar-mvp` Requirement 41 acceptance criterion 3.
3. WHEN the LicenseManager transitions `resolvedTier` from `.ultra` to a lower tier, THE CaffeineBar SHALL NOT delete any logged Cup count, timestamp, streak value, history record, Wrapped archive, or imported custom sound pack file (cross-reference Requirement 63 of this document).

### Requirement 6: Settings displays "Ultra unlocked" badge with entitlement set

**User Story:** As an Ultra user opening Settings, I want a visible confirmation that Ultra is active and a list of what Ultra unlocks, so that I can verify the purchase landed and I see the value of what I paid for.

#### Acceptance Criteria

1. WHILE `resolvedTier` is `.ultra`, THE SettingsView SHALL display an "Ultra unlocked" badge in the license section.
2. WHILE `resolvedTier` is `.ultra`, THE SettingsView SHALL list the Ultra entitlement set as enumerated bullet items: "iCloud sync across Macs", "Apple Health write integration", "Apple Shortcuts integration", "Annual Wrapped card", and "Custom sound import".
3. WHILE `resolvedTier` is `.pro` or `.free`, THE SettingsView SHALL NOT display the "Ultra unlocked" badge.

### Requirement 7: Pro features remain functional when Ultra is active

**User Story:** As an Ultra user, I want every Pro feature I was already using to keep working untouched, so that the upgrade is purely additive.

#### Acceptance Criteria

1. WHILE `resolvedTier` is `.ultra`, THE CaffeineBar SHALL render the HalfLifeClock per `caffeinebar-mvp` Requirement 18 with no modification.
2. WHILE `resolvedTier` is `.ultra`, THE CaffeineBar SHALL render the WeeklyGraphView per `caffeinebar-mvp` Requirement 20 with no modification.
3. WHILE `resolvedTier` is `.ultra`, THE CaffeineBar SHALL apply the Cut-off Window behavior per `caffeinebar-mvp` Requirement 19 with no modification.
4. WHILE `resolvedTier` is `.ultra`, THE CaffeineBar SHALL allow selection of any of the four bundled sound packs per `caffeinebar-mvp` Requirement 21 with no modification.
5. WHILE `resolvedTier` is `.ultra`, THE CaffeineBar SHALL render the streak ShareCard per `caffeinebar-mvp` Requirement 7 with no modification.
6. THE CaffeineBar SHALL NOT replace, hide, or behaviorally alter any Pro feature when Ultra is active.

---

## Section B — iCloud Sync (multi-Mac streak / history sync)

### Requirement 8: CloudKit private database used for sync; no third-party backend

**User Story:** As an Ultra user with two Macs, I want my coffee data synced through Apple's own infrastructure under my iCloud account, so that no third party ever sees my logs.

#### Acceptance Criteria

1. THE CaffeineBar iCloud sync layer SHALL use the CloudKit private database scoped to the user's iCloud account.
2. THE CaffeineBar SHALL NOT route any logged Cup count, timestamp, streak value, or history record through any server, endpoint, or service other than Apple's CloudKit.
3. THE CaffeineBar CloudKit container identifier SHALL be declared as `iCloud.app.caffeinebar` in the application entitlements file.

### Requirement 9: Synced fields enumerated

**User Story:** As an Ultra user, I want a precise list of which fields sync across my Macs, so that I know what to expect on the second Mac after I log on the first.

#### Acceptance Criteria

1. WHILE `resolvedTier` is `.ultra` AND iCloud sync is enabled, THE CaffeineBar SHALL sync `todayCount` for the current logical day defined by the reset hour to the CloudKit private database.
2. WHILE `resolvedTier` is `.ultra` AND iCloud sync is enabled, THE CaffeineBar SHALL sync `todayTimestamps` to the CloudKit private database.
3. WHILE `resolvedTier` is `.ultra` AND iCloud sync is enabled, THE CaffeineBar SHALL sync `streakDays` to the CloudKit private database.
4. WHILE `resolvedTier` is `.ultra` AND iCloud sync is enabled, THE CaffeineBar SHALL sync `personalRecord` to the CloudKit private database.
5. WHILE `resolvedTier` is `.ultra` AND iCloud sync is enabled, THE CaffeineBar SHALL sync `totalDaysLogged` to the CloudKit private database.
6. WHILE `resolvedTier` is `.ultra` AND iCloud sync is enabled, THE CaffeineBar SHALL sync daily aggregate history records (one record per logical day, keyed by the day's start-of-day date) to the CloudKit private database.

### Requirement 10: Fields explicitly NOT synced

**User Story:** As an Ultra user with different audio setups on two Macs, I want my per-device preferences to stay local, so that muting on my work Mac does not silence my home Mac.

#### Acceptance Criteria

1. THE CaffeineBar SHALL NOT sync `licenseKey` to CloudKit, and SHALL retain `licenseKey` only in the macOS Keychain on a per-Mac basis per `caffeinebar-mvp` Requirement 39.
2. THE CaffeineBar SHALL NOT sync `installedSoundPacks` to CloudKit.
3. THE CaffeineBar SHALL NOT sync `selectedSoundPack` to CloudKit.
4. THE CaffeineBar SHALL NOT sync `isMuted` to CloudKit.
5. THE CaffeineBar SHALL NOT sync `officeMode` to CloudKit.
6. THE CaffeineBar SHALL NOT sync any custom sound pack files (defined in Section F of this document) to CloudKit.

### Requirement 11: Conflict resolution — last-write-wins on per-day records, union on same-minute timestamps

**User Story:** As an Ultra user logging from two Macs in the same minute, I want both timestamps preserved instead of one overwriting the other, so that two real cups never collapse into one synced cup.

#### Acceptance Criteria

1. WHEN two Macs each commit a CloudKit record for the same logical day, THE CaffeineBar SHALL resolve the conflict using last-write-wins on per-day scalar fields (`todayCount` for the affected day, derived aggregates).
2. WHEN two Macs each contribute a timestamp to `todayTimestamps` for the same logical day, THE CaffeineBar SHALL preserve the union of all timestamps from both Macs, ordered ascending.
3. WHEN two Macs each contribute a timestamp recorded at the same minute, THE CaffeineBar SHALL preserve both timestamps as distinct entries in the union and SHALL NOT collapse them by minute precision.

### Requirement 12: Offline behavior — logging never blocked by sync availability

**User Story:** As an Ultra user offline, I want every coffee log to commit locally and instantly, with sync catching up later, so that the network is never on the critical path of a +1 click.

#### Acceptance Criteria

1. WHEN a log action is committed, THE CupStore SHALL persist the change to local storage per `caffeinebar-mvp` Requirements 32 through 35 regardless of iCloud reachability.
2. WHEN the network and CloudKit are unavailable, THE CaffeineBar SHALL queue the change for later sync and SHALL NOT block, delay, or fail the local log commit.
3. WHEN the network and CloudKit become available after an offline period, THE CaffeineBar SHALL flush the queued changes opportunistically without user action.

### Requirement 13: CloudSyncStatus surface in settings

**User Story:** As an Ultra user, I want to see when my data last synced and to be able to force a sync on demand, so that I can verify the sync layer is healthy.

#### Acceptance Criteria

1. THE SettingsView SHALL display the CloudSyncStatus element while `resolvedTier` is `.ultra`.
2. THE CloudSyncStatus element SHALL display the wall-clock timestamp of the most recent successful CloudKit sync.
3. WHEN a CloudKit sync error occurs, THE CloudSyncStatus element SHALL display a one-line human-readable description of the error.
4. THE CloudSyncStatus element SHALL display a "Sync now" button that, when activated, triggers an immediate CloudKit sync attempt.

### Requirement 14: iCloud account requirement messaging

**User Story:** As an Ultra user signed out of iCloud, I want a clear in-app warning that sync requires an iCloud account, so that I understand why my second Mac is not seeing my data.

#### Acceptance Criteria

1. WHILE `resolvedTier` is `.ultra` AND the user is signed out of iCloud on the current Mac, THE SettingsView SHALL display the warning copy "Sign in to iCloud to enable CaffeineBar sync across your Macs."
2. WHILE `resolvedTier` is `.ultra` AND the user is signed in to iCloud but has iCloud Drive disabled, THE SettingsView SHALL display the warning copy "Enable iCloud Drive to allow CaffeineBar to sync across your Macs."
3. THE iCloud account warning copy SHALL appear inside the CloudSyncStatus surface and SHALL NOT appear as a modal alert.

### Requirement 15: Privacy policy update — CloudKit enumerated as outbound data flow

**User Story:** As a privacy-conscious user reading the privacy policy, I want CloudKit sync explicitly listed alongside the existing license check, so that the policy never lies about what leaves my Mac.

#### Acceptance Criteria

1. THE in-app privacy policy view defined in `caffeinebar-mvp` Requirement 43 SHALL be amended to enumerate CloudKit sync as a separate outbound data flow distinct from the Polar.sh license validation flow.
2. THE caffeinebar.app website privacy policy SHALL be amended to enumerate CloudKit sync as a separate outbound data flow distinct from the Polar.sh license validation flow.
3. THE amended privacy policy text SHALL state that CloudKit data is stored under the user's iCloud account, that the CaffeineBar developer cannot read the contents, and that CloudKit sync is opt-out.

### Requirement 16: Sync opt-in/opt-out without losing Ultra entitlements

**User Story:** As an Ultra user who wants the other Ultra features but not multi-Mac sync, I want a toggle to disable iCloud sync without giving up Ultra, so that the feature set is configurable.

#### Acceptance Criteria

1. THE SettingsView SHALL provide an "Enable iCloud sync" toggle visible while `resolvedTier` is `.ultra`.
2. WHEN the user sets the "Enable iCloud sync" toggle to off, THE CaffeineBar SHALL stop syncing to CloudKit and SHALL retain `resolvedTier` at `.ultra`.
3. WHEN the user sets the "Enable iCloud sync" toggle to off, THE CaffeineBar SHALL retain every other Ultra entitlement (Apple Health write, Apple Shortcuts integration, annual Wrapped card, custom sound import) without modification.

---

## Section C — Apple Health Write Integration

### Requirement 17: HealthKit caffeine sample written on every coffee log

**User Story:** As an Ultra user already tracking my health data in Apple Health, I want every coffee I log in CaffeineBar to appear in Health automatically, so that my caffeine intake lives alongside my other health metrics.

#### Acceptance Criteria

1. WHILE `resolvedTier` is `.ultra` AND HealthKit caffeine write authorization has been granted, THE CaffeineBar SHALL write one HealthKit caffeine sample of type `HKQuantityTypeIdentifier.dietaryCaffeine` for every coffee log committed by the CupStore.
2. THE caffeine sample SHALL use the user-configurable per-cup dose value (defined in Requirement 20 of this document), defaulting to 95 milligrams.
3. THE caffeine sample's `startDate` and `endDate` SHALL equal the timestamp recorded by the CupStore for that log.

### Requirement 18: Write-only HealthKit data flow

**User Story:** As a privacy-conscious user, I want CaffeineBar to never read anything from Apple Health, so that my Health data stays out of an app whose only job is to track coffee.

#### Acceptance Criteria

1. THE CaffeineBar SHALL request HealthKit write authorization for `HKQuantityTypeIdentifier.dietaryCaffeine` only.
2. THE CaffeineBar SHALL NOT request HealthKit read authorization for any quantity type, category type, characteristic type, workout type, or correlation type.
3. THE CaffeineBar source code SHALL NOT contain any call to `HKHealthStore.requestAuthorization` whose `typesToRead` argument is non-empty.

### Requirement 19: Health authorization flow on first Ultra activation

**User Story:** As an Ultra user activating the tier for the first time, I want a clear prompt to grant Health write authorization that I can defer, so that the integration is opt-in but easy to enable later.

#### Acceptance Criteria

1. WHEN the LicenseManager transitions `resolvedTier` to `.ultra` for the first time on the current Mac, THE CaffeineBar SHALL present the macOS HealthKit write authorization prompt for `HKQuantityTypeIdentifier.dietaryCaffeine`.
2. WHEN the user defers, denies, or dismisses the HealthKit authorization prompt, THE CaffeineBar SHALL retain Ultra activation and SHALL NOT block any other Ultra feature.
3. THE SettingsView SHALL provide an "Enable Apple Health write" control that re-presents the HealthKit write authorization prompt when activated.

### Requirement 20: Configurable per-cup caffeine dose

**User Story:** As an Ultra user who drinks espresso, an Americano, or cold brew at different milligram totals, I want to set the per-cup dose written to Health, so that the data is accurate to my actual intake.

#### Acceptance Criteria

1. THE SettingsView SHALL provide a per-cup dose field that accepts integer milligram values.
2. THE per-cup dose field SHALL default to 95 milligrams.
3. THE per-cup dose field SHALL accept values in the inclusive range 0 through 500 milligrams.
4. IF the user enters a value outside the accepted range, THEN THE SettingsView SHALL clamp the value into range and SHALL NOT raise a modal alert.

### Requirement 21: Source attribution as "CaffeineBar" in Health.app

**User Story:** As an Ultra user inspecting my caffeine entries in Health.app, I want each entry attributed to "CaffeineBar" not to a bundle identifier string, so that the source is human-readable.

#### Acceptance Criteria

1. THE CaffeineBar SHALL set the `HKSource` display name on every written caffeine sample such that Health.app displays "CaffeineBar" as the source.
2. THE CaffeineBar SHALL NOT display its raw bundle identifier as the source attribution in Health.app.

### Requirement 22: Retroactive backfill of today's prior logs on enabling Health write

**User Story:** As an Ultra user who enabled Health write at lunch after logging two cups in the morning, I want this morning's cups backfilled into Health, so that today's data is complete on day one.

#### Acceptance Criteria

1. WHEN the user grants HealthKit caffeine write authorization AND the CupStore holds one or more log timestamps for the current logical day prior to the authorization grant, THE CaffeineBar SHALL write a HealthKit caffeine sample for each prior timestamp.
2. THE backfill writes SHALL be ordered chronologically ascending by the timestamp of each prior log.
3. THE backfill SHALL NOT write samples for any logical day other than the current logical day defined by the reset hour.

### Requirement 23: HealthKit write failure handling — local log still succeeds

**User Story:** As an Ultra user whose HealthKit authorization just got revoked at the OS level, I do not want the +1 Coffee click to feel broken, so that Health failures never break the core product.

#### Acceptance Criteria

1. IF a HealthKit write call fails for any reason (revoked authorization, OS error, sample validation rejection), THEN THE CupStore SHALL still increment the Cup count and persist the timestamp per `caffeinebar-mvp` Requirement 3 acceptance criterion 1.
2. IF a HealthKit write call fails, THEN THE CaffeineBar SHALL log the failure to the system console and SHALL NOT raise a modal alert or notification.
3. WHEN a HealthKit write failure occurs, THE SettingsView HealthSyncIndicator SHALL display a quiet status string describing the most recent failure.

### Requirement 24: Privacy policy update — HealthKit write enumerated, "we never read" copy

**User Story:** As a privacy-conscious user, I want the privacy policy to call out HealthKit write as a separate flow with explicit "we never read" copy, so that the integration is fully disclosed.

#### Acceptance Criteria

1. THE in-app privacy policy view defined in `caffeinebar-mvp` Requirement 43 SHALL be amended to enumerate HealthKit write as a separate data flow distinct from the Polar.sh license validation flow and the CloudKit sync flow.
2. THE caffeinebar.app website privacy policy SHALL be amended to enumerate HealthKit write as a separate data flow.
3. THE amended privacy policy text SHALL include the explicit copy "CaffeineBar never reads your Health data."

### Requirement 25: HealthKit entitlement and notarization re-test trigger

**User Story:** As an engineer adding a new Apple entitlement, I want the notarization rehearsal re-run because the entitlement set has changed, so that a stale rehearsal does not lead to a launch-day failure.

#### Acceptance Criteria

1. THE CaffeineBar entitlements file SHALL declare the `com.apple.developer.healthkit` entitlement.
2. THE CaffeineBar `Info.plist` SHALL declare the `NSHealthUpdateUsageDescription` purpose string.
3. WHEN the entitlements file changes to add the `com.apple.developer.healthkit` entitlement, THE Ultra release process SHALL re-execute the notarization rehearsal defined in `caffeinebar-mvp` Requirement 52 (cross-reference Requirement 57 of this document).

---

## Section D — Apple Shortcuts Integration

### Requirement 26: LogCoffeeIntent exposed via the AppIntents framework

**User Story:** As an Ultra user wiring CaffeineBar into a morning Shortcut, I want a modern App Intent the system can discover, so that Shortcuts, Siri, and Spotlight all see the same intent definition.

#### Acceptance Criteria

1. THE CaffeineBar SHALL declare a type named `LogCoffeeIntent` conforming to the `AppIntents.AppIntent` protocol.
2. THE `LogCoffeeIntent` SHALL be exposed via the modern AppIntents framework only.
3. THE CaffeineBar SHALL NOT declare any intent using the legacy `Intents.framework` SiriKit definitions.

### Requirement 27: Voice command — "Hey Siri, log a coffee in CaffeineBar"

**User Story:** As an Ultra user with my hands wrapped around an espresso cup, I want to log a coffee with a voice command, so that I do not have to set the cup down to click.

#### Acceptance Criteria

1. WHEN the user issues the voice command "Hey Siri, log a coffee in CaffeineBar", THE LogCoffeeIntent SHALL execute and SHALL invoke the same CupStore log path used by the Popover "+1 Coffee" button per `caffeinebar-mvp` Requirement 3.
2. WHEN the LogCoffeeIntent executes, THE SoundEngine SHALL play the escalation sound mapped to the resulting Cup count per `caffeinebar-mvp` Requirement 10.
3. WHEN the LogCoffeeIntent executes, THE MenuBarIcon SHALL update to the resulting Escalation State per `caffeinebar-mvp` Requirement 1.

### Requirement 28: Shortcuts.app discoverability

**User Story:** As an Ultra user browsing the Shortcuts gallery, I want CaffeineBar to appear there as a first-class app, so that the integration is discoverable without me reading any documentation.

#### Acceptance Criteria

1. THE LogCoffeeIntent SHALL declare a static `title` value of "Log Coffee".
2. THE LogCoffeeIntent SHALL declare a static `description` value that begins "Logs a coffee in CaffeineBar".
3. THE LogCoffeeIntent SHALL appear in the Shortcuts.app gallery under a CaffeineBar grouping.

### Requirement 29: Optional cupCount parameter for "log three coffees"

**User Story:** As an Ultra user batching a Shortcut to log three espressos, I want a parameter on the intent for the cup count, so that one intent invocation can represent more than one cup.

#### Acceptance Criteria

1. THE LogCoffeeIntent SHALL declare an optional `cupCount` parameter of integer type.
2. THE `cupCount` parameter SHALL default to 1 when omitted.
3. THE `cupCount` parameter SHALL accept values in the inclusive range 1 through 5.
4. WHEN the LogCoffeeIntent executes with `cupCount` equal to N, THE CupStore SHALL commit N sequential log actions, each producing its own timestamp, its own escalation sound, and its own MenuBarIcon update.
5. IF the `cupCount` parameter is supplied with a value outside the accepted range, THEN THE LogCoffeeIntent SHALL return a descriptive error result and SHALL NOT commit any partial log.

### Requirement 30: Donated intents on every Popover log

**User Story:** As an Ultra user with a daily 9 AM coffee habit, I want Siri Suggestions to surface CaffeineBar around 9 AM, so that the system learns my routine.

#### Acceptance Criteria

1. WHEN a log action is committed via the Popover "+1 Coffee" button per `caffeinebar-mvp` Requirement 3, THE CaffeineBar SHALL donate a `LogCoffeeIntent` instance to the system using `IntentDonationManager`.
2. THE donated intent SHALL include the timestamp of the log action.
3. THE CaffeineBar SHALL NOT donate intents for log actions that originated from the LogCoffeeIntent itself, to prevent feedback loops.

### Requirement 31: Localization via String Catalog

**User Story:** As an engineer planning future localization, I want intent strings exposed via String Catalog, so that future translators can localize the spoken phrase without touching Swift code.

#### Acceptance Criteria

1. THE LogCoffeeIntent's `title`, `description`, and `cupCount` parameter label SHALL be exposed via the project's `String Catalog` resource.
2. THE CaffeineBar SHALL ship the intent strings in English at the Ultra launch.
3. THE String Catalog SHALL be structured to accept additional locales without requiring source code changes.

### Requirement 32: Shortcuts privacy declaration — no location collected

**User Story:** As a privacy-conscious user reading the App Privacy nutrition labels, I want it stated explicitly that CaffeineBar's intents collect no location, so that the labels are unambiguous.

#### Acceptance Criteria

1. THE App Privacy nutrition label declaration for CaffeineBar SHALL state that no location data is collected by any App Intent at the Ultra launch.
2. WHERE a future App Intent introduces any location-based behavior, THE App Privacy nutrition labels SHALL be updated to declare "Coarse Location" before the intent ships.
3. THE LogCoffeeIntent SHALL NOT request, read, or include any location data in its execution path or its donation payload.

---

## Section E — Annual Wrapped Card (December launch moment)

### Requirement 33: Wrapped card rendered offscreen via ImageRenderer at native scale

**User Story:** As an Ultra user generating my year-end Wrapped, I want a high-DPI PNG that looks crisp on Retina displays, so that what I share looks like a designed asset, not a screenshot.

#### Acceptance Criteria

1. THE Wrapped card view SHALL be rendered offscreen via SwiftUI `ImageRenderer` at the screen's native scale to produce a high-DPI PNG.
2. THE Wrapped card SHALL use the same offscreen rendering mechanism as the Pro tier streak ShareCard defined in `caffeinebar-mvp` Requirement 7 acceptance criterion 1.
3. THE Wrapped card SHALL be exported as PNG and SHALL NOT be exported as JPEG, HEIC, PDF, or any other format.

### Requirement 34: Wrapped data points

**User Story:** As an Ultra user, I want the Wrapped to summarize my whole year of caffeine in one card, so that the card is rich enough to share but concise enough to read at a glance.

#### Acceptance Criteria

1. THE Wrapped card SHALL display the total cups logged for the calendar year covered by the Wrapped.
2. THE Wrapped card SHALL display the peak day (the calendar day with the highest cup count) along with that day's cup count.
3. THE Wrapped card SHALL display the average cups per day for the calendar year, computed across days the user logged at least one cup.
4. THE Wrapped card SHALL display the longest streak (the longest consecutive run of days with at least one log) for the calendar year.
5. THE Wrapped card SHALL display the top weekday by total cups (Monday through Sunday) for the calendar year.
6. THE Wrapped card SHALL display the top sound pack used for the calendar year, computed by the count of log events while each pack was selected.
7. THE Wrapped card SHALL display the count of "ambulance" trigger events (Cup-5+ events) for the calendar year.

### Requirement 35: Availability window — December 1 through January 15

**User Story:** As an Ultra user, I want the Wrapped surface to appear at the end of the year and stay available through mid-January, so that I have a real window to generate and share it.

#### Acceptance Criteria

1. WHILE the current wall-clock date is on or after December 1 of any year AND on or before January 15 of the following year, THE CaffeineBar SHALL surface the Wrapped card generation control inside the Popover and the SettingsView.
2. WHILE the current wall-clock date is outside the December 1 through January 15 window, THE CaffeineBar SHALL hide the Wrapped card generation control from the Popover and the SettingsView.
3. THE Wrapped card surfaced inside the December 1 through January 15 window SHALL summarize the most recent completed calendar year (i.e. the calendar year that ended on the most recent December 31).

### Requirement 36: Permanent personal Wrapped archive

**User Story:** As an Ultra user who missed the January 15 window, I want my generated Wrapped retained on disk so I can re-export it later, so that the artefact is not lost forever.

#### Acceptance Criteria

1. WHEN a Wrapped PNG is generated for a given calendar year, THE CaffeineBar SHALL persist the PNG into the WrappedArchive directory under the application support directory.
2. THE WrappedArchive directory SHALL be scoped to the current macOS user account.
3. WHILE a WrappedArchive entry exists for a given calendar year, THE SettingsView SHALL allow the user to re-export the archived PNG to the clipboard at any time, including outside the December 1 through January 15 window.

### Requirement 37: Sharing via NSPasteboard with watermark

**User Story:** As an Ultra user, I want one-click copy of the Wrapped PNG to my clipboard with a discoverable watermark, so that pasting into X or Slack carries the brand.

#### Acceptance Criteria

1. WHEN the user activates the "Share Wrapped card" control, THE Wrapped card SHALL be written to `NSPasteboard.general` using the same copy mechanism as the Pro tier streak ShareCard defined in `caffeinebar-mvp` Requirement 7 acceptance criterion 3.
2. THE Wrapped PNG SHALL include the watermark text "caffeinebar.app · YYYY Wrapped" where YYYY is the calendar year being summarized.
3. THE watermark SHALL be rendered as part of the PNG image and SHALL NOT be applied as a separate clipboard metadata field.

### Requirement 38: Marketing handoff to caffeinebar-launch deferred December moment

**User Story:** As the operator of the launch program, I want the Wrapped card defined as the artefact for the December Product Hunt moment, with the launch operating steps owned by the launch spec, so that the two specs do not duplicate operating procedure.

#### Acceptance Criteria

1. THE Wrapped card defined in this section SHALL be the artefact referenced by the December Wrapped Product Hunt launch moment deferred from `caffeinebar-launch` Requirement 60.
2. THIS spec SHALL NOT define launch-week operating steps, creator seeding cadence, paid-ad strategy, or upvote scheduling for the December Wrapped Product Hunt moment.
3. THIS spec SHALL satisfy the artefact prerequisite for the December Wrapped Product Hunt moment by ensuring Requirements 33 through 37 of this document are shippable on or before December 1.

### Requirement 39: Wrapped is computed entirely client-side; iCloud-synced data when sync is on

**User Story:** As a privacy-conscious Ultra user, I want my Wrapped computed locally with no server roundtrip, with multi-Mac data merged only when iCloud sync is on, so that the card is correct without sending my data anywhere new.

#### Acceptance Criteria

1. THE Wrapped card SHALL be computed entirely from local CaffeineBar data on the current Mac.
2. THE CaffeineBar SHALL NOT make any server roundtrip for the purpose of generating the Wrapped card.
3. WHILE iCloud sync is enabled per Requirement 16 of this document, THE Wrapped card SHALL include the union of synced data from all Macs that contributed history records to the CloudKit private database.
4. WHILE iCloud sync is disabled per Requirement 16 of this document, THE Wrapped card SHALL include only the data logged on the current Mac.

---

## Section F — Custom Sound Import

### Requirement 40: User-imported sound files for each escalation state

**User Story:** As an Ultra user, I want to import my own audio files for each cup level, so that I can replace the bundled escalation sounds with whatever I want to hear.

#### Acceptance Criteria

1. WHILE `resolvedTier` is `.ultra`, THE SettingsView SHALL allow the user to import a custom audio file for each of the six escalation states (Cup 1, Cup 2, Cup 3, Cup 4, Cup 5, Cup 5+).
2. THE custom sound import SHALL accept the file types `.m4a`, `.mp3`, and `.wav`.
3. WHILE a custom sound file is imported and selected for a given escalation state, THE SoundEngine SHALL play the imported file in place of the bundled asset for that state per `caffeinebar-mvp` Requirement 10.

### Requirement 41: NSOpenPanel file picker with size limits

**User Story:** As an Ultra user, I want a native macOS file picker filtered to audio types, with reasonable size limits, so that the import flow is familiar and the on-disk footprint stays bounded.

#### Acceptance Criteria

1. WHEN the user activates the "Choose file…" control for any escalation state, THE SettingsView SHALL present an `NSOpenPanel` filtered to file types `.m4a`, `.mp3`, and `.wav`.
2. IF a selected file's size exceeds 1 megabyte, THEN THE SettingsView SHALL reject the import and SHALL display the inline error copy "File too large. Maximum 1 MB per sound."
3. IF the cumulative size of all imported custom sound files exceeds 6 megabytes, THEN THE SettingsView SHALL reject the most recent import and SHALL display the inline error copy "Custom pack too large. Maximum 6 MB total."

### Requirement 42: Asset validation — duration, decode, no DRM

**User Story:** As an Ultra user importing a sound, I want the app to verify the file is playable before saving it, so that a bad file does not silently break my escalation pack.

#### Acceptance Criteria

1. WHEN a file is selected for import, THE SettingsView SHALL probe the file via `AVAudioPlayer` initialization to verify decode succeeds.
2. IF the AVAudioPlayer probe fails to decode the file, THEN THE SettingsView SHALL reject the import and SHALL display the inline error copy "File could not be decoded. Try a different audio file."
3. IF the AVAudioPlayer probe reports a duration greater than 3 seconds, THEN THE SettingsView SHALL reject the import and SHALL display the inline error copy "Sound too long. Maximum 3 seconds per sound."
4. IF the file contains DRM (e.g. an Apple Music protected track), THEN THE SettingsView SHALL reject the import and SHALL display the inline error copy "DRM-protected audio cannot be imported."

### Requirement 43: Per-cup mapping UI with preview

**User Story:** As an Ultra user, I want a per-state mapping UI with drag-and-drop and a preview button, so that I can audition sounds before committing them.

#### Acceptance Criteria

1. THE SettingsView SHALL display a row for each of the six escalation states (Cup 1, Cup 2, Cup 3, Cup 4, Cup 5, Cup 5+).
2. EACH row SHALL accept a dropped audio file via SwiftUI `onDrop` and SHALL also expose a "Choose file…" button that triggers the NSOpenPanel defined in Requirement 41 of this document.
3. EACH row SHALL expose a preview button that, when activated, plays the currently imported file for that escalation state through the SoundEngine.

### Requirement 44: Custom sound packs persisted to application support directory

**User Story:** As an Ultra user, I want my imported sounds saved in the standard macOS application support directory, so that they live where Apple expects user-imported assets to live.

#### Acceptance Criteria

1. WHEN a custom sound file is accepted by the validator defined in Requirement 42 of this document, THE CaffeineBar SHALL copy the file into a sandboxed subdirectory of the application support directory scoped to the current macOS user account.
2. THE CaffeineBar SHALL NOT modify, move, or delete the user's original source file.

### Requirement 45: Persistence across app updates via security-scoped bookmarks

**User Story:** As an Ultra user updating CaffeineBar to a new version, I want my custom sound pack to keep working without re-importing, so that an update never silently breaks my pack.

#### Acceptance Criteria

1. THE CaffeineBar SHALL persist file references to imported custom sound files as `Data`-encoded bookmarks.
2. THE persisted bookmarks SHALL use the security-scoped bookmark option where the macOS sandbox requires it.
3. WHEN the application launches and the SoundEngine resolves a custom sound reference, THE CaffeineBar SHALL resolve the persisted bookmark and SHALL use the resolved URL for playback.

### Requirement 46: Reset-to-default control

**User Story:** As an Ultra user, I want a single button that reverts my entire imported pack to the bundled defaults, so that I can recover from a bad import without re-importing six files.

#### Acceptance Criteria

1. THE SettingsView SHALL display a "Reset sound pack to default" control while `resolvedTier` is `.ultra`.
2. WHEN the user activates the "Reset sound pack to default" control, THE CaffeineBar SHALL revert the per-state mapping for all six escalation states to the Pro-tier bundled defaults defined in `caffeinebar-mvp` Requirement 21.
3. WHEN the user activates the "Reset sound pack to default" control, THE CaffeineBar SHALL retain the imported custom sound files on disk and SHALL NOT delete them.

### Requirement 47: Free / Pro users see custom sound import behind the Ultra blur gate

**User Story:** As a Free or Pro user, I want to see the custom sound import surface blurred with an Ultra unlock prompt, so that I understand what Ultra adds before I buy.

#### Acceptance Criteria

1. WHILE `resolvedTier` is `.free` or `.pro`, THE SettingsView SHALL render the custom sound import surface using the Pro-tier blur-and-unlock gating pattern defined in `caffeinebar-mvp` Requirement 23 acceptance criterion 1, substituting an "Unlock Ultra" call-to-action for the "Unlock Pro" call-to-action.
2. THE CaffeineBar SHALL NOT delete, hide, or restrict any logged Cup count, timestamp, streak value, or history record on the basis of the custom sound import gate, per the data-safety guarantee in `caffeinebar-mvp` Requirement 23 acceptance criterion 2.

---

## Section G — Mac App Store Distribution Decision

### Requirement 48: MAS distribution decision deferred from caffeinebar-launch

**User Story:** As the operator coordinating the launch and Ultra programs, I want the Day 90 Mac App Store distribution decision owned by this spec, so that the work that depends on Ultra entitlements lives where Ultra is specified.

#### Acceptance Criteria

1. THE Mac App Store distribution decision deferred from `caffeinebar-launch` Requirement 59 SHALL be evaluated under the criteria defined in this section.
2. THIS spec SHALL be the canonical owner of the MAS distribution decision framework, the entitlement audit, and the parity rules between direct-download and MAS distribution.

### Requirement 49: MAS trigger conditions

**User Story:** As the launch operator, I want MAS distribution opened only if the revenue trajectory and the Ultra feature shipment together justify it, so that we do not absorb MAS overhead before it pays for itself.

#### Acceptance Criteria

1. THE Launch operator SHALL open the MAS distribution path IF AND ONLY IF the Day 90 cumulative revenue is greater than or equal to $4,000 (the PRD §1.4 90-day target) AND at least two of the Ultra feature areas defined in Sections B through F of this document have shipped.
2. IF the Day 90 cumulative revenue is less than $4,000, THEN THE Launch operator SHALL defer the MAS distribution decision to the next quarterly review and SHALL retain a dated record of the deferral.
3. IF fewer than two Ultra feature areas have shipped at Day 90, THEN THE Launch operator SHALL defer the MAS distribution decision until at least two Ultra feature areas have shipped.

### Requirement 50: Sandbox compliance audit before MAS submission

**User Story:** As an engineer preparing the MAS build, I want every MVP component audited against the App Sandbox before submission, so that a sandbox violation never surfaces inside Apple's review.

#### Acceptance Criteria

1. THE MAS submission process SHALL audit the CallDetector's `NSWorkspace` running-applications inspection and CoreAudio active-input-stream check (defined in `caffeinebar-mvp` Requirement 14) against the App Sandbox entitlement set.
2. IF the App Sandbox entitlement set does not permit a CallDetector check required by `caffeinebar-mvp` Requirement 14, THEN THE MAS build SHALL exclude the affected CallDetector check and SHALL document the excluded check in the MAS submission package.
3. THE MAS build SHALL NOT ship to the MAS without a completed and dated sandbox compliance audit record.

### Requirement 51: Pricing parity between direct and MAS distribution

**User Story:** As a user comparing the direct download price and the MAS price, I want them identical, so that the channel I choose does not penalize me.

#### Acceptance Criteria

1. THE Pro tier price displayed in the MAS shall be $9.99, identical to the direct-download Pro price defined in `caffeinebar-mvp` Requirement 38 acceptance criterion 1.
2. THE Ultra tier price displayed in the MAS shall be $14.99, identical to the direct-download Ultra price defined in Requirement 1 of this document.
3. THE Apple platform fee (30% standard or 15% small business program) on MAS purchases SHALL be absorbed by the Launch operator and SHALL NOT be passed to the user as a price increase.

### Requirement 52: Direct-download .dmg remains the primary channel

**User Story:** As the launch operator, I want direct download to remain the primary distribution channel even if MAS ships, so that the operator retains direct customer relationships and lower fees.

#### Acceptance Criteria

1. WHILE MAS distribution is live, THE caffeinebar.app website SHALL continue to offer the notarized `.dmg` direct download defined in `caffeinebar-mvp` Requirement 49.
2. THE MAS distribution SHALL be additive to direct download and SHALL NOT replace direct download.

### Requirement 53: Polar.sh license remains valid in the MAS build; StoreKit purchase parity

**User Story:** As a user who bought Pro on caffeinebar.app and later installs the MAS build, I want my Polar.sh license to keep working, and I want a StoreKit purchase to unlock the same tier on the same Mac, so that the channels are interoperable.

#### Acceptance Criteria

1. WHEN a Polar.sh-issued license key is entered into the SettingsView license-entry field of the MAS build, THE LicenseManager SHALL validate the signature per `caffeinebar-mvp` Requirement 40 and SHALL update `resolvedTier` accordingly.
2. WHEN a StoreKit purchase of the Pro or Ultra tier completes inside the MAS build, THE CaffeineBar SHALL set `resolvedTier` to the corresponding tier on the current Mac for the current Apple ID.
3. THE CaffeineBar SHALL recognize at most one of (Polar.sh license, StoreKit purchase) as the active source of `resolvedTier` per Mac, with the higher tier winning if both sources resolve different tiers.

### Requirement 54: App Sandbox entitlements declared

**User Story:** As an engineer preparing the MAS build, I want only the minimum App Sandbox entitlements declared, so that the attack surface stays small and the App Sandbox audit passes.

#### Acceptance Criteria

1. THE MAS build entitlements file SHALL declare `com.apple.security.app-sandbox`.
2. THE MAS build entitlements file SHALL declare `com.apple.security.network.client` to permit CloudKit traffic and the license-validation network call.
3. THE MAS build entitlements file SHALL declare `com.apple.developer.healthkit` per Requirement 25 of this document.
4. THE MAS build entitlements file SHALL declare `com.apple.security.device.audio-input` only if the CallDetector audio-input check defined in `caffeinebar-mvp` Requirement 14 acceptance criterion 2 is retained in the MAS build.
5. THE MAS build entitlements file SHALL NOT declare any entitlement beyond the minimum set required by the features that ship in the MAS build.

---

## Section H — Post-MVP Build, Notarization, and QA

### Requirement 55: macOS minimum bumped only if a required API demands it

**User Story:** As an engineer scoping OS support, I want the macOS minimum to stay at Ventura unless a CloudKit, HealthKit, or AppIntents API used by Ultra requires a higher minimum, so that we do not gratuitously cut off existing users.

#### Acceptance Criteria

1. THE CaffeineBar `MACOSX_DEPLOYMENT_TARGET` SHALL remain at `13.0` unless an API used by an Ultra feature defined in Sections B, C, or D of this document requires a higher minimum.
2. IF an Ultra feature requires a higher `MACOSX_DEPLOYMENT_TARGET`, THEN THE Ultra release notes SHALL state the new minimum and the API that drove the bump.
3. THE CaffeineBar SHALL NOT bump the macOS minimum for cosmetic, stylistic, or non-essential API reasons.

### Requirement 56: Hardened Runtime entitlements updated for Ultra

**User Story:** As an engineer cutting the Ultra build, I want the Hardened Runtime entitlements set updated for every new capability Ultra introduces, so that notarization succeeds on the first attempt.

#### Acceptance Criteria

1. THE CaffeineBar entitlements file SHALL declare the `com.apple.developer.healthkit` entitlement per Requirement 25 of this document.
2. THE CaffeineBar entitlements file SHALL declare the CloudKit container entitlement `com.apple.developer.icloud-container-identifiers` referencing `iCloud.app.caffeinebar` per Requirement 8 acceptance criterion 3 of this document.
3. THE CaffeineBar entitlements file SHALL declare the AppIntents-related entitlements required for the LogCoffeeIntent to be discovered by Siri and Shortcuts.
4. THE CaffeineBar SHALL retain the Hardened Runtime entitlements declared by `caffeinebar-mvp` Requirement 48 unchanged.

### Requirement 57: Pre-submit notarization rehearsal re-run on entitlement change

**User Story:** As the Ultra release owner, I want a fresh notarization rehearsal on a clean VM before Ultra ships, so that the entitlement-set change does not surface as a launch-day failure.

#### Acceptance Criteria

1. THE Ultra release process SHALL re-execute the notarization rehearsal defined in `caffeinebar-mvp` Requirement 52 against the Ultra entitlement set on a clean macOS virtual machine that has no developer certificates installed at least 3 days before the public Ultra launch date.
2. IF the pre-submit notarization rehearsal fails on the Ultra entitlement set, THEN THE Ultra release process SHALL block the public Ultra launch until the failure is resolved.
3. THE Ultra notarization rehearsal SHALL be considered stale if any entitlement is added, removed, or modified after the rehearsal was executed, and a fresh rehearsal SHALL be required.

### Requirement 58: Unit tests for Ultra components

**User Story:** As the QA owner for the Ultra release, I want explicit unit tests for the new components, so that regressions in CloudKit conflict resolution, HealthKit writes, App Intent parameters, and custom sound validation are caught in CI.

#### Acceptance Criteria

1. THE CaffeineBarTests SHALL include a unit test that simulates two devices each contributing distinct timestamps to `todayTimestamps` for the same logical day and asserts that the conflict resolution per Requirement 11 of this document preserves the union of timestamps.
2. THE CaffeineBarTests SHALL include a unit test that mocks the HealthKit write success path and asserts that one caffeine sample of type `HKQuantityTypeIdentifier.dietaryCaffeine` is written per CupStore log per Requirement 17 of this document.
3. THE CaffeineBarTests SHALL include a unit test that exercises the LogCoffeeIntent's `cupCount` parameter at the boundary values 1, 5, 0, and 6, asserting acceptance per Requirement 29 of this document.
4. THE CaffeineBarTests SHALL include a unit test that exercises the custom sound asset validator per Requirement 42 of this document, covering the success path, an oversized file, an over-duration file, an undecodable file, and a DRM-protected file.

### Requirement 59: Integration tests — two real Macs cross-device sync

**User Story:** As the QA owner, I want a two-Mac integration test signed into the same iCloud account, so that the cross-device sync claim is validated against real CloudKit infrastructure.

#### Acceptance Criteria

1. THE Ultra release process SHALL execute an integration test in which two real Macs are signed into the same iCloud account and both run the CaffeineBar Ultra build.
2. WHEN one Mac in the integration test commits a log action, THE second Mac SHALL observe the synced state (`todayCount`, `todayTimestamps`, `streakDays`) within 5 minutes of network and CloudKit availability.
3. IF the integration test does not observe the synced state on the second Mac within 5 minutes, THEN THE Ultra release process SHALL block the public Ultra launch until the failure is resolved.

### Requirement 60: Privacy nutrition labels re-submission

**User Story:** As an Ultra release owner, I want App Privacy nutrition labels re-submitted for every new data flow, so that the public privacy declaration matches what Ultra actually does.

#### Acceptance Criteria

1. THE App Privacy nutrition labels SHALL be re-submitted for the Ultra release with declarations for HealthKit write data, CloudKit data, and App Intents donation activity.
2. THE App Privacy nutrition labels SHALL state that no HealthKit data is read by CaffeineBar per Requirement 18 of this document.
3. THE App Privacy nutrition labels SHALL state that CloudKit data is stored under the user's iCloud account and SHALL NOT claim that the developer has access to that data.
4. THE App Privacy nutrition labels SHALL state that App Intents donations are used solely to surface CaffeineBar in Siri Suggestions and SHALL NOT claim any other use.

---

## Section I — Backwards Compatibility & Data Safety

### Requirement 61: Existing Pro user data preserved on Ultra activation

**User Story:** As an existing Pro user activating Ultra, I want every byte of my local data preserved across the activation, so that my streak and history are never reset by an upgrade.

#### Acceptance Criteria

1. WHEN the LicenseManager transitions `resolvedTier` from `.pro` to `.ultra`, THE CupStore SHALL preserve every persisted field defined in `caffeinebar-mvp` Requirement 33 unchanged.
2. THE Ultra activation flow SHALL NOT execute any schema-breaking migration unless `dataVersion` is bumped per Requirement 62 of this document.
3. THE Ultra activation flow SHALL NOT delete any logged Cup count, timestamp, streak value, or history record.

### Requirement 62: dataVersion bumped to 2 only on schema change

**User Story:** As an engineer maintaining the migration path, I want `dataVersion` bumped only when a real schema change ships, so that the version field stays meaningful as a migration trigger.

#### Acceptance Criteria

1. THE CaffeineBar SHALL bump `caffeinebar.dataVersion` from `1` to `2` IF AND ONLY IF the Ultra release ships a schema-breaking change to the persisted UserDefaults shape.
2. WHEN `caffeinebar.dataVersion` is bumped from `1` to `2`, THE CaffeineBar SHALL execute the corresponding migration path exactly once on the first Ultra launch on a given Mac.
3. THE Ultra migration path SHALL be idempotent such that re-execution after the first run produces no further changes.
4. THE Ultra migration path SHALL NOT block any UI thread or any Popover render path, per the architectural rule in `caffeinebar-mvp` Requirement 36 acceptance criterion 2.

### Requirement 63: Ultra → Pro downgrade retains Ultra-only data on disk

**User Story:** As an Ultra user whose license expires, I want my Wrapped archive and my custom sound packs retained on disk, so that re-activating Ultra later restores my prior configuration.

#### Acceptance Criteria

1. WHEN the LicenseManager transitions `resolvedTier` from `.ultra` to a lower tier, THE CaffeineBar SHALL retain the WrappedArchive directory and every imported custom sound file on disk.
2. WHILE `resolvedTier` is below `.ultra` AND prior Ultra-only data exists on disk, THE SettingsView SHALL surface a "Re-activate Ultra to restore" prompt that references the retained data.
3. THE CaffeineBar SHALL NOT delete any Ultra-only data on disk on the basis of a tier downgrade.

### Requirement 64: CloudKit data on sync disable — local copy preserved, remote zone retained unless explicitly deleted

**User Story:** As an Ultra user disabling sync, I want my local data preserved and my remote zone left intact unless I explicitly choose to delete it, so that disabling sync never accidentally wipes data.

#### Acceptance Criteria

1. WHEN the user disables iCloud sync per Requirement 16 of this document, THE CaffeineBar SHALL retain the full local copy of every persisted field unchanged.
2. WHEN the user disables iCloud sync per Requirement 16 of this document, THE CaffeineBar SHALL NOT delete any record from the CloudKit private database.
3. THE SettingsView SHALL provide an explicit "Delete iCloud data" control distinct from the "Enable iCloud sync" toggle.
4. WHEN the user activates the "Delete iCloud data" control, THE CaffeineBar SHALL delete the CloudKit zone owned by CaffeineBar in the user's CloudKit private database, after the user confirms a destructive-action prompt.

### Requirement 65: Health data on disable — prior writes retained in Health.app

**User Story:** As an Ultra user revoking Health authorization, I want my prior caffeine samples to remain in Health under my control, so that revoking authorization does not destroy what was already shared.

#### Acceptance Criteria

1. WHEN the user revokes HealthKit caffeine write authorization for CaffeineBar at the macOS level, THE CaffeineBar SHALL stop writing new caffeine samples and SHALL NOT delete any caffeine sample CaffeineBar previously wrote.
2. THE CaffeineBar SHALL NOT call `HKHealthStore.delete` on any HealthKit caffeine sample under any user action other than an explicit, user-initiated "Delete CaffeineBar's Health samples" control, which is out of scope for the Ultra launch.
3. WHEN HealthKit write authorization is revoked, THE SettingsView HealthSyncIndicator SHALL display a quiet status string indicating that authorization is currently revoked.
