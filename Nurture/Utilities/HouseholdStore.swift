//
//  HouseholdStore.swift
//  Nurture
//
//  Persists Household and current Member. Household setup implementation.
//

import Foundation

/// Saves and loads Household and Member from UserDefaults.
enum HouseholdStore {
    private static let householdKey = "householdStore_household"
    private static let memberKey = "householdStore_member"
    private static let invitationCodeKey = "householdStore_invitationCode"
    private static let invitationCodeHouseholdKey = "householdStore_invitationCode_householdId"

    static func save(household: Household, member: Member) {
        if let h = try? JSONEncoder().encode(household) {
            UserDefaults.standard.set(h, forKey: householdKey)
        }
        if let m = try? JSONEncoder().encode(member) {
            UserDefaults.standard.set(m, forKey: memberKey)
        }
    }

    static func loadHousehold() -> Household? {
        guard let data = UserDefaults.standard.data(forKey: householdKey) else { return nil }
        return try? JSONDecoder().decode(Household.self, from: data)
    }

    static func loadMember() -> Member? {
        guard let data = UserDefaults.standard.data(forKey: memberKey) else { return nil }
        return try? JSONDecoder().decode(Member.self, from: data)
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: householdKey)
        UserDefaults.standard.removeObject(forKey: memberKey)
        UserDefaults.standard.removeObject(forKey: invitationCodeKey)
        UserDefaults.standard.removeObject(forKey: invitationCodeHouseholdKey)
    }

    static func saveInvitationCode(_ code: String, householdID: UUID) {
        UserDefaults.standard.set(code, forKey: invitationCodeKey)
        UserDefaults.standard.set(householdID.uuidString, forKey: invitationCodeHouseholdKey)
    }

    static func loadInvitationCode(householdID: UUID) -> String? {
        guard let storedID = UserDefaults.standard.string(forKey: invitationCodeHouseholdKey),
              storedID == householdID.uuidString else { return nil }
        return UserDefaults.standard.string(forKey: invitationCodeKey)
    }
}
