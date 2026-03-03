//
//  ServiceProtocols.swift
//  Nurture
//
//  Protocol abstractions for services. Enables mocking and dependency injection.
//  Architectural plan - enterprise scalability.
//

import Foundation
import Combine

// MARK: - Shared Bluetooth Types (protocol-safe, mock-friendly)

enum BluetoothPairingState: Equatable {
    case idle
    case bluetoothOff
    case scanning
    case connecting
    case connected
    case failed(BluetoothPairingError)
}

enum BluetoothPairingError: Error, Equatable, LocalizedError {
    case bluetoothUnavailable
    case scanTimeout
    case noDevicesFound
    case missingPeripheralIdentifier
    case deviceUnavailable
    case connectionTimeout
    case connectionFailed(String?)
    case disconnectedUnexpectedly

    var errorDescription: String? {
        switch self {
        case .bluetoothUnavailable:
            return "Bluetooth is off or unavailable. Please turn on Bluetooth and try again."
        case .scanTimeout:
            return "Could not find your Nurture band. Make sure it is nearby and charged, then try again."
        case .noDevicesFound:
            return "No Nurture bands were found nearby."
        case .missingPeripheralIdentifier:
            return "This device is missing its Bluetooth identifier. Please scan again."
        case .deviceUnavailable:
            return "That device is no longer available. Please scan again."
        case .connectionTimeout:
            return "Connection took too long. Please try pairing again."
        case .connectionFailed(let message):
            return message ?? "Could not connect to the Nurture band. Please try again."
        case .disconnectedUnexpectedly:
            return "Connection to the Nurture band was lost."
        }
    }
}

/// Protocol for Bluetooth/device scanning and connection.
/// Implementations: BluetoothService (real), mock for tests.
///
/// Published-state-driven design:
/// - UI/controllers observe @Published state on the concrete ObservableObject
/// - Methods start async BLE work and do not return immediate results
protocol BluetoothServiceProtocol: ObservableObject where ObjectWillChangePublisher == ObservableObjectPublisher {
    // Core BLE / pairing state
    var isPoweredOn: Bool { get }
    var discoveredDevices: [WearableDevice] { get }
    var connectedDevice: WearableDevice? { get }

    // Pairing UX state (published by implementation)
    var isScanning: Bool { get }
    var isConnecting: Bool { get }
    var pairingError: BluetoothPairingError? { get }
    var pairingState: BluetoothPairingState { get }

    // Actions (async work starts; results arrive via published state)
    func scanForDevices()
    func connectToDevice(_ device: WearableDevice)
    func stopScanning()
    func disconnectCurrentDevice()
}

/// Protocol for notifications (rollover, connection lost).
/// Implementations: NotificationService (real), mock for tests.
protocol NotificationServiceProtocol: AnyObject {
    func requestPermission(completion: @escaping (Bool) -> Void)
    func sendRolloverAlert(childName: String, rolloverTime: Date)
    func sendConnectionLostAlert()
    func sendSleepPrediction(childName: String, predictedTime: Date)
}
