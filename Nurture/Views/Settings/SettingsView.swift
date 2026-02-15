//
//  SettingsView.swift
//  Nurture
//
//  Settings menu: card-style sections with icons. PRD Section 6.
//

import SwiftUI

// MARK: - Section Header

private struct SettingsSectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.labelSmall)
            .foregroundColor(.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, Spacing.xs)
            .padding(.horizontal, Spacing.md)
    }
}

// MARK: - Section Card

private struct SettingsSectionCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.medium)
                    .fill(Color.white)
                    .cardShadowSecondary()
            )
    }
}

// MARK: - Row Types

private struct SettingsRow: View {
    let icon: String
    let title: String
    var value: String? = nil
    var showChevron: Bool = false
    var isDestructive: Bool = false

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(isDestructive ? .red : .textSecondary)
                .frame(width: 24, alignment: .center)

            Text(title)
                .font(.bodyMedium)
                .foregroundColor(isDestructive ? .red : .textPrimary)

            Spacer()

            if let value = value {
                Text(value)
                    .font(.bodyMedium)
                    .foregroundColor(.textSecondary)
            }
            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.textSecondary.opacity(0.5))
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
    }
}

private struct SettingsToggleRow: View {
    let icon: String
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.textSecondary)
                .frame(width: 24, alignment: .center)

            Text(title)
                .font(.bodyMedium)
                .foregroundColor(.textPrimary)

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(.sageGreen)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.xs)
    }
}

private struct SettingsDivider: View {
    var body: some View {
        Divider()
            .padding(.leading, 24 + Spacing.sm + Spacing.md)
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @ObservedObject var controller: SettingsController
    @ObservedObject var homeController: HomeController
    @ObservedObject var householdService: HouseholdService
    @ObservedObject var childrenStore: ChildrenStore
    @ObservedObject var rolloverAlertState: RolloverAlertState
    @ObservedObject var notificationService: NotificationService

    var body: some View {
        NavigationView {
            ZStack {
                DesignTokens.cream.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        if let household = householdService.currentHousehold {
                            householdSection(household)
                        }
                        childrenSection
                        deviceManagementSection
                        notificationsSection
                        accountSection
                        supportSection
                        appInfoSection
                        if useDemoMode {
                            demoSection
                        }
                    }
                    .padding(.vertical, Spacing.md)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func householdSection(_ household: Household) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            SettingsSectionHeader(title: "HOUSEHOLD")
            SettingsSectionCard {
                VStack(spacing: 0) {
                    SettingsRow(icon: "house", title: "Name", value: household.name)
                    SettingsDivider()
                    NavigationLink {
                        HouseholdMembersView(householdService: householdService)
                    } label: {
                        SettingsRow(icon: "person.2", title: "Members", showChevron: true)
                    }
                    .buttonStyle(.plain)
                    SettingsDivider()
                    NavigationLink {
                        InviteMemberView(householdService: householdService)
                    } label: {
                        SettingsRow(icon: "envelope", title: "Invite Member", showChevron: true)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, Spacing.md)
    }

    private var childrenSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SettingsSectionHeader(title: "CHILDREN")
            SettingsSectionCard {
                VStack(spacing: 0) {
                    ForEach(childrenStore.children) { child in
                        Button {
                            childrenStore.selectChild(child.id)
                        } label: {
                            HStack(spacing: Spacing.sm) {
                                Image(systemName: "person.crop.circle")
                                    .font(.system(size: 18))
                                    .foregroundColor(.textSecondary)
                                    .frame(width: 24, alignment: .center)
                                Text(child.name)
                                    .font(.bodyMedium)
                                    .foregroundColor(.textPrimary)
                                Spacer()
                                Text(child.ageRange.displayName)
                                    .font(.bodyMedium)
                                    .foregroundColor(.textSecondary)
                                Image(systemName: childrenStore.selectedChildID == child.id ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 20))
                                    .foregroundColor(childrenStore.selectedChildID == child.id ? .sageGreen : .textSecondary.opacity(0.5))
                            }
                            .padding(.horizontal, Spacing.md)
                            .padding(.vertical, Spacing.sm)
                        }
                        .buttonStyle(.plain)
                        if child.id != childrenStore.children.last?.id {
                            SettingsDivider()
                        }
                    }
                    if !childrenStore.children.isEmpty {
                        SettingsDivider()
                    }
                    NavigationLink {
                        AddChildView(childrenStore: childrenStore)
                    } label: {
                        SettingsRow(icon: "plus.circle", title: "Add Child", showChevron: true)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, Spacing.md)
    }

    private var deviceManagementSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SettingsSectionHeader(title: "DEVICE MANAGEMENT")
            SettingsSectionCard {
                VStack(spacing: 0) {
                    if let device = controller.device {
                        SettingsRow(icon: "battery.100", title: "Battery", value: device.batteryLevel.map { "\($0)%" } ?? "—")
                        SettingsDivider()
                        SettingsRow(icon: "info.circle", title: "Firmware", value: device.firmwareVersion ?? "—")
                        SettingsDivider()
                    }
                    Button {
                        // TODO: Unpair with confirmation
                    } label: {
                        SettingsRow(icon: "exclamationmark.triangle", title: "Unpair Device", isDestructive: true)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, Spacing.md)
    }

    private var notificationsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SettingsSectionHeader(title: "NOTIFICATIONS")
            SettingsSectionCard {
                VStack(spacing: 0) {
                    SettingsToggleRow(icon: "bell", title: "Rollover alerts", isOn: $controller.rolloverAlertsEnabled)
                    SettingsDivider()
                    SettingsToggleRow(icon: "lightbulb", title: "Nap predictions", isOn: $controller.napPredictionsEnabled)
                }
            }
        }
        .padding(.horizontal, Spacing.md)
    }

    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SettingsSectionHeader(title: "ACCOUNT")
            SettingsSectionCard {
                VStack(spacing: 0) {
                    SettingsRow(icon: "envelope", title: "Email (for waitlist/login)")
                    SettingsDivider()
                    SettingsRow(icon: "creditcard", title: "Subscription status")
                }
            }
        }
        .padding(.horizontal, Spacing.md)
    }

    private var supportSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SettingsSectionHeader(title: "SUPPORT & LEGAL")
            SettingsSectionCard {
                VStack(spacing: 0) {
                    SettingsRow(icon: "questionmark.circle", title: "FAQs", showChevron: true)
                    SettingsDivider()
                    SettingsRow(icon: "envelope", title: "Contact Support", showChevron: true)
                    SettingsDivider()
                    SettingsRow(icon: "hand.raised", title: "Privacy Policy", showChevron: true)
                    SettingsDivider()
                    SettingsRow(icon: "doc.text", title: "Terms of Service", showChevron: true)
                }
            }
        }
        .padding(.horizontal, Spacing.md)
    }

    private var appInfoSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SettingsSectionHeader(title: "APP INFO")
            SettingsSectionCard {
                VStack(spacing: 0) {
                    SettingsRow(icon: "info.circle", title: "Version 1.0.0 (MVP)")
                    SettingsDivider()
                    SettingsRow(icon: "star", title: "Rate the App", showChevron: true)
                }
            }
        }
        .padding(.horizontal, Spacing.md)
    }

    private var demoSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SettingsSectionHeader(title: "DEMO")
            SettingsSectionCard {
                VStack(spacing: 0) {
                    SettingsToggleRow(
                        icon: "sun.max",
                        title: "Show awake state",
                        isOn: Binding(
                            get: { homeController.demoShowAwake },
                            set: { homeController.setDemoAwake($0) }
                        )
                    )
                    SettingsDivider()
                    Button {
                        let name = childrenStore.selectedChild?.name ?? mockChildName
                        let time = Date()
                        rolloverAlertState.presentRollover(childName: name, time: time)
                        notificationService.sendRolloverAlert(childName: name, rolloverTime: time)
                    } label: {
                        SettingsRow(icon: "exclamationmark.triangle", title: "Simulate rollover")
                    }
                    .buttonStyle(.plain)
                    SettingsDivider()
                    Button {
                        UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
                        householdService.clear()
                        ChildProfileStore.clear()
                        childrenStore.load()
                    } label: {
                        SettingsRow(icon: "arrow.counterclockwise", title: "Reset onboarding")
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, Spacing.md)
    }
}
