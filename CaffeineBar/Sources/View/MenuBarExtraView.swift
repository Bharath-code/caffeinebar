//
//  MenuBarExtraView.swift
//  CaffeineBar
//
//  SwiftUI Frontend Agent — Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 3.1–3.5, 4.1–4.4, 8.1, 8.2
//  Popover structure for the MenuBarExtra window.
//

import SwiftUI

/// The main popover view displayed when the user clicks the MenuBarIcon.
/// Fixed width 260pt, dynamic height, `.ultraThinMaterial` background.
@available(macOS 14.0, *)
struct MenuBarExtraView: View {

    // MARK: - Environment

    @Environment(CupStore.self) private var store
    @Environment(LicenseManager.self) private var license
    @Environment(MeetingMode.self) private var meetingMode
    @Environment(\.dismiss) private var dismiss

    // MARK: - Body

    var body: some View {
        VStack(spacing: 16) {
            // Hero cup count (Req 2.3)
            heroCupCount

            // "+1 Coffee" button (Req 2.4, 3.1–3.5)
            logButton

            // Undo affordance (Req 4.1–4.4)
            if store.todayCount > 0 {
                undoButton
            }

            // Today's timestamps or empty state (Req 2.5, 8.1, 8.2)
            timestampsOrEmptyState

            Spacer(minLength: 0)

            // Settings gear in bottom-right corner (Req 2.6)
            settingsRow
        }
        .padding()
        .frame(width: 260) // Fixed width 260pt (Req 2.1, 24.3)
        .background(.ultraThinMaterial) // Req 2.2
    }

    // MARK: - Subviews

    /// Hero cup count display with heavy rounded font (Req 2.3).
    private var heroCupCount: some View {
        Text("\(store.todayCount)")
            .font(.system(size: 44, weight: .heavy, design: .rounded))
            .dynamicTypeSize(...DynamicTypeSize.accessibility3)
    }

    /// "+1 Coffee" button with borderedProminent style and large control size (Req 2.4).
    /// Dismisses popover after log unless keepPopoverOpen is true (Req 3.3, 3.4).
    /// No confirmation dialog (Req 3.5).
    private var logButton: some View {
        Button("+1 Coffee") {
            store.logCup()
            if !store.keepPopoverOpen {
                dismiss()
            }
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
    }

    /// "Undo last coffee" button shown only when todayCount > 0 (Req 4.1).
    /// Wired to ⌘+Z keyboard shortcut (Req 4.4).
    private var undoButton: some View {
        Button("Undo last coffee") {
            store.undoLastCup()
        }
        .keyboardShortcut("z", modifiers: .command)
        .buttonStyle(.plain)
        .font(.caption)
        .foregroundStyle(.secondary)
    }

    /// Today's log timestamps or empty state (Reqs 2.5, 8.1, 8.2).
    private var timestampsOrEmptyState: some View {
        Group {
            if store.todayCount == 0 {
                // Empty state (Req 8.1)
                emptyState
            } else {
                // Timestamps list (Req 2.5)
                timestampsList
            }
        }
    }

    /// Empty state: low-opacity SF Symbol + copy (Req 8.1).
    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "cup.and.saucer.fill")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)
                .opacity(0.4)
            Text("Engine cold. Log your first cup.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    /// Today's log timestamps in monospaced caption font (Req 2.5).
    private var timestampsList: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(Array(store.todayTimestamps.enumerated()), id: \.offset) { _, timestamp in
                Text(timestamp, format: .dateTime.hour().minute())
                    .font(.system(.caption, design: .monospaced))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Settings gear icon in the bottom-right corner (Req 2.6)
    /// and Meeting Mode toggle (Req 16.1, 16.2, 16.3).
    private var settingsRow: some View {
        HStack {
            // Meeting Mode toggle (Req 16.1, 16.2)
            Button {
                meetingMode.toggle()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: meetingMode.isActive ? "speaker.slash.fill" : "speaker.slash")
                    if meetingMode.isActive {
                        // Visual indicator: small filled circle when active (Req 16.3)
                        Circle()
                            .fill(.orange)
                            .frame(width: 6, height: 6)
                    }
                }
            }
            .buttonStyle(.plain)
            .foregroundStyle(meetingMode.isActive ? .orange : .secondary)
            .help(meetingMode.isActive ? "Meeting Mode: ON — audio suppressed" : "Meeting Mode: OFF")

            Spacer()

            Button {
                // Settings action — will open SettingsView in a later task
            } label: {
                Image(systemName: "gearshape")
            }
            .buttonStyle(.plain)
        }
    }
}
