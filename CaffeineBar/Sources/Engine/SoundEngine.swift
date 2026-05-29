//
//  SoundEngine.swift
//  CaffeineBar
//
//  Audio & Media Agent — Requirements: 9.3, 12.1, 12.2, 12.3, 13.1, 13.2
//

import AVFoundation
import AppKit
import os

// MARK: - SoundEngine

/// Single-instance audio engine that plays escalation sounds on cup log events.
///
/// Design constraints (from caffeinebar-mvp Req 12):
/// - At most ONE `AVAudioPlayer` instance alive at any time (Req 12.1).
/// - Prior player is stopped and nil'd before allocating a new one (Req 12.2).
/// - `[weak self]` in every completion handler to prevent retain cycles (Req 12.3).
/// - Assets are lazy-loaded on first play, never at launch (Req 9.3).
/// - Failures are logged via `os.Logger`; the engine never crashes (Req 13.1, 13.2).
@available(macOS 14.0, *)
final class SoundEngine: NSObject, AVAudioPlayerDelegate {

    // MARK: - Shared Instance

    /// Shared singleton for global access from views that cannot use environment injection
    /// (SoundEngine is an NSObject subclass for AVAudioPlayerDelegate conformance).
    static let shared = SoundEngine()

    // MARK: - Properties

    /// The single active player instance — at most ONE at any time (Req 12.1).
    private var currentPlayer: AVAudioPlayer?

    /// Whether audio is suppressed by CallDetector.
    private var isCallSuppressed: Bool = false

    /// Whether audio is suppressed by MeetingMode.
    private var isMeetingSuppressed: Bool = false

    /// Whether the user has globally muted sound.
    private var isMuted: Bool = false

    /// The current office mode configuration.
    private var officeMode: OfficeMode = .off

    /// The currently selected sound pack ID. Defaults to "Default".
    var selectedPackID: String = "Default"

    /// Logger for sound-related diagnostics (Req 13.1, 13.2).
    private let logger = Logger(subsystem: "app.caffeinebar", category: "sound")

    // MARK: - Public API

    /// Called when a cup is logged. Resolves the appropriate sound asset
    /// and plays it, respecting mute/suppression/office-mode state.
    ///
    /// - Parameters:
    ///   - count: The new cup count after logging.
    ///   - tier: The user's current license tier.
    func cupLogged(count: Int, tier: LicenseTier) {
        guard !isMuted, !isCallSuppressed, !isMeetingSuppressed else { return }

        guard let assetURL = resolveAsset(for: count, tier: tier) else {
            return
        }

        play(asset: assetURL)
    }

    /// Sets the global mute state.
    ///
    /// When muted, `cupLogged(count:tier:)` suppresses all audio playback
    /// while the MenuBarIcon continues to update (Req 11.2, 11.3).
    ///
    /// - Parameter muted: `true` to mute all sound, `false` to resume.
    func setMuted(_ muted: Bool) {
        isMuted = muted
    }

    /// Sets the call-detection suppression state (called by CallDetector).
    ///
    /// When suppressed, audio playback is silenced while icon escalation
    /// continues (Req 14.3).
    ///
    /// - Parameter suppressed: `true` to suppress audio, `false` to resume.
    func setCallSuppressed(_ suppressed: Bool) {
        isCallSuppressed = suppressed
    }

    /// Sets the meeting-mode suppression state (called by MeetingMode toggle).
    ///
    /// When suppressed, audio playback is silenced while icon escalation
    /// continues (Req 16.2).
    ///
    /// - Parameter suppressed: `true` to suppress audio, `false` to resume.
    func setMeetingSuppressed(_ suppressed: Bool) {
        isMeetingSuppressed = suppressed
    }

    /// Sets the suppression state (convenience for combined call + meeting state).
    ///
    /// - Parameter suppressed: `true` to suppress audio, `false` to resume.
    func setSuppressed(_ suppressed: Bool) {
        isCallSuppressed = suppressed
    }

    /// Configures Office Mode behavior.
    ///
    /// - Parameters:
    ///   - enabled: Whether Office Mode is active (Req 17.1).
    ///   - hapticOnly: When `true` and enabled, routes feedback to
    ///     `NSHapticFeedbackManager` instead of playing audio (Req 17.3).
    ///     When `false` and enabled, clamps volume to 50% (Req 17.2).
    func setOfficeMode(enabled: Bool, hapticOnly: Bool) {
        officeMode = OfficeModeHelper.resolveConfiguration(
            isEnabled: enabled,
            hapticOnly: hapticOnly
        )
    }

    // MARK: - AVAudioPlayerDelegate

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        // Clean up the finished player — prevent stale references
        if currentPlayer === player {
            currentPlayer = nil
        }
    }

    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: (any Error)?) {
        logger.error("Audio decode error: \(error?.localizedDescription ?? "unknown", privacy: .public)")
        if currentPlayer === player {
            currentPlayer = nil
        }
    }

    // MARK: - Internal (Testable) API

    /// Plays a sound asset from the given URL. Exposed as `internal` for soak testing (Req 57).
    ///
    /// Before allocating a new player:
    /// 1. Stops the prior player (Req 12.2).
    /// 2. Sets the prior reference to nil (Req 12.2).
    /// 3. Creates a new AVAudioPlayer with delegate set to self (Req 12.3).
    ///
    /// On failure, logs via `os.Logger` and returns without crashing (Req 13.1).
    func play(asset url: URL) {
        // Stop and release prior player (Req 12.2)
        currentPlayer?.stop()
        currentPlayer = nil

        // Handle haptic-only office mode — no audio playback
        if officeMode == .hapticOnly {
            performHaptic()
            return
        }

        // Lazy-load the asset on first play (Req 9.3)
        let player: AVAudioPlayer
        do {
            player = try AVAudioPlayer(contentsOf: url)
        } catch {
            // Log error and return gracefully (Req 13.1)
            logger.error("Failed to load sound asset at \(url.path, privacy: .public): \(error.localizedDescription, privacy: .public)")
            return
        }

        // Apply office mode volume clamping (Req 17.2)
        if officeMode == .quietVolume {
            player.volume = min(1.0, 0.5)
        }

        // Set delegate for cleanup — delegate pattern uses weak reference semantics (Req 12.3)
        player.delegate = self
        currentPlayer = player

        if !player.play() {
            logger.error("Failed to play sound asset at \(url.path, privacy: .public)")
            currentPlayer = nil
        }
    }

    /// Resolves the sound asset URL for the given cup count and license tier.
    /// Delegates to SoundPackRegistry for pack-aware resolution (Req 10, 21).
    /// Returns nil if the sound is gated behind a tier the user doesn't have.
    private func resolveAsset(for count: Int, tier: LicenseTier) -> URL? {
        let pack = SoundPackRegistry.pack(for: selectedPackID)
        guard let url = SoundPackRegistry.resolveAssetURL(for: count, pack: pack, tier: tier) else {
            if count >= 1 && count < 4 {
                logger.warning("Sound asset not found for cup \(count, privacy: .public) in pack \(self.selectedPackID, privacy: .public)")
            }
            return nil
        }
        return url
    }

    /// Performs a haptic feedback tap as a substitute for audio in haptic-only office mode (Req 17.3).
    private func performHaptic() {
        OfficeModeHelper.performHapticFeedback()
    }
}
