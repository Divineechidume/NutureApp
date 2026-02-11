//
//  QuickTourView.swift
//  Nurture
//
//  Onboarding screen 4: Optional carousel (skippable). PRD Section 7 - Quick Tour.
//

import SwiftUI

/// Optional 3-slide tour. Skippable; CTA "Start Tracking".
struct QuickTourView: View {
    var onStart: () -> Void
    var onSkip: () -> Void

    @State private var page = 0
    private let titles = [
        "See when your baby is sleeping",
        "Get alerts if they roll over",
        "Understand their sleep patterns"
    ]

    var body: some View {
        ZStack {
            DesignTokens.cream.ignoresSafeArea()
            VStack(spacing: DesignTokens.spacingXL) {
                HStack {
                    Spacer()
                    Button("Skip") { onSkip() }
                        .font(DesignTokens.captionFont())
                        .foregroundColor(DesignTokens.textSecondary)
                        .padding(DesignTokens.spacingMD)
                }
                TabView(selection: $page) {
                    ForEach(0..<titles.count, id: \.self) { index in
                        Text(titles[index])
                            .font(DesignTokens.headingFont(size: 22))
                            .foregroundColor(DesignTokens.textPrimary)
                            .multilineTextAlignment(.center)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                Button("Start Tracking") {
                    onStart()
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
