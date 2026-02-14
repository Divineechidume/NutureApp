//
//  SettingsView.swift
//  Nurture
//
//  Settings menu: Child Profile, Device, Notifications, Account, Support, App Info. PRD Section 6.
//  Demo: "Simulate rollover" triggers Safety Alerts flow for demo.
//

import SwiftUI

/// Settings sections per PRD: Child Profile, Device Management, Notifications, Account, Support & Legal, App Info.
struct SettingsView: View {
    @ObservedObject var controller: SettingsController
    @ObservedObject var rolloverAlertState: RolloverAlertState
    @ObservedObject var notificationService: NotificationService

    var body: some View {
        NavigationView {
            ZStack {
                DesignTokens.cream.ignoresSafeArea()
                List {
                    Section("Child Profile") {
                        if let child = controller.child {
                            HStack {
                                Text("Name")
                                    .foregroundColor(DesignTokens.textSecondary)
                                Spacer()
                                Text(child.name)
                                    .foregroundColor(DesignTokens.textPrimary)
                            }
                            HStack {
                                Text("Age range")
                                    .foregroundColor(DesignTokens.textSecondary)
                                Spacer()
                                Text(child.ageRange.displayName)
                                    .foregroundColor(DesignTokens.textPrimary)
                            }
                        }
                        // TODO: Navigate to profile edit; photo. PRD Section 6.
                    }
                    Section("Device Management") {
                        if let device = controller.device {
                            HStack {
                                Text("Battery")
                                    .foregroundColor(DesignTokens.textSecondary)
                                Spacer()
                                Text(device.batteryLevel.map { "\($0)%" } ?? "—")
                                    .foregroundColor(DesignTokens.textPrimary)
                            }
                            HStack {
                                Text("Firmware")
                                    .foregroundColor(DesignTokens.textSecondary)
                                Spacer()
                                Text(device.firmwareVersion ?? "—")
                                    .foregroundColor(DesignTokens.textPrimary)
                            }
                        }
                        Button("Unpair Device", role: .destructive) {
                            // TODO: Unpair with confirmation. PRD Section 6.
                        }
                    }
                    Section("Notifications") {
                        Toggle("Rollover alerts", isOn: $controller.rolloverAlertsEnabled)
                        Toggle("Nap predictions", isOn: $controller.napPredictionsEnabled)
                    }
                    Section("Account") {
                        // TODO: Email, subscription, Upgrade CTA. PRD Section 6.
                        Text("Email (for waitlist/login)")
                        Text("Subscription status")
                    }
                    Section("Support & Legal") {
                        Text("FAQs")
                        Text("Contact Support")
                        Text("Privacy Policy")
                        Text("Terms of Service")
                    }
                    Section("App Info") {
                        Text("Version 1.0.0 (MVP)")
                        Text("Rate the App")
                    }
                    if useDemoMode {
                        Section("Demo") {
                            Button("Simulate rollover") {
                                let name = controller.child?.name ?? mockChildName
                                let time = Date()
                                rolloverAlertState.presentRollover(childName: name, time: time)
                                notificationService.sendRolloverAlert(childName: name, rolloverTime: time)
                            }
                            Text("Reset onboarding")
                                .onTapGesture {
                                    UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
                                }
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
