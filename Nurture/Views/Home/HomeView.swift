//
//  HomeView.swift
//  Nurture
//
//  Main home screen: current sleep status and secondary cards. PRD Section 2 - Home Screen.
//  Soft sage when asleep, cream when awake; pull-to-refresh (TODO).
//

import SwiftUI

/// Main home screen. Status card (Asleep/Awake + duration) and secondary info cards.
struct HomeView: View {
    @ObservedObject var controller: HomeController

    var body: some View {
        let isAsleep = controller.isAsleep
        ZStack {
            (isAsleep ? DesignTokens.sageGreen : DesignTokens.cream).ignoresSafeArea()
        }
        .refreshable { controller.refresh() }
        .overlay(alignment: .topTrailing) {
            // Settings accessible from Home per PRD (gear top-right)
            // Navigation to Settings is via tab; optional: same-screen link
        }
        .overlay {
            ScrollView {
                VStack(spacing: DesignTokens.spacingLG) {
                    // TODO: Implement sleep status card per PRD Section 2
                    // - Show "Asleep" or "Awake" with icon
                    // - Display duration (e.g. "Sleeping for 1h 23m")
                    // - Show sleep start time when asleep
                    statusCard(isAsleep: isAsleep)
                    // TODO: Implement secondary info cards - last night, today's naps, next nap prediction (Feature 5)
                    secondaryCards(isAsleep: isAsleep)
                }
                .padding(DesignTokens.spacingLG)
            }
        }
    }

    private func statusCard(isAsleep: Bool) -> some View {
        VStack(spacing: DesignTokens.spacingSM) {
            Text(isAsleep ? "Asleep" : "Awake")
                .font(DesignTokens.statusTitleFont)
                .foregroundColor(isAsleep ? .white : DesignTokens.textPrimary)
            Text(isAsleep ? "Sleeping for \(controller.durationString)" : "Awake for \(controller.durationString)")
                .font(DesignTokens.bodyFont(size: 18))
                .foregroundColor(isAsleep ? .white.opacity(0.9) : DesignTokens.textSecondary)
            if let start = controller.sleepStartTimeString {
                Text("Fell asleep at \(start)")
                    .font(DesignTokens.captionFont())
                    .foregroundColor(isAsleep ? .white.opacity(0.8) : DesignTokens.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(DesignTokens.spacingXL)
        .background(isAsleep ? DesignTokens.darkSage : Color.white.opacity(0.8))
        .cornerRadius(DesignTokens.cardCornerRadius)
    }

    private func secondaryCards(isAsleep: Bool) -> some View {
        VStack(spacing: DesignTokens.spacingMD) {
            HStack {
                Image(systemName: "moon.fill")
                    .foregroundColor(DesignTokens.lavender)
                Text("Last Night")
                    .font(DesignTokens.captionFont())
                    .foregroundColor(DesignTokens.textSecondary)
                Spacer()
                Text(controller.lastNightTotalString + " total sleep")
                    .font(DesignTokens.bodyFont())
                    .foregroundColor(DesignTokens.textPrimary)
            }
            .padding(DesignTokens.spacingMD)
            .background(Color.white.opacity(0.9))
            .cornerRadius(DesignTokens.cardCornerRadius)

            HStack {
                Image(systemName: "sun.max.fill")
                    .foregroundColor(DesignTokens.peachCoral)
                Text("Today's Naps")
                    .font(DesignTokens.captionFont())
                    .foregroundColor(DesignTokens.textSecondary)
                Spacer()
                Text(controller.todaysNapsString)
                    .font(DesignTokens.bodyFont())
                    .foregroundColor(DesignTokens.textPrimary)
            }
            .padding(DesignTokens.spacingMD)
            .background(Color.white.opacity(0.9))
            .cornerRadius(DesignTokens.cardCorner)

            if !isAsleep, let nap = controller.napPrediction {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(DesignTokens.sageGreen)
                    Text("Next Nap")
                        .font(DesignTokens.captionFont())
                        .foregroundColor(DesignTokens.textSecondary)
                    Spacer()
                    Text(nap.message)
                        .font(DesignTokens.bodyFont())
                        .foregroundColor(DesignTokens.textPrimary)
                }
                .padding(DesignTokens.spacingMD)
                .background(Color.white.opacity(0.9))
                .cornerRadius(DesignTokens.cardCorner)
            }
        }
    }
}
