//
//  NapRecommendationEngine.swift
//  Nurture
//
//  State-based nap recommendation from awake duration vs configurable wake window.
//  No fixed timestamp; returns status message only. After 8 PM shows "Bedtime approaching".
//

import Foundation

/// Status-based nap recommendation (no nextNapTime timestamp).
struct NapRecommendation {
    enum Status {
        case napNotNeededYet
        case napApproaching
        case napRecommendedNow
        case napOverdue
        case bedtimeApproaching
    }
    let status: Status
    let message: String
}

/// State-based recommendation: awakeDuration vs wakeWindow. Recomputed when sleep history changes.
final class NapRecommendationEngine {
    /// Wake window in seconds. Default 2 hours.
    var wakeWindowSeconds: TimeInterval = 2 * 3600

    /// Hour (0–23) after which we show "Bedtime approaching" instead of nap recommendation. Default 20 (8 PM).
    var bedtimeHour: Int = 16

    private let calendar = Calendar.current

    /// Recommend based on current time and last sleep end. Uses awakeDuration = currentTime - lastSleepEndTime.
    /// After 8 PM returns "Bedtime approaching". No fixed nextNapTime.
    func recommend(lastSleepEndTime: Date?, currentTime: Date = Date()) -> NapRecommendation {
        let hour = calendar.component(.hour, from: currentTime)
        if hour >= bedtimeHour {
            return NapRecommendation(status: .bedtimeApproaching, message: "Bedtime approaching")
        }

        guard let lastEnd = lastSleepEndTime, lastEnd <= currentTime else {
            return NapRecommendation(status: .napNotNeededYet, message: "Nap not needed yet")
        }

        let awakeDuration = currentTime.timeIntervalSince(lastEnd)
        let threshold75 = wakeWindowSeconds * 0.75
        let threshold100 = wakeWindowSeconds
        let thresholdOverdue = wakeWindowSeconds + 3600 // + 1 hour

        if awakeDuration < threshold75 {
            return NapRecommendation(status: .napNotNeededYet, message: "Nap not needed yet")
        }
        if awakeDuration < threshold100 {
            return NapRecommendation(status: .napApproaching, message: "Nap approaching")
        }
        if awakeDuration < thresholdOverdue {
            return NapRecommendation(status: .napRecommendedNow, message: "Nap recommended now")
        }
        return NapRecommendation(status: .napOverdue, message: "Nap overdue")
    }
}
