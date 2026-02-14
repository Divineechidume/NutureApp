//
//  Constants.swift
//  Nurture
//
//  Central constants from PRD: wake windows (Section 5), nighttime definition, demo mode, alert throttle.
//

import Foundation

// MARK: - Demo Mode

/// When true, app uses mock data and skips real Bluetooth. Set via build setting USE_DEMO_MODE (Debug has it).
#if USE_DEMO_MODE
let useDemoMode = true
#else
let useDemoMode = false
#endif

/// Mock child name for demo. PRD: Initial state.
let mockChildName = "Emma"

/// Mock age range label for display. PRD: 6–12 months for demo.
let mockAgeRangeDisplay = "6-12 months"

// MARK: - Age-Based Wake Windows (PRD Section 5 - Nap Prediction)

/// Wake window in hours (min...max) per age range. Used by MLPredictionService for "next nap" estimate.
enum WakeWindowHours {
    /// 0–6 months: 1.5–2 hours
    static let zeroToSixMonths: (min: Double, max: Double) = (1.5, 2.0)
    /// 6–12 months: 2–3 hours
    static let sixToTwelveMonths: (min: Double, max: Double) = (2.0, 3.0)
    /// 1–2 years: 4–5 hours
    static let oneToTwoYears: (min: Double, max: Double) = (4.0, 5.0)
    /// 2–3 years: 5–6 hours
    static let twoToThreeYears: (min: Double, max: Double) = (5.0, 6.0)
}

// MARK: - Nighttime Definition (PRD: 7 PM – 7 AM = nighttime, rest = naps)

/// Hour (0–23) at which nighttime sleep starts.
let nighttimeStartHour = 19  // 7 PM
/// Hour (0–23) at which nighttime sleep ends.
let nighttimeEndHour = 7     // 7 AM

// MARK: - Age Range (PRD Section 1, 5)

/// Age bracket for child. Used in onboarding and nap prediction wake windows.
enum AgeRange: String, CaseIterable, Identifiable {
    case zeroToSixMonths = "0-6mo"
    case sixToTwelveMonths = "6-12mo"
    case oneToTwoYears = "1-2yr"
    case twoToThreeYears = "2-3yr"
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .zeroToSixMonths: return "0-6 months"
        case .sixToTwelveMonths: return "6-12 months"
        case .oneToTwoYears: return "1-2 years"
        case .twoToThreeYears: return "2-3 years"
        }
    }

    /// Returns age range from birthdate. PRD: 0-6mo, 6-12mo, 1-2yr, 2-3yr.
    static func from(birthdate: Date) -> AgeRange {
        let months = Calendar.current.dateComponents([.month], from: birthdate, to: Date()).month ?? 0
        switch months {
        case 0..<6: return .zeroToSixMonths
        case 6..<12: return .sixToTwelveMonths
        case 12..<24: return .oneToTwoYears
        default: return .twoToThreeYears
        }
    }
}

// MARK: - Safety Alerts (PRD Section 4)

/// Max one rollover alert per this many minutes unless dismissed (avoid spam).
let rolloverAlertThrottleMinutes = 5
