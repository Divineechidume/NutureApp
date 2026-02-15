//
//  PairDeviceView.swift
//  Nurture
//
//  Onboarding screen 3: Pair Nurture device + child profile. Success state with animation. PRD Section 1, 7.
//

import SwiftUI

/// Pair device wizard: instructions, child profile, success state with illustration.
struct PairDeviceView: View {
    @ObservedObject var controller: OnboardingController
    var onContinue: () -> Void

    @State private var showSuccess = false

    var body: some View {
        ZStack {
            DesignTokens.cream.ignoresSafeArea()

            if showSuccess {
                PairingSuccessView(onComplete: onContinue)
            } else {
                pairForm
            }
        }
    }

    private var pairForm: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.spacingLG) {
                Text("Pair Your Nurture Device")
                    .font(DesignTokens.headingFont(size: 24))
                    .foregroundColor(DesignTokens.textPrimary)

                Text("Turn on your wearable. We'll detect it via Bluetooth.")
                    .font(DesignTokens.bodyFont())
                    .foregroundColor(DesignTokens.textSecondary)

                Button("Pair Device") {
                    controller.startPairing()
                }
                .font(DesignTokens.bodyFont(size: 17))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignTokens.spacingMD)
                .background(DesignTokens.sageGreen)
                .cornerRadius(DesignTokens.buttonCornerRadius)
                .disabled(controller.isPairing)

                if controller.isPairing {
                    HStack {
                        ProgressView()
                        Text("Searching for device…")
                            .font(DesignTokens.captionFont())
                            .foregroundColor(DesignTokens.textSecondary)
                    }
                    .padding()
                }

                if let error = controller.pairingError {
                    Text(error)
                        .font(DesignTokens.captionFont())
                        .foregroundColor(DesignTokens.peachCoral)
                }

                Text("Child's name")
                    .font(DesignTokens.captionFont())
                    .foregroundColor(DesignTokens.textSecondary)
                TextField("Name", text: $controller.childName)
                    .textFieldStyle(.roundedBorder)

                Text("Birthdate")
                    .font(DesignTokens.captionFont())
                    .foregroundColor(DesignTokens.textSecondary)
                DatePicker("", selection: $controller.childBirthdate, displayedComponents: .date)
                    .labelsHidden()

                Text("Age range")
                    .font(DesignTokens.captionFont())
                    .foregroundColor(DesignTokens.textSecondary)
                Text(AgeRange.from(birthdate: controller.childBirthdate).displayName + " (from birthdate)")
                    .font(DesignTokens.bodyFont())
                    .foregroundColor(DesignTokens.textPrimary)

                if useDemoMode {
                    Button("Use already paired device (demo)") {
                        completeWithSuccess()
                    }
                    .font(DesignTokens.bodyFont(size: 17))
                    .foregroundColor(DesignTokens.sageGreen)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DesignTokens.spacingMD)
                    .overlay(RoundedRectangle(cornerRadius: DesignTokens.buttonCornerRadius).stroke(DesignTokens.sageGreen, lineWidth: 2))
                    .padding(.top, DesignTokens.spacingSM)
                }

                Button("Complete Setup") {
                    completeWithSuccess()
                }
                .font(DesignTokens.bodyFont(size: 17))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignTokens.spacingMD)
                .background(DesignTokens.sageGreen)
                .cornerRadius(DesignTokens.buttonCornerRadius)
                .padding(.top, DesignTokens.spacingMD)
            }
            .padding(DesignTokens.spacingLG)
        }
    }

    private func completeWithSuccess() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            showSuccess = true
        }
    }
}

struct PairingSuccessView: View {
    @State private var appear = false
    @State private var hasCompleted = false
    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: Spacing.md) {
            if appear {
                Image("success_pairing")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 100)
                    .transition(.scale.combined(with: .opacity))

                Text("Device Paired!")
                    .font(.headingLarge)
                    .foregroundColor(.textPrimary)
                    .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.cream)
        .contentShape(Rectangle())
        .onTapGesture {
            completeOnce()
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                appear = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                completeOnce()
            }
        }
    }

    private func completeOnce() {
        guard !hasCompleted else { return }
        hasCompleted = true
        onComplete()
    }
}
