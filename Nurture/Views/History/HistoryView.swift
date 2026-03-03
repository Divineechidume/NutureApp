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

    /// Mock total sleep hours for one demo week (Sun–Sat).
    private let mockWeekDurations: [Double] = [9.5, 8.2, 7.9, 10.0, 8.7, 9.0, 8.4]

    private var currentWeekStart: Date {
        let reference = calendar.date(byAdding: .day, value: weekOffset * 7, to: Date()) ?? Date()
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
                            if let day = controller.selectedDate.flatMap({ controller.daySummary(for: $0) }) {
                                selectedDayDetail(day)
                            }
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
        }
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

            let hours: Double?
            if useDemoMode && weekOffset == 0 && index < mockWeekDurations.count {
                hours = mockWeekDurations[index]
            } else if let summary = controller.daySummary(for: date) {
                hours = summary.totalDuration / 3600
            } else {
                hours = nil
            }

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
                Text("No history collected for this week")
                    .font(.bodySmall)
                    .foregroundColor(.textSecondary)
                    .padding(.top, Spacing.xs)
            } else {
                GeometryReader { proxy in
                    HStack(alignment: .bottom, spacing: Spacing.xs) {
                        ForEach(0..<dayBuckets.count, id: \.self) { index in
                            let bucket = dayBuckets[index]
                            let value = bucket.hours ?? 0
                            let heightRatio = CGFloat(value) / CGFloat(maxHours)
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
                                    .onTapGesture {
                                        if let _ = controller.daySummary(for: bucket.date) {
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
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.medium)
                .fill(Color.white)
                .cardShadowSecondary()
        )
    }

    private func selectedDayDetail(_ day: DaySummary) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(day.date.formatted(as: .dateLabel))
                        .font(.headingSmall)
                        .foregroundColor(.textPrimary)
                    Text("Total: \(day.totalDuration.durationString)")
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
                sessionRow(session)
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

    private func sessionRow(_ session: SleepSession) -> some View {
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
