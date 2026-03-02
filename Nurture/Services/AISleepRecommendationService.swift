//
//  AISleepRecommendationService.swift
//  Nurture
//
//  AI sleep recommendations using mock data. MVP: returns contextual tips from a fixed set.
//  Post-MVP: could use on-device ML or API based on sleep history and child profile.
//

import Foundation

/// Provides one AI-generated sleep recommendation at a time. MVP uses mock data only.
/// Integration point: HomeController calls when loading/refreshing; HomeView displays the tip.
final class AISleepRecommendationService {
    private let calendar = Calendar.current

    /// Returns a single recommendation based on child and recent sleep (mock logic for MVP).
    /// - Parameters:
    ///   - child: Selected child (age range used for contextual mock).
    ///   - lastNightTotalSeconds: Last night's total sleep in seconds.
    ///   - todaysNapsSeconds: Today's total nap duration in seconds.
    ///   - isCurrentlyAsleep: Whether child is currently asleep.
    func recommendation(
        for child: Child?,
        lastNightTotalSeconds: TimeInterval,
        todaysNapsSeconds: TimeInterval,
        isCurrentlyAsleep: Bool
    ) -> SleepRecommendation? {
        // Mock: pick one recommendation; in real implementation would score/rank by context.

        let lastNightHours = lastNightTotalSeconds / 3600
        let napsHours = todaysNapsSeconds / 3600

        // Transparency Layer: Show reasoning for AI predictions
        if isCurrentlyAsleep {
            return mockRecommendation(
                title: "Sleeping peacefully",
                message: "Your little one is getting good rest. No change needed.",
                category: .rest,
                reasoning: "Sleep patterns look healthy and consistent with age recommendations."
            )
        }

        // Suggest earlier bedtime if last night was short
        if lastNightHours < 8.5 {
            var comps = calendar.dateComponents([.year, .month, .day], from: Date())
            comps.hour = 19
            comps.minute = 30
            let suggested = calendar.date(from: comps) ?? Date()
            return mockRecommendation(
                title: "Tonight's suggestion",
                message: "Based on last night's sleep, an earlier bedtime around 7:30 PM might help.",
                suggestedBedtime: suggested,
                category: .bedtime,
                reasoning: "Last night's sleep was slightly shorter than recommended, so an earlier bedtime may help."
            )
        }

        // Suggest routine if naps are light
        if napsHours < 1.0 && lastNightHours >= 9 {
            return mockRecommendation(
                title: "Routine tip",
                message: "A short, consistent wind-down before bed can help your little one settle.",
                category: .routine,
                reasoning: "Today's nap duration has been lower than average, so extra rest tonight may be helpful."
            )
        }

        // Default: positive reinforcement
        if lastNightHours >= 9 {
            return mockRecommendation(
                title: "Looking good",
                message: "Last night's sleep was solid. Keeping a similar bedtime can help maintain the pattern.",
                category: .pattern,
                reasoning: "Sleep patterns look healthy and consistent with age recommendations."
            )
        }

        return mockRecommendation(
            title: "Sleep insight",
            message: "Aim for a calm, dim environment in the hour before bed — it can make a big difference.",
            category: .routine,
            reasoning: "Sleep patterns look healthy and consistent with age recommendations."
        )
    }

    private func mockRecommendation(
        title: String,
        message: String,
        suggestedBedtime: Date? = nil,
        category: SleepRecommendationCategory,
        reasoning: String = ""
    ) -> SleepRecommendation {
        SleepRecommendation(
            title: title,
            message: message,
            suggestedBedtime: suggestedBedtime,
            category: category,
            reasoning: reasoning
        )
    }
}
