//
//  Date+Formatting.swift
//  Nurture
//
//  Format dates for display: "Fell asleep at 7:32 PM", "2h 15m" duration. PRD Section 2.
//

import Foundation

extension Date {
    /// Display style for date/time strings. Avoids conflict with Foundation.Date.FormatStyle.
    enum DateDisplayStyle {
        case shortTime   // 7:32 PM
        case dateLabel   // "Today", "Yesterday", "Monday, Feb 3"
    }

    func formatted(as style: DateDisplayStyle) -> String {
        let formatter = DateFormatter()
        switch style {
        case .shortTime:
            formatter.timeStyle = .short
            return formatter.string(from: self)
        case .dateLabel:
            if Calendar.current.isDateInToday(self) { return "Today" }
            if Calendar.current.isDateInYesterday(self) { return "Yesterday" }
            formatter.dateFormat = "EEEE, MMM d"
            return formatter.string(from: self)
        }
    }
}

extension TimeInterval {
    /// Human-readable duration, e.g. "2h 15m" or "45m". PRD: "Sleeping for 1h 23m".
    var durationString: String {
        let h = Int(self) / 3600
        let m = (Int(self) % 3600) / 60
        if h > 0 {
            return "\(h)h \(m)m"
        }
        return "\(m)m"
    }
}
