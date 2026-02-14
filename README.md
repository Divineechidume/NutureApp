# Nurture iOS App

AI-powered sleep tracking app for children ages 0–3 that pairs with a Bluetooth ankle wearable. Built with **Swift** and **SwiftUI** using **MVC** architecture.

This repository contains the initial scaffolding and placeholder implementation. Junior developers can implement features by following the TODO comments and PRD references in the codebase.

---

## Architecture

- **MVC**: Model–View–Controller separation.
  - **Models** (`Nurture/Models/`): Data structures (Child, Household, Member, NurtureBand, NotificationPreferences, SleepSession, NapPrediction). No business logic. WearableDevice is a typealias for NurtureBand.
  - **Views** (`Nurture/Views/`): SwiftUI views only. They bind to controller state and design tokens; they do not call services directly.
  - **Controllers** (`Nurture/Controllers/`): `ObservableObject` types that hold state and coordinate services. They receive services via initializer (dependency injection) and expose `@Published` properties for the UI.
- **Services** (`Nurture/Services/`): Single-responsibility classes (Bluetooth, SleepDetection, Notifications, ML prediction). Controllers depend on them; views do not.
- **Utilities** (`Nurture/Utilities/`): Constants, design tokens, and extensions (e.g. date/duration formatting).

Principles: single responsibility per service, dependency injection into controllers, observable state with `@Published`, testability (avoid tight coupling).

---

## How to Navigate the Codebase

| Area                        | Location                                                                     | What you’ll find                                                             |
| --------------------------- | ---------------------------------------------------------------------------- | ---------------------------------------------------------------------------- |
| **App entry & root flow**   | `App/NurtureApp.swift`, `Views/RootView.swift`                               | Onboarding vs main tab decision; demo mode.                                  |
| **Current status (Home)**   | `Views/Home/HomeView.swift`, `Controllers/HomeController.swift`              | Asleep/awake, duration, last night, naps, nap prediction.                    |
| **History**                 | `Views/History/HistoryView.swift`, `Controllers/HistoryController.swift`     | Past 7 days, expandable list, nighttime vs naps.                             |
| **Onboarding**              | `Views/Onboarding/`, `Controllers/OnboardingController.swift`                | Welcome → Permissions → Pair Device → Quick Tour.                            |
| **Settings**                | `Views/Settings/SettingsView.swift`, `Controllers/SettingsController.swift`  | Profile, device, notifications, account.                                     |
| **Bluetooth & alerts**      | `Services/BluetoothService.swift`, `Services/NotificationService.swift`      | Pairing, real-time data, rollover and connection-lost alerts.                |
| **Rollover alert (Safety)** | `Views/RolloverAlertView.swift`, `RolloverAlertState`                        | Full-screen “Check on [Child]” and “I’ve Checked”; demo trigger in Settings. |
| **Sleep & ML**              | `Services/SleepDetectionService.swift`, `Services/MLPredictionService.swift` | Sleep/wake from BLE data; nap prediction (age-based then ML).                |
| **Design**                  | `Utilities/DesignTokens.swift`, `Utilities/Constants.swift`                  | Colors, typography, spacing; wake windows, demo flag.                        |

---

## PRD Mapping

| PRD Section                  | Primary files                                                                                   |
| ---------------------------- | ----------------------------------------------------------------------------------------------- |
| **§1 Device Pairing**        | `BluetoothService`, `WearableDevice`, `OnboardingController`, `Views/Onboarding/` (Pair Device) |
| **§2 Home — Current Status** | `HomeView`, `HomeController`, `SleepSession`, `BluetoothService`, `SleepDetectionService`       |
| **§3 Sleep History**         | `HistoryView`, `HistoryController`, `SleepSession`                                              |
| **§4 Safety Alerts**         | `NotificationService`, `BluetoothService`, rollover handling                                    |
| **§5 Nap Prediction**        | `NapPrediction`, `MLPredictionService`, `HomeView`                                              |
| **§6 Settings**              | `SettingsView`, `SettingsController`, `Child`, `WearableDevice`                                 |
| **§7 Onboarding**            | `Views/Onboarding/` (4 screens), `OnboardingController`                                         |
| **Visual Identity**          | `DesignTokens.swift` (sage, peach/coral, lavender, cream; Nunito, Open Sans)                    |

---

## Implementation Priority (for junior devs)

Suggested order:

1. **Design tokens + Constants** — Already present; extend as needed (e.g. custom fonts).
2. **Models and mock data** — Models are in place; add or adjust mocks in controllers for new screens.
3. **Onboarding flow and root flow** — Implement permission prompts and Pair Device (BLE scan/connect).
4. **Home screen with demo data** — Wire real data from `BluetoothService` and `SleepDetectionService` when available.
5. **History list** — Connect to local persistence; style bars (dark sage = night, peach = naps).
6. **Settings placeholders** — Implement profile edit, device battery/unpair, notification toggles.
7. **BluetoothService and pairing** — Scan, connect, discover characteristics, handle timeouts and errors.
8. **Sleep detection and notifications** — Parse BLE data into sleep/wake; trigger rollover and connection-lost alerts.
9. **Nap prediction** — Age-based logic is stubbed; add Core ML later for “learn over 14 days”.
10. **Persistence and polish** — Core Data or SwiftData for sessions and profile; analytics placeholders where noted.

---

## Local Setup

**Prerequisites:** Xcode 15+, iOS 15+ Simulator or device.

1. Clone the repo and open `Nurture.xcodeproj` in Xcode.
2. Select the **Nurture** scheme and an iOS Simulator (e.g. iPhone 15).
3. Build and run (⌘R).
4. To test onboarding again: Settings → Demo → Reset onboarding, then relaunch.

For more detail (troubleshooting, branch workflow), see [CONTRIBUTING.md](CONTRIBUTING.md).

---

## Running the App

1. Open `Nurture.xcodeproj` in Xcode (from the repo root).
2. Select an iOS Simulator (e.g. iPhone 15) and run (⌘R).
3. **Demo mode** is on by default: the app shows the full onboarding flow (Welcome, Permissions, Pair Device, Quick Tour), then Home with mock data (child “Emma”, “Asleep 2h 15m”, 3 days of history). Bluetooth is stubbed.
4. To test onboarding again: open **Settings** tab → **Demo** → **Reset onboarding**, then relaunch.

**Demo scope (upcoming demo):** The app is set up so the key demo features are:

- **Device Pairing & Setup** — Demo runs the full intro flow. On the Pair Device screen, tap **"Use already paired device (demo)"** to skip real BLE scanning and continue to Quick Tour and Home. Real scan/connect can be used when testing with hardware.
- **Home Screen** — Current status card (Asleep/Awake, duration, last night, today’s naps) with mock data; design matches PRD (sage when asleep, cream when awake).
- **Safety Alerts** — Full-screen rollover alert (peach/coral, “Check on [Child]”, “I’ve Checked”) and local notification. In **Settings → Demo**, tap **Simulate rollover** to trigger the alert and notification without hardware.

Everything else (History, Settings content, Nap prediction, etc.) is mocked for the demo.

---

## Git Workflow (Branching and Pull Requests)

**Do not push directly to `main`.** Keep `main` protected and deployable.

1. **Create a branch** for each feature or fix, for example:
   - `feature/home-sleep-status`
   - `fix/onboarding-skip`
   - `chore/design-tokens`
2. **Make your changes** on that branch and commit.
3. **Push the branch** and **open a pull request** into `main`.
4. Use the PR for review, discussion, and any CI checks before merging.
5. Maintainers may require approval before merging.

Quick start:

```bash
git checkout -b feature/your-feature-name
# make changes, then:
git add .
git commit -m "Description of change"
git push -u origin feature/your-feature-name
```

Then open a pull request in your Git host (e.g. GitHub, GitLab) from `feature/your-feature-name` into `main`.

---

## Code Quality

- Every file has a header comment (purpose + PRD reference where relevant).
- Types have doc comments (`///`).
- TODOs use the standard format: Feature, Purpose, PRD Reference, Implementation notes, Dependencies, Estimated complexity.
- Use Swift naming: `camelCase` for variables/functions, `PascalCase` for types.
- Group related code with `// MARK: - Section Name`.
