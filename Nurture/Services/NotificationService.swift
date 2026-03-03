//
//  NotificationService.swift
//  Nurture
//
//  Consolidated implementation: supports only rollover alerts. Test alerts reuse the same rollover API.
//

import Foundation
import UserNotifications

/// Payload delivered to the app when a notification is tapped.
struct NotificationPayload: Identifiable, Equatable {
    let id: String
    let title: String
    let body: String
    let userInfo: [AnyHashable: Any]

    static func == (lhs: NotificationPayload, rhs: NotificationPayload) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - In-file copy helpers

func rolloverSheetCopy(childName: String, rolloverTime: Date) -> (title: String, body: String) {
    let headerName = childName.isEmpty ? "Baby" : childName
    let f = DateFormatter(); f.timeStyle = .short
    let timeString = f.string(from: rolloverTime)
    let title = "\(headerName) may have rolled over."
    let body = "Your baby, \(headerName), rolled onto their tummy at \(timeString). Many babies begin rolling as they grow. If placed on their back to sleep, you may want to gently reposition them. 💗"
    return (title, body)
}

func sleepPredictionSheetCopy(childName: String, predictedTime: Date) -> (title: String, body: String) {
    let headerName = childName.isEmpty ? "Baby" : childName
    let title = "Sleepy window approaching for \(headerName) 🧸"
    let body = "Based on today’s rhythm, your baby may be ready for a nap soon. You might begin to notice sleepy cues like rubbing eyes or slowing down."
    return (title, body)
}

/// Notification categories used by the app. Only rollover is supported to keep UX consistent.
private enum NotificationCategory: String {
    case rollover = "ROLLOVER_ALERT"
    case sleepPrediction = "SLEEP_PREDICTION"
}

/// NotificationService publishes incoming notifications and schedules rollover-style local notifications.
///
/// Design notes / AI-integration guide:
/// - Single notification type: rollover alerts. Test alerts reuse the same scheduling so the user experience is identical.
/// - Bluetooth integration: when the BluetoothService detects a rollover event for a child, it should call:
///     NotificationService.shared.sendRolloverAlert(childName: childName, rolloverTime: Date())
///   The integrating agent must implement debounce/throttle (e.g., 60s) to avoid duplicate alerts for the same event.
/// - Critical alerts: if critical alerts are required, implement them here (requires Apple entitlements).
/// - userInfo keys: "childName", "scheduledTime", "rolloverTime", "deliveryTime".
final class NotificationService: NSObject, ObservableObject, NotificationServiceProtocol, UNUserNotificationCenterDelegate {
    static let shared = NotificationService()

    @Published var incomingNotification: NotificationPayload?

    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self

        // Register only the rollover category. Test alerts reuse this category so system copy is consistent.
        let rolloverCategory = UNNotificationCategory(identifier: NotificationCategory.rollover.rawValue, actions: [], intentIdentifiers: [], options: [.customDismissAction])
        let sleepPredictionCategory = UNNotificationCategory(identifier: NotificationCategory.sleepPrediction.rawValue, actions: [], intentIdentifiers: [], options: [.customDismissAction])
        UNUserNotificationCenter.current().setNotificationCategories([rolloverCategory, sleepPredictionCategory])
    }

    // MARK: - Permission

    func requestPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async { completion(granted) }
        }
    }

    func requestPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            requestPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    // MARK: - Public API (rollover only)

    /// Schedule a rollover-style system notification. This is the single canonical notification type.
    /// - Parameters:
    ///   - childName: display name for the child (included in userInfo for in-app UI)
    ///   - rolloverTime: the time of the rollover event; used in userInfo for the in-app sheet
    ///   - after: seconds to delay delivery (useful for testing)
    // Internal helper that schedules after a delay. Callers should use the protocol method below which ensures permission.
    private func scheduleRolloverAlert(childName: String, rolloverTime: Date, after seconds: TimeInterval = 0.5) {
        let (sheetTitle, sheetBody) = rolloverSheetCopy(childName: childName, rolloverTime: rolloverTime)

        let userInfo: [String: Any] = [
            "childName": childName,
            "rolloverTime": rolloverTime.timeIntervalSince1970,
            "sheetTitle": sheetTitle,
            "sheetBody": sheetBody,
            "notificationType": "rollover"
        ]

        scheduleLocalNotification(title: "Nurture", body: "\(childName) may have changed position.", category: .rollover, after: seconds, extraUserInfo: userInfo)
    }

    // Internal helper to schedule sleep prediction notification
    private func scheduleSleepPrediction(childName: String, predictedTime: Date, after seconds: TimeInterval = 0.5) {

        // Longer copy for the in-app sheet; follow same pattern as rollover
        let (sheetTitle, sheetBody) = sleepPredictionSheetCopy(childName: childName, predictedTime: predictedTime)

        let userInfo: [String: Any] = [
            "childName": childName,
            "predictedTime": predictedTime.timeIntervalSince1970,
            "sheetTitle": sheetTitle,
            "sheetBody": sheetBody,
            "notificationType": "sleepPrediction"
]

        // Use the product name as the visible system notification title to match rollover alerts
        scheduleLocalNotification(title: "Nurture", body: "Nap time may be near for \(childName)", category: .sleepPrediction, after: seconds, extraUserInfo: userInfo)
    }

    /// Protocol-conforming public API: requests permission then schedules a rollover alert.
    func sendRolloverAlert(childName: String, rolloverTime: Date) {
        requestPermission { [weak self] granted in
            guard granted else { return }
            self?.scheduleRolloverAlert(childName: childName, rolloverTime: rolloverTime, after: 0.5)
        }
    }

    /// Build a simple presentation tuple from a delivered NotificationPayload.
    /// Returns (displayTitle, displayBody, timestamp). This function reads `sheetTitle`/`sheetBody`
    /// from userInfo (set when scheduling) and falls back to the notification payload title/body.
    func presentation(from payload: NotificationPayload) -> (displayTitle: String, displayBody: String, timestamp: Date?) {
        let info = payload.userInfo
        let timestamp: Date? = (info["deliveryTime"] as? TimeInterval).flatMap { Date(timeIntervalSince1970: $0) } ?? (info["scheduledTime"] as? TimeInterval).flatMap { Date(timeIntervalSince1970: $0) }
        let displayTitle = (info["sheetTitle"] as? String) ?? payload.title
        let displayBody = (info["sheetBody"] as? String) ?? payload.body
        return (displayTitle, displayBody, timestamp)
    }

    /// Public API: schedule a sleep prediction notification (requests permission first)
    func sendSleepPrediction(childName: String, predictedTime: Date) {
        requestPermission { [weak self] granted in
            guard granted else { return }
            self?.scheduleSleepPrediction(childName: childName, predictedTime: predictedTime, after: 0.5)
        }
    }

    /// Convenience method used by Settings → Test Alert. Schedules a rollover alert so the test
    /// exercise the same code path as a real event.
    ///
    /// - Parameters:
    ///   - seconds: Delay before delivery. The system requires a minimum of 1 second for
    ///     `UNTimeIntervalNotificationTrigger`; values below 1 are clamped automatically via
    ///     `max(1, seconds)` in `scheduleLocalNotification`.
    ///   - childName: Name displayed in the notification. Defaults to "Baby".
    func sendRolloverTestNotification(after seconds: TimeInterval = 1, childName: String? = nil) {
        let name = childName ?? "Baby"
        requestPermission { granted in
            DispatchQueue.main.async {
                if granted {
                    self.scheduleRolloverAlert(childName: name, rolloverTime: Date(), after: seconds)
                }
            }
        }
    }

    /// Placeholder for connection-lost alerts; kept for protocol conformance.
    func sendConnectionLostAlert() {
        // Non-critical placeholder notification. Implement real logic when connection monitoring is available.
        scheduleLocalNotification(title: "Nurture", body: "Connection lost with device.", category: .rollover, after: 1.0, extraUserInfo: nil)
    }

    // MARK: - UNUserNotificationCenterDelegate

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let content = response.notification.request.content
        var info = content.userInfo
        // Attach deliveryTime so UI shows accurate time (fallback to scheduledTime if missing).
        info["deliveryTime"] = response.notification.date.timeIntervalSince1970
        let payload = NotificationPayload(id: response.notification.request.identifier, title: content.title, body: content.body, userInfo: info)
        DispatchQueue.main.async { self.incomingNotification = payload }
        completionHandler()
    }

    // MARK: - Helpers

    /// Schedules a local notification and merges extraUserInfo. Adds a scheduledTime entry.
    private func scheduleLocalNotification(id: String = UUID().uuidString, title: String, body: String, category: NotificationCategory, after seconds: TimeInterval, extraUserInfo: [String: Any]? = nil) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        var info = content.userInfo
        if let extra = extraUserInfo {
            for (k, v) in extra {
                info[k] = v
            }
        }
        info["scheduledTime"] = Date().timeIntervalSince1970
        content.userInfo = info

        content.categoryIdentifier = category.rawValue

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, seconds), repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("[NotificationService] Failed to schedule notification (\(category.rawValue)): \(error)")
            }
        }
    }

    // TODO (AI integration):
    // - BluetoothService should call `NotificationService.shared.sendRolloverAlert(childName:rolloverTime:)` on rollover detection.
    // - The integrating agent must implement debounce/throttle (e.g., 60s) to avoid duplicate alerts for same event.
    // - For critical alert support, request entitlements and implement critical notification flow here.
}
