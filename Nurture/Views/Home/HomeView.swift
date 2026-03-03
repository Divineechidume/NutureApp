//
//  HomeView.swift
//  Nurture
//
//  Main home screen: status card, secondary info cards, empty state when no device.
//  PRD Section 2 - Home Screen. Polished cards with shadows and typography hierarchy.
//

import SwiftUI

/// Main home screen. Status card (Asleep/Awake + duration) and secondary info cards.
struct HomeView: View {
    @ObservedObject var controller: HomeController
    @ObservedObject var childrenStore: ChildrenStore
    @ObservedObject var householdService: HouseholdService
    @ObservedObject private var manualStore = ManualSleepStore.shared

    @AppStorage("demoShowEmptyStates") private var demoShowEmptyStates = false
    @State private var showNapOptions = false
    @State private var showLogNapSheet = false
    @State private var showTodayNapsDetail = false
    @State private var logNapStart = Date()
    @State private var logNapEnd = Date()

    /// Whether a device is paired. In demo mode: true unless "Show empty states" is on; otherwise from BluetoothService.
    private var hasDevice: Bool {
        if useDemoMode && demoShowEmptyStates { return false }
        // TODO: Wire to BluetoothService / pairing state
        return useDemoMode ? true : true
    }

    /// True when showing "Sleeping" (night sleep or nap in progress).
    private var sleepStatusIsSleeping: Bool {
        controller.isAsleep || controller.napStartDate != nil
    }

    /// Status card duration: "Napping for: Xh Ym" (live) when nap in progress, else Sleeping/Awake.
    private var sleepStatusDurationText: String {
        if controller.napStartDate != nil {
            return "Napping for: \(controller.napDurationString)"
        }
        if controller.isAsleep {
            return "Sleeping for \(controller.durationString)"
        }
        return "Awake for \(controller.durationString)"
    }

    /// Start time for status card: nap start when napping, else night sleep start.
    private var sleepStatusStartTimeString: String? {
        if controller.napStartDate != nil { return controller.napStartTimeString }
        return controller.sleepStartTimeString
    }

    /// Today's Naps card text: always from today's stored nap entries (count + total duration).
    private var todaysNapsCardText: String {
        let today = Calendar.current.startOfDay(for: Date())
        let total = manualStore.napDuration(for: today)
        let count = manualStore.napEntries(for: today).count
        return "\(total.durationString) across \(count) nap\(count == 1 ? "" : "s")"
    }

    private var familyNameDisplay: String {
        let name = householdService.currentHousehold?.name ?? "My Family"
        return name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "My Family" : name
    }

    var body: some View {
        ZStack {
            (sleepStatusIsSleeping ? Color.sleepBackground : Color.awakeBackground).ignoresSafeArea()
        }
        .refreshable { controller.refresh() }
        .overlay {
            if hasDevice {
                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        homeHeader
                        SleepStatusCard(
                            isAsleep: sleepStatusIsSleeping,
                            duration: sleepStatusDurationText,
                            startTime: sleepStatusStartTimeString
                        )
                        sleepTrackingButtons
                        secondaryCards(isAsleep: sleepStatusIsSleeping)
                    }
                    .padding(Spacing.lg)
                }
            } else {
                NoDevicePairedView(onPairTapped: { /* Navigate to pairing */ })
            }
        }
        .sheet(isPresented: $showNapOptions) {
            NapOptionsModalView(
                onStartNap: {
                    showNapOptions = false
                    controller.startNap()
                },
                onLogNap: {
                    showNapOptions = false
                    let now = Date()
                    let calendar = Calendar.current
                    let todayStart = calendar.startOfDay(for: now)
                    logNapStart = now
                    let defaultEnd = now.addingTimeInterval(45 * 60)
                    logNapEnd = min(defaultEnd, calendar.date(byAdding: .second, value: 86399, to: todayStart) ?? defaultEnd)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        showLogNapSheet = true
                    }
                },
                onDismiss: { showNapOptions = false }
            )
        }
        .sheet(isPresented: $showLogNapSheet) {
            LogNapSheet(
                startTime: $logNapStart,
                endTime: $logNapEnd,
                onSave: { start, end in
                    controller.logNap(startDate: start, durationSeconds: end.timeIntervalSince(start))
                    showLogNapSheet = false
                },
                onCancel: { showLogNapSheet = false }
            )
        }
        .sheet(isPresented: $showTodayNapsDetail) {
            TodayNapsDetailView(onDismiss: { showTodayNapsDetail = false })
        }
    }

    private var sleepTrackingButtons: some View {
        HStack(spacing: Spacing.sm) {
            if controller.isAsleep {
                Button {
                    controller.endSleep()
                } label: {
                    Label("End Sleep", systemImage: "moon.zzz.fill")
                        .font(.labelMedium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.sm)
                        .background(RoundedRectangle(cornerRadius: CornerRadius.small).fill(Color.sageGreen))
                }
                .buttonStyle(.plain)
            } else if controller.napStartDate != nil {
                Button {
                    controller.endNap()
                } label: {
                    Label("End Nap", systemImage: "sun.max.fill")
                        .font(.labelMedium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.sm)
                        .background(RoundedRectangle(cornerRadius: CornerRadius.small).fill(Color(hex: "F59E0B")))
                }
                .buttonStyle(.plain)
            } else {
                Button {
                    controller.startSleep()
                } label: {
                    Label("Start Sleep", systemImage: "moon.zzz.fill")
                        .font(.labelMedium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.sm)
                        .background(RoundedRectangle(cornerRadius: CornerRadius.small).fill(Color.sageGreen))
                }
                .buttonStyle(.plain)

                Button {
                    showNapOptions = true
                } label: {
                    Label("Nap", systemImage: "sun.max.fill")
                        .font(.labelMedium)
                        .foregroundColor(.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: CornerRadius.small)
                                .fill(Color.cardBackground)
                                .overlay(RoundedRectangle(cornerRadius: CornerRadius.small).stroke(Color.sageGreen.opacity(0.5), lineWidth: 1))
                                .cardShadowSecondary()
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, Spacing.md)
    }

    private func secondaryCards(isAsleep: Bool) -> some View {
        VStack(spacing: Spacing.xs) {
            InfoCard(
                icon: "moon.fill",
                iconColor: Color(hex: "6366F1"),
                title: "Last Night",
                value: controller.lastNightTotalString + " total sleep"
            )
            Button {
                showTodayNapsDetail = true
            } label: {
                InfoCard(
                    icon: "sun.max.fill",
                    iconColor: Color(hex: "F59E0B"),
                    title: "Today's Naps",
                    value: todaysNapsCardText
                )
            }
            .buttonStyle(.plain)
            if !sleepStatusIsSleeping {
                NapRecommendationCard(recommendation: controller.napRecommendation)
            }
            if let rec = controller.sleepRecommendation {
                SleepRecommendationCard(recommendation: rec)
            }
        }
        .padding(.horizontal, Spacing.md)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isAsleep)
    }

    private var homeHeader: some View {
        HStack {
            Text(familyNameDisplay.uppercased())
                .font(.labelSmall)
                .foregroundColor(.textSecondary)
            Spacer()
            if !childrenStore.children.isEmpty {
                childSelectorPill
            }
        }
    }

    private var childSelectorPill: some View {
        Group {
            if childrenStore.children.count > 1 {
                Menu {
                    ForEach(childrenStore.children) { child in
                        Button {
                            childrenStore.selectChild(child.id)
                        } label: {
                            HStack {
                                Text(child.name)
                                if childrenStore.selectedChildID == child.id {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "figure.and.child.holdinghands")
                            .font(.system(size: 14))
                            .foregroundColor(Color.sageGreen)
                        Text(childrenStore.selectedChild?.name ?? "Child")
                            .font(.labelMedium)
                            .foregroundColor(.textPrimary)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.textSecondary)
                    }
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xs)
                    .background(
                        RoundedRectangle(cornerRadius: CornerRadius.small)
                            .fill(Color.white.opacity(0.9))
                            .overlay(
                                RoundedRectangle(cornerRadius: CornerRadius.small)
                                    .stroke(Color.sageGreen.opacity(0.5), lineWidth: 1)
                            )
                            .cardShadowSecondary()
                    )
                }
                .buttonStyle(.plain)
            } else if let child = childrenStore.selectedChild {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "figure.and.child.holdinghands")
                        .font(.system(size: 14))
                        .foregroundColor(Color.sageGreen)
                    Text(child.name)
                        .font(.labelMedium)
                        .foregroundColor(.textPrimary)
                }
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xs)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.small)
                        .fill(Color.white.opacity(0.9))
                        .overlay(
                            RoundedRectangle(cornerRadius: CornerRadius.small)
                                .stroke(Color.sageGreen.opacity(0.5), lineWidth: 1)
                        )
                        .cardShadowSecondary()
                )
            }
        }
    }
}

// MARK: - Sleep Status (Original PRD layout: centered on background, no card)

struct SleepStatusCard: View {
    let isAsleep: Bool
    let duration: String
    let startTime: String?

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: isAsleep ? "moon.zzz.fill" : "sun.max.fill")
                .font(.system(size: 48))
                .foregroundColor(isAsleep ? .white.opacity(0.9) : .textPrimary.opacity(0.9))

            Text(isAsleep ? "Asleep" : "Awake")
                .font(.displayLarge)
                .foregroundColor(isAsleep ? .white : .textPrimary)

            Text(duration)
                .font(.headingMedium)
                .foregroundColor(isAsleep ? .white.opacity(0.85) : .textSecondary)

            if let startTime = startTime, isAsleep {
                Text("Fell asleep at \(startTime)")
                    .font(.bodyMedium)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.lg)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isAsleep)
    }
}

// MARK: - Info Card

struct InfoCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(iconColor)
                .frame(width: 36, height: 36)
                .background(Circle().fill(iconColor.opacity(0.15)))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.labelSmall)
                    .foregroundColor(.textSecondary)
                Text(value)
                    .font(.bodyMedium)
                    .foregroundColor(.textPrimary)
            }

            Spacer()
        }
        .padding(Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.small)
                .fill(Color.cardBackground)
                .cardShadowSecondary()
        )
    }
}

// MARK: - Nap Recommendation Card (state-based, no timestamp)

struct NapRecommendationCard: View {
    let recommendation: NapRecommendation

    private let iconColor = Color(hex: "EAB308")

    var body: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: iconName)
                .font(.system(size: 18))
                .foregroundColor(iconColor)
                .frame(width: 36, height: 36)
                .background(Circle().fill(iconColor.opacity(0.15)))
            VStack(alignment: .leading, spacing: 2) {
                Text(titleText)
                    .font(.labelSmall)
                    .foregroundColor(.textSecondary)
                Text(recommendation.message)
                    .font(.bodyMedium)
                    .foregroundColor(.textPrimary)
            }
            Spacer()
        }
        .padding(Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.small)
                .fill(Color.cardBackground)
                .cardShadowSecondary()
        )
    }

    private var titleText: String {
        recommendation.status == .bedtimeApproaching ? "Tonight" : "Next Nap"
    }

    private var iconName: String {
        recommendation.status == .bedtimeApproaching ? "moon.fill" : "lightbulb.fill"
    }
}

// MARK: - AI Sleep Recommendation Card

struct SleepRecommendationCard: View {
    let recommendation: SleepRecommendation
    @State private var showDetails = false

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.timeStyle = .short
        return f
    }()

    private var iconName: String {
        switch recommendation.category {
        case .bedtime: return "moon.stars.fill"
        case .routine: return "sparkles"
        case .rest: return "heart.fill"
        case .pattern: return "chart.line.uptrend.xyaxis"
        }
    }

    private var iconColor: Color {
        switch recommendation.category {
        case .bedtime: return Color(hex: "6366F1")
        case .routine: return Color(hex: "8B5CF6")
        case .rest: return Color(hex: "EC4899")
        case .pattern: return Color.sageGreen
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: iconName)
                    .font(.system(size: 18))
                    .foregroundColor(iconColor)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(iconColor.opacity(0.15)))
                Text(recommendation.title)
                    .font(.labelSmall)
                    .foregroundColor(.textSecondary)
                Spacer()
                Image(systemName: showDetails ? "chevron.up" : "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.textSecondary)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showDetails.toggle()
                }
            }
            Text(recommendation.message)
                .font(.bodyMedium)
                .foregroundColor(.textPrimary)
            if let bedtime = recommendation.suggestedBedtime {
                Text("Suggested: \(Self.timeFormatter.string(from: bedtime))")
                    .font(.labelSmall)
                    .foregroundColor(iconColor)
            }

            // Transparency Layer: Show reasoning for AI predictions
            if showDetails && !recommendation.reasoning.isEmpty {
                Text(recommendation.reasoning)
                    .font(.bodySmall)
                    .foregroundColor(.textSecondary)
                    .padding(.top, Spacing.xs)
            }
        }
        .padding(Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.small)
                .fill(Color.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.small)
                        .stroke(iconColor.opacity(0.3), lineWidth: 1)
                )
                .cardShadowSecondary()
        )
    }
}

// MARK: - No Device Paired Empty State

struct NoDevicePairedView: View {
    var onPairTapped: () -> Void

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Image("empty_no_device")
                .resizable()
                .scaledToFit()
                .frame(height: 140)

            Text("No device paired")
                .font(.headingLarge)
                .foregroundColor(.textPrimary)

            Text("Pair your Nurture band to start tracking sleep")
                .font(.bodyMedium)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xl)

            Button(action: onPairTapped) {
                Text("Pair Device")
                    .font(.labelLarge)
                    .foregroundColor(.white)
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: CornerRadius.small)
                            .fill(Color.sageGreen)
                    )
            }
            .padding(.top, Spacing.sm)
        }
        .frame(maxHeight: .infinity)
        .padding(Spacing.lg)
        .background(Color.cream)
    }
}

// MARK: - Log Nap (manual entry) sheet — today only, start + end time, validation

struct LogNapSheet: View {
    @Binding var startTime: Date
    @Binding var endTime: Date
    var onSave: (Date, Date) -> Void
    var onCancel: () -> Void

    private let calendar = Calendar.current

    /// End time must never exceed current device time. Use for all calculations and when saving.
    private var cappedEndTime: Date {
        min(endTime, Date())
    }

    /// End > start, duration ≥ 1 minute. Uses cappedEndTime so future selection is auto-capped.
    private var canSave: Bool {
        guard cappedEndTime > startTime else { return false }
        return cappedEndTime.timeIntervalSince(startTime) >= 60
    }

    var body: some View {
        NavigationView {
            Form {
                Section {
                    DatePicker("Start time", selection: $startTime, displayedComponents: [.hourAndMinute])
                } header: {
                    Text("Start time (today)")
                }

                Section {
                    DatePicker("End time", selection: $endTime, displayedComponents: [.hourAndMinute])
                } header: {
                    Text("End time (today)")
                }

                if !canSave {
                    Section {
                        Text("End time must be after start time and at least 1 minute long. End time cannot exceed current time.")
                            .font(.bodySmall)
                            .foregroundColor(.textSecondary)
                    }
                }
            }
            .navigationTitle("Log Nap")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onCancel() }
                        .foregroundColor(.sageGreen)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(startTime, cappedEndTime)
                    }
                    .foregroundColor(canSave ? .sageGreen : .gray)
                    .disabled(!canSave)
                }
            }
            .background(Color.cream)
            .onAppear { clampToToday() }
            .onChange(of: startTime) { _ in clampToToday() }
            .onChange(of: endTime) { _ in clampToToday() }
        }
    }

    /// Keep start and end on today (no calendar selection).
    private func clampToToday() {
        let now = Date()
        let todayStart = calendar.startOfDay(for: now)
        let startComp = calendar.dateComponents([.hour, .minute], from: startTime)
        let endComp = calendar.dateComponents([.hour, .minute], from: endTime)
        startTime = calendar.date(bySettingHour: startComp.hour ?? 0, minute: startComp.minute ?? 0, second: 0, of: todayStart) ?? startTime
        endTime = calendar.date(bySettingHour: endComp.hour ?? 0, minute: endComp.minute ?? 0, second: 0, of: todayStart) ?? endTime
    }
}

// MARK: - Nap options modal (full-screen feel, lightweight sheet)

struct NapOptionsModalView: View {
    var onStartNap: () -> Void
    var onLogNap: () -> Void
    var onDismiss: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: Spacing.lg) {
                Text("Track a nap with the monitor or enter manually.")
                    .font(.bodyMedium)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.lg)

                VStack(spacing: Spacing.sm) {
                    Button {
                        dismiss()
                        onStartNap()
                    } label: {
                        Label("Start Nap", systemImage: "sun.max.fill")
                            .font(.labelLarge)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.sm)
                            .background(RoundedRectangle(cornerRadius: CornerRadius.small).fill(Color(hex: "F59E0B")))
                    }
                    .buttonStyle(.plain)

                    Button {
                        dismiss()
                        onLogNap()
                    } label: {
                        Label("Log Nap", systemImage: "pencil")
                            .font(.labelLarge)
                            .foregroundColor(.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.sm)
                            .background(
                                RoundedRectangle(cornerRadius: CornerRadius.small)
                                    .fill(Color.cardBackground)
                                    .overlay(RoundedRectangle(cornerRadius: CornerRadius.small).stroke(Color.sageGreen.opacity(0.5), lineWidth: 1))
                                    .cardShadowSecondary()
                            )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, Spacing.lg)

                Spacer()
            }
            .padding(.top, Spacing.xl)
            .background(Color.cream.ignoresSafeArea())
            .navigationTitle("Nap")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                        onDismiss()
                    }
                    .foregroundColor(.sageGreen)
                }
            }
        }
    }
}

// MARK: - Today's Naps detail (list of naps for today)

struct TodayNapsDetailView: View {
    var onDismiss: () -> Void

    @ObservedObject private var manualStore = ManualSleepStore.shared
    private let calendar = Calendar.current

    private var todayNaps: [ManualSleepEntry] {
        let today = calendar.startOfDay(for: Date())
        return manualStore.napEntries(for: today)
    }

    var body: some View {
        NavigationView {
            Group {
                if todayNaps.isEmpty {
                    VStack(spacing: Spacing.lg) {
                        Image(systemName: "sun.max")
                            .font(.system(size: 48))
                            .foregroundColor(.textSecondary.opacity(0.6))
                        Text("No naps logged today")
                            .font(.headingSmall)
                            .foregroundColor(.textPrimary)
                        Text("Use Start Nap or Log Nap on the Home screen to add entries.")
                            .font(.bodySmall)
                            .foregroundColor(.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Spacing.lg)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(todayNaps) { entry in
                            napRow(entry: entry)
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .background(Color.cream)
            .navigationTitle("Today's Naps")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onDismiss()
                    }
                    .foregroundColor(.sageGreen)
                }
            }
        }
    }

    private func formatTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.timeStyle = .short
        return f.string(from: date)
    }

    /// One nap row: "StartTime – EndTime (Duration)" with short time style for start/end.
    private func napRow(entry: ManualSleepEntry) -> some View {
        let endTime = entry.startDate.addingTimeInterval(entry.durationSeconds)
        return HStack {
            Text("\(formatTime(entry.startDate)) – \(formatTime(endTime)) (\(entry.durationSeconds.durationString))")
                .font(.bodyMedium)
                .foregroundColor(.textPrimary)
            Spacer()
        }
        .padding(.vertical, Spacing.xs)
    }
}

