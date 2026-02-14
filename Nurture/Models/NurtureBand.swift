//
//  NurtureBand.swift
//  Nurture
//
//  Nurture ankle wearable. Architectural plan - renamed from WearableDevice.
//  One band per child; can be shared across households (co-parenting).
//

import Foundation

/// Represents a Nurture ankle wearable.
/// One band per child; can be in multiple households for co-parenting.
struct NurtureBand: Identifiable, Codable {
    var id: UUID
    var name: String
    var serialNumber: String?
    var peripheralIdentifier: UUID?
    var childID: UUID?
    var householdIDs: [UUID]
    var batteryLevel: Int?
    var firmwareVersion: String?
    var lastSyncedAt: Date?
    var isConnected: Bool

    init(
        id: UUID = UUID(),
        name: String,
        serialNumber: String? = nil,
        peripheralIdentifier: UUID? = nil,
        childID: UUID? = nil,
        householdIDs: [UUID] = [],
        batteryLevel: Int? = nil,
        firmwareVersion: String? = nil,
        lastSyncedAt: Date? = nil,
        isConnected: Bool = false
    ) {
        self.id = id
        self.name = name
        self.serialNumber = serialNumber
        self.peripheralIdentifier = peripheralIdentifier
        self.childID = childID
        self.householdIDs = householdIDs
        self.batteryLevel = batteryLevel
        self.firmwareVersion = firmwareVersion
        self.lastSyncedAt = lastSyncedAt
        self.isConnected = isConnected
    }
}

/// Backward compatibility: WearableDevice is an alias for NurtureBand.
typealias WearableDevice = NurtureBand
