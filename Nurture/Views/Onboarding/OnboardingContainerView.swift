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
    @ObservedObject var householdService: HouseholdService

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
                        createHouseholdIfNeeded(parentName: controller.parentName)
                        hasCompletedOnboarding = true
                    },
                    onSkip: {
                        controller.skipTour()
                        let child = controller.buildChildProfile()
                        ChildProfileStore.save(child)
                        createHouseholdIfNeeded(parentName: controller.parentName)
                        hasCompletedOnboarding = true
                    }
                )
            }
        }
    }

    private func createHouseholdIfNeeded(parentName: String) {
        guard householdService.currentHousehold == nil else { return }
        let name = parentName.trimmingCharacters(in: .whitespacesAndNewlines)
        let memberName = name.isEmpty ? "Primary Caregiver" : name
        let member = Member(name: memberName, email: "", role: .primary)
        let householdName = Self.householdNameFromParentName(name)
        _ = householdService.createHousehold(name: householdName, primaryMember: member)
    }

    /// Derives "The [LastName]s" from parent name. "John Smith" → "The Smiths". "Sarah Jones" → "The Jones".
    private static func householdNameFromParentName(_ name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "My Family" }
        let parts = trimmed.split(separator: " ", omittingEmptySubsequences: true).map(String.init)
        let lastName = parts.count > 1 ? parts.last! : parts[0]
        let base = lastName.prefix(1).uppercased() + lastName.dropFirst().lowercased()
        let suffix = base.lowercased().hasSuffix("s") ? "" : "s"
        return "The \(base)\(suffix)"
    }
}
