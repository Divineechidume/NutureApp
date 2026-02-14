//
//  SyncCoordinator.swift
//  Nurture
//
//  Prevents BLE conflicts when multiple phones could connect to same band.
//  Only one device actively syncs per band at a time. Architectural plan.
//

import Foundation
import Combine

/// Coordinates which device syncs with which band. Prevents multiple phones connecting to same band.
final class SyncCoordinator: ObservableObject {
    /// Band IDs currently claimed for sync by this device.
    @Published private(set) var claimedBandIDs: Set<UUID> = []

    /// Claim exclusive sync rights for a band. Returns true if claimed.
    func claimBandSync(bandID: UUID, memberID: UUID) -> Bool {
        // Phase 1: local only - no coordination with other devices
        claimedBandIDs.insert(bandID)
        return true
    }

    /// Release sync claim when out of Bluetooth range or user switches away.
    func releaseBandSync(bandID: UUID) {
        claimedBandIDs.remove(bandID)
    }

    /// Whether this device should actively sync with the given band.
    func shouldSync(bandID: UUID) -> Bool {
        claimedBandIDs.contains(bandID)
    }
}
