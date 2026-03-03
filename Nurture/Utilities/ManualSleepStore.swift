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

    /// Total sleep duration (seconds) for a given calendar day (sessions attributed by start date).
    func totalDuration(for date: Date) -> TimeInterval {
        let dayStart = calendar.startOfDay(for: date)
        return entries
            .filter { calendar.isDate($0.startDate, inSameDayAs: dayStart) }
            .reduce(0) { $0 + $1.durationSeconds }
    }

    /// Sessions for a given day (for day detail panel), attributed by start date.
    func sessions(for date: Date) -> [SleepSession] {
        let dayStart = calendar.startOfDay(for: date)
        return entries
            .filter { calendar.isDate($0.startDate, inSameDayAs: dayStart) }
            .map { $0.toSleepSession() }
    }
}
