//
//  MainTabView.swift
//  Nurture
//
//  Tab bar: Home, History, Settings. PRD Section 2, 3, 6 - bottom tab bar.
//

import SwiftUI

/// Main tab container. Home | History | Settings. Controllers created once at tab level.
struct MainTabView: View {
    @StateObject private var homeController = HomeController()
    @StateObject private var historyController = HistoryController()
    @StateObject private var settingsController = SettingsController()

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
            SettingsView(controller: settingsController)
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .tint(DesignTokens.sageGreen)
    }
}
