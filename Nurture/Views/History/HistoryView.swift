//
//  HistoryView.swift
//  Nurture
//
//  Past 7 days sleep list; expandable rows. Empty state with illustration. PRD Section 3.
//

import SwiftUI

/// List of past 7 days, newest first; tap to expand sessions.
struct HistoryView: View {
    @ObservedObject var controller: HistoryController
    @AppStorage("demoShowEmptyStates") private var demoShowEmptyStates = false

    private var showEmptyState: Bool {
        (useDemoMode && demoShowEmptyStates) || controller.daySummaries.isEmpty
    }

    var body: some View {
        NavigationView {
            ZStack {
                DesignTokens.cream.ignoresSafeArea()
                if showEmptyState {
                    EmptyHistoryView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(controller.daySummaries) { day in
                            dayRow(day)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func dayRow(_ day: DaySummary) -> some View {
        let isExpanded = controller.expandedDayId == day.id
        return Section {
            Button {
                controller.toggleExpanded(dayId: day.id)
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: DesignTokens.spacingXS) {
                        Text(day.date.formatted(as: .dateLabel))
                            .font(DesignTokens.headingFont(size: 17))
                            .foregroundColor(DesignTokens.textPrimary)
                        Text("Total: \(day.totalDuration.durationString)")
                            .font(DesignTokens.captionFont())
                            .foregroundColor(DesignTokens.textSecondary)
                    }
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(DesignTokens.textSecondary)
                }
                .padding(.vertical, DesignTokens.spacingSM)
            }
            if isExpanded {
                ForEach(day.sessions) { session in
                    sessionRow(session)
                }
            }
        }
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
