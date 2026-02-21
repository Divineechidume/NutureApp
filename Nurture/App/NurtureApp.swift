//
//  NurtureApp.swift
//  Nurture
//
//  App entry point. PRD: Overall flow (Section 7 Onboarding, Section 2 Home).
//  Decides onboarding vs main tab view; supports demo mode for simulator.
//

import SwiftUI
import UserNotifications

@main
struct NurtureApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate
    @StateObject private var notificationService = NotificationService.shared

    init() {
        // NotificationService registers itself as UNUserNotificationCenter.delegate in its initializer.
    }

    var body: some Scene {
        WindowGroup {
            RootView(hasCompletedOnboarding: $hasCompletedOnboarding)
                .environmentObject(notificationService)
        }
    }
}
