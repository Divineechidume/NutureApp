//
//  HistoryView.swift
//  Nurture
//
//  Calendar view of sleep history. Month grid with dots for days with data; tap day to see sessions. PRD Section 3.
//

import SwiftUI

/// Calendar view of sleep history. Month grid, tap day to see sessions below.
struct HistoryView: View {
    @ObservedObject var controller: HistoryController
    @AppStorage("demoShowEmptyStates") private var demoShowEmptyStates = false

    private var showEmptyState: Bool {
        // Preserve demo "empty state" toggle for design previews; otherwise
        // show the weekly view and handle missing data per-week.
        (useDemoMode && demoShowEmptyStates)
    }

    private let calendar = Calendar.current
    private let weekdays = ["S", "M", "T", "W", "T", "F", "S"]
    @State private var weekOffset: Int = 0

    /// Demo week only: week of Mar 1, 2026 (Sun = Mar 1, Mon = Mar 2, Tue = Mar 3). Other weeks show "No Data Available".
    private var demoWeekStart: Date {
        calendar.date(from: DateComponents(year: 2026, month: 3, day: 1))!
    }

    private var maxWeekOffset: Int { 0 }

    private var currentWeekStart: Date {
        let reference = calendar.date(byAdding: .day, value: weekOffset * 7, to: demoWeekStart) ?? demoWeekStart
        return calendar.dateInterval(of: .weekOfYear, for: reference)?.start ?? calendar.startOfDay(for: reference)
    }

    private var isCurrentWeekDemoWeek: Bool {
        calendar.isDate(currentWeekStart, inSameDayAs: demoWeekStart)
    }

    var body: some View {
        NavigationView {
            ZStack {
                DesignTokens.cream.ignoresSafeArea()
                if showEmptyState {
                    EmptyHistoryView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: Spacing.lg) {
                            weekHeader
                            weeklyBarChart
                            dayDetailOrPlaceholder
                        }
                        .padding(Spacing.lg)
                    }
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var weekHeader: some View {
        HStack {
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    weekOffset -= 1
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.sageGreen)
                    .frame(width: 44, height: 44)
            }
            Spacer()
            Text(weekTitle(from: currentWeekStart))
                .font(.headingMedium)
                .foregroundColor(.textPrimary)
            Spacer()
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    weekOffset += 1
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.sageGreen)
                    .frame(width: 44, height: 44)
            }
            .disabled(weekOffset >= maxWeekOffset)
            .opacity(weekOffset >= maxWeekOffset ? 0.35 : 1.0)
        }
    }

    /// Day detail: static content for Sun/Mon/Tue; "No Data" when totalSleepSeconds == 0; blank when no selection.
    @ViewBuilder
    private var dayDetailOrPlaceholder: some View {
        if let selected = controller.selectedDate {
            if totalSleepSeconds(for: selected) > 0 {
                hardcodedDayDetail(date: selected)
            } else {
                noDataPlaceholder
            }
        } else {
            emptyDayDetailPlaceholder
        }
    }

    /// Shown when a day is selected but has no data (e.g. Wed–Sat of demo week).
    private var noDataPlaceholder: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Day details")
                        .font(.headingSmall)
                        .foregroundColor(.textPrimary)
                    Text("No Data")
                        .font(.bodySmall)
                        .foregroundColor(.textSecondary)
                }
                Spacer()
            }
            .padding(Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.medium)
                    .fill(Color.white)
                    .cardShadowSecondary()
            )
        }
    }

    /// Blank metrics section when no day selected.
    private var emptyDayDetailPlaceholder: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Day details")
                        .font(.headingSmall)
                        .foregroundColor(.textPrimary)
                    Text("Total: —")
                        .font(.bodySmall)
                        .foregroundColor(.textSecondary)
                }
                Spacer()
            }
            .padding(Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.medium)
                    .fill(Color.white)
                    .cardShadowSecondary()
            )
        }
    }

    /// Hardcoded totals for exactly three demo days (Sun/Mon/Tue Mar 1–3, 2026). No dynamic computation.
    private func totalSleepSeconds(for date: Date) -> TimeInterval {
        let sun = calendar.date(from: DateComponents(year: 2026, month: 3, day: 1))!
        let mon = calendar.date(from: DateComponents(year: 2026, month: 3, day: 2))!
        let tue = calendar.date(from: DateComponents(year: 2026, month: 3, day: 3))!
        if calendar.isDate(date, inSameDayAs: sun) { return 13.5 * 3600 }
        if calendar.isDate(date, inSameDayAs: mon) { return 13.5 * 3600 }
        if calendar.isDate(date, inSameDayAs: tue) { return 13.5 * 3600 }
        return 0
    }

    /// Static day detail for Sun/Mon/Tue: total + two fixed rows (Night Sleep 8h 30m, Nap 5h 0m). No session arrays.
    private func hardcodedDayDetail(date: Date) -> some View {
        let totalSeconds = totalSleepSeconds(for: date)
        return VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(date.formatted(as: .dateLabel))
                        .font(.headingSmall)
                        .foregroundColor(.textPrimary)
                    Text("Total: \(totalSeconds.durationString)")
                        .font(.bodySmall)
                        .foregroundColor(.textSecondary)
                }
                Spacer()
            }
            .padding(Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.medium)
                    .fill(Color.white)
                    .cardShadowSecondary()
            )

            VStack(spacing: 0) {
                staticSleepRow(icon: "moon.fill", label: "Night Sleep: 8h 30m", color: DesignTokens.darkSage)
                staticSleepRow(icon: "sun.max.fill", label: "Nap: 5h 0m", color: DesignTokens.peachCoral)
            }
            .padding(Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.medium)
                    .fill(Color.white)
                    .cardShadowSecondary()
            )
        }
    }

    private func staticSleepRow(icon: String, label: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            Text(label)
                .font(DesignTokens.captionFont())
                .foregroundColor(DesignTokens.textPrimary)
            Spacer()
        }
        .padding(.vertical, DesignTokens.spacingXS)
    }

    private var weeklyBarChart: some View {
        let dates = (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: currentWeekStart)
        }

        struct DayBucket {
            let date: Date
            let label: String
            let hours: Double
        }

        let dayBuckets: [DayBucket] = dates.enumerated().map { index, date in
            let label = weekdays[index]
            let hours = totalSleepSeconds(for: date) / 3600
            return DayBucket(date: date, label: label, hours: hours)
        }

        let maxHours = max(dayBuckets.map(\.hours).max() ?? 10, 1)
        let hasDataThisWeek = dayBuckets.contains { $0.hours > 0 }

        return VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text("This week's sleep")
                    .font(.headingSmall)
                    .foregroundColor(.textPrimary)
                Spacer()
            }

            if !isCurrentWeekDemoWeek {
                Text("No Data Available")
                    .font(.bodySmall)
                    .foregroundColor(.textSecondary)
                    .padding(.top, Spacing.xs)
            } else if !hasDataThisWeek {
                Text("No history available for this week")
                    .font(.bodySmall)
                    .foregroundColor(.textSecondary)
                    .padding(.top, Spacing.xs)
            }

            // Always show bar area (empty bars when no data)
            GeometryReader { proxy in
                HStack(alignment: .bottom, spacing: Spacing.xs) {
                    ForEach(0..<dayBuckets.count, id: \.self) { index in
                        let bucket = dayBuckets[index]
                        let value = bucket.hours
                        let heightRatio = hasDataThisWeek ? CGFloat(value) / CGFloat(maxHours) : 0
                        let barHeight = max(4, proxy.size.height * heightRatio)

                        VStack(spacing: 4) {
                            if value > 0 {
                                Text(String(format: "%.1fh", value))
                                    .font(.labelSmall)
                                    .foregroundColor(.textSecondary)
                            } else {
                                Text(" ")
                                    .font(.labelSmall)
                            }

                            RoundedRectangle(cornerRadius: CornerRadius.small)
                                .fill(Color.sageGreen.opacity(value > 0 ? 0.9 : 0.2))
                                .frame(height: barHeight)
                                .frame(maxWidth: .infinity)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    controller.selectDate(bucket.date)
                                }

                            Text(bucket.label)
                                .font(.labelSmall)
                                .foregroundColor(.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .frame(height: 140)
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.medium)
                .fill(Color.white)
                .cardShadowSecondary()
        )
    }

    private func weekTitle(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "Week of \(formatter.string(from: date))"
    }

    /// Returns array of optional day numbers. nil = empty cell for alignment.
    private func daysInMonth(for month: Date) -> [Int?] {
        guard let range = calendar.range(of: .day, in: .month, for: month),
              let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: month)) else {
            return []
        }
        let firstWeekday = calendar.component(.weekday, from: monthStart)
        let firstWeekdayZero = calendar.firstWeekday
        let leadingBlanks = (firstWeekday - firstWeekdayZero + 7) % 7
        var result: [Int?] = Array(repeating: nil, count: leadingBlanks)
        for day in 1...range.count {
            result.append(day)
        }
        return result
    }

}

struct EmptyHistoryView: View {
    var body: some View {
        VStack(spacing: Spacing.lg) {
            Image("empty_no_data")
                .resizable()
                .scaledToFit()
                .frame(height: 140)

            Text("No sleep data yet")
                .font(.headingLarge)
                .foregroundColor(.textPrimary)

            Text("Sleep sessions will appear here once your Nurture band starts tracking")
                .font(.bodyMedium)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xl)
        }
        .frame(maxHeight: .infinity)
    }
}
