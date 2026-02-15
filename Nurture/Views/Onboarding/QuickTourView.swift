//
//  QuickTourView.swift
//  Nurture
//
//  Onboarding screen 4: Optional carousel with custom illustrations. PRD Section 7 - Quick Tour.
//

import SwiftUI

struct OnboardingSlideContent {
    let imageName: String
    let title: String
    let subtitle: String
}

/// Optional 4-slide tour with illustrations. Skippable; CTA "Start Tracking".
struct QuickTourView: View {
    var onStart: () -> Void
    var onSkip: () -> Void

    @State private var page = 0

    private let slides: [OnboardingSlideContent] = [
        OnboardingSlideContent(
            imageName: "sleep_tracking",
            title: "See when your baby is sleeping",
            subtitle: "Real-time sleep detection with our gentle ankle wearable"
        ),
        OnboardingSlideContent(
            imageName: "position_awareness",
            title: "Get position change notifications",
            subtitle: "Know when your baby changes position during sleep"
        ),
        OnboardingSlideContent(
            imageName: "nap_prediction",
            title: "Understand their sleep patterns",
            subtitle: "Spot patterns and predict when they might need a nap"
        ),
        OnboardingSlideContent(
            imageName: "household_sharing",
            title: "Share with your whole household",
            subtitle: "All caregivers can access sleep data and receive notifications"
        )
    ]

    var body: some View {
        ZStack {
            DesignTokens.cream.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button("Skip") { onSkip() }
                        .font(.labelMedium)
                        .foregroundColor(.textSecondary)
                        .padding(Spacing.md)
                }

                TabView(selection: $page) {
                    ForEach(0..<slides.count, id: \.self) { index in
                        OnboardingSlide(
                            imageName: slides[index].imageName,
                            title: slides[index].title,
                            subtitle: slides[index].subtitle
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))

                Button("Start Tracking") {
                    onStart()
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

struct OnboardingSlide: View {
    let imageName: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()

            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(height: 220)

            VStack(spacing: 12) {
                Text(title)
                    .font(.displayMedium)
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)

                Text(subtitle)
                    .font(.bodyLarge)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xl)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
