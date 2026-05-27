//
//  CupStoreLogUndoTests.swift
//  CaffeineBarTests
//
//  Tests for logCup() and undoLastCup() — Task 1.3
//  Requirements: 3.1, 4.3, 4.5, 6.4
//

import Testing
import Foundation
@testable import CaffeineBar

@Suite("CupStore logCup and undoLastCup")
struct CupStoreLogUndoTests {

    /// Creates a CupStore backed by an ephemeral UserDefaults suite.
    private func makeStore() -> CupStore {
        let suiteName = "test.cupstore.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        return CupStore(defaults: defaults)
    }

    // MARK: - logCup() Tests (Req 3.1)

    @Test("logCup increments todayCount by 1")
    func logCupIncrementsCount() {
        guard #available(macOS 14.0, *) else { return }
        let store = makeStore()
        #expect(store.todayCount == 0)
        store.logCup()
        #expect(store.todayCount == 1)
        store.logCup()
        #expect(store.todayCount == 2)
    }

    @Test("logCup appends a timestamp to todayTimestamps")
    func logCupAppendsTimestamp() {
        guard #available(macOS 14.0, *) else { return }
        let store = makeStore()
        #expect(store.todayTimestamps.isEmpty)
        store.logCup()
        #expect(store.todayTimestamps.count == 1)
        store.logCup()
        #expect(store.todayTimestamps.count == 2)
    }

    @Test("logCup timestamps are in chronological order")
    func logCupTimestampsChronological() {
        guard #available(macOS 14.0, *) else { return }
        let store = makeStore()
        store.logCup()
        let first = store.todayTimestamps[0]
        Thread.sleep(forTimeInterval: 0.01)
        store.logCup()
        let second = store.todayTimestamps[1]
        #expect(second >= first)
    }

    // MARK: - personalRecord (Req 6.4)

    @Test("logCup updates personalRecord when count exceeds it")
    func logCupUpdatesPersonalRecord() {
        guard #available(macOS 14.0, *) else { return }
        let store = makeStore()
        #expect(store.personalRecord == 0)
        store.logCup()
        #expect(store.personalRecord == 1)
        store.logCup()
        #expect(store.personalRecord == 2)
    }

    @Test("personalRecord does not decrease after undo")
    func personalRecordMonotonicallyNonDecreasing() {
        guard #available(macOS 14.0, *) else { return }
        let store = makeStore()
        store.logCup()
        store.logCup()
        store.logCup()
        #expect(store.personalRecord == 3)
        store.undoLastCup()
        #expect(store.personalRecord == 3) // Must not decrease
    }

    // MARK: - undoLastCup() Tests (Req 4.3)

    @Test("undoLastCup decrements todayCount by 1")
    func undoDecrementsCount() {
        guard #available(macOS 14.0, *) else { return }
        let store = makeStore()
        store.logCup()
        store.logCup()
        #expect(store.todayCount == 2)
        store.undoLastCup()
        #expect(store.todayCount == 1)
    }

    @Test("undoLastCup removes the last timestamp")
    func undoRemovesLastTimestamp() {
        guard #available(macOS 14.0, *) else { return }
        let store = makeStore()
        store.logCup()
        store.logCup()
        let firstTimestamp = store.todayTimestamps[0]
        store.undoLastCup()
        #expect(store.todayTimestamps.count == 1)
        #expect(store.todayTimestamps[0] == firstTimestamp)
    }

    @Test("undoLastCup is a no-op when todayCount is 0")
    func undoNoOpAtZero() {
        guard #available(macOS 14.0, *) else { return }
        let store = makeStore()
        #expect(store.todayCount == 0)
        store.undoLastCup() // Should not crash or go negative
        #expect(store.todayCount == 0)
        #expect(store.todayTimestamps.isEmpty)
    }

    // MARK: - Bounded Undo / Ring Buffer (Req 4.5)

    @Test("todayTimestamps is bounded to 50 entries")
    func timestampsBoundedToFifty() {
        guard #available(macOS 14.0, *) else { return }
        let store = makeStore()
        for _ in 0..<60 {
            store.logCup()
        }
        #expect(store.todayTimestamps.count == 50)
        #expect(store.todayCount == 60)
    }

    @Test("ring buffer drops oldest entry when at capacity")
    func ringBufferDropsOldest() {
        guard #available(macOS 14.0, *) else { return }
        let store = makeStore()
        // Log 50 cups
        for _ in 0..<50 {
            store.logCup()
        }
        let secondTimestamp = store.todayTimestamps[1]
        // Log one more — should drop the first
        store.logCup()
        #expect(store.todayTimestamps.count == 50)
        #expect(store.todayTimestamps[0] == secondTimestamp)
    }

    // MARK: - Undo is left-inverse of log

    @Test("undo after log returns count to previous value")
    func undoIsLeftInverseOfLog() {
        guard #available(macOS 14.0, *) else { return }
        let store = makeStore()
        store.logCup()
        store.logCup()
        let countBefore = store.todayCount
        store.logCup()
        store.undoLastCup()
        #expect(store.todayCount == countBefore)
    }
}
