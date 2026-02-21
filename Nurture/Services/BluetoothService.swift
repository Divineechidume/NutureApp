//
//  BluetoothService.swift
//  Nurture
//
//  Handles all Bluetooth communication with the Nurture ankle wearable.
//  PRD: Device Pairing (§1), Safety Alerts (§4), Sleep Tracking (§2).
//

import Foundation
import Combine
import CoreBluetooth

/// Handles BLE communication: pairing, real-time data, connection monitoring.
/// Integration point: Controllers consume device list, connection state, and sleep/rollover signals.
final class BluetoothService: NSObject, ObservableObject, BluetoothServiceProtocol {
    // MARK: - Published State (Protocol + UI/Controller Observability)

    @Published var isPoweredOn = false
    @Published var connectedDevice: WearableDevice?
    @Published var discoveredDevices: [WearableDevice] = []

    /// Published pairing state for onboarding / settings screens
    @Published var isScanning = false
    @Published var isConnecting = false
    @Published var pairingError: BluetoothPairingError?
    @Published var pairingState: BluetoothPairingState = .idle

    // TODO: Set up Bluetooth Central Manager
    // Purpose: Scan, connect, and maintain connection to wearable
    // PRD Reference: Section 1 (Pairing), Section 2 (real-time sync), Section 4 (rollover alerts)
    // Implementation notes:
    // - Create CBCentralManager in init with delegate queue
    // - Implement CBCentralManagerDelegate (state, discover, connect, disconnect)
    // - Implement CBPeripheralDelegate for characteristics
    // Dependencies: CoreBluetooth framework
    // Estimated complexity: High

    // TODO: Implement BLE characteristic read for sleep state — blocks Home current status
    private var centralManager: CBCentralManager?

    /// CoreBluetooth peripherals are kept private to the service.
    /// The app/UI deals only with NurtureBand / WearableDevice.
    private var peripheralsByIdentifier: [UUID: CBPeripheral] = [:]

    /// Track which device is currently being connected
    private var pendingConnectPeripheralIdentifier: UUID?

    /// Pairing timers (owned by BLE service, not controller)
    private var scanTimeoutWorkItem: DispatchWorkItem?
    private var connectTimeoutWorkItem: DispatchWorkItem?

    // TODO: Replace with your final Nurture service/characteristic UUIDs once firmware is updated.
    // Current Arduino prototype is advertising:
    // - Service: "1101"
    // - Angle characteristic: "2101"
    private let nurtureServiceUUID = CBUUID(string: "1101")
    private let angleCharacteristicUUID = CBUUID(string: "2101")

    // Future placeholders (safe to keep even if firmware doesn't expose them yet)
    private let sleepStateCharacteristicUUID = CBUUID(string: "2201")
    private let rolloverCharacteristicUUID = CBUUID(string: "2301")

    private let scanTimeoutSeconds: TimeInterval = 10
    private let connectTimeoutSeconds: TimeInterval = 8

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: .main)
    }

    deinit {
        invalidateScanTimeout()
        invalidateConnectTimeout()
    }

    // MARK: - Device Pairing (PRD Section 1)

    /// Scan for Nurture wearables in range. Show list if multiple. PRD Section 1 edge cases.
    func scanForDevices() {
        guard let centralManager else {
            setPairingFailure(.bluetoothUnavailable)
            print("Bluetooth not available")
            return
        }

        guard centralManager.state == .poweredOn else {
            setPairingFailure(.bluetoothUnavailable)
            print("Bluetooth not powered on")
            return
        }

        pairingError = nil
        pairingState = .scanning
        isScanning = true
        isConnecting = false
        discoveredDevices.removeAll()
        peripheralsByIdentifier.removeAll()
        pendingConnectPeripheralIdentifier = nil
        connectedDevice = nil

        centralManager.scanForPeripherals(
            withServices: [nurtureServiceUUID],
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        )
        
        print("Scanning for devices...")

        scheduleScanTimeout()
    }

    /// Connect to selected device. Handle timeout and "already paired elsewhere". PRD Section 1.
    func connectToDevice(_ device: WearableDevice) {
        guard let centralManager else {
            setPairingFailure(.bluetoothUnavailable)
            return
        }

        guard centralManager.state == .poweredOn else {
            setPairingFailure(.bluetoothUnavailable)
            return
        }

        guard let peripheralIdentifier = device.peripheralIdentifier else {
            setPairingFailure(.missingPeripheralIdentifier)
            return
        }

        guard let peripheral = peripheralsByIdentifier[peripheralIdentifier] else {
            setPairingFailure(.deviceUnavailable)
            return
        }

        if isScanning {
            centralManager.stopScan()
            isScanning = false
            invalidateScanTimeout()
        }

        pairingError = nil
        pairingState = .connecting
        isConnecting = true
        pendingConnectPeripheralIdentifier = peripheralIdentifier

        peripheral.delegate = self
        centralManager.connect(peripheral, options: nil)

        scheduleConnectTimeout()
    }

    func stopScanning() {
        guard let centralManager else { return }
        centralManager.stopScan()
        isScanning = false
        invalidateScanTimeout()

        if discoveredDevices.isEmpty {
            setPairingFailure(.noDevicesFound)
        } else if pairingState == .scanning {
            pairingState = .idle
        }
    }

    func disconnectCurrentDevice() {
        guard
            let centralManager,
            let connected = connectedDevice,
            let peripheralID = connected.peripheralIdentifier,
            let peripheral = peripheralsByIdentifier[peripheralID]
        else { return }

        centralManager.cancelPeripheralConnection(peripheral)
    }

    // MARK: - Real-Time Data (PRD Section 2, 4)

    // TODO: Implement real-time data streaming
    // Purpose: Sleep/wake state and rollover events for Home and Alerts
    // PRD Reference: Section 2 (sync), Section 4 (rollover signal)
    // Implementation notes:
    // - Subscribe to accelerometer (or processed) characteristic
    // - Parse sleep vs wake; parse rollover event
    // - Notify NotificationService on rollover; update state for HomeController
    // Dependencies: NotificationService, SleepDetectionService (optional)
    // Estimated complexity: High

    // MARK: - Connection Monitoring (PRD Section 4)

    // TODO: Implement connection monitoring
    // Purpose: Alert user if connection lost. PRD Section 4 edge cases.
    // Implementation notes:
    // - centralManager(_:didDisconnectPeripheral:error:)
    // - Trigger "Connection lost with Nurture device" via NotificationService
    // Dependencies: NotificationService
    // Estimated complexity: Medium

    // MARK: - Timeout Management

    private func scheduleScanTimeout() {
        invalidateScanTimeout()

        let work = DispatchWorkItem { [weak self] in
            guard let self, let centralManager = self.centralManager else { return }
            guard self.isScanning else { return }

            centralManager.stopScan()
            self.isScanning = false

            if self.discoveredDevices.isEmpty {
                self.setPairingFailure(.scanTimeout)
            } else {
                self.pairingState = .idle
            }
        }

        scanTimeoutWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + scanTimeoutSeconds, execute: work)
    }

    private func invalidateScanTimeout() {
        scanTimeoutWorkItem?.cancel()
        scanTimeoutWorkItem = nil
    }

    private func scheduleConnectTimeout() {
        invalidateConnectTimeout()

        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            guard self.isConnecting else { return }

            self.isConnecting = false

            if let centralManager = self.centralManager,
               let pendingID = self.pendingConnectPeripheralIdentifier,
               let peripheral = self.peripheralsByIdentifier[pendingID] {
                centralManager.cancelPeripheralConnection(peripheral)
            }

            self.pendingConnectPeripheralIdentifier = nil
            self.setPairingFailure(.connectionTimeout)
        }

        connectTimeoutWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + connectTimeoutSeconds, execute: work)
    }

    private func invalidateConnectTimeout() {
        connectTimeoutWorkItem?.cancel()
        connectTimeoutWorkItem = nil
    }

    // MARK: - Helpers

    private func setPairingFailure(_ error: BluetoothPairingError) {
        pairingError = error
        pairingState = .failed(error)
        isScanning = false
        isConnecting = false
        invalidateScanTimeout()
        invalidateConnectTimeout()
    }

    private func upsertDiscoveredBand(from peripheral: CBPeripheral, rssi: NSNumber?) {
        let peripheralID = peripheral.identifier
        peripheralsByIdentifier[peripheralID] = peripheral

        let displayName = (peripheral.name?.isEmpty == false) ? peripheral.name! : "Nurture Band"
        print("Discovered band: \(displayName)")

        if let idx = discoveredDevices.firstIndex(where: { $0.peripheralIdentifier == peripheralID }) {
            discoveredDevices[idx].name = displayName
            discoveredDevices[idx].peripheralIdentifier = peripheralID
        } else {
            var band = WearableDevice(name: displayName)
            band.peripheralIdentifier = peripheralID
            band.isConnected = false
            discoveredDevices.append(band)
        }
    }

    private func markBandConnected(peripheralIdentifier: UUID, isConnected: Bool) {
        if let idx = discoveredDevices.firstIndex(where: { $0.peripheralIdentifier == peripheralIdentifier }) {
            discoveredDevices[idx].isConnected = isConnected

            if isConnected {
                connectedDevice = discoveredDevices[idx]
            } else if connectedDevice?.peripheralIdentifier == peripheralIdentifier {
                connectedDevice = nil
            }
        } else if connectedDevice?.peripheralIdentifier == peripheralIdentifier, !isConnected {
            connectedDevice = nil
        }
    }
}

// MARK: - CBCentralManagerDelegate (stub for scaffolding)

extension BluetoothService: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        isPoweredOn = central.state == .poweredOn
        
        print("centralManagerDidUpdateState: \(central.state)")

        switch central.state {
        case .poweredOn:
            if pairingState == .bluetoothOff {
                pairingState = .idle
            }

        case .poweredOff, .unauthorized, .unsupported, .resetting, .unknown:
            isScanning = false
            isConnecting = false
            invalidateScanTimeout()
            invalidateConnectTimeout()
            connectedDevice = nil
            pairingState = .bluetoothOff
            pairingError = .bluetoothUnavailable

        @unknown default:
            pairingState = .bluetoothOff
            pairingError = .bluetoothUnavailable
        }
    }

    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String : Any],
        rssi RSSI: NSNumber
    ) {
        print("centralManager:didDiscover: \(peripheral.name ?? "Unknown")")
        upsertDiscoveredBand(from: peripheral, rssi: RSSI)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        invalidateConnectTimeout()
        isConnecting = false
        pendingConnectPeripheralIdentifier = nil

        let peripheralID = peripheral.identifier
        markBandConnected(peripheralIdentifier: peripheralID, isConnected: true)

        pairingError = nil
        pairingState = .connected

        peripheral.delegate = self
        peripheral.discoverServices([nurtureServiceUUID])
    }

    func centralManager(
        _ central: CBCentralManager,
        didFailToConnect peripheral: CBPeripheral,
        error: Error?
    ) {
        invalidateConnectTimeout()
        isConnecting = false
        pendingConnectPeripheralIdentifier = nil
        markBandConnected(peripheralIdentifier: peripheral.identifier, isConnected: false)

        setPairingFailure(.connectionFailed(error?.localizedDescription))
    }

    func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error: Error?
    ) {
        let wasConnecting = isConnecting
        invalidateConnectTimeout()
        isConnecting = false
        pendingConnectPeripheralIdentifier = nil
        markBandConnected(peripheralIdentifier: peripheral.identifier, isConnected: false)

        if wasConnecting {
            setPairingFailure(.connectionFailed(error?.localizedDescription))
            return
        }

        if error != nil {
            pairingError = .disconnectedUnexpectedly
            pairingState = .failed(.disconnectedUnexpectedly)
        } else if pairingState == .connected {
            pairingState = .idle
        }
    }
}

// MARK: - CBPeripheralDelegate (scaffold for characteristics)

extension BluetoothService: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error {
            pairingError = .connectionFailed("Failed to discover services: \(error.localizedDescription)")
            return
        }

        guard let services = peripheral.services else { return }

        for service in services where service.uuid == nurtureServiceUUID {
            // Request all current + future characteristics we care about.
            // It's safe if some are not present on the Arduino yet.
            peripheral.discoverCharacteristics(
                [angleCharacteristicUUID, sleepStateCharacteristicUUID, rolloverCharacteristicUUID],
                for: service
            )
        }
    }

    func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverCharacteristicsFor service: CBService,
        error: Error?
    ) {
        if let error {
            pairingError = .connectionFailed("Failed to discover characteristics: \(error.localizedDescription)")
            return
        }

        guard let characteristics = service.characteristics else { return }

        for characteristic in characteristics {
            if characteristic.uuid == angleCharacteristicUUID ||
                characteristic.uuid == sleepStateCharacteristicUUID ||
                characteristic.uuid == rolloverCharacteristicUUID {

                if characteristic.properties.contains(.notify) {
                    peripheral.setNotifyValue(true, for: characteristic)
                }

                if characteristic.properties.contains(.read) {
                    peripheral.readValue(for: characteristic)
                }
            }
        }
    }

    func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateValueFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        if let error {
            print("BLE value update error: \(error.localizedDescription)")
            return
        }

        guard let value = characteristic.value else { return }

        if characteristic.uuid == angleCharacteristicUUID {
            // Arduino sends BLEUnsignedCharCharacteristic ("2101") for angle.
            guard let angleByte = value.first else { return }
            let angle = Int(angleByte)

            // TODO: Route to a published sensor/debug state or a processing service.
            print("Angle: \(angle)°")

            // Example future behavior:
            // if angle > 140 { rollover detected candidate }
            return
        }

        if characteristic.uuid == sleepStateCharacteristicUUID {
            // TODO: Parse sleep state payload when firmware adds this characteristic
            print("Received sleep state payload (\(value.count) bytes)")
            return
        }

        if characteristic.uuid == rolloverCharacteristicUUID {
            // TODO: Parse rollover event payload when firmware adds this characteristic
            print("Received rollover payload (\(value.count) bytes)")
            return
        }

        print("Received \(value.count) bytes from characteristic \(characteristic.uuid.uuidString)")
    }
}
