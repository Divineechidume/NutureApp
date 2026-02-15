//
//  MainTabView.swift
//  Nurture
//
//  Tab bar: Home, History, Settings. Custom elevated design. PRD Section 2, 3, 6.
//

import SwiftUI

enum MainTab: String, CaseIterable, Identifiable {
    case home = "Home"
    case history = "History"
    case settings = "Settings"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .history: return "clock.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

/// Main tab container with custom elevated tab bar. Home | History | Settings.
struct MainTabView: View {
    @ObservedObject var rolloverAlertState: RolloverAlertState
    @ObservedObject var householdService: HouseholdService
    @ObservedObject var childrenStore: ChildrenStore

    @StateObject private var homeController: HomeController
    @StateObject private var historyController: HistoryController
    @StateObject private var settingsController = SettingsController()
    @StateObject private var notificationService = NotificationService()

    @State private var selectedTab: MainTab = .home

    init(rolloverAlertState: RolloverAlertState, householdService: HouseholdService, childrenStore: ChildrenStore) {
        self.rolloverAlertState = rolloverAlertState
        self.householdService = householdService
        self.childrenStore = childrenStore
        _homeController = StateObject(wrappedValue: HomeController(childrenStore: childrenStore))
        _historyController = StateObject(wrappedValue: HistoryController(childrenStore: childrenStore))
    }

    var body: some View {
        VStack(spacing: 0) {
            Group {
                switch selectedTab {
                case .home:
                    HomeView(controller: homeController, childrenStore: childrenStore)
                case .history:
                    HistoryView(controller: historyController)
                case .settings:
                    SettingsView(
                        controller: settingsController,
                        homeController: homeController,
                        householdService: householdService,
                        childrenStore: childrenStore,
                        rolloverAlertState: rolloverAlertState,
                        notificationService: notificationService
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            CustomTabBar(selectedTab: $selectedTab)
        }
        .onAppear { childrenStore.load() }
        .ignoresSafeArea(.keyboard)
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: MainTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(MainTab.allCases) { tab in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 24))
                        Text(tab.rawValue)
                            .font(.labelSmall)
                    }
                    .foregroundColor(selectedTab == tab ? .sageGreen : .textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.sm)
                }
                .buttonStyle(.plain)
            }
        }
        .background(
            Color.white
                .elevatedShadow()
                .ignoresSafeArea(edges: .bottom)
        )
    }
}
