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

/// Provides past 7 days of sleep data for HistoryView. TODO: PersistenceService.
final class HistoryController: ObservableObject {
    @Published var daySummaries: [DaySummary] = []
    @Published var expandedDayId: Date?

    // Integration point: Local persistence — load/save sleep sessions (Core Data / SwiftData).
    // TODO: Inject PersistenceService or local storage
    // Purpose: Load/save sleep sessions; retain 30 days (configurable). PRD Technical Requirements.
    // Dependencies: SleepSession model, Core Data or SwiftData
    // Estimated complexity: Medium

    init() {
        if useDemoMode {
            loadMockHistory()
        }
    }

    func toggleExpanded(dayId: Date) {
        if expandedDayId == dayId {
            expandedDayId = nil
        } else {
            expandedDayId = dayId
        }
    }

    private func loadMockHistory() {
        let cal = Calendar.current
        let childId = UUID()
        var summaries: [DaySummary] = []
        for dayOffset in 0..<3 {
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
