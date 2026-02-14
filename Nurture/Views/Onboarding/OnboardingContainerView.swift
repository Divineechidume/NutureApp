//
//  OnboardingContainerView.swift
//  Nurture
//
//  Container that steps through onboarding screens and sets hasCompletedOnboarding. PRD Section 7.
//

import SwiftUI

/// Steps through Welcome → Permissions → Pair Device → Quick Tour; sets hasCompletedOnboarding at end.
struct OnboardingContainerView: View {
    @Binding var hasCompletedOnboarding: Bool
    @ObservedObject var controller: OnboardingController

    var body: some View {
        Group {
            switch controller.currentStep {
            case .welcome:
                WelcomeView(onContinue: { controller.advance() })
            case .permissions:
                PermissionsView(onContinue: { controller.advance() })
            case .pairDevice:
                PairDeviceView(
                    controller: controller,
                    onContinue: { controller.completeOnboarding(); controller.advance() }
                )
            case .quickTour:
                QuickTourView(
                    onStart: {
                        let child = controller.buildChildProfile()
                        ChildProfileStore.save(child)
                        hasCompletedOnboarding = true
                    },
                    onSkip: {
                        controller.skipTour()
                        let child = controller.buildChildProfile()
                        ChildProfileStore.save(child)
                        hasCompletedOnboarding = true
                    }
                )
            }
        }
    }
}
