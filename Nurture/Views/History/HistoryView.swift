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

    /// Demo week: Mar 1, 2026. Sunday = Mar 1, Monday = Mar 2, Today = Mar 3 (demo), Tomorrow = Mar 4.
    private var demoWeekStart: Date {
        calendar.date(from: DateComponents(year: 2026, month: 3, day: 1))!
    }

    private var demoSunday: Date { calendar.startOfDay(for: demoWeekStart) }
    private var demoMonday: Date { calendar.date(byAdding: .day, value: 1, to: demoSunday)! }
    private var demoToday: Date { calendar.date(byAdding: .day, value: 2, to: demoSunday)! }
    private var demoTomorrow: Date { calendar.date(byAdding: .day, value: 3, to: demoSunday)! }

    /// Real calendar today (for dynamic total when viewing a week that contains today).
    private var realTodayStart: Date { calendar.startOfDay(for: Date()) }

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

    /// Day detail when data exists; "No Data" when selected day has no data; blank when no selection.
    @ViewBuilder
    private var dayDetailOrPlaceholder: some View {
        if let selected = controller.selectedDate {
            if hasDataForDisplay(for: selected) {
                dayDetailContent(for: selected)
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

    /// Single source of truth: total sleep for a date in seconds. Bar chart and label use this only. No cached values.
    /// Sunday (Mar 1) → 11h; Monday (Mar 2) → 11.5h; Today → base 9.75h + logged today; else → 0.
    private func totalSleepSeconds(for date: Date) -> TimeInterval {
        let dayStart = calendar.startOfDay(for: date)
        if calendar.isDate(dayStart, inSameDayAs: demoSunday) { return 11 * 3600 }
        if calendar.isDate(dayStart, inSameDayAs: demoMonday) { return 11.5 * 3600 }
        if calendar.isDate(dayStart, inSameDayAs: realTodayStart) {
            let baseToday: TimeInterval = 9.75 * 3600
            return baseToday + manualStore.totalSleepSeconds(for: date)
        }
        return 0
    }

    /// True if the date has any displayable sleep (for showing day detail vs "No Data").
    private func hasDataForDisplay(for date: Date) -> Bool {
        totalSleepSeconds(for: date) > 0
    }

    /// Whether the date is read-only (Sunday or Monday). Today and others are not locked.
    private func isLockedDay(_ date: Date) -> Bool {
        let dayStart = calendar.startOfDay(for: date)
        return calendar.isDate(dayStart, inSameDayAs: demoSunday) || calendar.isDate(dayStart, inSameDayAs: demoMonday)
    }

    private var weeklyBarChart: some View {
        let dates = (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: currentWeekStart)
        }

        struct DayBucket {
            let date: Date
            let label: String
            /// Bar height source: totalSleepSeconds(for: date) / 3600. No cached values.
            let hours: Double
        }

        let dayBuckets: [DayBucket] = dates.enumerated().map { index, date in
            let label = weekdays[index]
            let totalSeconds = isCurrentWeekDemoWeek ? totalSleepSeconds(for: date) : 0
            let hours = totalSeconds / 3600
            return DayBucket(date: date, label: label, hours: hours)
        }

        let allHours = dayBuckets.map(\.hours)
        let hasDataThisWeek = isCurrentWeekDemoWeek && allHours.contains { $0 > 0 }
        let maxHours = max(allHours.max() ?? 10, 1)

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

            // Bar height = totalSleepSeconds(for: date) / 3600 (single source of truth)
            GeometryReader { proxy in
                HStack(alignment: .bottom, spacing: Spacing.xs) {
                    ForEach(0..<dayBuckets.count, id: \.self) { index in
                        let bucket = dayBuckets[index]
                        let value = bucket.hours
                        let heightRatio = maxHours > 0 ? CGFloat(value) / CGFloat(maxHours) : 0
                        let barHeight = max(4, proxy.size.height * heightRatio)

                        VStack(spacing: 4) {
                            if value > 0 {
                                Text(String(format: "%.1fh", value))
                                    .font(.labelSmall)
                                    .foregroundColor(.textSecondary)
                            } else {
                                Text("0h")
                                    .font(.labelSmall)
                                    .foregroundColor(.textSecondary)
                            }

                            RoundedRectangle(cornerRadius: CornerRadius.small)
                                .fill(Color.sageGreen.opacity(value > 0 ? 0.9 : 0.2))
                                .frame(height: barHeight)
                                .frame(maxWidth: .infinity)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    if isCurrentWeekDemoWeek {
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

    /// Day detail: locked breakdown for Sunday/Monday; base + logged sessions for Today. Uses totalSleepSeconds only.
    @ViewBuilder
    private func dayDetailContent(for date: Date) -> some View {
        let dayStart = calendar.startOfDay(for: date)
        let totalSeconds = totalSleepSeconds(for: date)

        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(dayStart.formatted(as: .dateLabel))
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

            if calendar.isDate(dayStart, inSameDayAs: demoSunday) {
                lockedDaySessionsCard(rows: [
                    (label: "Night sleep", duration: 10 * 3600),
                    (label: "Nap", duration: 1 * 3600),
                ])
            } else if calendar.isDate(dayStart, inSameDayAs: demoMonday) {
                lockedDaySessionsCard(rows: [
                    (label: "Night sleep", duration: 9 * 3600),
                    (label: "Nap", duration: (2 * 3600) + (30 * 60)),
                ])
            } else if calendar.isDate(dayStart, inSameDayAs: realTodayStart) {
                todayDetailSessionsCard(for: date)
            }
        }
    }

    /// Read-only card for Sunday/Monday. No edit or delete.
    private func lockedDaySessionsCard(rows: [(label: String, duration: TimeInterval)]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack {
                    Image(systemName: row.label.lowercased().contains("night") ? "moon.fill" : "sun.max.fill")
                        .foregroundColor(row.label.lowercased().contains("night") ? DesignTokens.darkSage : DesignTokens.peachCoral)
                        .frame(width: 24)
                    Text(row.label)
                        .font(DesignTokens.captionFont())
                        .foregroundColor(DesignTokens.textPrimary)
                    Spacer()
                    Text(row.duration.durationString)
                        .font(DesignTokens.captionFont())
                        .foregroundColor(DesignTokens.textSecondary)
                }
                .padding(.vertical, DesignTokens.spacingXS)
            }
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.medium)
                .fill(Color.white)
                .cardShadowSecondary()
        )
    }

    /// Today: base rows (9h 15m night, 30m nap) + any sessions from ManualSleepStore (deletable).
    private func todayDetailSessionsCard(for date: Date) -> some View {
        let baseNight: TimeInterval = 9 * 3600 + 15 * 60
        let baseNap: TimeInterval = 30 * 60
        let loggedSessions = manualStore.sessions(for: date)
        let deletableIds = manualStore.entryIds(for: date)

        return VStack(alignment: .leading, spacing: 0) {
            lockedRow(label: "Night sleep", duration: baseNight)
            lockedRow(label: "Nap", duration: baseNap)
            ForEach(loggedSessions) { session in
                sessionRow(session, canDelete: deletableIds.contains(session.id)) {
                    manualStore.remove(entryId: session.id)
                }
            }
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.medium)
                .fill(Color.white)
                .cardShadowSecondary()
        )
    }

    private func lockedRow(label: String, duration: TimeInterval) -> some View {
        HStack {
            Image(systemName: label.lowercased().contains("night") ? "moon.fill" : "sun.max.fill")
                .foregroundColor(label.lowercased().contains("night") ? DesignTokens.darkSage : DesignTokens.peachCoral)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(DesignTokens.captionFont())
                    .foregroundColor(DesignTokens.textPrimary)
                Text(duration.durationString)
                    .font(DesignTokens.captionFont())
                    .foregroundColor(DesignTokens.textSecondary)
            }
            Spacer()
        }
        .padding(.vertical, DesignTokens.spacingXS)
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
