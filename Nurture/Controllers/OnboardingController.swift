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
    @Published var parentName: String = ""
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
    private let bluetoothService: any BluetoothServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    init(bluetoothService: any BluetoothServiceProtocol) {
        self.bluetoothService = bluetoothService
        bindBluetoothService()
    }

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

    /// Starts device pairing. TODO: Call BluetoothService.scanForDevices() and update isPairing/pairingError.
    /// PRD Reference: Section 1 - Device Pairing & Setup
    func startPairing() {
        pairingError = nil

        guard bluetoothService.isPoweredOn else {
            isPairing = false
            pairingError = BluetoothPairingError.bluetoothUnavailable.errorDescription
            return
        }

        isPairing = true
        bluetoothService.scanForDevices()

        if useDemoMode {
            // Demo: simulate scan ending so UI doesn't stay stuck
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                self?.isPairing = false
            }
        }
    }

    func buildChildProfile() -> Child {
        Child(
            name: childName.isEmpty ? mockChildName : childName,
            birthdate: childBirthdate,
            ageRange: AgeRange.from(birthdate: childBirthdate)
        )
    }

    // MARK: - Private

    private func bindBluetoothService() {
        bluetoothService.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.syncPairingStateFromBluetooth()
            }
            .store(in: &cancellables)

        syncPairingStateFromBluetooth()
    }

    private func syncPairingStateFromBluetooth() {
        if useDemoMode { return }

        isPairing = bluetoothService.isScanning || bluetoothService.isConnecting
        pairingError = bluetoothService.pairingError?.errorDescription

        if bluetoothService.connectedDevice != nil {
            pairingError = nil
            isPairing = false
        }
    }
}
