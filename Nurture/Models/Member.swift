//
//  Member.swift
//  Nurture
//
//  Represents a household member (parent, caregiver). Architectural plan - household-centric model.
//  Can belong to multiple households for co-parenting scenarios.
//

import Foundation

/// Role of a household member.
enum MemberRole: String, Codable, CaseIterable {
    case primary
    case secondary
    case caregiver
}

/// Represents a household member (parent or caregiver).
/// Can belong to multiple households (co-parenting).
struct Member: Identifiable, Codable {
    var id: UUID
    var name: String
    var email: String
    var role: MemberRole
    var householdIDs: [UUID]
    var notificationPreferences: NotificationPreferences

    init(
        id: UUID = UUID(),
        name: String,
        email: String = "",
        role: MemberRole = .primary,
        householdIDs: [UUID] = [],
        notificationPreferences: NotificationPreferences = NotificationPreferences()
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.role = role
        self.householdIDs = householdIDs
        self.notificationPreferences = notificationPreferences
    }
}
