//
//  PermissionsView.swift
//  Nurture
//
//  Onboarding screen 2: Request Bluetooth and Push Notification permissions. PRD Section 7.
//

import SwiftUI

/// Permissions screen. Explain and request Bluetooth + Notifications.
struct PermissionsView: View {
    var onContinue: () -> Void

    var body: some View {
        ZStack {
            DesignTokens.cream.ignoresSafeArea()
            VStack(spacing: DesignTokens.spacingXL) {
                Spacer()
                Text("Permissions")
                    .font(DesignTokens.headingFont(size: 28))
                    .foregroundColor(DesignTokens.textPrimary)
                // TODO: Request Bluetooth permission and explain why (1 sentence)
                // PRD Reference: Section 7 - Screen 2
                Text("We need Bluetooth to connect to your Nurture wearable and track sleep.")
                    .font(DesignTokens.bodyFont())
                    .foregroundColor(DesignTokens.textSecondary)
                    .multilineTextAlignment(.center)
                // TODO: Request Push Notification permission and explain why
                // PRD Reference: Section 4 - Safety Alerts; Section 7
                Text("We need notifications to alert you immediately if your baby rolls over.")
                    .font(DesignTokens.bodyFont())
                    .foregroundColor(DesignTokens.textSecondary)
                    .multilineTextAlignment(.center)
                Spacer()
                Button("Continue") {
                    onContinue()
                }
                .font(DesignTokens.bodyFont(size: 17))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignTokens.spacingMD)
                .background(DesignTokens.sageGreen)
                .cornerRadius(DesignTokens.buttonCornerRadius)
                .padding(.horizontal, DesignTokens.spacingLG)
                .padding(.bottom, DesignTokens.spacingXL)
            }
        }
    }
}
