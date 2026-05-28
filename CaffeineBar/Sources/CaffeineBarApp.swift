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

    // MARK: - Sparkle

    /// Sparkle updater controller for in-app updates (Req 50).
    /// `startingUpdater: false` during development — set to `true` for release builds
    /// once the EdDSA signing key is configured in the appcast.
    private let updaterController = SPUStandardUpdaterController(
        startingUpdater: false,
        updaterDelegate: nil,
        userDriverDelegate: nil
    )

    // MARK: - Body

    var body: some Scene {
        MenuBarExtra("CaffeineBar", systemImage: "cup.and.saucer") {
            MenuBarExtraView()
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
