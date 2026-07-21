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
    @State private var activeTab: Int = 0

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
                    halfLifeHours: store.effectiveHalfLifeHours,
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
                // Play escalation sound via shared SoundEngine (Req 9.3, 12.1)
                // Sync mute/suppression state before playing
                SoundEngine.shared.setMuted(store.isMuted)
                SoundEngine.shared.setMeetingSuppressed(meetingMode.isActive)
                SoundEngine.shared.cupLogged(count: store.todayCount, tier: license.resolvedTier)
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
                Button {
                    store.undoLastCup()
                } label: {
                    HStack(spacing: 4) {
                        Text("Undo last coffee")
                        Text("⌘Z")
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                            .foregroundStyle(.tertiary)
                    }
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
            if store.todayCount == 0 {
                emptyState
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Picker("", selection: $activeTab) {
                    Text("History").tag(0)
                    Text("Predictor").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.top, 4)
                .padding(.bottom, 6)

                if activeTab == 0 {
                    ScrollView(.vertical) {
                        timestampsList
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 6)
                    }
                    .scrollIndicators(.never)
                    .padding(.horizontal, 16)
                    .frame(minHeight: 80, maxHeight: .infinity)

                    Divider()
                        .padding(.horizontal, 12)

                    // Weekly chart — fixed height, always visible
                    weeklyChartSection
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .frame(height: 140)
                } else {
                    predictorView
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.horizontal, 16)
                }
            }
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

    /// Groups timestamps by time of day: Morning (before 12), Afternoon (12-17), Evening (17+)
    private enum TimeOfDay: String {
        case morning = "Morning"
        case afternoon = "Afternoon"
        case evening = "Evening"

        static func from(_ date: Date) -> TimeOfDay {
            let hour = Calendar.current.component(.hour, from: date)
            if hour < 12 { return .morning }
            if hour < 17 { return .afternoon }
            return .evening
        }
    }

    private var timestampsList: some View {
        VStack(alignment: .leading, spacing: 6) {
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

            // Group by time of day
            let grouped = groupedTimestamps()
            ForEach(grouped, id: \.period) { group in
                // Period header
                Text(group.period)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.quaternary)
                    .textCase(.uppercase)
                    .padding(.top, group.period == grouped.first?.period ? 0 : 4)

                ForEach(group.entries, id: \.index) { entry in
                    timestampRow(index: entry.index, timestamp: entry.timestamp)
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Today's Log History")
    }

    private struct TimestampGroup {
        let period: String
        let entries: [(index: Int, timestamp: Date)]
    }

    private func groupedTimestamps() -> [TimestampGroup] {
        let reversed = Array(store.todayTimestamps.reversed().enumerated())
        var groups: [String: [(index: Int, timestamp: Date)]] = [:]
        var order: [String] = []

        for (index, timestamp) in reversed {
            let period = TimeOfDay.from(timestamp).rawValue
            if groups[period] == nil {
                order.append(period)
                groups[period] = []
            }
            groups[period]?.append((index: index, timestamp: timestamp))
        }

        return order.compactMap { period in
            guard let entries = groups[period] else { return nil }
            return TimestampGroup(period: period, entries: entries)
        }
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

    // MARK: - Predictor View (Reqs: 18, 19 integration)

    private var predictorView: some View {
        VStack(spacing: 12) {
            // Chart Area
            VStack(alignment: .leading, spacing: 4) {
                Text("CAFFEINE TIMELINE (24H)")
                    .font(.system(.caption2, weight: .bold))
                    .foregroundStyle(.tertiary)
                
                caffeineCurveChart
                    .frame(height: 110)
                    .background(Color.black.opacity(0.15))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.06), lineWidth: 1)
                    )
            }

            // Calculations Grid
            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 8) {
                GridRow {
                    predictorMetricCard(
                        title: "CURRENT LEVEL",
                        value: "\(Int(store.caffeineLevel(at: Date()))) mg",
                        subtitle: currentLevelStatus()
                    )
                    predictorMetricCard(
                        title: "PREDICTED CRASH",
                        value: formattedCrashTime(),
                        subtitle: crashSubtitle()
                    )
                }
                GridRow {
                    predictorMetricCard(
                        title: "NEXT COFFEE",
                        value: formattedNextCoffeeTime(),
                        subtitle: nextCoffeeSubtitle()
                    )
                    predictorMetricCard(
                        title: "BEDTIME LEVEL",
                        value: "\(Int(store.caffeineLevel(at: resolvedBedtime()))) mg",
                        subtitle: bedtimeSleepStatus()
                    )
                }
            }

            // Share Timeline Button
            Button {
                shareCrashTimeline()
            } label: {
                Label(showShareCopied ? "Clipboard Copied! ✅" : "Share Crash Timeline", systemImage: "square.and.arrow.up")
                    .font(.system(.caption, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(6)
            }
            .buttonStyle(.plain)
            .padding(.bottom, 6)
        }
    }

    private func predictorMetricCard(title: String, value: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(.secondary)
                .tracking(0.5)
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
            Text(subtitle)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(Color.white.opacity(0.03))
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.white.opacity(0.04), lineWidth: 1)
        )
    }

    private func currentLevelStatus() -> String {
        let level = store.caffeineLevel(at: Date())
        if level > 150 { return "Over-caffeinated ⚡️" }
        if level > 80 { return "Focused / Alert" }
        if level > 20 { return "Mild Buzz" }
        return "Empty"
    }

    private func formattedCrashTime() -> String {
        if let crash = store.predictedCrashTime() {
            return crash.formatted(date: .omitted, time: .shortened)
        }
        return "--:--"
    }

    private func crashSubtitle() -> String {
        if store.predictedCrashTime() != nil {
            return "Drops < 30mg"
        }
        return store.todayCount > 0 ? "Steady alert zone" : "No active caffeine"
    }

    private func formattedNextCoffeeTime() -> String {
        if let next = store.nextCoffeeTime() {
            if Calendar.current.isDateInToday(next) && abs(next.timeIntervalSinceNow) < 300 {
                return "Now"
            }
            return next.formatted(date: .omitted, time: .shortened)
        }
        return "Skip"
    }

    private func nextCoffeeSubtitle() -> String {
        if store.nextCoffeeTime() != nil {
            return "Alert level dip"
        }
        return "Too close to bedtime 🚫"
    }

    private func resolvedBedtime() -> Date {
        let calendar = Calendar.current
        let bedtimeComponents = calendar.dateComponents([.hour, .minute], from: store.bedtime)
        return calendar.date(bySettingHour: bedtimeComponents.hour ?? 22,
                             minute: bedtimeComponents.minute ?? 0,
                             second: 0,
                             of: Date()) ?? Date()
    }

    private func bedtimeSleepStatus() -> String {
        let level = store.caffeineLevel(at: resolvedBedtime())
        return level > 50 ? "Ruin sleep warning! ⚠️" : "Safe for sleep ✅"
    }

    private var caffeineCurveChart: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            let padding: CGFloat = 8
            let graphHeight = height - padding * 2
            let graphWidth = width - padding * 2

            let startTime = Date().addingTimeInterval(-8 * 3600)
            let duration: TimeInterval = 24 * 3600

            let timePoints = stride(from: 0.0, through: 1.0, by: 0.02).map { progress in
                let date = startTime.addingTimeInterval(progress * duration)
                return (progress: progress, level: store.caffeineLevel(at: date))
            }
            let maxVal = max(100.0, timePoints.map { $0.level }.max() ?? 100.0)

            ZStack {
                // Grid lines
                ForEach(Array(stride(from: 50.0, through: maxVal, by: 50.0)), id: \.self) { val in
                    let y = padding + graphHeight * (1.0 - CGFloat(val / maxVal))
                    Path { path in
                        path.move(to: CGPoint(x: padding, y: y))
                        path.addLine(to: CGPoint(x: width - padding, y: y))
                    }
                    .stroke(Color.white.opacity(0.04), lineWidth: 1)
                }

                // Current time line
                let currentProgress = CGFloat((Date().timeIntervalSince(startTime)) / duration)
                if currentProgress >= 0 && currentProgress <= 1 {
                    let curX = padding + currentProgress * graphWidth
                    Path { path in
                        path.move(to: CGPoint(x: curX, y: padding))
                        path.addLine(to: CGPoint(x: curX, y: height - padding))
                    }
                    .stroke(Color.orange.opacity(0.3), style: StrokeStyle(lineWidth: 1.5, dash: [4]))
                }

                // Curve path
                Path { path in
                    guard !timePoints.isEmpty else { return }
                    let startX = padding + CGFloat(timePoints[0].progress) * graphWidth
                    let startY = padding + graphHeight * (1.0 - CGFloat(timePoints[0].level / maxVal))
                    path.move(to: CGPoint(x: startX, y: startY))

                    for pt in timePoints.dropFirst() {
                        let x = padding + CGFloat(pt.progress) * graphWidth
                        let y = padding + graphHeight * (1.0 - CGFloat(pt.level / maxVal))
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
                .stroke(Color.orange, lineWidth: 2)

                // Current level dot
                if currentProgress >= 0 && currentProgress <= 1 {
                    let curX = padding + currentProgress * graphWidth
                    let curY = padding + graphHeight * (1.0 - CGFloat(store.caffeineLevel(at: Date()) / maxVal))
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 6, height: 6)
                        .position(x: curX, y: curY)
                }
            }
        }
    }

    private func shareCrashTimeline() {
        let currentLevel = Int(store.caffeineLevel(at: Date()))
        let crashVal = formattedCrashTime()
        let nextCoffeeVal = formattedNextCoffeeTime()
        
        let shareText = """
        ☕️ Caffeine Crash Predictor:
        • Current Level: \(currentLevel) mg
        • Crash Predicted: \(crashVal)
        • Next Coffee: \(nextCoffeeVal)
        Track your coffee & sleep zones at caffeinebar.app
        """
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([shareText as NSString])
        
        showShareCopied = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showShareCopied = false
        }
    }
}
