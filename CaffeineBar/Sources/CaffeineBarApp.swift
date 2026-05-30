//
//  CaffeineBarApp.swift
//  CaffeineBar
//
//  Lead Architect (Orchestrator) — Requirement: 46
//  Registers MenuBarExtra with .window style and injects shared state.
//

import SwiftUI
import Sparkle

/// CaffeineBar — macOS menu bar utility for tracking daily coffee intake.
/// LSUIElement = true: runs as a menu bar extra with no Dock icon (Req 46).
/// Minimum deployment target: macOS 13.0 (Ventura).
@available(macOS 14.0, *)
@main
struct CaffeineBarApp: App {

    // MARK: - Shared State

    /// The single source of truth for all logged data and user preferences.
    @State private var cupStore = CupStore()

    /// Observable license state. Defaults to `.free` until a valid key is entered.
    @State private var licenseManager = LicenseManager()

    /// Manual mute override — independent of CallDetector (Req 16).
    @State private var meetingMode = MeetingMode()

    /// Detects active voice/video calls to suppress audio (Req 14).
    @State private var callDetector = CallDetector()

    // MARK: - Computed (Req 29.2)

    /// Whether the current state is beyond the user's configured cut-off time.
    /// Used to append "Approaching cut-off." to the MenuBarIcon accessibility label.
    private var menuBarIconIsInCutoff: Bool {
        guard licenseManager.resolvedTier >= .pro,
              let lastLog = cupStore.todayTimestamps.last else {
            return false
        }
        return CutOffReminder.isBeyondCutOff(
            lastLogTimestamp: lastLog,
            halfLifeHours: cupStore.effectiveHalfLifeHours,
            bedtime: cupStore.bedtime
        )
    }

    // MARK: - Sparkle

    /// Sparkle updater controller for in-app updates (Reqs 50.1, 50.2).
    /// Starts the updater immediately so it checks for updates on launch.
    /// The 24-hour automatic check interval is configured in `configureUpdater()`.
    private let updaterController: SPUStandardUpdaterController

    init() {
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
        configureUpdater()

        // Activate call detection polling (Req 14)
        callDetector.startMonitoring()

        // Wire call state changes to SoundEngine suppression (Req 14.3)
        callDetector.onCallStateChanged = { isActive in
            SoundEngine.shared.setCallSuppressed(isActive)
        }
    }

    /// Configures Sparkle to check for updates every 24 hours (Req 50.1).
    /// Sparkle's standard user driver automatically prompts the user with
    /// release notes and an install button when an update is available (Req 50.2).
    private func configureUpdater() {
        let updater = updaterController.updater
        updater.automaticallyChecksForUpdates = true
        updater.updateCheckInterval = 86_400 // 24 hours in seconds
    }

    // MARK: - Body

    var body: some Scene {
        MenuBarExtra {
            MenuBarExtraView()
        } label: {
            // Req 29.2: Dynamic accessibility label based on cup count and escalation state
            Label {
                Text("CaffeineBar")
            } icon: {
                Image(systemName: IconRenderer.systemImageName(for: cupStore.todayCount))
            }
            .accessibilityLabel(
                IconRenderer.accessibilityLabel(
                    for: cupStore.todayCount,
                    isInCutoff: menuBarIconIsInCutoff
                )
            )
        }
        .menuBarExtraStyle(.window)
        .environment(cupStore)
        .environment(licenseManager)
        .environment(meetingMode)

        Window("CaffeineBar Settings", id: "settings") {
            SettingsView()
                .environment(cupStore)
                .environment(licenseManager)
                .onDisappear {
                    // Revert to accessory when settings closes
                    NSApp.setActivationPolicy(.accessory)
                }
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 380, height: 420)
        .windowStyle(.titleBar)
    }
}
