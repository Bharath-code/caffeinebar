//
//  CupStore.swift
//  CaffeineBar
//
//  Core Engine Agent — Requirements: 15, 32, 33, 35
//

import Foundation
import Observation
import os

// MARK: - MetabolismProfile

/// User-selected caffeine metabolism speed.
/// Drives the HalfLifeClock clearance calculation.
/// - fast: halfLife = 5.0 hours
/// - normal: halfLife = 5.5 hours
/// - slow: halfLife = 6.0 hours
enum MetabolismProfile: String, Codable, CaseIterable, Sendable {
    case fast
    case normal
    case slow

    var halfLifeHours: Double {
        switch self {
        case .fast:   return 5.0
        case .normal: return 5.5
        case .slow:   return 6.0
        }
    }
}

// MARK: - DayRecord

/// Archived record of a single day's coffee intake.
struct DayRecord: Codable, Sendable {
    let date: Date          // Start-of-day (reset boundary)
    let count: Int          // Total cups that day
    let timestamps: [Date]  // Individual log times
}

// MARK: - CupStore

/// The single observable state container for CaffeineBar.
/// All persisted fields use UserDefaults with the `caffeinebar.` key prefix (Req 32).
/// Every write is wrapped in `ProcessInfo.processInfo.performActivity` with
/// `.userInitiated` to survive lid-close suspension (Req 35).
@available(macOS 14.0, *)
@MainActor
@Observable
final class CupStore {

    // MARK: - UserDefaults Keys (Req 32: caffeinebar.* prefix)

    private enum Keys {
        static let todayCount = "caffeinebar.todayCount"
        static let todayTimestamps = "caffeinebar.todayTimestamps"
        static let lastResetDate = "caffeinebar.lastResetDate"
        static let streakDays = "caffeinebar.streakDays"
        static let personalRecord = "caffeinebar.personalRecord"
        static let totalDaysLogged = "caffeinebar.totalDaysLogged"
        static let resetHour = "caffeinebar.resetHour"
        static let bedtime = "caffeinebar.bedtime"
        static let metabolismProfile = "caffeinebar.metabolismProfile"
        static let isMuted = "caffeinebar.isMuted"
        static let officeMode = "caffeinebar.officeMode"
        static let officeModeHapticOnly = "caffeinebar.officeModeHapticOnly"
        static let autoMuteOnCalls = "caffeinebar.autoMuteOnCalls"
        static let installedSoundPacks = "caffeinebar.installedSoundPacks"
        static let selectedSoundPack = "caffeinebar.selectedSoundPack"
        static let dailyHistory = "caffeinebar.dailyHistory"
        static let dataVersion = "caffeinebar.dataVersion"
        static let keepPopoverOpen = "caffeinebar.keepPopoverOpen"
    }

    // MARK: - Default Values

    private static let defaultBundledPacks = ["default", "yourmom", "gordonramsay", "nasa"]

    private static var defaultBedtime: Date {
        var components = DateComponents()
        components.hour = 22
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }

    // MARK: - Persisted State (Req 33)

    private(set) var todayCount: Int = 0
    private(set) var todayTimestamps: [Date] = []
    private(set) var lastResetDate: Date = .distantPast
    private(set) var streakDays: Int = 0
    private(set) var personalRecord: Int = 0
    private(set) var totalDaysLogged: Int = 0

    var resetHour: Int = 0 {
        didSet { schedulePersist() }
    }

    var bedtime: Date = CupStore.defaultBedtime {
        didSet { schedulePersist() }
    }

    var metabolismProfile: MetabolismProfile = .normal {
        didSet { schedulePersist() }
    }

    var isMuted: Bool = false {
        didSet { schedulePersist() }
    }

    var officeMode: Bool = false {
        didSet { schedulePersist() }
    }

    /// Whether Office Mode uses haptic-only feedback instead of capped audio (Req 17.3).
    var officeModeHapticOnly: Bool = false {
        didSet { schedulePersist() }
    }

    /// Defaults to `true` on first launch (Req 15).
    var autoMuteOnCalls: Bool = true {
        didSet { schedulePersist() }
    }

    var installedSoundPacks: [String] = CupStore.defaultBundledPacks {
        didSet { schedulePersist() }
    }

    var selectedSoundPack: String = "default" {
        didSet { schedulePersist() }
    }

    /// When true, the popover remains open after a log action (Req 3.4).
    /// Defaults to true — most users want to see the count update.
    var keepPopoverOpen: Bool = true {
        didSet { schedulePersist() }
    }

    private(set) var dailyHistory: [DayRecord] = []

    /// Schema version — set to 1 from first build (Req 32).
    private(set) var dataVersion: Int = 1

    // MARK: - Dependencies

    private let defaults: UserDefaults

    /// Timer for scheduling the next daily reset check.
    private var resetTimer: Timer?

    /// Debounce task for batching rapid preference changes into a single persist (performance fix).
    private var persistDebounceTask: Task<Void, Never>?

    // MARK: - Initialization

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        loadFromDefaults()
        ensureDataVersion()
        evaluateReset()
    }

    // MARK: - Constants

    /// Maximum number of timestamps retained in the undo buffer (Req 4.5).
    /// When appending would exceed this limit, the oldest entry is dropped (ring buffer).
    static let maxUndoHistory = 50

    // MARK: - Public API

    /// Increment cup count, append timestamp, update personal record (Reqs 3.1, 6.4).
    /// Bounded to `maxUndoHistory` entries via ring buffer (Req 4.5).
    /// Wrapped in `performActivity` to survive lid-close (Req 35).
    func logCup() {
        ProcessInfo.processInfo.performActivity(
            options: .userInitiated,
            reason: "Logging a cup of coffee"
        ) { [self] in
            todayCount += 1

            // Ring buffer: drop oldest timestamp if at capacity (Req 4.5)
            if todayTimestamps.count >= CupStore.maxUndoHistory {
                todayTimestamps.removeFirst()
            }
            todayTimestamps.append(Date())

            // Update personal record if new high (Req 6.4)
            if todayCount > personalRecord {
                personalRecord = todayCount
            }

            persistAll()
        }
    }

    /// Decrement cup count, remove last timestamp (Req 4.3).
    /// Guards against underflow — no-op when count is already 0.
    /// Wrapped in `performActivity` to survive lid-close (Req 35).
    func undoLastCup() {
        ProcessInfo.processInfo.performActivity(
            options: .userInitiated,
            reason: "Undoing last cup log"
        ) { [self] in
            guard todayCount > 0 else { return }

            todayCount -= 1

            if !todayTimestamps.isEmpty {
                todayTimestamps.removeLast()
            }

            persistAll()
        }
    }

    /// Check if the daily reset boundary has been crossed and fire reset if needed.
    /// Uses `Calendar.current.startOfDay(for:)` + resetHour to compute the boundary.
    /// Guards with `lastResetDate < boundary` for exactly-once semantics (Req 5.4 DST safety).
    /// - Requirements: 5.1, 5.2, 5.3, 5.4, 6.1, 6.2, 6.3
    func evaluateReset() {
        ProcessInfo.processInfo.performActivity(
            options: .userInitiated,
            reason: "Evaluating daily reset boundary"
        ) { [self] in
            let now = Date()
            let calendar = Calendar.current

            // Compute today's reset boundary: start of today + resetHour in seconds
            var boundary = calendar.startOfDay(for: now)
                .addingTimeInterval(TimeInterval(resetHour * 3600))

            // If the boundary is in the future, use yesterday's boundary
            if boundary > now {
                if let yesterday = calendar.date(byAdding: .day, value: -1, to: now) {
                    boundary = calendar.startOfDay(for: yesterday)
                        .addingTimeInterval(TimeInterval(resetHour * 3600))
                }
            }

            // Guard: only fire if lastResetDate < boundary (exactly-once semantics)
            guard lastResetDate < boundary else {
                scheduleNextResetCheck()
                return
            }

            // Fire the reset
            // Archive the prior day if todayCount > 0
            if todayCount > 0 {
                // Use the boundary as the archived day's date (the day that just ended).
                // On first launch, lastResetDate is .distantPast, so we compute yesterday's
                // start-of-day to get a meaningful date for the chart lookup.
                let archivedDate: Date
                if lastResetDate == .distantPast {
                    // First reset ever — attribute to yesterday
                    archivedDate = calendar.startOfDay(for: calendar.date(byAdding: .day, value: -1, to: now) ?? now)
                } else {
                    archivedDate = calendar.startOfDay(for: lastResetDate)
                }

                let record = DayRecord(
                    date: archivedDate,
                    count: todayCount,
                    timestamps: todayTimestamps
                )
                dailyHistory.append(record)

                // Check if migration is needed after appending (Req 36)
                scheduleMigrationIfNeeded()

                // Update streak: prior day had logs
                streakDays += 1
                totalDaysLogged += 1
            } else {
                // Prior day had no logs — reset streak
                streakDays = 0
            }

            // Reset today's state
            todayCount = 0
            todayTimestamps = []
            lastResetDate = boundary

            persistAll()
            scheduleNextResetCheck()
        }
    }

    /// Computes the next reset boundary and schedules a timer to call `evaluateReset()` at that time.
    /// Cancels any existing timer before scheduling a new one.
    /// - Requirements: 5.1, 5.3
    func scheduleNextResetCheck() {
        // Cancel any existing timer
        resetTimer?.invalidate()
        resetTimer = nil

        let now = Date()
        let calendar = Calendar.current

        // Compute the next reset boundary
        var nextBoundary = calendar.startOfDay(for: now)
            .addingTimeInterval(TimeInterval(resetHour * 3600))

        // If the boundary is in the past or now, advance to tomorrow's boundary
        if nextBoundary <= now {
            if let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) {
                nextBoundary = calendar.startOfDay(for: tomorrow)
                    .addingTimeInterval(TimeInterval(resetHour * 3600))
            }
        }

        let delay = nextBoundary.timeIntervalSince(now)
        guard delay > 0 else { return }

        resetTimer = Timer.scheduledTimer(
            withTimeInterval: delay,
            repeats: false
        ) { [weak self] _ in
            Task { @MainActor in
                self?.evaluateReset()
            }
        }
    }

    // MARK: - Persistence (Req 35)

    /// Schedules a debounced persist. Rapid preference changes are batched into
    /// a single write after 300ms of inactivity, avoiding redundant serialization
    /// of the full state (including potentially large `dailyHistory`).
    private func schedulePersist() {
        persistDebounceTask?.cancel()
        persistDebounceTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            persistAll()
        }
    }

    /// Persists all mutable state to UserDefaults.
    /// Wrapped in `ProcessInfo.performActivity` with `.userInitiated` to survive
    /// lid-close suspension (Req 35).
    func persistAll() {
        ProcessInfo.processInfo.performActivity(
            options: .userInitiated,
            reason: "Persisting CupStore state to UserDefaults"
        ) { [self] in
            defaults.set(todayCount, forKey: Keys.todayCount)

            if let timestampsData = try? JSONEncoder().encode(todayTimestamps) {
                defaults.set(timestampsData, forKey: Keys.todayTimestamps)
            }

            defaults.set(lastResetDate.timeIntervalSince1970, forKey: Keys.lastResetDate)
            defaults.set(streakDays, forKey: Keys.streakDays)
            defaults.set(personalRecord, forKey: Keys.personalRecord)
            defaults.set(totalDaysLogged, forKey: Keys.totalDaysLogged)
            defaults.set(resetHour, forKey: Keys.resetHour)
            defaults.set(bedtime.timeIntervalSince1970, forKey: Keys.bedtime)
            defaults.set(metabolismProfile.rawValue, forKey: Keys.metabolismProfile)
            defaults.set(isMuted, forKey: Keys.isMuted)
            defaults.set(officeMode, forKey: Keys.officeMode)
            defaults.set(officeModeHapticOnly, forKey: Keys.officeModeHapticOnly)
            defaults.set(autoMuteOnCalls, forKey: Keys.autoMuteOnCalls)
            defaults.set(installedSoundPacks, forKey: Keys.installedSoundPacks)
            defaults.set(selectedSoundPack, forKey: Keys.selectedSoundPack)
            defaults.set(keepPopoverOpen, forKey: Keys.keepPopoverOpen)
            defaults.set(dataVersion, forKey: Keys.dataVersion)

            if let historyData = try? JSONEncoder().encode(dailyHistory) {
                defaults.set(historyData, forKey: Keys.dailyHistory)
            }
        }
    }

    // MARK: - Load from UserDefaults

    private func loadFromDefaults() {
        todayCount = defaults.integer(forKey: Keys.todayCount)

        if let timestampsData = defaults.data(forKey: Keys.todayTimestamps),
           let decoded = try? JSONDecoder().decode([Date].self, from: timestampsData) {
            todayTimestamps = decoded
        }

        let lastResetInterval = defaults.double(forKey: Keys.lastResetDate)
        if lastResetInterval > 0 {
            lastResetDate = Date(timeIntervalSince1970: lastResetInterval)
        } else {
            lastResetDate = .distantPast
        }

        streakDays = defaults.integer(forKey: Keys.streakDays)
        personalRecord = defaults.integer(forKey: Keys.personalRecord)
        totalDaysLogged = defaults.integer(forKey: Keys.totalDaysLogged)

        // resetHour defaults to 0 (midnight)
        if defaults.object(forKey: Keys.resetHour) != nil {
            resetHour = defaults.integer(forKey: Keys.resetHour)
        } else {
            resetHour = 0
        }

        // bedtime defaults to 22:00
        let bedtimeInterval = defaults.double(forKey: Keys.bedtime)
        if bedtimeInterval > 0 {
            bedtime = Date(timeIntervalSince1970: bedtimeInterval)
        } else {
            bedtime = CupStore.defaultBedtime
        }

        // metabolismProfile defaults to "normal"
        if let profileRaw = defaults.string(forKey: Keys.metabolismProfile),
           let profile = MetabolismProfile(rawValue: profileRaw) {
            metabolismProfile = profile
        } else {
            metabolismProfile = .normal
        }

        // isMuted defaults to false
        isMuted = defaults.bool(forKey: Keys.isMuted)

        // officeMode defaults to false
        officeMode = defaults.bool(forKey: Keys.officeMode)

        // officeModeHapticOnly defaults to false (Req 17.3)
        officeModeHapticOnly = defaults.bool(forKey: Keys.officeModeHapticOnly)

        // autoMuteOnCalls defaults to true (Req 15)
        if defaults.object(forKey: Keys.autoMuteOnCalls) != nil {
            autoMuteOnCalls = defaults.bool(forKey: Keys.autoMuteOnCalls)
        } else {
            autoMuteOnCalls = true
        }

        // installedSoundPacks defaults to all 4 bundled packs
        if let packs = defaults.stringArray(forKey: Keys.installedSoundPacks) {
            installedSoundPacks = packs
        } else {
            installedSoundPacks = CupStore.defaultBundledPacks
        }

        // selectedSoundPack defaults to "default"
        if let pack = defaults.string(forKey: Keys.selectedSoundPack) {
            selectedSoundPack = pack
        } else {
            selectedSoundPack = "default"
        }

        // keepPopoverOpen defaults to true so the popover stays open after logging
        if defaults.object(forKey: Keys.keepPopoverOpen) != nil {
            keepPopoverOpen = defaults.bool(forKey: Keys.keepPopoverOpen)
        } else {
            keepPopoverOpen = true
        }

        // dailyHistory defaults to []
        if let historyData = defaults.data(forKey: Keys.dailyHistory),
           let decoded = try? JSONDecoder().decode([DayRecord].self, from: historyData) {
            dailyHistory = decoded
        }

        // dataVersion defaults to 1
        if defaults.object(forKey: Keys.dataVersion) != nil {
            dataVersion = defaults.integer(forKey: Keys.dataVersion)
        } else {
            dataVersion = 1
        }
    }

    // MARK: - Data Version (Req 32)

    /// Ensures `caffeinebar.dataVersion = 1` is set from first build.
    private func ensureDataVersion() {
        if defaults.object(forKey: Keys.dataVersion) == nil {
            dataVersion = 1
            ProcessInfo.processInfo.performActivity(
                options: .userInitiated,
                reason: "Setting initial dataVersion"
            ) { [self] in
                defaults.set(dataVersion, forKey: Keys.dataVersion)
            }
        }

        // Ensure autoMuteOnCalls is persisted on first launch (Req 15)
        if defaults.object(forKey: Keys.autoMuteOnCalls) == nil {
            ProcessInfo.processInfo.performActivity(
                options: .userInitiated,
                reason: "Setting initial autoMuteOnCalls default"
            ) { [self] in
                defaults.set(true, forKey: Keys.autoMuteOnCalls)
            }
        }
    }

    // MARK: - Migration (Req 36)

    /// Logger for migration-related events.
    private static let migrationLogger = Logger(
        subsystem: "app.caffeinebar",
        category: "migration"
    )

    /// Schedules background migration when dailyHistory exceeds 1000 entries.
    /// Migration to SQLite/Core Data runs on a utility-QoS background queue
    /// and never blocks the main thread (Req 36.1, 36.2).
    func scheduleMigrationIfNeeded() {
        guard dailyHistory.count > 1000 else { return }

        let entryCount = dailyHistory.count
        CupStore.migrationLogger.info(
            "dailyHistory has \(entryCount) entries (>1000). Scheduling background migration."
        )

        DispatchQueue.global(qos: .utility).async {
            CupStore.migrationLogger.info(
                "Background migration task started for \(entryCount) daily history entries. (SQLite/Core Data migration scaffold — actual migration deferred to post-MVP.)"
            )
            // TODO: Implement actual SQLite/Core Data migration here.
            // This scaffold confirms the background dispatch path works.
            // The migration will:
            // 1. Open/create the SQLite database
            // 2. Batch-insert dailyHistory records
            // 3. On success, trim the UserDefaults-backed array
            // 4. Update caffeinebar.dataVersion
            CupStore.migrationLogger.info(
                "Background migration task completed (scaffold). No data was migrated in this MVP build."
            )
        }
    }
}
