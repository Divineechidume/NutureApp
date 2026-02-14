//
//  HouseholdService.swift
//  Nurture
//
//  Manages household membership and invitations. Architectural plan - household-centric.
//  Phase 1: local invitation codes (no backend). Future: cloud sync, co-parenting.
//

import Foundation
import Combine

/// Manages household creation, membership, and invitations.
final class HouseholdService: ObservableObject {
    // MARK: - Published State

    @Published var currentHousehold: Household?
    @Published var currentMember: Member?

    // MARK: - Actions

    /// Create a new household (during onboarding). Primary member becomes first member.
    func createHousehold(name: String, primaryMember: Member) -> Household {
        let household = Household(
            name: name,
            memberIDs: [primaryMember.id],
            bandIDs: []
        )
        var member = primaryMember
        member.householdIDs.append(household.id)
        currentHousehold = household
        currentMember = member
        return household
    }

    /// Generate a 6-digit invitation code for this household. Local only (no backend).
    func generateInvitationCode() -> String {
        String(format: "%06d", Int.random(in: 0...999999))
    }

    /// Join a household using an invitation code. Phase 1: stub (would validate code, add member).
    /// TODO: Store invitation codes; validate and add member to household.
    func joinHousehold(invitationCode: String, member: Member) -> Bool {
        // Stub for Phase 1 - no backend to validate codes
        return false
    }

    /// Remove a member from the household. Requires primary member permission.
    func removeMember(memberID: UUID, from household: Household) -> Bool {
        guard currentMember?.role == .primary else { return false }
        var h = household
        h.memberIDs.removeAll { $0 == memberID }
        currentHousehold = h
        return true
    }
}
