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

## Testing on a Real Device (Bluetooth Only)

The Simulator does not support Bluetooth. To test pairing, BLE streaming, or rollover alerts, you need to run the app on a physical iPhone or iPad.

### Setup (one-time per developer)

1. Connect your iPhone to your Mac via USB.
2. In Xcode, select your device as the run destination (instead of a Simulator).
3. Open **Signing & Capabilities** for the Nurture target and set **Team** to your personal Apple ID. If the project has a hardcoded team and you see signing errors, change it to your own.
4. Build and run (⌘R).
5. On first run, if the app fails to launch: go to **Settings → General → VPN & Device Management** on your device, trust your developer certificate, then try again.

### Limitations (free Apple ID)

- The app expires after ~7 days. Rebuild and run from Xcode to reinstall.
- No paid Developer Program required for basic BLE testing.

For non-Bluetooth work (UI, history, settings, demo mode), the Simulator is sufficient.

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
- **Hardware** — `hardware/nurture_band/` (production firmware), `hardware/prototypes/` (reference sketches). See [hardware/README.md](hardware/README.md). Changes to the BLE protocol may require testing with the iOS app’s `BluetoothService` (PRD §1, §4).

See [README.md](README.md) for PRD mapping and architecture details.

## Troubleshooting

- **Build fails**: Ensure you use relative paths; avoid absolute paths in project settings. Check signing (Team) if running on a device.
- **Simulator issues**: Reset Simulator (Device → Erase All Content and Settings) if the app behaves oddly.
- **Demo mode**: Toggle `useDemoMode` in `Constants.swift` or via build setting if configured.
