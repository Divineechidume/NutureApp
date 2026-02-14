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
    @StateObject private var onboardingController = OnboardingController()
    @StateObject private var rolloverAlertState = RolloverAlertState()

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                MainTabView(rolloverAlertState: rolloverAlertState)
            } else {
                OnboardingContainerView(hasCompletedOnboarding: $hasCompletedOnboarding, controller: onboardingController)
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
