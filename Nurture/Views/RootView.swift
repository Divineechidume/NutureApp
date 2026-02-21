//
//  RootView.swift
//  Nurture
//
//  Root container: shows Onboarding or Main tab based on hasCompletedOnboarding. PRD Section 7, 4.
//  Presents full-screen rollover alert when RolloverAlertState.activeRollover is set.
//

import SwiftUI

/// Decides whether to show onboarding flow or main tab view. Demo mode runs full onboarding (Welcome, Permissions, Pair Device, Quick Tour).
/// Holds app-level rollover alert state and presents RolloverAlertView over the main content when active.
struct RootView: View {
    @Binding var hasCompletedOnboarding: Bool
    @StateObject private var bluetoothService: BluetoothService
    @StateObject private var onboardingController: OnboardingController
    @StateObject private var rolloverAlertState = RolloverAlertState()
    @StateObject private var householdService = HouseholdService()
    @StateObject private var childrenStore = ChildrenStore()

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
    }
}
