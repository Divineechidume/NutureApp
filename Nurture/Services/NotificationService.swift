//
//  NotificationService.swift
//  Nurture
//
//  Push and local notifications. PRD Section 4 - Safety Alerts (rollover, connection lost).
//

import Foundation
import UserNotifications

/// Requests permission; sends rollover and connection-lost alerts. Critical alerts for rollover (PRD §4).
final class NotificationService: ObservableObject, NotificationServiceProtocol {
    /// Request notification permission. Call during onboarding (PermissionsView). PRD Section 7.
    func requestPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async { completion(granted) }
        }
    }

    // TODO: Implement critical alert for rollover
    // Purpose: Notify parent immediately when baby rolls over (even if phone locked)
    // PRD Reference: Section 4 - "⚠️ [Child's Name] has rolled over"
    // Implementation notes:
    // - Use critical alert entitlement if available (iOS 12+); else high-priority local notification
    // - Message: "⚠️ [Child's Name] has rolled over"
    // - Throttle: max 1 per rolloverAlertThrottleMinutes unless dismissed
    // Dependencies: Child name from profile; trigger from BluetoothService/controller
    // Estimated complexity: Medium

    /// Integration point: Called from BluetoothService or controller when rollover signal received.
    /// Schedules a local notification; for demo also trigger in-app alert from caller.
    func sendRolloverAlert(childName: String, rolloverTime: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Rollover"
        content.body = "⚠️ \(childName) has rolled over"
        content.sound = .default
        content.categoryIdentifier = "ROLLOVER_ALERT"
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.5, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { _ in }
    }

    // TODO: Implement connection lost notification
    // Purpose: "Connection lost with Nurture device" when BLE disconnects. PRD Section 4 edge cases.
    func sendConnectionLostAlert() {
        // TODO: Schedule local notification
    }
}
