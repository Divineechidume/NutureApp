//
//  WelcomeView.swift
//  Nurture
//
//  Onboarding screen 1: Welcome with custom illustration. PRD Section 7.
//

import SwiftUI

/// Welcome screen. Custom illustration + "Sleep tracking for your whole household" + Get Started.
struct WelcomeView: View {
    var onContinue: () -> Void

    var body: some View {
        ZStack {
            DesignTokens.cream.ignoresSafeArea()
            VStack(spacing: Spacing.lg) {
                Spacer()

                Image("welcome_family")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 220)

                VStack(spacing: 12) {
                    Text("Welcome to Nurture")
                        .font(.displayMedium)
                        .foregroundColor(.textPrimary)

                    Text("Sleep tracking for your whole household")
                        .font(.bodyLarge)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }

                Spacer()

                Button("Get Started") {
                    onContinue()
                }
                .font(.labelLarge)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.small)
                        .fill(Color.sageGreen)
                )
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.xl)
            }
        }
    }
}
