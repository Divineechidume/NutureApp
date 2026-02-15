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

    init() {
        currentHousehold = HouseholdStore.loadHousehold()
        currentMember = HouseholdStore.loadMember()
    }

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
        HouseholdStore.save(household: household, member: member)
        return household
    }

    /// Generate a 6-digit invitation code for this household. Local only (no backend).
    func generateInvitationCode() -> String {
        String(format: "%06d", Int.random(in: 0...999999))
    }

    /// Store invitation code for this household.
    func storeInvitationCode(_ code: String) {
        guard let household = currentHousehold else { return }
        HouseholdStore.saveInvitationCode(code, householdID: household.id)
    }

    /// Get existing invitation code or create a new one.
    func getOrCreateInvitationCode() -> String {
        guard let household = currentHousehold else { return generateInvitationCode() }
        if let existing = HouseholdStore.loadInvitationCode(householdID: household.id) {
            return existing
        }
        let code = generateInvitationCode()
        storeInvitationCode(code)
        return code
    }

    /// Join a household using an invitation code. Phase 1: stub (would validate code, add member).
    /// TODO: Store invitation codes; validate and add member to household.
    func joinHousehold(invitationCode: String, member: Member) -> Bool {
        // Stub for Phase 1 - no backend to validate codes
        return false
    }

    /// Clear household and member (e.g. when resetting onboarding).
    func clear() {
        currentHousehold = nil
        currentMember = nil
        HouseholdStore.clear()
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
