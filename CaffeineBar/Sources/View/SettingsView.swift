//
//  SettingsView.swift
//  CaffeineBar
//
//  SwiftUI Frontend Agent — Requirements: 5.2, 6.5, 11.1, 11.2, 11.3, 11.4, 15.1, 15.2, 17.1, 17.2, 17.3, 37.2
//  Settings form with reset hour picker, Office Mode toggles, sound controls, and streak stats.
//

import SwiftUI

/// Settings view providing the daily reset hour picker, Office Mode controls,
/// and streak statistics. Presentable from the settings gear in MenuBarExtraView.
@available(macOS 14.0, *)
struct SettingsView: View {

    // MARK: - Environment

    @Environment(CupStore.self) private var store

    // MARK: - Body

    var body: some View {
        Form {
            // Reset hour picker (Req 5.2)
            resetHourSection

            // Office Mode (Req 17.1, 17.2, 17.3)
            officeModeSection

            // Sound (Req 11.4, 15.2)
            soundSection

            // Streak stats (Req 6.5)
            streakStatsSection

            // iCloud sync note (Req 37.2)
            syncNoteSection
        }
        .formStyle(.grouped)
        .frame(width: 360, height: 400)
    }

    // MARK: - Sections

    /// Picker for the daily reset hour, 0–23, displayed in 12-hour format.
    private var resetHourSection: some View {
        Section("Daily Reset") {
            @Bindable var store = store
            Picker("Reset Hour", selection: $store.resetHour) {
                ForEach(0..<24, id: \.self) { hour in
                    Text(formattedHour(hour))
                        .tag(hour)
                }
            }
        }
    }

    /// Office Mode toggle and haptic-only sub-option (Reqs 17.1, 17.2, 17.3).
    private var officeModeSection: some View {
        Section("Office Mode") {
            @Bindable var store = store
            Toggle("Office Mode", isOn: $store.officeMode)
                .help("Caps volume to 50% or uses haptic feedback only")

            if store.officeMode {
                Toggle("Haptic only (no audio)", isOn: $store.officeModeHapticOnly)
                    .help("Replace sound with trackpad haptic tap")
                    .padding(.leading, 20)
            }
        }
    }

    /// Mute toggle and auto-mute on calls toggle (Reqs 11.4, 15.2).
    private var soundSection: some View {
        Section("Sound") {
            @Bindable var store = store
            Toggle("Mute", isOn: $store.isMuted)
                .help("Silences all sounds. Icon still updates.")

            Toggle("Auto-mute on calls", isOn: $store.autoMuteOnCalls)
                .help("Automatically mute during calls (Zoom, FaceTime)")
        }
    }

    /// Displays streak statistics: streakDays, personalRecord, totalDaysLogged.
    private var streakStatsSection: some View {
        Section("Streak Stats") {
            LabeledContent("Current Streak") {
                Text("\(store.streakDays) \(store.streakDays == 1 ? "day" : "days")")
            }
            LabeledContent("Personal Record") {
                Text("\(store.personalRecord) \(store.personalRecord == 1 ? "cup" : "cups")")
            }
            LabeledContent("Total Days Logged") {
                Text("\(store.totalDaysLogged) \(store.totalDaysLogged == 1 ? "day" : "days")")
            }
        }
    }

    /// Informational note about streak scope and future iCloud sync.
    private var syncNoteSection: some View {
        Section {
            Text("Streaks are per macOS user account; iCloud sync coming in Ultra.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Helpers

    /// Formats a 24-hour integer (0–23) into 12-hour display (e.g., "12:00 AM", "1:00 AM").
    private func formattedHour(_ hour: Int) -> String {
        let period = hour < 12 ? "AM" : "PM"
        let displayHour: Int
        switch hour {
        case 0:
            displayHour = 12
        case 1...11:
            displayHour = hour
        case 12:
            displayHour = 12
        default:
            displayHour = hour - 12
        }
        return "\(displayHour):00 \(period)"
    }
}
