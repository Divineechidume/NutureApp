//
//  MainTabView.swift
//  Nurture
//
//  Tab bar: Home, History, Settings. PRD Section 2, 3, 6 - bottom tab bar.
//

import SwiftUI

/// Main tab container. Home | History | Settings. Controllers created once at tab level.
/// Passes rolloverAlertState and notificationService to Settings for demo "Simulate rollover".
struct MainTabView: View {
    @ObservedObject var rolloverAlertState: RolloverAlertState
    @StateObject private var homeController = HomeController()
    @StateObject private var historyController = HistoryController()
    @StateObject private var settingsController = SettingsController()
    @StateObject private var notificationService = NotificationService()

    var body: some View {
        TabView {
            HomeView(controller: homeController)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
            HistoryView(controller: historyController)
                .tabItem {
                    Label("History", systemImage: "clock.fill")
                }
            SettingsView(
                controller: settingsController,
                rolloverAlertState: rolloverAlertState,
                notificationService: notificationService
            )
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
        }
        .tint(DesignTokens.sageGreen)
    }
}
