//
//  NapPrediction.swift
//  Nurture
//
//  AI/age-based nap time suggestion. PRD Section 5 (Nap Prediction).
//  Source: MLPredictionService (age-based for MVP; Core ML later).
//

import Foundation

/// Confidence level for nap prediction. Used for display (e.g. "Likely ready" vs "Might be ready soon").
enum NapConfidence: String {
    case high
    case medium
    case low
}

/// Suggested nap time and message. Source: MLPredictionService (age-based wake windows in MVP).
/// Displayed on Home when child is awake. PRD: "Likely ready for a nap around 2:00 PM".
struct NapPrediction {
    /// Suggested time for next nap.
    var suggestedTime: Date
    /// Confidence level (high/medium/low) for UI.
    var confidence: NapConfidence
    /// User-facing message, e.g. "Likely ready around 2:00 PM" or "Might be ready for a nap soon".
    var message: String
    /// Human-readable explanation for the prediction (transparency).
    var reasoning: String
}
