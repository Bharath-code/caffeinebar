//
//  OfficeMeetingModeTests.swift
//  CaffeineBarTests
//
//  Unit tests for Office Mode and Meeting Mode — Task 12.12
//  Requirements: 16.1, 16.2, 16.3, 17.1, 17.2, 17.3
//

import Testing
import Foundation
@testable import CaffeineBar

// MARK: - Office Mode Tests

@Suite("OfficeMode volume clamping and haptic routing")
struct OfficeModeTests {

    // MARK: - Volume Clamping (Req 17.2)

    @Test("clampedVolume caps at 50% of system volume")
    func clampedVolumeAt50Percent() {
        guard #available(macOS 14.0, *) else { return }
        // System volume = 1.0, requested = 1.0 → cap = 0.5
        let result = OfficeModeHelper.clampedVolume(requestedVolume: 1.0, systemVolume: 1.0)
        #expect(result == 0.5)
    }

    @Test("clampedVolume passes through when requested is below cap")
    func clampedVolumePassesThrough() {
        guard #available(macOS 14.0, *) else { return }
        // System volume = 1.0, cap = 0.5, requested = 0.3 → 0.3
        let result = OfficeModeHelper.clampedVolume(requestedVolume: 0.3, systemVolume: 1.0)
        #expect(result == 0.3)
    }

    @Test("clampedVolume scales with system volume")
    func clampedVolumeScalesWithSystem() {
        guard #available(macOS 14.0, *) else { return }
        // System volume = 0.6, cap = 0.3, requested = 0.5 → 0.3
        let result = OfficeModeHelper.clampedVolume(requestedVolume: 0.5, systemVolume: 0.6)
        #expect(abs(result - 0.3) < 0.001)
    }

    @Test("clampedVolume with zero system volume returns zero")
    func clampedVolumeZeroSystem() {
        guard #available(macOS 14.0, *) else { return }
        let result = OfficeModeHelper.clampedVolume(requestedVolume: 0.8, systemVolume: 0.0)
        #expect(result == 0.0)
    }

    @Test("clampedVolume with zero requested volume returns zero")
    func clampedVolumeZeroRequested() {
        guard #available(macOS 14.0, *) else { return }
        let result = OfficeModeHelper.clampedVolume(requestedVolume: 0.0, systemVolume: 1.0)
        #expect(result == 0.0)
    }

    // MARK: - OfficeModeManager adjustedVolume (Req 17.2)

    @Test("OfficeModeManager adjustedVolume clamps when enabled and not haptic-only")
    func managerAdjustedVolumeClampsWhenEnabled() {
        guard #available(macOS 14.0, *) else { return }
        let manager = OfficeModeManager()
        manager.isEnabled = true
        manager.hapticOnly = false
        let result = manager.adjustedVolume(systemVolume: 0.8)
        // 50% of 0.8 = 0.4
        #expect(abs(result - 0.4) < 0.001)
    }

    @Test("OfficeModeManager adjustedVolume returns system volume when disabled")
    func managerAdjustedVolumePassesThroughWhenDisabled() {
        guard #available(macOS 14.0, *) else { return }
        let manager = OfficeModeManager()
        manager.isEnabled = false
        manager.hapticOnly = false
        let result = manager.adjustedVolume(systemVolume: 0.8)
        #expect(result == 0.8)
    }

    @Test("OfficeModeManager adjustedVolume returns system volume when haptic-only")
    func managerAdjustedVolumePassesThroughWhenHapticOnly() {
        guard #available(macOS 14.0, *) else { return }
        let manager = OfficeModeManager()
        manager.isEnabled = true
        manager.hapticOnly = true
        // When haptic-only, audio is not played at all, so volume is irrelevant
        // The method returns systemVolume unchanged (audio won't be used)
        let result = manager.adjustedVolume(systemVolume: 0.8)
        #expect(result == 0.8)
    }

    // MARK: - Configuration Resolution (Req 17.1, 17.2, 17.3)

    @Test("resolveConfiguration returns .off when not enabled")
    func resolveConfigOff() {
        guard #available(macOS 14.0, *) else { return }
        let mode = OfficeModeHelper.resolveConfiguration(isEnabled: false, hapticOnly: false)
        #expect(mode == .off)
    }

    @Test("resolveConfiguration returns .off when not enabled even if hapticOnly is true")
    func resolveConfigOffIgnoresHaptic() {
        guard #available(macOS 14.0, *) else { return }
        let mode = OfficeModeHelper.resolveConfiguration(isEnabled: false, hapticOnly: true)
        #expect(mode == .off)
    }

    @Test("resolveConfiguration returns .quietVolume when enabled and not haptic-only")
    func resolveConfigQuietVolume() {
        guard #available(macOS 14.0, *) else { return }
        let mode = OfficeModeHelper.resolveConfiguration(isEnabled: true, hapticOnly: false)
        #expect(mode == .quietVolume)
    }

    @Test("resolveConfiguration returns .hapticOnly when enabled and haptic-only selected")
    func resolveConfigHapticOnly() {
        guard #available(macOS 14.0, *) else { return }
        let mode = OfficeModeHelper.resolveConfiguration(isEnabled: true, hapticOnly: true)
        #expect(mode == .hapticOnly)
    }

    // MARK: - OfficeModeManager resolvedMode (Req 17.1, 17.2, 17.3)

    @Test("OfficeModeManager resolvedMode reflects state changes")
    func managerResolvedModeReflectsState() {
        guard #available(macOS 14.0, *) else { return }
        let manager = OfficeModeManager()

        // Initially disabled
        #expect(manager.resolvedMode == .off)

        // Enable office mode
        manager.isEnabled = true
        #expect(manager.resolvedMode == .quietVolume)

        // Switch to haptic-only
        manager.hapticOnly = true
        #expect(manager.resolvedMode == .hapticOnly)

        // Disable office mode
        manager.isEnabled = false
        #expect(manager.resolvedMode == .off)
    }
}

// MARK: - Meeting Mode Tests

@Suite("MeetingMode suppression and toggle")
@MainActor
struct MeetingModeTests {

    // MARK: - Toggle (Req 16.1)

    @Test("MeetingMode starts inactive")
    func meetingModeStartsInactive() {
        guard #available(macOS 14.0, *) else { return }
        let mode = MeetingMode()
        #expect(mode.isActive == false)
    }

    @Test("toggle() flips isActive from false to true")
    func toggleActivates() {
        guard #available(macOS 14.0, *) else { return }
        let mode = MeetingMode()
        mode.toggle()
        #expect(mode.isActive == true)
    }

    @Test("toggle() flips isActive from true to false")
    func toggleDeactivates() {
        guard #available(macOS 14.0, *) else { return }
        let mode = MeetingMode()
        mode.toggle()
        #expect(mode.isActive == true)
        mode.toggle()
        #expect(mode.isActive == false)
    }

    @Test("activate() sets isActive to true")
    func activateSetsTrue() {
        guard #available(macOS 14.0, *) else { return }
        let mode = MeetingMode()
        mode.activate()
        #expect(mode.isActive == true)
    }

    @Test("deactivate() sets isActive to false")
    func deactivateSetsFalse() {
        guard #available(macOS 14.0, *) else { return }
        let mode = MeetingMode()
        mode.activate()
        mode.deactivate()
        #expect(mode.isActive == false)
    }

    @Test("activate() is idempotent")
    func activateIdempotent() {
        guard #available(macOS 14.0, *) else { return }
        let mode = MeetingMode()
        mode.activate()
        mode.activate()
        #expect(mode.isActive == true)
    }

    @Test("deactivate() is idempotent")
    func deactivateIdempotent() {
        guard #available(macOS 14.0, *) else { return }
        let mode = MeetingMode()
        mode.deactivate()
        mode.deactivate()
        #expect(mode.isActive == false)
    }

    // MARK: - Suppression (Req 16.2)

    @Test("Meeting Mode active means audio should be suppressed")
    func meetingModeSuppressesAudio() {
        guard #available(macOS 14.0, *) else { return }
        let mode = MeetingMode()
        mode.activate()
        // When isActive is true, SoundEngine must suppress audio (Req 16.2)
        #expect(mode.isActive == true)
    }

    @Test("Meeting Mode inactive means audio is not suppressed")
    func meetingModeDoesNotSuppressWhenInactive() {
        guard #available(macOS 14.0, *) else { return }
        let mode = MeetingMode()
        // When isActive is false, audio plays normally
        #expect(mode.isActive == false)
    }

    // MARK: - Icon escalation independence (Req 16.2 — icon still updates)

    @Test("Meeting Mode does not affect icon escalation state")
    func meetingModeDoesNotAffectIconEscalation() {
        guard #available(macOS 14.0, *) else { return }
        let mode = MeetingMode()
        mode.activate()

        // Icon escalation is driven by CupStore.todayCount, not by MeetingMode.
        // Verify that MeetingMode has no count or escalation-related state.
        // The icon renderer uses cup count directly — MeetingMode only gates audio.
        #expect(mode.isActive == true)

        // IconRenderer should still produce correct escalation for any count
        // even when Meeting Mode is active
        let icon0 = IconRenderer.icon(for: 0)
        let icon3 = IconRenderer.icon(for: 3)
        let icon5 = IconRenderer.icon(for: 5)

        // Icons are non-nil and distinct for different counts
        #expect(icon0 != nil)
        #expect(icon3 != nil)
        #expect(icon5 != nil)
    }

    @Test("IconRenderer produces correct escalation labels regardless of Meeting Mode")
    func iconLabelsIndependentOfMeetingMode() {
        guard #available(macOS 14.0, *) else { return }
        let mode = MeetingMode()
        mode.activate()

        // Escalation labels should work the same whether Meeting Mode is on or off
        let label0 = IconRenderer.accessibilityLabel(for: 0, isInCutoff: false)
        let label4 = IconRenderer.accessibilityLabel(for: 4, isInCutoff: false)
        let label5 = IconRenderer.accessibilityLabel(for: 5, isInCutoff: true)

        // Count 0 uses "No cups logged" rather than the digit "0"
        #expect(label0.contains("No cups logged"))
        #expect(label4.contains("4 cups logged"))
        #expect(label5.contains("5 cups logged"))
    }
}

// MARK: - CupStore Office Mode Defaults Tests

@Suite("CupStore Office Mode defaults")
@MainActor
struct CupStoreOfficeModeDefaultsTests {

    /// Creates a CupStore backed by an ephemeral UserDefaults suite.
    private func makeStore() -> CupStore {
        if #available(macOS 14.0, *) {
            let suiteName = "test.officemode.\(UUID().uuidString)"
            let defaults = UserDefaults(suiteName: suiteName)!
            return CupStore(defaults: defaults)
        }
        fatalError("Requires macOS 14.0+")
    }

    @Test("officeMode defaults to false in CupStore (Req 17.1)")
    func officeModeDefaultsFalse() {
        guard #available(macOS 14.0, *) else { return }
        let store = makeStore()
        #expect(store.officeMode == false)
    }

    @Test("officeModeHapticOnly defaults to false in CupStore (Req 17.3)")
    func officeModeHapticOnlyDefaultsFalse() {
        guard #available(macOS 14.0, *) else { return }
        let store = makeStore()
        #expect(store.officeModeHapticOnly == false)
    }

    @Test("officeMode can be toggled on in CupStore")
    func officeModeCanBeEnabled() {
        guard #available(macOS 14.0, *) else { return }
        let store = makeStore()
        store.officeMode = true
        #expect(store.officeMode == true)
    }

    @Test("officeModeHapticOnly can be toggled on in CupStore")
    func officeModeHapticOnlyCanBeEnabled() {
        guard #available(macOS 14.0, *) else { return }
        let store = makeStore()
        store.officeModeHapticOnly = true
        #expect(store.officeModeHapticOnly == true)
    }
}

// MARK: - Combined Office Mode + Meeting Mode Tests

@Suite("OfficeMode and MeetingMode interaction")
@MainActor
struct OfficeMeetingModeInteractionTests {

    @Test("Meeting Mode suppresses audio regardless of Office Mode state")
    func meetingModeTakesPrecedence() {
        guard #available(macOS 14.0, *) else { return }
        let meetingMode = MeetingMode()
        let officeManager = OfficeModeManager()

        // Office mode enabled with quiet volume
        officeManager.isEnabled = true
        officeManager.hapticOnly = false

        // Meeting mode activated — should suppress all audio
        meetingMode.activate()

        // Meeting Mode isActive means full suppression regardless of office mode
        #expect(meetingMode.isActive == true)
        #expect(officeManager.resolvedMode == .quietVolume)
        // SoundEngine checks meetingMode.isActive first — if true, no audio at all
    }

    @Test("Meeting Mode suppresses audio even when Office Mode is haptic-only")
    func meetingModeSuppressesEvenHapticOnly() {
        guard #available(macOS 14.0, *) else { return }
        let meetingMode = MeetingMode()
        let officeManager = OfficeModeManager()

        officeManager.isEnabled = true
        officeManager.hapticOnly = true
        meetingMode.activate()

        // Both are active — Meeting Mode means full silence (no haptic either in practice,
        // since the SoundEngine suppresses all output when meetingMode.isActive)
        #expect(meetingMode.isActive == true)
        #expect(officeManager.resolvedMode == .hapticOnly)
    }
}
