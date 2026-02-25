//
//  RootView.swift
//  Nurture
//
//  Root container: shows Onboarding or Main tab based on hasCompletedOnboarding. PRD Section 7, 4.
//  Presents full-screen rollover alert when RolloverAlertState.activeRollover is set.
//  Presents in-app sheet via NotificationDetailView when a notification is tapped.
//

import SwiftUI

/// Decides whether to show onboarding flow or main tab view. Demo mode runs full onboarding (Welcome, Permissions, Pair Device, Quick Tour).
/// Holds app-level rollover alert state and presents RolloverAlertView over the main content when active.
/// Observes NotificationService and presents NotificationDetailView when a notification is tapped.
struct RootView: View {
    @Binding var hasCompletedOnboarding: Bool
    @StateObject private var bluetoothService: BluetoothService
    @StateObject private var onboardingController: OnboardingController
    @StateObject private var rolloverAlertState = RolloverAlertState()
    @StateObject private var householdService = HouseholdService()
    @StateObject private var childrenStore = ChildrenStore()

    @EnvironmentObject private var notificationService: NotificationService
    @State private var presentedNotification: NotificationPayload?

    init(hasCompletedOnboarding: Binding<Bool>) {
        self._hasCompletedOnboarding = hasCompletedOnboarding

        let bluetoothService = BluetoothService()
        _bluetoothService = StateObject(wrappedValue: bluetoothService)
        _onboardingController = StateObject(
            wrappedValue: OnboardingController(bluetoothService: bluetoothService)
        )
    }

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                MainTabView(
                    rolloverAlertState: rolloverAlertState,
                    householdService: householdService,
                    childrenStore: childrenStore
                )
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
            let presentation = notificationService.presentation(from: payload)
            NotificationDetailView(
                displayTitle: presentation.displayTitle,
                displayBody: presentation.displayBody,
                timestamp: presentation.timestamp,
                onDismiss: {
                    notificationService.incomingNotification = nil
                    presentedNotification = nil
                }
            )
        }
    }
}
