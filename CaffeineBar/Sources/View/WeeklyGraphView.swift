//
//  WeeklyGraphView.swift
//  CaffeineBar
//
//  SwiftUI Frontend Agent — Requirements: 20.1, 20.2, 20.3
//  7-day bar chart of daily cup counts using Swift Charts.
//

import SwiftUI
import Charts

/// A compact 7-day bar chart showing daily coffee intake.
///
/// - Always renders all 7 days (padding missing days with zero counts).
/// - Includes today's live count (not just archived history).
/// - Uses rounded bar tops (Apple HIG style).
/// - Bars exceeding the cut-off threshold are rendered in `status.warning` color (Req 20.3).
@available(macOS 14.0, *)
struct WeeklyGraphView: View {

    // MARK: - Inputs

    let history: [DayRecord]
    let todayCount: Int
    let cutoffThreshold: Int?

    // MARK: - State

    @State private var selectedDayLabel: String?

    // MARK: - Internal Model

    struct DayEntry: Identifiable, Equatable {
        let id: Date
        let dayLabel: String
        let date: Date
        let count: Int
        let exceedsCutoff: Bool
        let isToday: Bool
    }

    // MARK: - Computed

    private var chartData: [DayEntry] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        var lookup: [Date: Int] = [:]
        for record in history {
            let key = calendar.startOfDay(for: record.date)
            lookup[key] = record.count
        }
        // Include today's live count
        lookup[today] = todayCount

        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEE"

        var entries: [DayEntry] = []
        for offset in stride(from: -6, through: 0, by: 1) {
            guard let day = calendar.date(byAdding: .day, value: offset, to: today) else { continue }
            let count = lookup[day] ?? 0
            let exceedsCutoff: Bool = {
                guard let threshold = cutoffThreshold, threshold > 0 else { return false }
                return count > threshold
            }()
            entries.append(DayEntry(
                id: day,
                dayLabel: dayFormatter.string(from: day),
                date: day,
                count: count,
                exceedsCutoff: exceedsCutoff,
                isToday: day == today
            ))
        }
        return entries
    }

    private var hasAnyData: Bool {
        chartData.contains { $0.count > 0 }
    }

    private var maxCount: Int {
        max(chartData.map(\.count).max() ?? 0, 1)
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header
            Text("THIS WEEK")
                .font(.system(.caption2, weight: .semibold))
                .foregroundStyle(.tertiary)
                .tracking(0.3)
                .padding(.top, 4)

            // Chart
            Chart(chartData) { entry in
                BarMark(
                    x: .value("Day", entry.dayLabel),
                    y: .value("Cups", entry.count == 0 ? 0.3 : Double(entry.count))
                )
                .foregroundStyle(barColor(for: entry))
                .opacity(barOpacity(for: entry))
            }
            .chartYScale(domain: 0...(maxCount + 2))
            .chartYAxis(.hidden)
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let label = value.as(String.self) {
                            Text(label)
                                .font(.system(.caption2, weight: isCurrentDay(label) ? .bold : .regular))
                                .foregroundStyle(isCurrentDay(label) ? .primary : .secondary)
                        }
                    }
                }
            }
            .chartXSelection(value: $selectedDayLabel)
            .frame(height: 110)

            // Info row below chart
            infoRow
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
    }

    // MARK: - Info Row

    private var selectedDay: DayEntry? {
        guard let label = selectedDayLabel else { return nil }
        return chartData.first { $0.dayLabel == label }
    }

    @ViewBuilder
    private var infoRow: some View {
        Group {
            if let selected = selectedDay, hasAnyData {
                tooltipText(for: selected)
            } else if hasAnyData {
                let todayEntry = chartData.last
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 5, height: 5)
                    Text("Today: \(todayEntry?.count ?? 0) cup\(todayEntry?.count == 1 ? "" : "s")")
                        .font(.system(.caption2, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .center)
            } else {
                Text("Start logging to see your week")
                    .font(.system(.caption2))
                    .foregroundStyle(.quaternary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .frame(height: 16) // Fixed height prevents layout shift on hover
    }

    // MARK: - Helpers

    private func barColor(for entry: DayEntry) -> Color {
        if !hasAnyData { return .accentColor }
        if entry.exceedsCutoff { return .statusWarning }
        if entry.isToday { return .accentColor }
        return .accentColor.opacity(0.7)
    }

    private func barOpacity(for entry: DayEntry) -> Double {
        if !hasAnyData { return 0.3 }
        if entry.count == 0 { return 0.15 }
        return 1.0
    }

    private func isCurrentDay(_ label: String) -> Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return label == formatter.string(from: Date())
    }

    private func tooltipText(for entry: DayEntry) -> some View {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d"
        return HStack(spacing: 4) {
            Text(dateFormatter.string(from: entry.date))
                .font(.system(.caption2, weight: .medium))
                .foregroundStyle(.secondary)
            Text("·")
                .foregroundStyle(.quaternary)
            Text("\(entry.count) cup\(entry.count == 1 ? "" : "s")")
                .font(.system(.caption2, weight: .semibold))
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private var accessibilitySummary: String {
        let total = chartData.reduce(0) { $0 + $1.count }
        let maxDay = chartData.max(by: { $0.count < $1.count })
        return "Weekly caffeine chart. \(total) cups over 7 days. Peak: \(maxDay?.count ?? 0) cups on \(maxDay?.dayLabel ?? "none")."
    }
}
