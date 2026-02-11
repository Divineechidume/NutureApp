//
//  PairDeviceView.swift
//  Nurture
//
//  Onboarding screen 3: Pair Nurture device + child profile. PRD Section 1, Section 7.
//

import SwiftUI

/// Pair device wizard: instructions, device list (if multiple), child name/birthdate/age range.
struct PairDeviceView: View {
    @ObservedObject var controller: OnboardingController
    var onContinue: () -> Void

    var body: some View {
        ZStack {
            DesignTokens.cream.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.spacingLG) {
                    Text("Pair Your Nurture Device")
                        .font(DesignTokens.headingFont(size: 24))
                        .foregroundColor(DesignTokens.textPrimary)
                    // TODO: Clear pairing instructions with illustrations. PRD Section 1.
                    Text("Turn on your wearable. We'll detect it via Bluetooth.")
                        .font(DesignTokens.bodyFont())
                        .foregroundColor(DesignTokens.textSecondary)
                    // TODO: Show list if multiple devices; handle pairing timeout and retry. PRD Section 1 edge cases.
                    if controller.isPairing {
                        ProgressView().padding()
                    }
                    if let error = controller.pairingError {
                        Text(error).font(DesignTokens.captionFont()).foregroundColor(DesignTokens.peachCoral)
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
                    Picker("Age range", selection: $controller.childAgeRange) {
                        ForEach(AgeRange.allCases) { range in
                            Text(range.displayName).tag(range)
                        }
                    }
                    .pickerStyle(.menu)
                    Button("Complete Setup") {
                        onContinue()
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
    }
}
