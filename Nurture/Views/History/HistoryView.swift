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
    @ObservedObject private var manualStore = ManualSleepStore.shared
    @AppStorage("demoShowEmptyStates") private var demoShowEmptyStates = false

    private var showEmptyState: Bool {
        // Preserve demo "empty state" toggle for design previews; otherwise
        // show the weekly view and handle missing data per-week.
        (useDemoMode && demoShowEmptyStates)
    }

    private let calendar = Calendar.current
    private let weekdays = ["S", "M", "T", "W", "T", "F", "S"]
    @State private var weekOffset: Int = 0

    /// Anchor the weekly mock history to Tue, Mar 3, 2026.
    private var mockAnchorDate: Date {
        calendar.date(from: DateComponents(year: 2026, month: 3, day: 3)) ?? Date()
    }

    private var maxWeekOffset: Int { 0 }

    private var currentWeekStart: Date {
        let reference = calendar.date(byAdding: .day, value: weekOffset * 7, to: mockAnchorDate) ?? mockAnchorDate
        return calendar.dateInterval(of: .weekOfYear, for: reference)?.start ?? calendar.startOfDay(for: reference)
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

    /// Day detail when data exists; blank metrics placeholder when no selection or no data.
    @ViewBuilder
    private var dayDetailOrPlaceholder: some View {
        if let selected = controller.selectedDate,
           let day = daySummaryForDisplay(for: selected) {
            selectedDayDetail(day)
        } else {
            emptyDayDetailPlaceholder
        }
    }

    /// Blank metrics section so layout stays intact when no history or no day selected.
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

    /// Single source of truth for History: total sleep (night + naps) for a date in seconds. Used by label and bar; no cached arrays.
    private func totalSleepSeconds(for date: Date) -> TimeInterval {
        guard let day = daySummaryForDisplay(for: date) else { return 0 }
        return day.sessions.reduce(0) { $0 + $1.durationSeconds }
    }

    /// Mock sessions for Tuesday Mar 3, 2026: night 9h 15m + nap 1h 30m + nap 1h = 11h 45m total.
    private func mockSessionsForTuesdayMar3() -> [SleepSession] {
        let childId = UUID()
        let tue = calendar.date(from: DateComponents(year: 2026, month: 3, day: 3))!
        let prevDay = calendar.date(byAdding: .day, value: -1, to: tue)!
        let nightStart = calendar.date(bySettingHour: 19, minute: 45, second: 0, of: prevDay)!
        let nightEnd = nightStart.addingTimeInterval(9 * 3600 + 15 * 60)
        let nap1Start = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: tue)!
        let nap1End = nap1Start.addingTimeInterval(1 * 3600 + 30 * 60)
        let nap2Start = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: tue)!
        let nap2End = nap2Start.addingTimeInterval(3600)
        return [
            SleepSession(startDate: nightStart, endDate: nightEnd, isNighttime: true, childId: childId),
            SleepSession(startDate: nap1Start, endDate: nap1End, isNighttime: false, childId: childId),
            SleepSession(startDate: nap2Start, endDate: nap2End, isNighttime: false, childId: childId),
        ]
    }

    private func daySummaryForDisplay(for date: Date) -> DaySummary? {
        let dayStart = calendar.startOfDay(for: date)
        var sessions: [SleepSession] = ManualSleepStore.shared.sessions(for: date)

        if let existing = controller.daySummary(for: date) {
            sessions.append(contentsOf: existing.sessions)
        }
        if sessions.isEmpty, calendar.isDate(date, inSameDayAs: mockAnchorDate) {
            sessions = mockSessionsForTuesdayMar3()
        }
        if sessions.isEmpty, let mockH = mockHoursForFallback(for: date), mockH > 0 {
            let prevDay = calendar.date(byAdding: .day, value: -1, to: dayStart) ?? dayStart
            let bedtime = calendar.date(bySettingHour: 19, minute: 45, second: 0, of: prevDay) ?? prevDay
            let wake = bedtime.addingTimeInterval(mockH * 3600)
            sessions.append(SleepSession(startDate: bedtime, endDate: wake, isNighttime: true, childId: UUID()))
        }

        if sessions.isEmpty { return nil }
        return DaySummary(id: dayStart, date: dayStart, sessions: sessions)
    }

    /// Fallback mock hours only for weeks that are not the primary mock week (Mar 1 2026).
    private func mockHoursForFallback(for date: Date) -> Double? {
        let weekMar1 = calendar.date(from: DateComponents(year: 2026, month: 3, day: 1))!
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? calendar.startOfDay(for: date)
        if calendar.isDate(weekStart, inSameDayAs: weekMar1) { return nil }
        let weekFeb22 = calendar.date(from: DateComponents(year: 2026, month: 2, day: 22))!
        if calendar.isDate(weekStart, inSameDayAs: weekFeb22) {
            let weekdayIndex = calendar.component(.weekday, from: date) - 1
            let seed = Int(weekStart.timeIntervalSince1970) ^ (weekdayIndex * 1_109_519_737)
            return deterministicHours(min: 7.0, max: 11.0, seed: seed)
        }
        return nil
    }

    private func deterministicHours(min: Double, max: Double, seed: Int) -> Double {
        var x = UInt64(bitPattern: Int64(seed))
        x = x &* 6364136223846793005 &+ 1442695040888963407
        let unit = Double(x % 10_000) / 10_000.0
        let value = min + (max - min) * unit
        return (value * 10).rounded() / 10
    }

    private var weeklyBarChart: some View {
        let dates = (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: currentWeekStart)
        }

        struct DayBucket {
            let date: Date
            let label: String
            let hours: Double?
        }

        let dayBuckets: [DayBucket] = dates.enumerated().map { index, date in
            let label = weekdays[index]
            let totalSeconds = totalSleepSeconds(for: date)
            let hours: Double? = totalSeconds > 0 ? totalSeconds / 3600 : nil
            return DayBucket(date: date, label: label, hours: hours)
        }

        let availableHours = dayBuckets.compactMap { $0.hours }
        let hasDataThisWeek = !availableHours.isEmpty
        let maxHours = max(availableHours.max() ?? 10, 1)

        return VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text("This week's sleep")
                    .font(.headingSmall)
                    .foregroundColor(.textPrimary)
                Spacer()
            }

            if !hasDataThisWeek {
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
                        let value = bucket.hours ?? 0
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
                                    if bucket.hours != nil {
                                        controller.selectDate(bucket.date)
                                    }
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

    private func selectedDayDetail(_ day: DaySummary) -> some View {
        let deletableIds = ManualSleepStore.shared.entryIds(for: day.date)
        let totalSeconds = totalSleepSeconds(for: day.date)
        return VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(day.date.formatted(as: .dateLabel))
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

            ForEach(day.sessions) { session in
                sessionRow(session, canDelete: deletableIds.contains(session.id)) {
                    ManualSleepStore.shared.remove(entryId: session.id)
                }
            }
            .padding(Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.medium)
                    .fill(Color.white)
                    .cardShadowSecondary()
            )
        }
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

    private func sessionRow(_ session: SleepSession, canDelete: Bool, onDelete: @escaping () -> Void) -> some View {
        let f = DateFormatter()
        f.timeStyle = .short
        let startStr = f.string(from: session.startDate)
        let endStr = session.endDate.map { f.string(from: $0) } ?? "—"
        return HStack {
            Image(systemName: session.isNighttime ? "moon.fill" : "sun.max.fill")
                .foregroundColor(session.isNighttime ? DesignTokens.darkSage : DesignTokens.peachCoral)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(startStr + " – " + endStr)
                    .font(DesignTokens.captionFont())
                    .foregroundColor(DesignTokens.textPrimary)
                Text(session.durationSeconds.durationString)
                    .font(DesignTokens.captionFont())
                    .foregroundColor(DesignTokens.textSecondary)
            }
            Spacer()
            if canDelete {
                Button(role: .destructive) { onDelete() } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 16))
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, DesignTokens.spacingXS)
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
