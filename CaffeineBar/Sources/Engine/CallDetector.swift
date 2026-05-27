//
//  CallDetector.swift
//  CaffeineBar
//
//  Core Engine Agent — Requirements: 14.1, 14.2, 14.3
//

import AppKit
import CoreAudio
import Foundation
import os

// MARK: - CallDetector

/// Detects active voice/video calls by combining two heuristics:
/// 1. Bundle-ID scan of running applications for known call apps (Req 14.1).
/// 2. CoreAudio default-input-device "is running" check to catch browser-based
///    Meet/Teams calls (Req 14.2).
///
/// Polled on a 2-second timer. The cached `isCallActive` result is used by
/// `SoundEngine` to suppress audio playback while still allowing icon updates (Req 14.3).
@available(macOS 14.0, *)
final class CallDetector {

    // MARK: - Public API

    /// Cached result of the most recent call-detection poll.
    /// When `true`, audio playback should be suppressed (icon still updates).
    private(set) var isCallActive: Bool = false

    /// Callback invoked on the main thread when the call-active state changes.
    /// Used by `SoundEngine` to suppress/resume audio playback.
    var onCallStateChanged: ((Bool) -> Void)?

    // MARK: - Known Call Bundle IDs (Req 14.1)

    /// Bundle identifiers of known call/meeting applications.
    /// When any of these are running and active, we consider a call in progress.
    let knownCallBundles: Set<String> = [
        "us.zoom.xos",
        "com.apple.FaceTime"
    ]

    // MARK: - Private State

    private var pollTimer: Timer?
    private static let logger = Logger(
        subsystem: "app.caffeinebar",
        category: "CallDetector"
    )

    // MARK: - Lifecycle

    init() {}

    deinit {
        stopMonitoring()
    }

    // MARK: - Monitoring

    /// Starts the 2-second polling timer for call detection.
    /// Performs an initial check immediately, then polls every 2 seconds.
    func startMonitoring() {
        guard pollTimer == nil else { return }

        // Perform an initial check immediately
        updateCallStatus()

        pollTimer = Timer.scheduledTimer(
            withTimeInterval: 2.0,
            repeats: true
        ) { [weak self] _ in
            self?.updateCallStatus()
        }
    }

    /// Stops the polling timer and invalidates it.
    func stopMonitoring() {
        pollTimer?.invalidate()
        pollTimer = nil
    }

    // MARK: - Detection Logic

    /// Updates the cached `isCallActive` by combining both detection heuristics.
    /// Fires `onCallStateChanged` only when the state actually transitions.
    private func updateCallStatus() {
        let bundleDetected = scanRunningApplications()
        let audioInputActive = checkCoreAudioInputStreams()
        let newState = bundleDetected || audioInputActive

        let previousState = isCallActive
        isCallActive = newState

        // Only fire callback on actual state transitions
        if newState != previousState {
            onCallStateChanged?(newState)
        }
    }

    /// Scans `NSWorkspace.shared.runningApplications` for known call bundle IDs
    /// that are currently active (not terminated). (Req 14.1)
    ///
    /// - Returns: `true` if any known call application is running.
    func scanRunningApplications() -> Bool {
        let runningApps = NSWorkspace.shared.runningApplications

        for app in runningApps {
            guard let bundleID = app.bundleIdentifier else { continue }

            if knownCallBundles.contains(bundleID) {
                // Check that the app is not terminated
                if !app.isTerminated {
                    return true
                }
            }
        }

        return false
    }

    /// Queries CoreAudio to determine if the default input device is currently
    /// running (i.e., actively capturing audio). This catches browser-based
    /// calls (Google Meet, Microsoft Teams in browser) that don't have a
    /// dedicated bundle ID in `knownCallBundles`. (Req 14.2)
    ///
    /// - Returns: `true` if the default input device is running somewhere.
    func checkCoreAudioInputStreams() -> Bool {
        // Step 1: Get the default input device
        var deviceID = AudioObjectID(0)
        var propertySize = UInt32(MemoryLayout<AudioObjectID>.size)

        var addressDefaultInput = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        let statusInput = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &addressDefaultInput,
            0,
            nil,
            &propertySize,
            &deviceID
        )

        guard statusInput == noErr else {
            Self.logger.warning(
                "Failed to get default input device. OSStatus: \(statusInput)"
            )
            return false
        }

        // A device ID of 0 or kAudioObjectUnknown means no input device
        guard deviceID != 0, deviceID != kAudioObjectUnknown else {
            return false
        }

        // Step 2: Check if the device is running somewhere
        var isRunning: UInt32 = 0
        var runningSize = UInt32(MemoryLayout<UInt32>.size)

        var addressIsRunning = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceIsRunningSomewhere,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        let statusRunning = AudioObjectGetPropertyData(
            deviceID,
            &addressIsRunning,
            0,
            nil,
            &runningSize,
            &isRunning
        )

        guard statusRunning == noErr else {
            Self.logger.warning(
                "Failed to query device running state for device \(deviceID). OSStatus: \(statusRunning)"
            )
            return false
        }

        return isRunning != 0
    }
}
