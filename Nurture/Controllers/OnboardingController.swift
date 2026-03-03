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
/// Exposes "complete onboarding" and "skip tour". Coordinates BluetoothService for Pair Device step.
final class OnboardingController: ObservableObject {
    // MARK: - Published State

    @Published var currentStep: OnboardingStep = .welcome
    @Published var childName: String = ""
    @Published var childBirthdate: Date = Calendar.current.date(byAdding: .month, value: -8, to: Date()) ?? Date()
    @Published var parentName: String = ""
    @Published var isPairing: Bool = false
    @Published var pairingError: String?
    /// Discovered BLE devices; kept in sync with BluetoothService for UI binding.
    @Published var discoveredDevices: [WearableDevice] = []

    enum OnboardingStep: Int, CaseIterable {
        case welcome = 0
        case permissions
        case pairDevice
        case quickTour
    }

    // MARK: - Dependencies

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

    /// Starts BLE scan for Nurture wearables. PRD Section 1 - Device Pairing & Setup.
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

    /// Connects to the selected wearable. Results arrive via syncPairingStateFromBluetooth (connectedDevice / pairingError).
    func connect(to device: WearableDevice) {
        bluetoothService.connectToDevice(device)
    }

    /// Stops BLE scan so the discovered device list is stable.
    func stopScanning() {
        bluetoothService.stopScanning()
    }

    /// Current connected device, if any. For transitioning to success state in PairDeviceView.
    var connectedDevice: WearableDevice? { bluetoothService.connectedDevice }

    /// True while connection to a selected device is in progress.
    var isConnecting: Bool { bluetoothService.isConnecting }

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
        discoveredDevices = bluetoothService.discoveredDevices

        if useDemoMode { return }

        isPairing = bluetoothService.isScanning || bluetoothService.isConnecting
        pairingError = bluetoothService.pairingError?.errorDescription

        if bluetoothService.connectedDevice != nil {
            pairingError = nil
            isPairing = false
        }
    }
}
