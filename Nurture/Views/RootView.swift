//
//  RootView.swift
//  Nurture
//
//  Root container: shows Onboarding or Main tab view based on hasCompletedOnboarding. PRD Section 7, 4.
//  Presents full-screen rollover alert when RolloverAlertState.activeRollover is set.
//

import SwiftUI

/// Root container: shows Onboarding or MainTabView based on onboarding state; presents rollover alert and notification detail sheet.
struct RootView: View {
    @Binding var hasCompletedOnboarding: Bool
    @StateObject private var onboardingController = OnboardingController()
    @StateObject private var rolloverAlertState = RolloverAlertState()
    @StateObject private var householdService = HouseholdService()
    @StateObject private var childrenStore = ChildrenStore()
    private let notificationService = NotificationService.shared
    @State private var presentedNotification: NotificationPayload?

    var body: some View {
        // Keep presentedNotification in sync with the service's incomingNotification
        // so SwiftUI sheet can bind to a local @State Binding.
        Group {
            if hasCompletedOnboarding {
                MainTabView(
                    rolloverAlertState: rolloverAlertState,
                    householdService: householdService,
                    childrenStore: childrenStore
                )
                .environmentObject(notificationService)
            } else {
                OnboardingContainerView(
                    hasCompletedOnboarding: $hasCompletedOnboarding,
                    controller: onboardingController,
                    householdService: householdService
                )
            }
        }
        .overlay {
            if let rollover = rolloverAlertState.activeRollover {
                RolloverAlertView(
                    childName: rollover.childName,
                    rolloverTime: rollover.time,
                    onDismiss: { rolloverAlertState.dismiss() }
                )
            }
        }
        .onAppear { presentedNotification = notificationService.incomingNotification }
        .onReceive(notificationService.$incomingNotification) { new in presentedNotification = new }
        .sheet(item: $presentedNotification) { payload in
            // Use the NotificationService instance to build the presentation model
            let presentation = notificationService.presentation(from: payload)
            NavigationView {
                VStack(alignment: .center, spacing: Spacing.md) {
                    Text(presentation.displayTitle)
                        .font(.displayMedium)
                        .foregroundColor(.textPrimary)
                        .multilineTextAlignment(.center)
                        .padding(.top, Spacing.lg)

                    Text(relativeTimeLabel(for: presentation.timestamp))
                        .font(.labelSmall)
                        .foregroundColor(.textSecondary)

                    Text(presentation.displayBody)
                        .font(.bodyMedium)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.md)

                    Spacer()

                    Button(action: { notificationService.incomingNotification = nil; presentedNotification = nil }) {
                        Text("Done")
                            .font(.labelLarge)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.sm)
                            .background(RoundedRectangle(cornerRadius: CornerRadius.small).fill(Color.sageGreen))
                            .padding(.horizontal, Spacing.md)
                    }
                    .buttonStyle(.plain)
                    .padding(.bottom, Spacing.xl)
                }
                .background(Color.cream.ignoresSafeArea())
                .navigationTitle("Notification")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
}

// Helper: relative time label used by the sheet
private func relativeTimeLabel(for date: Date?) -> String {
    guard let date = date else { return "" }
    let delta = Int(Date().timeIntervalSince(date))
    if delta < 60 { return "Just now" }
    if delta < 3600 { return "\(delta / 60)m ago" }
    if delta < 86400 { return "\(delta / 3600)h ago" }
    // Use DateDisplayStyle for days and beyond
    return date.formatted(as: .dateLabel)
}
