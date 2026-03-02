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
    @StateObject private var bluetoothService: BluetoothService
    @StateObject private var onboardingController: OnboardingController
    @StateObject private var rolloverAlertState = RolloverAlertState()
    @StateObject private var householdService = HouseholdService()
    @StateObject private var childrenStore = ChildrenStore()
    private let notificationService = NotificationService.shared
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
        // Keep presentedNotification in sync with the service's incomingNotification
        // so SwiftUI sheet can bind to a local @State Binding.
        Group {
            if hasCompletedOnboarding {
                MainTabView(
                    bluetoothService: bluetoothService,
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
