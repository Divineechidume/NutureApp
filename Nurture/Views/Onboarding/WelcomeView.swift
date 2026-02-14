//
//  WelcomeView.swift
//  Nurture
//
//  Onboarding screen 1: Welcome. PRD Section 7 - "Welcome to Nurture", CTA "Get Started".
//

import SwiftUI

/// Welcome screen. Illustration + "Simple sleep tracking for ages 0–3" + Get Started.
struct WelcomeView: View {
    var onContinue: () -> Void

    var body: some View {
        ZStack {
            DesignTokens.cream.ignoresSafeArea()
            VStack(spacing: DesignTokens.spacingXL) {
                Spacer()
                // TODO: Add illustration of wearable + phone
                // PRD Reference: Section 7 - Screen 1
                Text("Welcome to Nurture")
                    .font(DesignTokens.headingFont(size: 28))
                    .foregroundColor(DesignTokens.textPrimary)
                Text("Simple sleep tracking for ages 0–3")
                    .font(DesignTokens.bodyFont())
                    .foregroundColor(DesignTokens.textSecondary)
                    .multilineTextAlignment(.center)
                Text("A calm companion for your baby's sleep")
                    .font(DesignTokens.bodyFont())
                    .foregroundColor(DesignTokens.textSecondary)
                    .multilineTextAlignment(.center)
                Spacer()
                Button("Get Started") {
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
