//
//  HouseholdMembersView.swift
//  Nurture
//
//  Lists household members. Household setup implementation.
//

import SwiftUI

/// Lists household members. Primary member cannot be removed.
struct HouseholdMembersView: View {
    @ObservedObject var householdService: HouseholdService

    var body: some View {
        ZStack {
            DesignTokens.cream.ignoresSafeArea()
            List {
                if let member = householdService.currentMember, let household = householdService.currentHousehold {
                    Section("Members") {
                        MemberRow(
                            member: member,
                            isPrimary: true,
                            household: household,
                            householdService: householdService
                        )
                    }
                }
                Text("Invite members from the Invite Member screen.")
                    .font(DesignTokens.captionFont())
                    .foregroundColor(DesignTokens.textSecondary)
            }
        }
        .navigationTitle("Household Members")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct MemberRow: View {
    let member: Member
    let isPrimary: Bool
    let household: Household
    @ObservedObject var householdService: HouseholdService

    private var subtitle: String {
        if member.email.isEmpty {
            return member.role.rawValue
        }
        return "\(member.email) · \(member.role.rawValue)"
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(member.name)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(DesignTokens.textPrimary)
                Text(subtitle)
                    .font(DesignTokens.captionFont())
                    .foregroundColor(DesignTokens.textSecondary)
            }
            Spacer()
            if isPrimary {
                Text("Primary")
                    .font(DesignTokens.captionFont())
                    .foregroundColor(DesignTokens.sageGreen)
            } else {
                Button {
                    _ = householdService.removeMember(memberID: member.id, from: household)
                    if let updated = householdService.currentHousehold, let current = householdService.currentMember {
                        HouseholdStore.save(household: updated, member: current)
                    }
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 18))
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
