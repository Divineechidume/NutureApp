//
//  SettingsController.swift
//  Nurture
//
//  Child profile, device info, notification toggles. PRD Section 6 - Settings & Account.
//  Demo: mock child and device. TODO: BluetoothService (battery, unpair), persistence.
//

import Foundation
import Combine

/// Manages settings screen state: profile, device, notification toggles.
final class SettingsController: ObservableObject {
    @Published var child: Child?
    @Published var device: WearableDevice?
    @Published var rolloverAlertsEnabled: Bool = true
    @Published var napPredictionsEnabled: Bool = true

    // TODO: Inject BluetoothService for battery level and unpair
    // PRD Reference: Section 6 - Device Management
    // Estimated complexity: Low

    init() {
        if let savedChild = ChildProfileStore.load() {
            child = savedChild
        } else if useDemoMode {
            let birthdate = Calendar.current.date(byAdding: .month, value: -8, to: Date()) ?? Date()
            child = Child(name: mockChildName, birthdate: birthdate, ageRange: AgeRange.from(birthdate: birthdate))
        }
        if useDemoMode {
            device = WearableDevice(name: "Nurture Ankle", batteryLevel: 85, firmwareVersion: "1.0.0", isConnected: true)
        }
    }
}
