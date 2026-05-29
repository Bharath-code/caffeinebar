#!/bin/bash
# =============================================================================
# Notarization Rehearsal Verification Script
# =============================================================================
# Owner: Build & Release Agent
# Requirements: 52.1, 52.2
#
# This script automates the verifiable parts of the notarization rehearsal.
# It should be run on a clean macOS VM with no developer certificates.
#
# Usage:
#   ./scripts/notarization-rehearsal.sh <path-to-dmg>
#
# Example:
#   ./scripts/notarization-rehearsal.sh build/CaffeineBar.dmg
# =============================================================================

set -euo pipefail

# --- Configuration ---
ENTITLEMENTS_FILE="CaffeineBar/CaffeineBar.entitlements"
REHEARSAL_RECORD_FILE="docs/NOTARIZATION_REHEARSAL_RECORD.json"
APP_NAME="CaffeineBar"
EXPECTED_ENTITLEMENTS=(
    "com.apple.security.app-sandbox"
    "com.apple.security.network.client"
    "com.apple.security.device.audio-input"
)

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# --- Helper Functions ---
pass() { echo -e "${GREEN}✓ PASS:${NC} $1"; }
fail() { echo -e "${RED}✗ FAIL:${NC} $1"; FAILURES=$((FAILURES + 1)); }
warn() { echo -e "${YELLOW}⚠ WARN:${NC} $1"; }
info() { echo -e "  ℹ $1"; }

# --- Argument Validation ---
if [ $# -lt 1 ]; then
    echo "Usage: $0 <path-to-dmg>"
    echo ""
    echo "Options:"
    echo "  --check-only    Only verify entitlements hash against last rehearsal"
    echo ""
    exit 1
fi

FAILURES=0
DMG_PATH="$1"

# --- Check-only mode: verify entitlements haven't changed since last rehearsal ---
if [ "${1:-}" = "--check-only" ]; then
    echo "=== Entitlement Change Check ==="
    echo ""

    if [ ! -f "$REHEARSAL_RECORD_FILE" ]; then
        fail "No rehearsal record found at $REHEARSAL_RECORD_FILE"
        echo "   Run a full rehearsal first."
        exit 1
    fi

    if [ ! -f "$ENTITLEMENTS_FILE" ]; then
        fail "Entitlements file not found at $ENTITLEMENTS_FILE"
        exit 1
    fi

    CURRENT_HASH=$(shasum -a 256 "$ENTITLEMENTS_FILE" | awk '{print $1}')
    RECORDED_HASH=$(python3 -c "import json; print(json.load(open('$REHEARSAL_RECORD_FILE'))['entitlements_sha256'])" 2>/dev/null || echo "")

    if [ -z "$RECORDED_HASH" ]; then
        fail "Could not read entitlements hash from rehearsal record"
        exit 1
    fi

    if [ "$CURRENT_HASH" = "$RECORDED_HASH" ]; then
        pass "Entitlements unchanged since last rehearsal"
        info "Hash: $CURRENT_HASH"
    else
        fail "REHEARSAL VOIDED: Entitlements have changed!"
        info "Recorded: $RECORDED_HASH"
        info "Current:  $CURRENT_HASH"
        echo ""
        echo "A new notarization rehearsal MUST be executed before launch."
    fi
    exit $FAILURES
fi

# --- Full Rehearsal Mode ---
echo "=============================================="
echo " CaffeineBar Notarization Rehearsal"
echo "=============================================="
echo ""
echo "Date: $(date '+%Y-%m-%d %H:%M:%S %Z')"
echo "DMG:  $DMG_PATH"
echo ""

# --- Step 0: Validate DMG exists ---
if [ ! -f "$DMG_PATH" ]; then
    fail "DMG file not found: $DMG_PATH"
    exit 1
fi
pass "DMG file exists"

# --- Step 1: Check for developer certificates (clean VM verification) ---
echo ""
echo "--- Step 1: Clean VM Verification ---"

SIGNING_IDENTITIES=$(security find-identity -v -p codesigning 2>/dev/null | grep -c "valid identities found" || true)
IDENTITY_COUNT=$(security find-identity -v -p codesigning 2>/dev/null | tail -1 | grep -oE '[0-9]+' || echo "0")

if [ "$IDENTITY_COUNT" = "0" ]; then
    pass "No developer signing identities found (clean VM confirmed)"
else
    warn "Found $IDENTITY_COUNT signing identities — this may not be a clean VM"
    info "For a valid rehearsal, the VM should have 0 developer certificates"
fi

# --- Step 2: Compute entitlements hash ---
echo ""
echo "--- Step 2: Entitlements Hash ---"

if [ -f "$ENTITLEMENTS_FILE" ]; then
    ENTITLEMENTS_HASH=$(shasum -a 256 "$ENTITLEMENTS_FILE" | awk '{print $1}')
    pass "Entitlements file found"
    info "SHA-256: $ENTITLEMENTS_HASH"
else
    warn "Entitlements file not found at $ENTITLEMENTS_FILE (expected if running on VM without source)"
    ENTITLEMENTS_HASH="NOT_AVAILABLE_ON_VM"
fi

# --- Step 3: Gatekeeper assessment on DMG ---
echo ""
echo "--- Step 3: Gatekeeper Assessment (DMG) ---"

DMG_HASH=$(shasum -a 256 "$DMG_PATH" | awk '{print $1}')
info "DMG SHA-256: $DMG_HASH"

SPCTL_RESULT=$(spctl --assess --type open --context context:primary-signature --verbose "$DMG_PATH" 2>&1 || true)
if echo "$SPCTL_RESULT" | grep -q "accepted"; then
    pass "spctl --assess: DMG accepted by Gatekeeper"
else
    fail "spctl --assess: DMG NOT accepted by Gatekeeper"
    info "Output: $SPCTL_RESULT"
fi

# --- Step 4: Stapler validation ---
echo ""
echo "--- Step 4: Notarization Staple Validation ---"

STAPLER_RESULT=$(xcrun stapler validate "$DMG_PATH" 2>&1 || true)
if echo "$STAPLER_RESULT" | grep -qi "valid"; then
    pass "Notarization ticket is stapled and valid"
else
    fail "Notarization staple validation failed"
    info "Output: $STAPLER_RESULT"
fi

# --- Step 5: Mount DMG and verify app ---
echo ""
echo "--- Step 5: Mount DMG & Verify App ---"

MOUNT_POINT=$(hdiutil attach "$DMG_PATH" -nobrowse -noverify 2>/dev/null | grep "/Volumes" | awk -F'\t' '{print $NF}' | xargs)

if [ -z "$MOUNT_POINT" ]; then
    fail "Failed to mount DMG"
else
    pass "DMG mounted at: $MOUNT_POINT"

    APP_PATH="$MOUNT_POINT/$APP_NAME.app"

    if [ -d "$APP_PATH" ]; then
        pass "App bundle found: $APP_PATH"

        # Verify code signature
        echo ""
        echo "--- Step 6: Code Signature Verification ---"

        CODESIGN_RESULT=$(codesign --verify --deep --strict --verbose=2 "$APP_PATH" 2>&1 || true)
        if echo "$CODESIGN_RESULT" | grep -q "valid on disk"; then
            pass "Code signature is valid"
        else
            fail "Code signature verification failed"
            info "Output: $CODESIGN_RESULT"
        fi

        # Gatekeeper assessment on app
        echo ""
        echo "--- Step 7: Gatekeeper Assessment (App) ---"

        APP_SPCTL_RESULT=$(spctl --assess --verbose "$APP_PATH" 2>&1 || true)
        if echo "$APP_SPCTL_RESULT" | grep -q "accepted"; then
            pass "spctl --assess: App accepted by Gatekeeper"
        else
            fail "spctl --assess: App NOT accepted by Gatekeeper"
            info "Output: $APP_SPCTL_RESULT"
        fi

        # Extract and display entitlements from signed app
        echo ""
        echo "--- Step 8: Entitlements Extraction ---"

        APP_ENTITLEMENTS=$(codesign -d --entitlements - "$APP_PATH" 2>/dev/null || echo "EXTRACTION_FAILED")
        if [ "$APP_ENTITLEMENTS" != "EXTRACTION_FAILED" ]; then
            pass "Entitlements extracted from signed app"
            echo "$APP_ENTITLEMENTS" | grep -A1 "com.apple.security" | head -20
        else
            warn "Could not extract entitlements from app"
        fi
    else
        fail "App bundle not found at expected path: $APP_PATH"
    fi

    # Unmount
    hdiutil detach "$MOUNT_POINT" -quiet 2>/dev/null || true
    info "DMG unmounted"
fi

# --- Summary ---
echo ""
echo "=============================================="
echo " REHEARSAL SUMMARY"
echo "=============================================="
echo ""
echo "Date:              $(date '+%Y-%m-%d %H:%M:%S %Z')"
echo "DMG:               $DMG_PATH"
echo "DMG SHA-256:       $DMG_HASH"
echo "Entitlements Hash: $ENTITLEMENTS_HASH"
echo "Failures:          $FAILURES"
echo ""

if [ $FAILURES -eq 0 ]; then
    echo -e "${GREEN}══════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  RESULT: PASS — Rehearsal successful${NC}"
    echo -e "${GREEN}══════════════════════════════════════════════${NC}"
else
    echo -e "${RED}══════════════════════════════════════════════${NC}"
    echo -e "${RED}  RESULT: FAIL — $FAILURES check(s) failed${NC}"
    echo -e "${RED}══════════════════════════════════════════════${NC}"
fi

# --- Record results to JSON ---
echo ""
echo "--- Recording Results ---"

cat > "$REHEARSAL_RECORD_FILE" << EOF
{
    "rehearsal_date": "$(date -u '+%Y-%m-%dT%H:%M:%SZ')",
    "dmg_path": "$DMG_PATH",
    "dmg_sha256": "$DMG_HASH",
    "entitlements_file": "$ENTITLEMENTS_FILE",
    "entitlements_sha256": "$ENTITLEMENTS_HASH",
    "signing_identities_on_vm": $IDENTITY_COUNT,
    "macos_version": "$(sw_vers -productVersion 2>/dev/null || echo 'unknown')",
    "macos_build": "$(sw_vers -buildVersion 2>/dev/null || echo 'unknown')",
    "failures": $FAILURES,
    "result": "$([ $FAILURES -eq 0 ] && echo 'PASS' || echo 'FAIL')",
    "notes": "Automated rehearsal via notarization-rehearsal.sh"
}
EOF

pass "Results recorded to $REHEARSAL_RECORD_FILE"
echo ""
echo "IMPORTANT: Any change to $ENTITLEMENTS_FILE after this rehearsal"
echo "           voids the result. Run './scripts/notarization-rehearsal.sh --check-only'"
echo "           before release to verify entitlements are unchanged."
echo ""

exit $FAILURES
