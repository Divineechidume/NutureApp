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

    @AppStorage("demoShowEmptyStates") private var demoShowEmptyStates = false
    @State private var showNapOptions = false
    @State private var showLogNapSheet = false
    @State private var logNapStart = Date()
    @State private var logNapMinutes: Int = 45

    /// Whether a device is paired. In demo mode: true unless "Show empty states" is on; otherwise from BluetoothService.
    private var hasDevice: Bool {
        if useDemoMode && demoShowEmptyStates { return false }
        // TODO: Wire to BluetoothService / pairing state
        return useDemoMode ? true : true
    }

    private var familyNameDisplay: String {
        let name = householdService.currentHousehold?.name ?? "My Family"
        return name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "My Family" : name
    }

    var body: some View {
        ZStack {
            (controller.isAsleep ? Color.sleepBackground : Color.awakeBackground).ignoresSafeArea()
        }
        .refreshable { controller.refresh() }
        .overlay {
            if hasDevice {
                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        homeHeader
                        SleepStatusCard(
                            isAsleep: controller.isAsleep,
                            duration: controller.isAsleep ? "Sleeping for \(controller.durationString)" : "Awake for \(controller.durationString)",
                            startTime: controller.sleepStartTimeString
                        )
                        sleepTrackingButtons
                        secondaryCards(isAsleep: controller.isAsleep)
                    }
                    .padding(Spacing.lg)
                }
            } else {
                NoDevicePairedView(onPairTapped: { /* Navigate to pairing */ })
            }
        }
        .confirmationDialog("Nap", isPresented: $showNapOptions, titleVisibility: .visible) {
            Button("Start Nap") {
                controller.startNap()
            }
            Button("Log Nap") {
                logNapStart = Date()
                logNapMinutes = 45
                showLogNapSheet = true
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Track a nap with the monitor or enter manually.")
        }
        .sheet(isPresented: $showLogNapSheet) {
            LogNapSheet(
                startTime: $logNapStart,
                durationMinutes: $logNapMinutes,
                onSave: {
                    controller.logNap(startDate: logNapStart, durationSeconds: TimeInterval(logNapMinutes * 60))
                    showLogNapSheet = false
                },
                onCancel: { showLogNapSheet = false }
            )
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
            InfoCard(
                icon: "sun.max.fill",
                iconColor: Color(hex: "F59E0B"),
                title: "Today's Naps",
                value: controller.todaysNapsString
            )
            if !isAsleep, let nap = controller.napPrediction {
                NapPredictionCard(prediction: nap)
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

// MARK: - Nap Prediction Card (expandable reasoning)

struct NapPredictionCard: View {
    let prediction: NapPrediction
    @State private var showDetails = false

    private let iconColor = Color(hex: "EAB308")

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 18))
                    .foregroundColor(iconColor)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(iconColor.opacity(0.15)))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Next Nap")
                        .font(.labelSmall)
                        .foregroundColor(.textSecondary)
                    Text(prediction.message)
                        .font(.bodyMedium)
                        .foregroundColor(.textPrimary)
                }
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

            // Transparency Layer: Show reasoning for AI predictions
            if showDetails && !prediction.reasoning.isEmpty {
                Text(prediction.reasoning)
                    .font(.bodySmall)
                    .foregroundColor(.textSecondary)
                    .padding(.top, Spacing.xs)
            }
        }
        .padding(Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.small)
                .fill(Color.cardBackground)
                .cardShadowSecondary()
        )
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

// MARK: - Log Nap (manual entry) sheet

struct LogNapSheet: View {
    @Binding var startTime: Date
    @Binding var durationMinutes: Int
    var onSave: () -> Void
    var onCancel: () -> Void

    private let durationOptions = [15, 30, 45, 60, 90, 120]

    var body: some View {
        NavigationView {
            Form {
                Section {
                    DatePicker("Start time", selection: $startTime, displayedComponents: [.date, .hourAndMinute])
                } header: {
                    Text("Nap start")
                }

                Section {
                    Picker("Duration", selection: $durationMinutes) {
                        ForEach(durationOptions, id: \.self) { mins in
                            Text(durationString(mins)).tag(mins)
                        }
                    }
                    .pickerStyle(.menu)
                } header: {
                    Text("Duration")
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
                    Button("Save") { onSave() }
                        .fontWeight(.semibold)
                        .foregroundColor(.sageGreen)
                }
            }
            .background(Color.cream)
        }
    }

    private func durationString(_ minutes: Int) -> String {
        if minutes < 60 { return "\(minutes) min" }
        let h = minutes / 60
        let m = minutes % 60
        return m == 0 ? "\(h) hr" : "\(h) hr \(m) min"
    }
}

