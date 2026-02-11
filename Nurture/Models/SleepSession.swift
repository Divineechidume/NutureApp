//
//  SleepSession.swift
//  Nurture
//
//  A single sleep session (nighttime or nap). PRD Section 2 (Home), Section 3 (History).
//  Data from wearable via Bluetooth / SleepDetectionService.
//

import Foundation

/// One continuous sleep session. Source: wearable via Bluetooth / SleepDetectionService.
/// Used for Home duration display, History list, and nighttime vs nap distinction (7 PM–7 AM = nighttime).
struct SleepSession: Identifiable {
    /// Unique identifier.
    var id: UUID
    /// When sleep started. From wearable/sleep detection.
    var startDate: Date
    /// When sleep ended; nil if currently asleep. From wearable/sleep detection.
    var endDate: Date?
    /// True if session falls in nighttime window (7 PM–7 AM). Derived or stored for History display.
    var isNighttime: Bool
    /// Which child this session belongs to.
    var childId: UUID

    init(id: UUID = UUID(), startDate: Date, endDate: Date? = nil, isNighttime: Bool, childId: UUID) {
        self.id = id
        self.startDate = startDate
        self.endDate = endDate
        self.isNighttime = isNighttime
        self.childId = childId
    }

    /// Duration in seconds. Uses now if endDate is nil (ongoing session).
    var durationSeconds: TimeInterval {
        let end = endDate ?? Date()
        return end.timeIntervalSince(startDate)
    }
}
