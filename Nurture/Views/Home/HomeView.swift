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

    /// Whether a device is paired. In demo mode always true; otherwise from BluetoothService.
    private var hasDevice: Bool {
        // TODO: Wire to BluetoothService / pairing state
        true
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
                        if childrenStore.children.count > 1 {
                            childSelector
                        }
                        SleepStatusCard(
                            isAsleep: controller.isAsleep,
                            duration: controller.isAsleep ? "Sleeping for \(controller.durationString)" : "Awake for \(controller.durationString)",
                            startTime: controller.sleepStartTimeString
                        )
                        secondaryCards(isAsleep: controller.isAsleep)
                    }
                    .padding(Spacing.lg)
                }
            } else {
                NoDevicePairedView(onPairTapped: { /* Navigate to pairing */ })
            }
        }
    }

    private func secondaryCards(isAsleep: Bool) -> some View {
        VStack(spacing: Spacing.sm) {
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
                InfoCard(
                    icon: "lightbulb.fill",
                    iconColor: Color(hex: "EAB308"),
                    title: "Next Nap",
                    value: nap.message
                )
            }
        }
        .padding(.horizontal, Spacing.md)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isAsleep)
    }

    private var childSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                ForEach(childrenStore.children) { child in
                    Button {
                        childrenStore.selectChild(child.id)
                    } label: {
                        HStack(spacing: Spacing.xs) {
                            Text(child.name)
                                .font(.labelMedium)
                                .foregroundColor(childrenStore.selectedChildID == child.id ? .white : .textPrimary)
                        }
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.xs)
                        .background(
                            RoundedRectangle(cornerRadius: CornerRadius.small)
                                .fill(childrenStore.selectedChildID == child.id ? Color.sageGreen : Color.white.opacity(0.9))
                                .cardShadowSecondary()
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Spacing.md)
        }
        .padding(.bottom, Spacing.xs)
    }
}

// MARK: - Sleep Status Card

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
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.large)
                .fill(isAsleep ? Color.sleepBackground : Color.cardBackground)
                .cardShadowPrimary()
        )
        .padding(.horizontal, Spacing.md)
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
        HStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(iconColor)
                .frame(width: 48, height: 48)
                .background(Circle().fill(iconColor.opacity(0.15)))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.bodySmall)
                    .foregroundColor(.textSecondary)
                Text(value)
                    .font(.headingSmall)
                    .foregroundColor(.textPrimary)
            }

            Spacer()
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.medium)
                .fill(Color.cardBackground)
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
