//
//  OfficeMode.swift
//  CaffeineBar
//
//  Core Engine Agent — Requirements: 17.1, 17.2, 17.3
//
//  Office Mode provides a quieter alternative to full mute:
//  - Volume-capped mode: clamps playback gain to 50% of system volume (Req 17.2)
//  - Haptic-only mode: routes feedback to NSHapticFeedbackManager instead of audio (Req 17.3)
//  - Icon escalation is always preserved regardless of mode.
//

import AppKit
import Observation

// MARK: - OfficeMode

/// Office Mode configuration for audio output behavior.
///
/// - `off`: Normal playback — no volume capping.
/// - `quietVolume`: Clamp output volume to 50% of system volume (Req 17.2).
/// - `hapticOnly`: Replace audio with haptic feedback only (Req 17.3).
enum OfficeMode: Sendable {
    /// Normal playback — no volume clamping.
    case off
    /// Clamp output volume to 50% of system volume.
    case quietVolume
    /// Replace audio with haptic feedback only.
    case hapticOnly
}

// MARK: - OfficeModeManager

/// Observable Office Mode controller that coordinates with CupStore and SoundEngine.
///
/// Provides:
/// - `isEnabled`: bound to `CupStore.officeMode` (Req 17.1)
/// - `hapticOnly`: bound to `CupStore.officeModeHapticOnly` (Req 17.3)
/// - `adjustedVolume(systemVolume:)`: returns clamped volume when enabled (Req 17.2)
/// - `performHaptic()`: invokes NSHapticFeedbackManager (Req 17.3)
///
/// The SoundEngine uses `resolvedMode` to decide whether to clamp volume or
/// substitute haptic feedback. Icon escalation is always preserved.
@available(macOS 14.0, *)
@Observable
final class OfficeModeManager {

    // MARK: - State

    /// Whether Office Mode is enabled (bound to CupStore.officeMode).
    /// When true, audio is either volume-capped or replaced by haptic feedback.
    var isEnabled: Bool = false

    /// Whether haptic-only mode is active (bound to CupStore.officeModeHapticOnly).
    /// When true and `isEnabled` is true, haptic feedback replaces audio entirely.
    var hapticOnly: Bool = false

    // MARK: - Computed

    /// The resolved OfficeMode enum value based on current state.
    var resolvedMode: OfficeMode {
        OfficeModeHelper.resolveConfiguration(isEnabled: isEnabled, hapticOnly: hapticOnly)
    }

    // MARK: - Public API

    /// Returns the adjusted volume when Office Mode is enabled.
    ///
    /// When enabled (non-haptic), clamps volume to 50% of system volume (Req 17.2).
    /// When disabled, returns the system volume unchanged.
    ///
    /// - Parameter systemVolume: The current macOS system output volume (0.0–1.0).
    /// - Returns: The effective playback volume (0.0–1.0).
    func adjustedVolume(systemVolume: Float) -> Float {
        guard isEnabled, !hapticOnly else { return systemVolume }
        return min(systemVolume, systemVolume * 0.5)
    }

    /// Performs a haptic feedback tap as a substitute for audio playback (Req 17.3).
    ///
    /// Invokes `NSHapticFeedbackManager.defaultPerformer` with a generic
    /// alignment pattern performed immediately.
    func performHaptic() {
        NSHapticFeedbackManager.defaultPerformer.perform(
            .generic,
            performanceTime: .now
        )
    }
}

// MARK: - OfficeModeHelper

/// Engine helper that provides Office Mode volume clamping and haptic feedback.
///
/// The SoundEngine consults these methods before playing audio to determine
/// whether to clamp volume or substitute haptic feedback. Icon escalation
/// is always preserved regardless of Office Mode state.
@available(macOS 14.0, *)
enum OfficeModeHelper {

    // MARK: - Volume Clamping (Req 17.2)

    /// Returns the effective playback volume when Office Mode is in volume-capped mode.
    ///
    /// The effective volume is clamped to at most 50% of the system output volume.
    /// If the requested volume is already below the cap, it passes through unchanged.
    ///
    /// - Parameters:
    ///   - requestedVolume: The volume the SoundEngine would normally use (0.0–1.0).
    ///   - systemVolume: The current macOS system output volume (0.0–1.0).
    /// - Returns: The clamped volume value (0.0–1.0).
    static func clampedVolume(requestedVolume: Float, systemVolume: Float) -> Float {
        let cap = systemVolume * 0.5
        return min(requestedVolume, cap)
    }

    // MARK: - Haptic Feedback (Req 17.3)

    /// Performs a haptic feedback tap as a substitute for audio playback.
    ///
    /// Invokes `NSHapticFeedbackManager.defaultPerformer` with a generic
    /// alignment pattern performed immediately. This provides tactile
    /// confirmation of a log action without any audible output.
    static func performHapticFeedback() {
        NSHapticFeedbackManager.defaultPerformer.perform(
            .generic,
            performanceTime: .now
        )
    }

    // MARK: - Configuration Resolution

    /// Resolves the current Office Mode configuration from CupStore state.
    ///
    /// - Parameters:
    ///   - isEnabled: Whether `officeMode` is toggled on in CupStore (Req 17.1).
    ///   - hapticOnly: Whether the haptic-only sub-option is selected.
    /// - Returns: The resolved `OfficeMode`.
    static func resolveConfiguration(isEnabled: Bool, hapticOnly: Bool) -> OfficeMode {
        guard isEnabled else { return .off }
        return hapticOnly ? .hapticOnly : .quietVolume
    }
}
