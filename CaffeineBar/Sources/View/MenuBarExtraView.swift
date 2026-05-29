//
//  MenuBarExtraView.swift
//  CaffeineBar
//
//  SwiftUI Frontend Agent — Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 3.1–3.5, 4.1–4.4, 8.1, 8.2, 24.1, 24.2, 24.3, 25.1, 25.2, 25.3, 26.5, 27.1, 27.2, 28.1, 28.2, 28.3, 28.4, 28.5
//  Popover structure for the MenuBarExtra window.
//

import SwiftUI
import AppKit

// MARK: - PopoverControl Focus Enum (Req 28.4, 28.5)

/// Defines the focusable controls in the popover for Full Keyboard Access.
/// Tab order: logButton → undoButton → historyItem(0..n) → settingsGear (Req 28.5).
enum PopoverControl: Hashable {
    case logButton
    case undoButton
    case historyItem(Int)
    case settingsGear
}

/// The main popover view displayed when the user clicks the MenuBarIcon.
/// Fixed 280×500pt frame. `.ultraThinMaterial` background.
/// At `.accessibility1+` Dynamic Type sizes, horizontal rows re-flow to vertical stacks (Req 24.2).
@available(macOS 14.0, *)
struct MenuBarExtraView: View {

    // MARK: - Environment

    @Environment(CupStore.self) private var store
    @Environment(LicenseManager.self) private var license
    @Environment(MeetingMode.self) private var meetingMode
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast

    // MARK: - Focus State (Req 28.4)

    @FocusState private var focusedControl: PopoverControl?

    // MARK: - Animation State

    @State private var shakeOffset: CGFloat = 0
    @State private var pulseScale: CGFloat = 1.0
    @State private var boldStrokeFadeOpacity: Double = 1.0
    @State private var previousCupCount: Int = 0
    @State private var logBounceScale: CGFloat = 1.0

    // MARK: - Computed

    private var isAccessibilitySize: Bool {
        dynamicTypeSize >= .accessibility1
    }

    /// The escalation tint color for the hero count number.
    /// Matches the icon tint: cups 0-3 = primary, cup 4 = warning amber, cup 5+ = danger red.
    private var heroCountColor: Color {
        switch store.todayCount {
        case 0:
            return .secondary
        case 1, 2, 3:
            return .primary
        case 4:
            return .statusWarning
        default:
            return .statusDanger
        }
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            topSection

            Divider()
                .padding(.horizontal, 12)

            middleSection

            bottomToolbar
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Settings")
        }
        .frame(width: 280, height: 500)
        .background(.ultraThinMaterial)
        .onExitCommand { dismiss() }
        .defaultFocus($focusedControl, .logButton)
    }

    // MARK: - Top Section

    private var topSection: some View {
        VStack(alignment: .center, spacing: 6) {
            // Header
            Text("TODAY'S COFFEE")
                .font(.system(.caption2, weight: .semibold))
                .foregroundStyle(.tertiary)
                .tracking(0.5)
                .padding(.top, 4)

            // Hero cup count — centered, color escalates with state
            VStack(spacing: 0) {
                heroCountText
                Text(store.todayCount == 1 ? "cup" : "cups")
                    .font(.system(.caption, design: .rounded, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            // Escalation state chip + sound preview
            HStack(spacing: 8) {
                EscalationStateChip(cupCount: store.todayCount)

                // Sound preview button — plays a system sound as preview feedback
                if store.todayCount > 0 {
                    Button {
                        NSSound(named: "Tink")?.play()
                    } label: {
                        Image(systemName: "speaker.wave.1.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                            .padding(4)
                            .background(Circle().fill(.secondary.opacity(0.1)))
                    }
                    .buttonStyle(.plain)
                    .help("Preview sound")
                }
            }

            // Half-life clock — Pro only, cups > 0
            if store.todayCount > 0, let lastTimestamp = store.todayTimestamps.last {
                HalfLifeClock(
                    lastLogTimestamp: lastTimestamp,
                    metabolismProfile: store.metabolismProfile,
                    tier: license.resolvedTier
                )
                .proGated(tier: license.resolvedTier)
            }

            // Today's caffeine total
            if store.todayCount > 0 {
                Text("~\(store.todayCount * 95)mg caffeine today")
                    .font(.system(.caption2, weight: .medium))
                    .foregroundStyle(.tertiary)
            }

            // "+1 Coffee" button
            Button {
                store.logCup()
                // Haptic feedback on every log
                NSHapticFeedbackManager.defaultPerformer.perform(
                    .alignment,
                    performanceTime: .now
                )
                // Visual feedback bounce — stronger scale
                withAnimation(.spring(response: 0.15, dampingFraction: 0.4)) {
                    logBounceScale = 1.15
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                        logBounceScale = 1.0
                    }
                }
                triggerEscalationAnimation(for: store.todayCount)
                UpsellNotifier.postUpsellIfNeeded(
                    cupCount: store.todayCount,
                    tier: license.resolvedTier,
                    resetHour: store.resetHour
                )
                if !store.keepPopoverOpen {
                    dismiss()
                }
            } label: {
                HStack {
                    Label("+1 Coffee", systemImage: "cup.and.saucer.fill")
                    Spacer()
                    Text("⌘1")
                        .font(.system(.caption2, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, 4)
            .keyboardShortcut("1", modifiers: .command)
            .focused($focusedControl, equals: .logButton)

            // Undo button
            if store.todayCount > 0 {
                Button("Undo last coffee") {
                    store.undoLastCup()
                }
                .buttonStyle(.plain)
                .font(.system(.caption, weight: .medium))
                .foregroundStyle(.secondary)
                .keyboardShortcut("z", modifiers: .command)
                .focused($focusedControl, equals: .undoButton)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Hero Status")
    }

    // MARK: - Hero Count Text

    private var heroCountText: some View {
        Text("\(store.todayCount)")
            .font(.system(size: 48, weight: .heavy, design: .rounded))
            .foregroundStyle(heroCountColor)
            .dynamicTypeSize(...DynamicTypeSize.accessibility3)
            .contentTransition(reduceMotion ? .opacity : .numericText())
            .offset(x: reduceMotion ? 0 : shakeOffset)
            .scaleEffect(reduceMotion ? logBounceScale : pulseScale * logBounceScale)
            .opacity(reduceMotion && store.todayCount == 4 ? boldStrokeFadeOpacity : 1.0)
            .fontWeight(reduceMotion && store.todayCount == 4 ? .black : .heavy)
            .overlay {
                if reduceMotion && store.todayCount >= 5 {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.red.opacity(0.05))
                }
            }
            .animation(reduceMotion ? nil : .default, value: store.todayCount)
    }

    // MARK: - Escalation Animation Triggers

    private func triggerEscalationAnimation(for count: Int) {
        if reduceMotion {
            if count == 4 {
                boldStrokeFadeOpacity = 0
                withAnimation(.easeIn(duration: 0.4)) {
                    boldStrokeFadeOpacity = 1.0
                }
            }
            return
        }
        if count == 4 {
            triggerShakeAnimation()
        } else if count >= 5 {
            triggerPulseAnimation()
        }
    }

    private func triggerShakeAnimation() {
        let d: Double = 0.08
        withAnimation(.easeInOut(duration: d)) { shakeOffset = 6 }
        DispatchQueue.main.asyncAfter(deadline: .now() + d) {
            withAnimation(.easeInOut(duration: d)) { shakeOffset = -6 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + d * 2) {
            withAnimation(.easeInOut(duration: d)) { shakeOffset = 5 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + d * 3) {
            withAnimation(.easeInOut(duration: d)) { shakeOffset = -5 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + d * 4) {
            withAnimation(.easeInOut(duration: d)) { shakeOffset = 0 }
        }
    }

    private func triggerPulseAnimation() {
        withAnimation(.easeInOut(duration: 0.2)) { pulseScale = 1.2 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.easeInOut(duration: 0.2)) { pulseScale = 1.0 }
        }
    }

    // MARK: - Middle Section

    private var middleSection: some View {
        VStack(spacing: 0) {
            // Timestamps — scrollable, takes flexible space
            if store.todayCount == 0 {
                emptyState
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView(.vertical) {
                    timestampsList
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 6)
                }
                .scrollIndicators(.never)
                .padding(.horizontal, 16)
                .frame(minHeight: 80, maxHeight: .infinity)
            }

            Divider()
                .padding(.horizontal, 12)

            // Weekly chart — fixed height, always visible
            weeklyChartSection
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(height: 140)
        }
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
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("TODAY'S LOG")
                    .font(.system(.caption2, weight: .semibold))
                    .foregroundStyle(.tertiary)
                    .tracking(0.3)
                Spacer()
                if let lastLog = store.todayTimestamps.last {
                    let minutesAgo = max(1, Int(Date().timeIntervalSince(lastLog) / 60))
                    Text("\(minutesAgo) min ago")
                        .font(.system(size: 10))
                        .foregroundStyle(.quaternary)
                }
            }

            ForEach(Array(store.todayTimestamps.reversed().enumerated()), id: \.offset) { index, timestamp in
                timestampRow(index: index, timestamp: timestamp)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Today's Log History")
    }

    @ViewBuilder
    private func timestampRow(index: Int, timestamp: Date) -> some View {
        let cupNumber = store.todayCount - index
        let numberColor: Color = cupNumber >= 5 ? .statusDanger : (cupNumber == 4 ? .statusWarning : .gray)
        HStack(spacing: 6) {
            Text("#\(cupNumber)")
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundColor(numberColor)
            Text("·")
                .font(.system(size: 10))
                .foregroundColor(.gray)
            Text(timestamp, format: .dateTime.hour().minute())
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.secondary)
            Spacer()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(cupTimestampLabel(cupNumber: cupNumber, timestamp: timestamp))
        .focusable()
        .focused($focusedControl, equals: .historyItem(index))
    }

    private func cupTimestampLabel(cupNumber: Int, timestamp: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        formatter.amSymbol = "AM"
        formatter.pmSymbol = "PM"
        return "Cup \(cupNumber) at \(formatter.string(from: timestamp))"
    }

    // MARK: - Weekly Chart

    private var weeklyChartSection: some View {
        WeeklyGraphView(
            history: store.dailyHistory,
            todayCount: store.todayCount,
            cutoffThreshold: 4
        )
        .proGated(tier: license.resolvedTier)
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
                        Text("Meeting")
                            .font(.system(.caption2, weight: .medium))
                        Circle()
                            .fill(.orange)
                            .frame(width: 5, height: 5)
                    }
                }
                .padding(.horizontal, meetingMode.isActive ? 6 : 0)
                .padding(.vertical, meetingMode.isActive ? 2 : 0)
                .background {
                    if meetingMode.isActive {
                        Capsule().fill(Color.orange.opacity(0.12))
                    }
                }
                .increasedContrastBorder()
            }
            .buttonStyle(.plain)
            .foregroundStyle(meetingMode.isActive ? .orange : .secondary)

            // Share streak card (Pro-gated)
            if license.resolvedTier >= .pro && store.todayCount > 0 {
                Button {
                    let card = ShareCardView(
                        cupCount: store.todayCount,
                        streakDays: store.streakDays,
                        personalRecord: store.personalRecord
                    )
                    card.renderToPasteboard()
                    showShareCopied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) { showShareCopied = false }
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(.caption))
                }
                .buttonStyle(.plain)
                .foregroundStyle(showShareCopied ? .green : .secondary)
            }

            // Streak badge
            if store.streakDays > 0 {
                HStack(spacing: 2) {
                    Image(systemName: "flame.fill")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                    Text("\(store.streakDays)")
                        .font(.system(.caption2, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
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
            .focused($focusedControl, equals: .settingsGear)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}
