//
//  HalfLifeClock.swift
//  CaffeineBar
//
//  SwiftUI Frontend Agent — Requirements: 18.1, 18.2, 18.3, 18.4
//  Displays the projected wall-clock time at which caffeine clears the user's system.
//

import SwiftUI

/// Displays the caffeine clearance time based on the user's last log and metabolism profile.
///
/// Clearance is defined as ~6 half-lives (97% elimination):
/// `clearanceTime = lastLogTimestamp + halfLifeHours × 6 hours`
///
/// Only renders content when `tier >= .pro`. The parent view is responsible for
/// hiding this view entirely when `todayCount == 0`.
@available(macOS 14.0, *)
struct HalfLifeClock: View {

    // MARK: - Inputs

    let lastLogTimestamp: Date
    let metabolismProfile: MetabolismProfile
    let tier: LicenseTier

    // MARK: - Computed

    /// The projected time at which caffeine from the last dose is 97% eliminated.
    var clearanceTime: Date {
        let clearanceSeconds = metabolismProfile.halfLifeHours * 6.0 * 3600.0
        return lastLogTimestamp.addingTimeInterval(clearanceSeconds)
    }

    /// Formatted clearance time as a wall-clock string (e.g. "9:47 PM").
    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        formatter.amSymbol = "AM"
        formatter.pmSymbol = "PM"
        return formatter.string(from: clearanceTime)
    }

    // MARK: - Body

    var body: some View {
        if tier >= .pro {
            HStack(spacing: 6) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(.caption))
                    .foregroundStyle(.secondary)

                Text("Caffeine clears at \(formattedTime)")
                    .font(.system(.caption, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Caffeine clears your system at \(formattedTime)")
        }
    }
}
