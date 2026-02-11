//
//  RootView.swift
//  Nurture
//
//  Root container: shows Onboarding or Main tab based on hasCompletedOnboarding. PRD Section 7, 4.
//

import SwiftUI

/// Decides whether to show onboarding flow or main tab view. In demo mode, can auto-complete onboarding.
struct RootView: View {
    @Binding var hasCompletedOnboarding: Bool
    @StateObject private var onboardingController = OnboardingController()

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                MainTabView()
            } else {
                OnboardingContainerView(hasCompletedOnboarding: $hasCompletedOnboarding, controller: onboardingController)
            }
        }
        .onAppear {
            if useDemoMode {
                // Option A: Land on Home with mock data without going through onboarding
                hasCompletedOnboarding = true
            }
        }
    }
}
