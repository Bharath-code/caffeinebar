//
//  UpsellNotifier.swift
//  CaffeineBar
//
//  SwiftUI Frontend Agent — Requirements: 22.1, 22.2
//  Posts a native macOS notification at Cup 4 for Free-tier users,
//  at most once per logical day.
//

import Foundation
import UserNotifications
import os

// MARK: - UpsellNotifier

/// Posts the Free-tier upsell notification when the user logs their 4th cup.
///
/// - Requirement 22.1: Post "Cup 4. Something is about to happen. Unlock CaffeineBar Pro to find out."
///   when cupCount == 4 AND tier == .free.
/// - Requirement 22.2: At most once per logical day.
@available(macOS 14.0, *)
enum UpsellNotifier {

    private static let logger = Logger(
        subsystem: "app.caffeinebar",
        category: "upsell"
    )

    /// UserDefaults key tracking the last date the upsell notification was posted.
    private static let lastUpsellDateKey = "caffeinebar.lastUpsellDate"

    // MARK: - Public API

    /// Posts the Free-tier upsell notification if conditions are met.
    ///
    /// Conditions:
    /// 1. `tier == .free`
    /// 2. `cupCount == 4`
    /// 3. The upsell has not already been posted today (same logical day).
    ///
    /// - Parameters:
    ///   - cupCount: The current cup count after the log action.
    ///   - tier: The user's current license tier.
    ///   - resetHour: The user's configured daily reset hour (0–23), used to determine the logical day boundary.
    static func postUpsellIfNeeded(
        cupCount: Int,
        tier: LicenseTier,
        resetHour: Int
    ) {
        // Only fire for Free tier at exactly cup 4
        guard tier == .free, cupCount == 4 else { return }

        // Check once-per-logical-day guard
        guard !hasPostedToday(resetHour: resetHour) else {
            logger.debug("Upsell already posted today. Skipping.")
            return
        }

        // Post the notification
        let content = UNMutableNotificationContent()
        content.title = "CaffeineBar"
        content.body = "Cup 4. Something is about to happen. Unlock CaffeineBar Pro to find out."
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "app.caffeinebar.upsell.\(UUID().uuidString)",
            content: content,
            trigger: nil // Deliver immediately
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                logger.error("Failed to post upsell notification: \(error.localizedDescription)")
            } else {
                logger.info("Posted Free-tier upsell notification at cup 4.")
                markPostedToday()
            }
        }
    }

    // MARK: - Once-Per-Day Guard

    /// Returns `true` if the upsell notification has already been posted during the current logical day.
    ///
    /// A "logical day" starts at the user's configured `resetHour`.
    private static func hasPostedToday(resetHour: Int) -> Bool {
        guard let lastPosted = UserDefaults.standard.object(forKey: lastUpsellDateKey) as? Date else {
            return false
        }

        let now = Date()
        let boundary = currentDayBoundary(resetHour: resetHour)

        // The upsell was posted after the current day's reset boundary
        return lastPosted >= boundary && lastPosted <= now
    }

    /// Records the current timestamp as the last upsell post date.
    private static func markPostedToday() {
        UserDefaults.standard.set(Date(), forKey: lastUpsellDateKey)
    }

    /// Computes the start of the current logical day based on the reset hour.
    /// If the reset boundary for today hasn't passed yet, uses yesterday's boundary.
    private static func currentDayBoundary(resetHour: Int) -> Date {
        let now = Date()
        let calendar = Calendar.current

        var boundary = calendar.startOfDay(for: now)
            .addingTimeInterval(TimeInterval(resetHour * 3600))

        // If the boundary is in the future, the current logical day started yesterday
        if boundary > now {
            if let yesterday = calendar.date(byAdding: .day, value: -1, to: now) {
                boundary = calendar.startOfDay(for: yesterday)
                    .addingTimeInterval(TimeInterval(resetHour * 3600))
            }
        }

        return boundary
    }
}
