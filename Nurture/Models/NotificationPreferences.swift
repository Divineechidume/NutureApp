//
//  NotificationPreferences.swift
//  Nurture
//
//  Notification settings per household member. PRD Section 4, 6.
//  Used by Member model; controls rollover, nap, battery, connection alerts.
//

import Foundation

/// Notification preferences for a household member.
struct NotificationPreferences: Codable, Equatable {
    var receiveRolloverAlerts: Bool = true
    var receiveNapPredictions: Bool = true
    var receiveLowBatteryAlerts: Bool = true
    var receiveConnectionLostAlerts: Bool = true
    var quietHoursStart: Date?
    var quietHoursEnd: Date?

    init(
        receiveRolloverAlerts: Bool = true,
        receiveNapPredictions: Bool = true,
        receiveLowBatteryAlerts: Bool = true,
        receiveConnectionLostAlerts: Bool = true,
        quietHoursStart: Date? = nil,
        quietHoursEnd: Date? = nil
    ) {
        self.receiveRolloverAlerts = receiveRolloverAlerts
        self.receiveNapPredictions = receiveNapPredictions
        self.receiveLowBatteryAlerts = receiveLowBatteryAlerts
        self.receiveConnectionLostAlerts = receiveConnectionLostAlerts
        self.quietHoursStart = quietHoursStart
        self.quietHoursEnd = quietHoursEnd
    }
}
