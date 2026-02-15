//
//  HistoryController.swift
//  Nurture
//
//  Holds past 7 days of sleep summaries. PRD Section 3 - Sleep History.
//  Demo: 3 days mock sessions. TODO: local persistence (Core Data / SwiftData).
//

import Foundation
import Combine

/// One day's summary for History list: date + sessions (nighttime + naps).
struct DaySummary: Identifiable {
    let id: Date
    let date: Date
    let sessions: [SleepSession]
    var totalDuration: TimeInterval { sessions.reduce(0) { $0 + $1.durationSeconds } }
}

/// Provides sleep data for HistoryView calendar. TODO: PersistenceService.
final class HistoryController: ObservableObject {
    @Published var daySummaries: [DaySummary] = []
    @Published var selectedDate: Date?
    @Published var displayedMonth: Date = Date()

    private let childrenStore: ChildrenStore?
    private let calendar = Calendar.current

    // Integration point: Local persistence — load/save sleep sessions (Core Data / SwiftData).
    // TODO: Inject PersistenceService or local storage
    // Purpose: Load/save sleep sessions; retain 30 days (configurable). PRD Technical Requirements.
    // Dependencies: SleepSession model, Core Data or SwiftData
    // Estimated complexity: Medium

    init(childrenStore: ChildrenStore? = nil) {
        self.childrenStore = childrenStore
        if useDemoMode {
            loadMockHistory()
        }
    }

    func selectDate(_ date: Date?) {
        selectedDate = date
    }

    func goToPreviousMonth() {
        guard let prev = calendar.date(byAdding: .month, value: -1, to: displayedMonth) else { return }
        displayedMonth = prev
    }

    func goToNextMonth() {
        guard let next = calendar.date(byAdding: .month, value: 1, to: displayedMonth) else { return }
        displayedMonth = next
    }

    /// Returns DaySummary for the given date, or nil if no data.
    func daySummary(for date: Date) -> DaySummary? {
        let dayStart = calendar.startOfDay(for: date)
        return daySummaries.first { calendar.isDate($0.date, inSameDayAs: dayStart) }
    }

    /// Returns start-of-day dates in the given month that have sleep data.
    func datesWithData(in month: Date) -> Set<Date> {
        guard let range = calendar.range(of: .day, in: .month, for: month),
              let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: month)) else {
            return []
        }
        var result: Set<Date> = []
        for dayOffset in 0..<range.count {
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: monthStart) else { continue }
            if daySummary(for: day) != nil {
                result.insert(calendar.startOfDay(for: day))
            }
        }
        return result
    }

    private func loadMockHistory() {
        let cal = Calendar.current
        let childId = childrenStore?.selectedChild?.id ?? UUID()
        var summaries: [DaySummary] = []
        for dayOffset in 0..<14 {
            guard let dayStart = cal.date(byAdding: .day, value: -dayOffset, to: Date()),
                  let prevDay = cal.date(byAdding: .day, value: -1, to: dayStart) else { continue }
            let nightStart = cal.date(bySettingHour: 19, minute: 15, second: 0, of: prevDay)!
            let nightEnd = cal.date(bySettingHour: 6, minute: 30, second: 0, of: dayStart)!
            let napStart = cal.date(bySettingHour: 9, minute: 45, second: 0, of: dayStart)!
            let napEnd = cal.date(bySettingHour: 10, minute: 15, second: 0, of: dayStart)!
            let sessions: [SleepSession] = [
                SleepSession(startDate: nightStart, endDate: nightEnd, isNighttime: true, childId: childId),
                SleepSession(startDate: napStart, endDate: napEnd, isNighttime: false, childId: childId)
            ]
            summaries.append(DaySummary(id: dayStart, date: dayStart, sessions: sessions))
        }
        daySummaries = summaries
    }
}
