# Notarization Rehearsal Checklist & Record

**Spec References:** caffeinebar-mvp Requirements 52.1, 52.2  
**Owner:** Build & Release Agent  
**Status:** Template — fill in during rehearsal execution

---

## Prerequisites

Before executing the rehearsal, confirm ALL of the following:

- [ ] Clean macOS VM provisioned (no developer certificates installed)
- [ ] VM has no Apple Developer account signed in via Xcode
- [ ] VM Keychain contains zero signing identities (`security find-identity -v -p codesigning` returns 0 matches)
- [ ] Rehearsal is scheduled ≥3 days before the planned launch date
- [ ] The `.dmg` artifact was produced by the CI pipeline (`.github/workflows/release.yml`)
- [ ] The `.dmg` has been notarized and stapled (`xcrun stapler validate` passes on the build machine)

---

## Step-by-Step Execution Procedure

### 1. Transfer the `.dmg` to the Clean VM

Transfer the notarized `.dmg` to the clean VM via a method that does not alter the file (e.g., `scp`, shared folder, AirDrop). Do NOT re-sign or modify the file after transfer.

### 2. Verify Gatekeeper Assessment

```bash
# Check that Gatekeeper accepts the DMG
spctl --assess --type open --context context:primary-signature --verbose CaffeineBar.dmg
```

**Expected output:** `CaffeineBar.dmg: accepted`

### 3. Open the `.dmg`

Double-click `CaffeineBar.dmg` in Finder (or use `open CaffeineBar.dmg` from Terminal).

- [ ] No Gatekeeper warning dialog appears
- [ ] No "unidentified developer" message
- [ ] No "damaged and can't be opened" message
- [ ] The disk image mounts successfully

### 4. Launch the App from the Mounted Volume

Open `CaffeineBar.app` directly from the mounted `.dmg` volume.

- [ ] No Gatekeeper warning on app launch
- [ ] App launches and displays the menu bar icon
- [ ] No crash on first launch

### 5. Verify Code Signature

```bash
# Verify the app's code signature
codesign --verify --deep --strict --verbose=2 /Volumes/CaffeineBar/CaffeineBar.app

# Check the notarization staple on the DMG
xcrun stapler validate CaffeineBar.dmg
```

### 6. Verify Entitlements Match

```bash
# Extract entitlements from the signed app
codesign -d --entitlements - /Volumes/CaffeineBar/CaffeineBar.app
```

Compare the output against the expected entitlements:
- `com.apple.security.app-sandbox` = `false`
- `com.apple.security.network.client` = `true`
- `com.apple.security.device.audio-input` = `true`

### 7. Record Entitlements Hash

```bash
# Compute SHA-256 of the entitlements file (from source repo)
shasum -a 256 CaffeineBar/CaffeineBar.entitlements
```

Record this hash — any change to it after the rehearsal voids the result.

### 8. Run the Automation Script (Optional)

```bash
./scripts/notarization-rehearsal.sh /path/to/CaffeineBar.dmg
```

---

## Pass/Fail Criteria

### PASS — All of the following must be true:

1. `spctl --assess` returns `accepted` for the `.dmg`
2. The `.dmg` opens without any Gatekeeper warning dialog
3. `CaffeineBar.app` launches without any Gatekeeper warning
4. `codesign --verify --deep --strict` passes on the app bundle
5. `xcrun stapler validate` passes on the `.dmg`
6. Extracted entitlements match the expected set exactly

### FAIL — Any of the following:

- Gatekeeper displays a warning or blocks the `.dmg` or app
- `spctl --assess` returns anything other than `accepted`
- Code signature verification fails
- Staple validation fails
- Entitlements mismatch

---

## What Voids the Rehearsal (Req 52.2)

The rehearsal is **immediately voided** if ANY of the following occur after it passes:

1. **Any entitlement added** to `CaffeineBar/CaffeineBar.entitlements`
2. **Any entitlement removed** from `CaffeineBar/CaffeineBar.entitlements`
3. **Any entitlement value modified** in `CaffeineBar/CaffeineBar.entitlements`
4. The SHA-256 hash of `CaffeineBar/CaffeineBar.entitlements` changes from the recorded value

### Tracking Entitlement Changes

The entitlements hash recorded at rehearsal time serves as the integrity check. Before any release:

```bash
# Compare current hash against recorded hash
CURRENT_HASH=$(shasum -a 256 CaffeineBar/CaffeineBar.entitlements | awk '{print $1}')
RECORDED_HASH="<hash from rehearsal record below>"

if [ "$CURRENT_HASH" != "$RECORDED_HASH" ]; then
    echo "⚠️  REHEARSAL VOIDED: Entitlements changed since rehearsal."
    echo "   A new rehearsal MUST be executed before launch."
fi
```

---

## How to Re-Run if Voided

1. Produce a new notarized `.dmg` from the CI pipeline with the updated entitlements
2. Provision a clean macOS VM (or reset the existing one to a clean snapshot)
3. Re-execute this entire checklist from the beginning
4. Record new results below

---

## Rehearsal Record

Fill in this section during execution:

| Field | Value |
|-------|-------|
| **Date of Rehearsal** | _YYYY-MM-DD_ |
| **Planned Launch Date** | _YYYY-MM-DD_ |
| **Days Before Launch** | _N (must be ≥3)_ |
| **macOS VM Version** | _e.g., macOS 14.5 Sonoma_ |
| **VM Signing Identities** | _0 (confirmed via `security find-identity`)_ |
| **DMG File** | _CaffeineBar-vX.Y.Z.dmg_ |
| **DMG SHA-256** | _hash_ |
| **Entitlements File SHA-256** | _hash_ |
| **spctl --assess Result** | _accepted / rejected_ |
| **Gatekeeper Warnings** | _none / describe_ |
| **App Launch Result** | _success / failure_ |
| **codesign --verify Result** | _pass / fail_ |
| **stapler validate Result** | _pass / fail_ |
| **Overall Result** | **PASS / FAIL** |
| **Executed By** | _name_ |
| **Notes** | _any observations_ |

---

## Rehearsal History

| Date | Version | Result | Entitlements Hash | Voided? | Reason |
|------|---------|--------|-------------------|---------|--------|
| _YYYY-MM-DD_ | _vX.Y.Z_ | _PASS/FAIL_ | _hash_ | _No/Yes_ | _—_ |

---

## References

- caffeinebar-mvp Requirement 52.1: Rehearsal on clean VM ≥3 days before launch
- caffeinebar-mvp Requirement 52.2: Entitlement change voids rehearsal
- caffeinebar-ultra Requirement 57: Ultra entitlement changes require re-rehearsal
- CI Workflow: `.github/workflows/release.yml`
- Entitlements: `CaffeineBar/CaffeineBar.entitlements`
