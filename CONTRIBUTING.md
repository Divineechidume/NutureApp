# Contributing to Nurture

Thank you for contributing to the Nurture iOS app. This guide helps you get set up for local development.

## Prerequisites

- **Xcode 15+** (or latest stable)
- **iOS 15+** Simulator or device
- **macOS** (required for iOS development)

## Local Setup

1. **Clone the repository**

   ```bash
   git clone <repo-url>
   cd NurtureApp
   ```

2. **Open the project**
   - Open `Nurture.xcodeproj` in Xcode
   - Do not use `.xcworkspace` unless you add CocoaPods/SPM workspace dependencies later

3. **Select scheme and destination**
   - Scheme: **Nurture**
   - Destination: iOS Simulator (e.g. iPhone 15 or iPhone 16)

4. **Build and run**
   - Press ⌘R or click Run
   - The app launches in Demo mode by default (mock data, no real Bluetooth)

5. **Reset onboarding** (to test intro flow again)
   - Run the app → Settings tab → Demo → Reset onboarding
   - Quit and relaunch the app

## Branch and PR Workflow

1. Create a branch for your work: `git checkout -b feature/your-feature-name`
2. Make changes and commit with clear messages
3. Push and open a pull request into `main`
4. Do not push directly to `main` — all changes go through PRs

## Codebase Navigation

- **Models** — `Nurture/Models/` (Child, SleepSession, WearableDevice, NapPrediction)
- **Views** — `Nurture/Views/` (SwiftUI views; bind to controller state only)
- **Controllers** — `Nurture/Controllers/` (state coordination, coordinate services)
- **Services** — `Nurture/Services/` (Bluetooth, Notifications, Sleep, ML)
- **Utilities** — `Nurture/Utilities/` (Constants, DesignTokens, ChildProfileStore)

See [README.md](README.md) for PRD mapping and architecture details.

## Troubleshooting

- **Build fails**: Ensure you use relative paths; avoid absolute paths in project settings. Check signing (Team) if running on a device.
- **Simulator issues**: Reset Simulator (Device → Erase All Content and Settings) if the app behaves oddly.
- **Demo mode**: Toggle `useDemoMode` in `Constants.swift` or via build setting if configured.
