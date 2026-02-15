//
//  InviteMemberView.swift
//  Nurture
//
//  Displays 6-digit invitation code. Household setup implementation.
//

import SwiftUI

/// Displays invitation code for adding members to the household.
struct InviteMemberView: View {
    @ObservedObject var householdService: HouseholdService
    @State private var invitationCode: String = ""
    @State private var copied = false

    var body: some View {
        ZStack {
            DesignTokens.cream.ignoresSafeArea()
            VStack(spacing: DesignTokens.spacingXL) {
                Text("Share this code with the person you want to invite")
                    .font(DesignTokens.bodyFont())
                    .foregroundColor(DesignTokens.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                Text(invitationCode.isEmpty ? "------" : invitationCode)
                    .font(.system(size: 36, weight: .bold, design: .monospaced))
                    .foregroundColor(DesignTokens.textPrimary)
                    .tracking(8)
                Button(copied ? "Copied!" : "Copy Code") {
                    UIPasteboard.general.string = invitationCode
                    copied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        copied = false
                    }
                }
                .disabled(invitationCode.isEmpty)
                .font(DesignTokens.bodyFont(size: 17))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignTokens.spacingMD)
                .background(DesignTokens.sageGreen)
                .cornerRadius(DesignTokens.buttonCornerRadius)
                .padding(.horizontal, DesignTokens.spacingLG)
                Button("Generate New Code") {
                    invitationCode = householdService.generateInvitationCode()
                    householdService.storeInvitationCode(invitationCode)
                }
                .font(DesignTokens.captionFont())
                .foregroundColor(DesignTokens.sageGreen)
                Spacer()
            }
            .padding(.top, DesignTokens.spacingXL)
        }
        .navigationTitle("Invite Member")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            invitationCode = householdService.getOrCreateInvitationCode()
        }
    }
}
