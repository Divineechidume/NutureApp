//
//  NurtureApp.swift
//  Nurture
//
//  App entry point. PRD: Overall flow (Section 7 Onboarding, Section 2 Home).
//  Decides onboarding vs main tab view; supports demo mode for simulator.
//

import SwiftUI

@main
struct NurtureApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    var body: some Scene {
        WindowGroup {
            RootView(hasCompletedOnboarding: $hasCompletedOnboarding)
        }
    }
}
