//
//  MenuBarExtraView.swift
//  CaffeineBar
//
//  SwiftUI Frontend Agent — Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 3.1–3.5, 4.1–4.4, 8.1, 8.2
//  Popover structure for the MenuBarExtra window.
//

import SwiftUI

/// The main popover view displayed when the user clicks the MenuBarIcon.
/// Fixed size 260×320pt, `.ultraThinMaterial` background.
@available(macOS 14.0, *)
struct MenuBarExtraView: View {

    // MARK: - Environment

    @Environment(CupStore.self) private var store
    @Environment(LicenseManager.self) private var license
    @Environment(MeetingMode.self) private var meetingMode
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openWindow) private var openWindow

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Top section: hero count + button (fixed)
            topSection

            Divider()
                .padding(.horizontal, 12)

            // Middle section: timestamps (scrollable, fills remaining space)
            middleSection

            Divider()
                .padding(.horizontal, 12)

            // Bottom toolbar: Meeting Mode + Settings (fixed)
            bottomToolbar
        }
        .frame(width: 260, height: 320) // Fixed size — no jumping
        .background(.ultraThinMaterial) // Req 2.2
    }

    // MARK: - Top Section

    private var topSection: some View {
        VStack(spacing: 10) {
            // Header
            Text("Today's Coffee")
                .font(.system(.caption, weight: .medium))
                .foregroundStyle(.tertiary)
                .textCase(.uppercase)

            // Hero cup count (Req 2.3)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(store.todayCount)")
                    .font(.system(size: 48, weight: .heavy, design: .rounded))
                    .dynamicTypeSize(...DynamicTypeSize.accessibility3)
                    .contentTransition(.numericText())
                Text(store.todayCount == 1 ? "cup" : "cups")
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            // "+1 Coffee" button (Req 2.4)
            Button {
                store.logCup()
                if !store.keepPopoverOpen {
                    dismiss()
                }
            } label: {
                Label("+1 Coffee", systemImage: "plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, 4)

            // Undo button (Req 4.1–4.4)
            if store.todayCount > 0 {
                Button("Undo last coffee") {
                    store.undoLastCup()
                }
                .buttonStyle(.plain)
                .font(.system(.caption, weight: .medium))
                .foregroundStyle(.secondary)
            } else {
                // Invisible placeholder to prevent layout shift
                Text(" ")
                    .font(.system(.caption, weight: .medium))
                    .hidden()
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 10)
    }

    // MARK: - Middle Section (Timestamps / Empty State)

    private var middleSection: some View {
        Group {
            if store.todayCount == 0 {
                // Empty state (Req 8.1)
                VStack(spacing: 8) {
                    Spacer()
                    Image(systemName: "cup.and.saucer.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(.quaternary)
                    Text("Engine cold.\nLog your first cup.")
                        .font(.system(.caption, weight: .medium))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Timestamps list (Req 2.5)
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(Array(store.todayTimestamps.reversed().enumerated()), id: \.offset) { _, timestamp in
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(.secondary.opacity(0.3))
                                    .frame(width: 4, height: 4)
                                Text(timestamp, format: .dateTime.hour().minute())
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
                }
                .padding(.horizontal, 16)
            }
        }
        .frame(maxHeight: .infinity)
    }

    // MARK: - Bottom Toolbar

    private var bottomToolbar: some View {
        HStack {
            // Meeting Mode toggle (Req 16.1, 16.2)
            Button {
                meetingMode.toggle()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: meetingMode.isActive ? "speaker.slash.fill" : "speaker.wave.2")
                        .font(.system(.caption))
                    if meetingMode.isActive {
                        Circle()
                            .fill(.orange)
                            .frame(width: 5, height: 5)
                    }
                }
            }
            .buttonStyle(.plain)
            .foregroundStyle(meetingMode.isActive ? .orange : .secondary)
            .help(meetingMode.isActive ? "Meeting Mode: ON" : "Meeting Mode: OFF")

            Spacer()

            // Settings gear (Req 2.6)
            Button {
                NSApp.setActivationPolicy(.regular)
                NSApp.activate(ignoringOtherApps: true)
                openWindow(id: "settings")
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(.caption))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .help("Settings")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}
