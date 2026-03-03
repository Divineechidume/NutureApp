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

    /// Day detail when data exists; "No Data" when selected day has no data; blank when no selection.
    @ViewBuilder
    private var dayDetailOrPlaceholder: some View {
        if let selected = controller.selectedDate {
            if let day = daySummaryForDisplay(for: selected) {
                selectedDayDetail(day)
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

    /// Single source of truth for History: total sleep (night + naps) for a date in seconds. Used by label and bar; no cached arrays.
    private func totalSleepSeconds(for date: Date) -> TimeInterval {
        guard let day = daySummaryForDisplay(for: date) else { return 0 }
        return day.sessions.reduce(0) { $0 + $1.durationSeconds }
    }

    /// Hardcoded sleep + nap entries for demo week only. Sunday Mar 1, Monday Mar 2, Tuesday Mar 3. Returns nil for all other days.
    private func hardcodedSessions(for date: Date) -> [SleepSession]? {
        let childId = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E5F") ?? UUID()
        let sun = calendar.date(from: DateComponents(year: 2026, month: 3, day: 1))!
        let mon = calendar.date(from: DateComponents(year: 2026, month: 3, day: 2))!
        let tue = calendar.date(from: DateComponents(year: 2026, month: 3, day: 3))!
        let feb28 = calendar.date(from: DateComponents(year: 2026, month: 2, day: 28))!

        if calendar.isDate(date, inSameDayAs: sun) {
            let nightStart = calendar.date(bySettingHour: 20, minute: 15, second: 0, of: feb28)!
            let nightEnd = calendar.date(bySettingHour: 7, minute: 0, second: 0, of: sun)!
            let napStart = calendar.date(bySettingHour: 13, minute: 10, second: 0, of: sun)!
            let napEnd = calendar.date(bySettingHour: 14, minute: 0, second: 0, of: sun)!
            return [
                SleepSession(startDate: nightStart, endDate: nightEnd, isNighttime: true, childId: childId),
                SleepSession(startDate: napStart, endDate: napEnd, isNighttime: false, childId: childId),
            ]
        }
        if calendar.isDate(date, inSameDayAs: mon) {
            let nightStart = calendar.date(bySettingHour: 20, minute: 0, second: 0, of: sun)!
            let nightEnd = calendar.date(bySettingHour: 7, minute: 30, second: 0, of: mon)!
            let nap1Start = calendar.date(bySettingHour: 12, minute: 30, second: 0, of: mon)!
            let nap1End = calendar.date(bySettingHour: 13, minute: 15, second: 0, of: mon)!
            let nap2Start = calendar.date(bySettingHour: 16, minute: 0, second: 0, of: mon)!
            let nap2End = calendar.date(bySettingHour: 16, minute: 35, second: 0, of: mon)!
            return [
                SleepSession(startDate: nightStart, endDate: nightEnd, isNighttime: true, childId: childId),
                SleepSession(startDate: nap1Start, endDate: nap1End, isNighttime: false, childId: childId),
                SleepSession(startDate: nap2Start, endDate: nap2End, isNighttime: false, childId: childId),
            ]
        }
        if calendar.isDate(date, inSameDayAs: tue) {
            let nightStart = calendar.date(bySettingHour: 19, minute: 45, second: 0, of: mon)!
            let nightEnd = calendar.date(bySettingHour: 4, minute: 50, second: 0, of: tue)!
            let napStart = calendar.date(bySettingHour: 14, minute: 10, second: 0, of: tue)!
            let napEnd = calendar.date(bySettingHour: 15, minute: 5, second: 0, of: tue)!
            return [
                SleepSession(startDate: nightStart, endDate: nightEnd, isNighttime: true, childId: childId),
                SleepSession(startDate: napStart, endDate: napEnd, isNighttime: false, childId: childId),
            ]
        }
        return nil
    }

    private func daySummaryForDisplay(for date: Date) -> DaySummary? {
        let dayStart = calendar.startOfDay(for: date)
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? dayStart
        if !calendar.isDate(weekStart, inSameDayAs: demoWeekStart) {
            return nil
        }
        var sessions: [SleepSession] = ManualSleepStore.shared.sessions(for: date)
        if let existing = controller.daySummary(for: date) {
            sessions.append(contentsOf: existing.sessions)
        }
        if sessions.isEmpty, let hardcoded = hardcodedSessions(for: date) {
            sessions = hardcoded
        }
        if sessions.isEmpty { return nil }
        return DaySummary(id: dayStart, date: dayStart, sessions: sessions)
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
            let totalSeconds = isCurrentWeekDemoWeek ? totalSleepSeconds(for: date) : 0
            let hours: Double? = totalSeconds > 0 ? totalSeconds / 3600 : nil
            return DayBucket(date: date, label: label, hours: hours)
        }

        let availableHours = dayBuckets.compactMap { $0.hours }
        let hasDataThisWeek = isCurrentWeekDemoWeek && !availableHours.isEmpty
        let maxHours = max(availableHours.max() ?? 10, 1)

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
                                    if isCurrentWeekDemoWeek || bucket.hours != nil {
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
