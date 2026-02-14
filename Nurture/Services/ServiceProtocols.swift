//
//  ServiceProtocols.swift
//  Nurture
//
//  Protocol abstractions for services. Enables mocking and dependency injection.
//  Architectural plan - enterprise scalability.
//

import Foundation
import Combine

/// Protocol for Bluetooth/device scanning and connection.
/// Implementations: BluetoothService (real), mock for tests.
protocol BluetoothServiceProtocol: ObservableObject {
    var isPoweredOn: Bool { get }
    var connectedDevice: WearableDevice? { get }
    var discoveredDevices: [WearableDevice] { get }
    func scanForDevices() -> [WearableDevice]
    func connectToDevice(_ device: WearableDevice) -> Bool
}

/// Protocol for notifications (rollover, connection lost).
/// Implementations: NotificationService (real), mock for tests.
protocol NotificationServiceProtocol: AnyObject {
    func requestPermission(completion: @escaping (Bool) -> Void)
    func sendRolloverAlert(childName: String, rolloverTime: Date)
    func sendConnectionLostAlert()
}
