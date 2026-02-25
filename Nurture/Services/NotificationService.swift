//
//  NotificationService.swift
//  Nurture
//
//  Consolidated notification service: rollover alerts and sleep-prediction notifications.
//  Test helpers let Settings trigger a dry-run of each alert type.
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

// MARK: - In-file presentation model & copy helpers

/// Lightweight enum describing notification kinds handled by the app.
enum NotificationType {
    case rollover
    case sleepPrediction
    case unknown
}

/// Presentation model: simple, local struct used for normalizing payloads when needed.
struct NotificationPresentation {
    let id: String
    let type: NotificationType
    let displayTitle: String
    let displayBody: String
    let childName: String?
    let timestamp: Date?
    let userInfo: [AnyHashable: Any]
}

func makePresentation(from payload: NotificationPayload) -> NotificationPresentation {
    let info = payload.userInfo
    let timestamp: Date? = (info["deliveryTime"] as? TimeInterval).flatMap { Date(timeIntervalSince1970: $0) }
        ?? (info["scheduledTime"] as? TimeInterval).flatMap { Date(timeIntervalSince1970: $0) }
    let childName = info["childName"] as? String
    let rawType = (info["notificationType"] as? String)?.lowercased()
    let type: NotificationType
    switch rawType {
    case "sleepprediction": type = .sleepPrediction
    case "rollover": type = .rollover
    default: type = .unknown
    }
    let displayTitle = (info["sheetTitle"] as? String) ?? payload.title
    let displayBody = (info["sheetBody"] as? String) ?? payload.body
    return NotificationPresentation(id: payload.id, type: type, displayTitle: displayTitle, displayBody: displayBody, childName: childName, timestamp: timestamp, userInfo: info)
}

func rolloverSheetCopy(childName: String, rolloverTime: Date) -> (title: String, body: String) {
    let headerName = childName.isEmpty ? "Baby" : childName
    let f = DateFormatter(); f.timeStyle = .short
    let timeString = f.string(from: rolloverTime)
    let title = "\(headerName) may have rolled over 🧸"
    let body = "Your baby, \(headerName), rolled onto their tummy at \(timeString). Many babies begin rolling as they grow. If placed on their back to sleep, you may want to gently reposition them. 💗"
    return (title, body)
}

func sleepPredictionSheetCopy(childName: String, predictedTime: Date) -> (title: String, body: String) {
    let headerName = childName.isEmpty ? "Baby" : childName
    let title = "Sleepy window approaching for \(headerName) 🧸"
    let body = "Based on today's rhythm, your baby may be ready for a nap soon. You might begin to notice sleepy cues like rubbing eyes or slowing down."
    return (title, body)
}

/// Notification categories used by the app.
private enum NotificationCategory: String {
    case rollover = "ROLLOVER_ALERT"
    case sleepPrediction = "SLEEP_PREDICTION"
}

/// NotificationService publishes incoming notifications and schedules local notifications.
///
/// Design notes / AI-integration guide:
/// - Bluetooth integration: when BluetoothService detects a rollover event, call:
///     NotificationService.shared.sendRolloverAlert(childName: childName, rolloverTime: Date())
///   The integrating agent must implement debounce/throttle (e.g., 60 s) to avoid duplicate alerts.
/// - Critical alerts: if critical alerts are required, implement them here (requires Apple entitlements).
/// - userInfo keys: "childName", "scheduledTime", "rolloverTime"/"predictedTime", "deliveryTime".
final class NotificationService: NSObject, ObservableObject, NotificationServiceProtocol, UNUserNotificationCenterDelegate {
    static let shared = NotificationService()

    @Published var incomingNotification: NotificationPayload?

    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self

        let rolloverCategory = UNNotificationCategory(
            identifier: NotificationCategory.rollover.rawValue,
            actions: [],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        let sleepPredictionCategory = UNNotificationCategory(
            identifier: NotificationCategory.sleepPrediction.rawValue,
            actions: [],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        UNUserNotificationCenter.current().setNotificationCategories([rolloverCategory, sleepPredictionCategory])
    }

    // MARK: - NotificationServiceProtocol

    /// Request notification permission. Call during onboarding (PermissionsView). PRD Section 7.
    func requestPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async { completion(granted) }
        }
    }

    /// Integration point: Called from BluetoothService or controller when rollover signal received.
    /// Schedules a local notification; callers should also trigger in-app alert via RolloverAlertState.
    func sendRolloverAlert(childName: String, rolloverTime: Date) {
        requestPermission { [weak self] granted in
            guard granted else { return }
            self?.scheduleRolloverAlert(childName: childName, rolloverTime: rolloverTime, after: 0.5)
        }
    }

    /// Public API: schedule a sleep prediction notification (requests permission first).
    func sendSleepPrediction(childName: String, predictedTime: Date) {
        requestPermission { [weak self] granted in
            guard granted else { return }
            self?.scheduleSleepPrediction(childName: childName, predictedTime: predictedTime, after: 0.5)
        }
    }

    /// Schedules a rollover alert for testing purposes (called from Settings → Test Rollover Alert).
    /// Named distinctly to clarify this sends a rollover notification, not a sleep prediction.
    func sendRolloverTestNotification(after seconds: TimeInterval = 1, childName: String? = nil) {
        let name = childName ?? "Baby"
        requestPermission { [weak self] granted in
            guard granted else { return }
            DispatchQueue.main.async {
                self?.scheduleRolloverAlert(childName: name, rolloverTime: Date(), after: seconds)
            }
        }
    }

    /// Placeholder for connection-lost alerts; kept for protocol conformance.
    func sendConnectionLostAlert() {
        // Non-critical placeholder notification. Implement real logic when connection monitoring is available.
        scheduleLocalNotification(
            title: "Nurture",
            body: "Connection lost with device.",
            category: .rollover,
            after: 1.0,
            extraUserInfo: nil
        )
    }

    /// Build a simple presentation tuple from a delivered NotificationPayload.
    /// Reads `sheetTitle`/`sheetBody` from userInfo (set when scheduling) and falls back to payload title/body.
    func presentation(from payload: NotificationPayload) -> (displayTitle: String, displayBody: String, timestamp: Date?) {
        let info = payload.userInfo
        let timestamp: Date? = (info["deliveryTime"] as? TimeInterval).flatMap { Date(timeIntervalSince1970: $0) }
            ?? (info["scheduledTime"] as? TimeInterval).flatMap { Date(timeIntervalSince1970: $0) }
        let displayTitle = (info["sheetTitle"] as? String) ?? payload.title
        let displayBody = (info["sheetBody"] as? String) ?? payload.body
        return (displayTitle, displayBody, timestamp)
    }

    // MARK: - UNUserNotificationCenterDelegate

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let content = response.notification.request.content
        var info = content.userInfo
        // Attach deliveryTime so UI shows accurate time (fallback to scheduledTime if missing).
        info["deliveryTime"] = response.notification.date.timeIntervalSince1970
        let payload = NotificationPayload(
            id: response.notification.request.identifier,
            title: content.title,
            body: content.body,
            userInfo: info
        )
        DispatchQueue.main.async { self.incomingNotification = payload }
        completionHandler()
    }

    // MARK: - Private scheduling

    private func scheduleRolloverAlert(childName: String, rolloverTime: Date, after seconds: TimeInterval) {
        let copy = rolloverSheetCopy(childName: childName, rolloverTime: rolloverTime)
        let extraInfo: [String: Any] = [
            "notificationType": "rollover",
            "childName": childName,
            "rolloverTime": rolloverTime.timeIntervalSince1970,
            "sheetTitle": copy.title,
            "sheetBody": copy.body
        ]
        scheduleLocalNotification(
            title: "Rollover Alert",
            body: "⚠️ \(childName.isEmpty ? "Baby" : childName) may have rolled over",
            category: .rollover,
            after: seconds,
            extraUserInfo: extraInfo
        )
    }

    private func scheduleSleepPrediction(childName: String, predictedTime: Date, after seconds: TimeInterval) {
        let copy = sleepPredictionSheetCopy(childName: childName, predictedTime: predictedTime)
        let extraInfo: [String: Any] = [
            "notificationType": "sleepPrediction",
            "childName": childName,
            "predictedTime": predictedTime.timeIntervalSince1970,
            "sheetTitle": copy.title,
            "sheetBody": copy.body
        ]
        scheduleLocalNotification(
            title: "Sleep Prediction",
            body: "💤 \(childName.isEmpty ? "Baby" : childName) may be ready for a nap soon",
            category: .sleepPrediction,
            after: seconds,
            extraUserInfo: extraInfo
        )
    }

    /// Schedules a local notification and merges extraUserInfo. Adds a scheduledTime entry.
    /// - Parameter seconds: Delay before delivery. UNTimeIntervalNotificationTrigger requires a
    ///   positive interval; a floor of 0.1 s is enforced so callers may pass 0 for near-immediate delivery.
    private func scheduleLocalNotification(
        id: String = UUID().uuidString,
        title: String,
        body: String,
        category: NotificationCategory,
        after seconds: TimeInterval,
        extraUserInfo: [String: Any]?
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        var info = content.userInfo
        if let extra = extraUserInfo {
            for (k, v) in extra { info[k] = v }
        }
        info["scheduledTime"] = Date().timeIntervalSince1970
        content.userInfo = info
        content.categoryIdentifier = category.rawValue

        // UNTimeIntervalNotificationTrigger requires a strictly positive interval.
        // Enforce a 0.1 s minimum so callers may pass 0 for near-immediate delivery.
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(0.1, seconds), repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("[NotificationService] Failed to schedule notification (\(category.rawValue)): \(error)")
            }
        }
    }

    // TODO (AI integration):
    // - BluetoothService should call `NotificationService.shared.sendRolloverAlert(childName:rolloverTime:)` on rollover detection.
    // - The integrating agent must implement debounce/throttle (e.g., 60 s) to avoid duplicate alerts for same event.
    // - For critical alert support, request entitlements and implement critical notification flow here.
}
