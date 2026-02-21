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

1. **Enable Developer Mode** on your iPhone (required on iOS 16+): **Settings → Privacy & Security → Developer Mode** → turn on. Your device will restart.
2. Connect your iPhone to your Mac via USB.
3. In Xcode, select your device as the run destination (instead of a Simulator).
4. Open **Signing & Capabilities** for the Nurture target and set **Team** to your personal Apple ID. If the project has a hardcoded team and you see signing errors, change it to your own.
5. Build and run (⌘R).
6. On first run, if the app fails to launch: go to **Settings → General → VPN & Device Management** on your device, trust your developer certificate, then try again.

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

- **"The app identifier cannot be registered" / "No provisioning profiles found"**: Change the bundle ID to something unique to you. In Xcode: Nurture target → **Signing & Capabilities** → **Bundle Identifier** → set to e.g. `com.yourfirstname.nurture` or `com.yourcompany.nurture` (use a reversed domain you own or a unique string). Ensure **Team** is set to your Apple ID.
- **App won't run on device / "Developer Mode required"**: On iOS 16+, enable **Settings → Privacy & Security → Developer Mode**. Your device will restart.
- **Build fails**: Ensure you use relative paths; avoid absolute paths in project settings. Check signing (Team) if running on a device.
- **Simulator issues**: Reset Simulator (Device → Erase All Content and Settings) if the app behaves oddly.
- **Demo mode**: Toggle `useDemoMode` in `Constants.swift` or via build setting if configured.
