//
//  CutOffReminder.swift
//  CaffeineBar
//
//  SwiftUI Frontend Agent — Requirements: 19.1, 19.2, 19.3
//  Computes whether the current clearance time exceeds bedtime and posts
//  a notification on late logs for Pro/Ultra users.
//

import Foundation
import UserNotifications
import os

// MARK: - CutOffReminder

/// Provides cut-off time computation and notification posting for late-night logs.
///
/// - Requirement 19.1: Bedtime is configurable as a time-of-day value in SettingsView.
/// - Requirement 19.2: When clearanceTime > bedtime, the icon applies `status.warning` amber tint.
/// - Requirement 19.3: Posts "That's your problem tonight." notification on late logs (Pro/Ultra only).
@available(macOS 14.0, *)
enum CutOffReminder {

    private static let logger = Logger(
        subsystem: "app.caffeinebar",
        category: "cutoff"
    )

    // MARK: - Clearance Computation

    /// Computes the clearance time for the most recent log based on the effective half-life.
    /// Clearance is defined as ~6 half-lives (97% elimination).
    ///
    /// - Parameters:
    ///   - lastLogTimestamp: The timestamp of the most recent cup logged.
    ///   - halfLifeHours: The effective caffeine half-life in hours (adjusted for age/weight).
    /// - Returns: The projected wall-clock time at which caffeine clears the system.
    static func clearanceTime(
        lastLogTimestamp: Date,
        halfLifeHours: Double
    ) -> Date {
        let clearanceHours = halfLifeHours * 6.0
        return lastLogTimestamp.addingTimeInterval(clearanceHours * 3600)
    }

    /// Determines whether the computed clearance time exceeds the user's configured bedtime.
    ///
    /// Bedtime is stored as a full `Date` but only the hour and minute components are meaningful.
    /// This method extracts the time-of-day from `bedtime` and compares it against the clearance time
    /// on the same calendar day as the clearance time.
    ///
    /// - Parameters:
    ///   - lastLogTimestamp: The timestamp of the most recent cup logged.
    ///   - halfLifeHours: The effective caffeine half-life in hours (adjusted for age/weight).
    ///   - bedtime: The user's configured bedtime (only hour/minute are used).
    /// - Returns: `true` if the clearance time is later than bedtime on the relevant day.
    static func isBeyondCutOff(
        lastLogTimestamp: Date,
        halfLifeHours: Double,
        bedtime: Date
    ) -> Bool {
        let clearance = clearanceTime(lastLogTimestamp: lastLogTimestamp, halfLifeHours: halfLifeHours)
        let bedtimeToday = resolvedBedtime(for: clearance, bedtime: bedtime)
        return clearance > bedtimeToday
    }

    /// Resolves the bedtime `Date` to the same calendar day as the reference date.
    /// Extracts hour and minute from `bedtime` and applies them to the day of `referenceDate`.
    ///
    /// - Parameters:
    ///   - referenceDate: The date whose calendar day is used.
    ///   - bedtime: The stored bedtime (only hour/minute matter).
    /// - Returns: A `Date` representing bedtime on the same day as `referenceDate`.
    static func resolvedBedtime(for referenceDate: Date, bedtime: Date) -> Date {
        let calendar = Calendar.current
        let bedtimeComponents = calendar.dateComponents([.hour, .minute], from: bedtime)
        let dayComponents = calendar.dateComponents([.year, .month, .day], from: referenceDate)

        var combined = DateComponents()
        combined.year = dayComponents.year
        combined.month = dayComponents.month
        combined.day = dayComponents.day
        combined.hour = bedtimeComponents.hour
        combined.minute = bedtimeComponents.minute

        return calendar.date(from: combined) ?? referenceDate
    }

    // MARK: - Notification

    /// Posts a native macOS user notification with the body "That's your problem tonight."
    /// when a cup is logged and the resulting clearance time exceeds bedtime.
    ///
    /// Only fires when `tier >= .pro`.
    ///
    /// - Parameters:
    ///   - lastLogTimestamp: The timestamp of the cup just logged.
    ///   - halfLifeHours: The effective caffeine half-life in hours (adjusted for age/weight).
    ///   - bedtime: The user's configured bedtime.
    ///   - tier: The user's current license tier.
    static func postLateLogNotificationIfNeeded(
        lastLogTimestamp: Date,
        halfLifeHours: Double,
        bedtime: Date,
        tier: LicenseTier
    ) {
        // Only active for Pro/Ultra tier (Req 19.3)
        guard tier >= .pro else { return }

        // Check if clearance exceeds bedtime
        guard isBeyondCutOff(
            lastLogTimestamp: lastLogTimestamp,
            halfLifeHours: halfLifeHours,
            bedtime: bedtime
        ) else { return }

        // Post the notification
        let content = UNMutableNotificationContent()
        content.title = "CaffeineBar"
        content.body = "That's your problem tonight."
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "app.caffeinebar.cutoff.\(UUID().uuidString)",
            content: content,
            trigger: nil // Deliver immediately
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                logger.error("Failed to post cut-off notification: \(error.localizedDescription)")
            } else {
                logger.info("Posted late-log cut-off notification.")
            }
        }
    }

    /// Requests notification authorization if not already granted.
    /// Should be called early in the app lifecycle.
    static func requestNotificationAuthorizationIfNeeded() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound]
        ) { granted, error in
            if let error {
                logger.error("Notification authorization error: \(error.localizedDescription)")
            } else {
                logger.info("Notification authorization granted: \(granted)")
            }
        }
    }
}
