//
//  Household.swift
//  Nurture
//
//  Central entity for family unit. Architectural plan - household-centric model.
//  Owns bands and children; has members. One household per family (or per co-parent unit).
//

import Foundation

/// Represents a household (family unit).
/// Central entity for permissions and data access.
struct Household: Identifiable, Codable {
    var id: UUID
    var name: String
    var createdAt: Date
    var memberIDs: [UUID]
    var bandIDs: [UUID]

    init(
        id: UUID = UUID(),
        name: String,
        createdAt: Date = Date(),
        memberIDs: [UUID] = [],
        bandIDs: [UUID] = []
    ) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.memberIDs = memberIDs
        self.bandIDs = bandIDs
    }
}
