//
//  MenuBarExtraView.swift
//  CaffeineBar
//
//  SwiftUI Frontend Agent — Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 3.1–3.5, 4.1–4.4, 8.1, 8.2
//  Popover structure for the MenuBarExtra window.
//

import SwiftUI

/// The main popover view displayed when the user clicks the MenuBarIcon.
/// Fixed size 260×400pt, `.ultraThinMaterial` background.
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
            // Top: hero count + button + half-life
            topSection

            Divider()
                .padding(.horizontal, 12)

            // Middle: scrollable content area
            middleSection

            Divider()
                .padding(.horizontal, 12)

            // Bottom: always-visible toolbar
            bottomToolbar
        }
        .frame(width: 260, height: 400)
        .background(.ultraThinMaterial)
    }

    // MARK: - Top Section

    private var topSection: some View {
        VStack(spacing: 8) {
            // Header
            Text("TODAY'S COFFEE")
                .font(.system(.caption2, weight: .semibold))
                .foregroundStyle(.tertiary)
                .tracking(0.5)

            // Hero cup count
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(store.todayCount)")
                    .font(.system(size: 44, weight: .heavy, design: .rounded))
                    .dynamicTypeSize(...DynamicTypeSize.accessibility3)
                    .contentTransition(.numericText())
                Text(store.todayCount == 1 ? "cup" : "cups")
                    .font(.system(.callout, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            // Half-life clock — shown inline when Pro and cups > 0
            if store.todayCount > 0, let lastTimestamp = store.todayTimestamps.last {
                HalfLifeClock(
                    lastLogTimestamp: lastTimestamp,
                    metabolismProfile: store.metabolismProfile,
                    tier: license.resolvedTier
                )
                .proGated(tier: license.resolvedTier)
                .padding(.vertical, 2)
            }

            // "+1 Coffee" button
            Button {
                store.logCup()
                UpsellNotifier.postUpsellIfNeeded(
                    cupCount: store.todayCount,
                    tier: license.resolvedTier,
                    resetHour: store.resetHour
                )
                if !store.keepPopoverOpen {
                    dismiss()
                }
            } label: {
                Label("+1 Coffee", systemImage: "cup.and.saucer.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, 4)

            // Undo button
            if store.todayCount > 0 {
                Button("Undo last coffee") {
                    store.undoLastCup()
                }
                .buttonStyle(.plain)
                .font(.system(.caption, weight: .medium))
                .foregroundStyle(.secondary)
            } else {
                Text(" ").font(.caption).hidden()
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    // MARK: - Middle Section

    private var middleSection: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 10) {
                if store.todayCount == 0 {
                    // Empty state
                    emptyState
                } else {
                    // Timestamps
                    timestampsList
                }

                // Weekly chart — always shown (blurred for Free)
                weeklyChartSection
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 8)
        }
        .padding(.horizontal, 16)
        .frame(maxHeight: .infinity)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 6) {
            Image(systemName: "cup.and.saucer.fill")
                .font(.system(size: 20))
                .foregroundStyle(.quaternary)
            Text("Engine cold. Log your first cup.")
                .font(.system(.caption, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    // MARK: - Timestamps

    private var timestampsList: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("TODAY'S LOG")
                .font(.system(.caption2, weight: .semibold))
                .foregroundStyle(.tertiary)
                .tracking(0.3)

            ForEach(Array(store.todayTimestamps.reversed().enumerated()), id: \.offset) { _, timestamp in
                HStack(spacing: 6) {
                    Text("☕")
                        .font(.system(.caption2))
                    Text(timestamp, format: .dateTime.hour().minute())
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Weekly Chart

    private var weeklyChartSection: some View {
        WeeklyGraphView(
            history: store.dailyHistory,
            todayCount: store.todayCount,
            cutoffThreshold: 4
        )
        .proGated(tier: license.resolvedTier)
        .padding(.top, 4)
    }

    // MARK: - Bottom Toolbar

    @State private var showShareCopied = false

    private var bottomToolbar: some View {
        HStack(spacing: 12) {
            // Meeting Mode toggle
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

            // Share streak card (Pro-gated, Req 7.4)
            if license.resolvedTier >= .pro && store.todayCount > 0 {
                Button {
                    let card = ShareCardView(
                        cupCount: store.todayCount,
                        streakDays: store.streakDays,
                        personalRecord: store.personalRecord
                    )
                    card.renderToPasteboard()
                    showShareCopied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        showShareCopied = false
                    }
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(.caption))
                        if showShareCopied {
                            Text("Copied!")
                                .font(.system(.caption2, weight: .medium))
                        }
                    }
                }
                .buttonStyle(.plain)
                .foregroundStyle(showShareCopied ? .green : .secondary)
                .help("Copy streak card to clipboard")
            }

            Spacer()

            // Settings gear
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
