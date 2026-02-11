//
//  WearableDevice.swift
//  Nurture
//
//  Represents the Nurture ankle wearable. PRD Section 1 (Pairing), Section 6 (Device Management).
//  Data from BluetoothService (connection, battery, firmware).
//

import Foundation

/// Represents a Nurture ankle wearable device.
/// Source: BluetoothService (scan, connect, battery, firmware). Used in Settings and pairing flow.
struct WearableDevice: Identifiable {
    /// App-level unique id.
    var id: UUID
    /// Display name (e.g. "Nurture Ankle").
    var name: String
    /// BLE peripheral identifier for reconnection. From CoreBluetooth.
    var peripheralIdentifier: UUID?
    /// 0–100 when available. From device characteristic.
    var batteryLevel: Int?
    /// Firmware version string from device. From device characteristic.
    var firmwareVersion: String?
    /// Whether currently connected. From BluetoothService connection state.
    var isConnected: Bool

    init(
        id: UUID = UUID(),
        name: String,
        peripheralIdentifier: UUID? = nil,
        batteryLevel: Int? = nil,
        firmwareVersion: String? = nil,
        isConnected: Bool = false
    ) {
        self.id = id
        self.name = name
        self.peripheralIdentifier = peripheralIdentifier
        self.batteryLevel = batteryLevel
        self.firmwareVersion = firmwareVersion
        self.isConnected = isConnected
    }
}
