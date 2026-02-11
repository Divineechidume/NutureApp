//
//  OnboardingController.swift
//  Nurture
//
//  Manages onboarding flow state. PRD Section 7 (Onboarding Flow).
//  Coordinates steps: Welcome → Permissions → Pair Device → Quick Tour (skippable).
//

import Foundation
import Combine

/// Manages current onboarding step, child profile draft, and pairing state.
/// Exposes "complete onboarding" and "skip tour". Receives BluetoothService for Pair Device step (TODO).
final class OnboardingController: ObservableObject {
    // MARK: - Published State

    @Published var currentStep: OnboardingStep = .welcome
    @Published var childName: String = ""
    @Published var childBirthdate: Date = Calendar.current.date(byAdding: .month, value: -8, to: Date()) ?? Date()
    @Published var childAgeRange: AgeRange = .sixToTwelveMonths
    @Published var isPairing: Bool = false
    @Published var pairingError: String?

    enum OnboardingStep: Int, CaseIterable {
        case welcome = 0
        case permissions
        case pairDevice
        case quickTour
    }

    // MARK: - Dependencies

    // TODO: Inject BluetoothService for Pair Device step
    // Purpose: Scan and connect to wearable during onboarding
    // PRD Reference: Section 1 - Device Pairing & Setup
    // Dependencies: BluetoothService must be implemented
    // Estimated complexity: Medium

    init() {}

    // MARK: - Actions

    func advance() {
        guard let next = OnboardingStep(rawValue: currentStep.rawValue + 1) else { return }
        currentStep = next
    }

    func completeOnboarding() {
        // Analytics: track event "onboarding_completed"
        currentStep = .quickTour
    }

    func skipTour() {
        // Analytics: track event "onboarding_tour_skipped"
    }

    func buildChildProfile() -> Child {
        Child(
            name: childName.isEmpty ? mockChildName : childName,
            birthdate: childBirthdate,
            ageRange: childAgeRange
        )
    }
}
