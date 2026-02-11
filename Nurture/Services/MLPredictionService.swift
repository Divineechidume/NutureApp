//
//  MLPredictionService.swift
//  Nurture
//
//  Nap time prediction. MVP: age-based wake windows (Constants). Post-MVP: Core ML. PRD Section 5.
//

import Foundation

/// Provides "next nap" estimate. MVP uses Constants wake windows; later can use Core ML model.
/// Integration point: HomeController calls when child is awake and displays result on Home.
/// Analytics: Consider tracking when prediction is shown and when nap was taken (for model tuning).
final class MLPredictionService {
    /// Predict next nap time from last wake time and age. PRD: "Likely ready for a nap around 2:00 PM".
    func predictNextNap(wakeTime: Date, ageRange: AgeRange) -> NapPrediction {
        let (minHours, maxHours) = wakeWindowHours(for: ageRange)
        let midHours = (minHours + maxHours) / 2
        let suggested = Calendar.current.date(byAdding: .hour, value: Int(midHours), to: wakeTime) ?? wakeTime
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        let timeStr = formatter.string(from: suggested)
        return NapPrediction(
            suggestedTime: suggested,
            confidence: .high,
            message: "Likely ready for a nap around \(timeStr)"
        )
    }

    private func wakeWindowHours(for ageRange: AgeRange) -> (Double, Double) {
        switch ageRange {
        case .zeroToSixMonths: return WakeWindowHours.zeroToSixMonths
        case .sixToTwelveMonths: return WakeWindowHours.sixToTwelveMonths
        case .oneToTwoYears: return WakeWindowHours.oneToTwoYears
        case .twoToThreeYears: return WakeWindowHours.twoToThreeYears
        }
    }

    // TODO: Implement AI-powered nap prediction (post-MVP)
    // Purpose: Learn from child's actual patterns over 14 days; use Core ML for personalized prediction
    // PRD Reference: Section 5 - Optional: Learn from child's actual patterns over time
    // Implementation notes:
    // - Days 1-14: Use age-based defaults (current implementation)
    // - Day 15+: Load Core ML model; input recent sleep/wake history; output suggested time + confidence
    // Dependencies: Persistence for history; trained Core ML model
    // Estimated complexity: High
}
