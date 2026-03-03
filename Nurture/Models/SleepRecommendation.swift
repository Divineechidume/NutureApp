//
//  SleepRecommendation.swift
//  Nurture
//
//  AI-generated sleep tip or suggestion. Used by AISleepRecommendationService (mock data for MVP).
//

import Foundation

/// Category of recommendation for icon and display. Reassuring, not clinical (PRD tone).
enum SleepRecommendationCategory: String {
    case bedtime = "Bedtime"
    case routine = "Routine"
    case rest = "Rest"
    case pattern = "Pattern"
}

/// A single AI sleep recommendation: title, message, optional suggested time.
/// Displayed on Home as a supportive tip. Source: AISleepRecommendationService (mock for MVP).
struct SleepRecommendation: Identifiable {
    var id: UUID
    /// Short label, e.g. "Tonight's suggestion"
    var title: String
    /// User-facing message — supportive, not judgmental (PRD).
    var message: String
    /// Optional suggested bedtime for display (e.g. "7:30 PM").
    var suggestedBedtime: Date?
    /// Category for icon (bedtime, routine, rest, pattern).
    var category: SleepRecommendationCategory
    /// Human-readable explanation for the recommendation (transparency).
    var reasoning: String

    init(
        id: UUID = UUID(),
        title: String,
        message: String,
        suggestedBedtime: Date? = nil,
        category: SleepRecommendationCategory,
        reasoning: String = ""
    ) {
        self.id = id
        self.title = title
        self.message = message
        self.suggestedBedtime = suggestedBedtime
        self.category = category
        self.reasoning = reasoning
    }
}
