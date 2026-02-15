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
                if let member = householdService.currentMember {
                    Section("Members") {
                        MemberRow(member: member, isPrimary: true)
                    }
                }
                if (householdService.currentHousehold?.memberIDs.count ?? 0) <= 1 {
                    Text("Invite members from the Invite Member screen.")
                        .font(DesignTokens.captionFont())
                        .foregroundColor(DesignTokens.textSecondary)
                }
            }
        }
        .navigationTitle("Members")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct MemberRow: View {
    let member: Member
    let isPrimary: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(member.name)
                    .font(DesignTokens.bodyFont())
                    .foregroundColor(DesignTokens.textPrimary)
                Text(member.role.rawValue.capitalized)
                    .font(DesignTokens.captionFont())
                    .foregroundColor(DesignTokens.textSecondary)
            }
            Spacer()
            if isPrimary {
                Text("Primary")
                    .font(DesignTokens.captionFont())
                    .foregroundColor(DesignTokens.sageGreen)
            }
        }
    }
}
