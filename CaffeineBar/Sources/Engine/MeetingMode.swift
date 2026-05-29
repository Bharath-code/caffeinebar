//
//  MeetingMode.swift
//  CaffeineBar
//
//  Core Engine Agent — Requirements: 16.1, 16.2, 16.3
//

import Foundation
import Observation

// MARK: - MeetingMode

/// Manual mute override that suppresses all audio playback when active.
///
/// Meeting Mode is independent of `CallDetector` — it provides a guaranteed-silent
/// state the user can toggle from the MenuBarIcon right-click context menu (Req 16.1).
///
/// When `isActive` is true:
/// - `SoundEngine` must suppress all audio playback (Req 16.2).
/// - The MenuBarIcon should display a small dot badge indicator (Req 16.3).
///
/// ## Integration TODOs
/// - **Context Menu:** Wire the "Meeting Mode" toggle into the MenuBarExtra's
///   right-click context menu (SwiftUI `.contextMenu` or `NSMenu` on the status item).
/// - **Dot Badge:** The `IconRenderer` or `MenuBarExtra` configuration should observe
///   `isActive` and render a small dot badge on the MenuBarIcon when true.
/// - **SoundEngine:** `SoundEngine` should check `meetingMode.isActive` before playing
///   any asset and suppress playback when true.
@available(macOS 14.0, *)
@MainActor
@Observable
final class MeetingMode {

    // MARK: - State

    /// Whether Meeting Mode is currently active.
    /// When `true`, all audio playback is suppressed (Req 16.2).
    var isActive: Bool = false

    // MARK: - Public API

    /// Toggles Meeting Mode on or off.
    ///
    /// Called from the MenuBarIcon right-click context menu (Req 16.1).
    /// When toggled on, signals `SoundEngine` to suppress audio.
    /// When toggled off, audio playback resumes normally.
    func toggle() {
        isActive.toggle()
    }

    /// Activates Meeting Mode, suppressing all audio.
    func activate() {
        isActive = true
    }

    /// Deactivates Meeting Mode, allowing audio playback to resume.
    func deactivate() {
        isActive = false
    }
}
