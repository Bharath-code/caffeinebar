//
//  CupStore.swift
//  CaffeineBar
//
//  Core Engine Agent — Requirements: 15, 32, 33, 35
//

import Foundation
import Observation

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
        static let autoMuteOnCalls = "caffeinebar.autoMuteOnCalls"
        static let installedSoundPacks = "caffeinebar.installedSoundPacks"
        static let selectedSoundPack = "caffeinebar.selectedSoundPack"
        static let dailyHistory = "caffeinebar.dailyHistory"
        static let dataVersion = "caffeinebar.dataVersion"
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
        didSet { persistAll() }
    }

    var bedtime: Date = CupStore.defaultBedtime {
        didSet { persistAll() }
    }

    var metabolismProfile: MetabolismProfile = .normal {
        didSet { persistAll() }
    }

    var isMuted: Bool = false {
        didSet { persistAll() }
    }

    var officeMode: Bool = false {
        didSet { persistAll() }
    }

    /// Defaults to `true` on first launch (Req 15).
    var autoMuteOnCalls: Bool = true {
        didSet { persistAll() }
    }

    var installedSoundPacks: [String] = CupStore.defaultBundledPacks {
        didSet { persistAll() }
    }

    var selectedSoundPack: String = "default" {
        didSet { persistAll() }
    }

    private(set) var dailyHistory: [DayRecord] = []

    /// Schema version — set to 1 from first build (Req 32).
    private(set) var dataVersion: Int = 1

    // MARK: - Dependencies

    private let defaults: UserDefaults

    // MARK: - Initialization

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        loadFromDefaults()
        ensureDataVersion()
    }

    // MARK: - Public API

    /// Increment cup count, append timestamp, update personal record.
    /// Full implementation in Task 1.3.
    func logCup() {
        // Stub — will be implemented in Task 1.3
    }

    /// Decrement cup count, remove last timestamp.
    /// Full implementation in Task 1.3.
    func undoLastCup() {
        // Stub — will be implemented in Task 1.3
    }

    /// Check if the daily reset boundary has been crossed and fire reset if needed.
    /// Full implementation in Task 4.3.
    func evaluateReset() {
        // Stub — will be implemented in Task 4.3
    }

    // MARK: - Persistence (Req 35)

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
            defaults.set(autoMuteOnCalls, forKey: Keys.autoMuteOnCalls)
            defaults.set(installedSoundPacks, forKey: Keys.installedSoundPacks)
            defaults.set(selectedSoundPack, forKey: Keys.selectedSoundPack)
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

    /// Schedules background migration when dailyHistory exceeds 1000 entries.
    /// Migration to SQLite/Core Data runs on a background queue and never blocks the main thread.
    func scheduleMigrationIfNeeded() {
        guard dailyHistory.count > 1000 else { return }
        // Migration implementation deferred to Task 4.5.
        // Will run on a background DispatchQueue when triggered.
    }
}
