//
//  ManualSleepStore.swift
//  Nurture
//
//  In-memory store for manually logged sleep/nap sessions. Feeds History weekly view.
//

import Foundation
import Combine

/// A completed sleep or nap session logged manually or from "End Sleep" / "End Nap".
struct ManualSleepEntry: Identifiable, Equatable {
    let id: UUID
    let startDate: Date
    let endDate: Date
    let isNighttime: Bool
    let childId: UUID

    var durationSeconds: TimeInterval { endDate.timeIntervalSince(startDate) }

    init(id: UUID = UUID(), startDate: Date, endDate: Date, isNighttime: Bool, childId: UUID) {
        self.id = id
        self.startDate = startDate
        self.endDate = endDate
        self.isNighttime = isNighttime
        self.childId = childId
    }

    func toSleepSession() -> SleepSession {
        SleepSession(id: id, startDate: startDate, endDate: endDate, isNighttime: isNighttime, childId: childId)
    }
}

/// Shared store for manual sleep/nap entries. HistoryView reads from here for weekly bars and day detail.
final class ManualSleepStore: ObservableObject {
    static let shared = ManualSleepStore()

    @Published private(set) var entries: [ManualSleepEntry] = []

    private let calendar = Calendar.current

    private init() {}

    func add(startDate: Date, endDate: Date, isNighttime: Bool, childId: UUID) {
        let entry = ManualSleepEntry(startDate: startDate, endDate: endDate, isNighttime: isNighttime, childId: childId)
        entries.append(entry)
    }

    /// Removes an entry by id. No-op if not found (e.g. mock-only session).
    func remove(entryId: UUID) {
        entries.removeAll { $0.id == entryId }
    }

    /// IDs of manual entries for a given day (for delete eligibility in History).
    func entryIds(for date: Date) -> Set<UUID> {
        let dayStart = calendar.startOfDay(for: date)
        return Set(entries
            .filter { calendar.isDate($0.startDate, inSameDayAs: dayStart) }
            .map(\.id))
    }

    /// Single source of truth for daily totals: sum of all sleep sessions + all naps for the date (by start date).
    func totalSleepSeconds(for date: Date) -> TimeInterval {
        let dayStart = calendar.startOfDay(for: date)
        return entries
            .filter { calendar.isDate($0.startDate, inSameDayAs: dayStart) }
            .reduce(0) { $0 + $1.durationSeconds }
    }

    /// Total sleep duration (seconds) for a given calendar day. Delegates to totalSleepSeconds(for:).
    func totalDuration(for date: Date) -> TimeInterval {
        totalSleepSeconds(for: date)
    }

    /// Nap-only duration for a day (for Today's Naps).
    func napDuration(for date: Date) -> TimeInterval {
        let dayStart = calendar.startOfDay(for: date)
        return entries
            .filter { !$0.isNighttime && calendar.isDate($0.startDate, inSameDayAs: dayStart) }
            .reduce(0) { $0 + $1.durationSeconds }
    }

    /// Nap entries for a day, chronological order (for Today's Naps detail list).
    func napEntries(for date: Date) -> [ManualSleepEntry] {
        let dayStart = calendar.startOfDay(for: date)
        return entries
            .filter { !$0.isNighttime && calendar.isDate($0.startDate, inSameDayAs: dayStart) }
            .sorted { $0.startDate < $1.startDate }
    }

    /// Sessions for a given day (for day detail panel), attributed by start date.
    func sessions(for date: Date) -> [SleepSession] {
        let dayStart = calendar.startOfDay(for: date)
        return entries
            .filter { calendar.isDate($0.startDate, inSameDayAs: dayStart) }
            .map { $0.toSleepSession() }
    }

    /// End time of the most recent completed sleep or nap (for awake duration and next-nap prediction).
    /// Pass childId to scope to one child, or nil for all entries.
    func lastSleepEndDate(childId: UUID?) -> Date? {
        let list = childId == nil ? entries : entries.filter { $0.childId == childId }
        return list.map(\.endDate).max()
    }
}
