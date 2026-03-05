//
//  RolloverAlertView.swift
//  Nurture
//
//  Full-screen rollover alert. PRD Section 4: "Check on [Child's Name]", peach/coral, "I've Checked".
//

import SwiftUI

/// Holds the active rollover alert to show app-wide. Set when rollover is received (BLE or demo trigger); clear on dismiss.
/// Enforces PRD: max 1 alert per 5 minutes unless dismissed.
final class RolloverAlertState: ObservableObject {
    @Published var activeRollover: (childName: String, time: Date)?

    /// Last time we showed/sent a rollover alert; used for throttle. Cleared on dismiss so next rollover can alert within 5 min.
    private var lastRolloverAlertTime: Date?

    /// Presents the full-screen rollover alert (demo or after throttle check). Does not send push; caller sends notification when appropriate.
    func presentRollover(childName: String, time: Date) {
        activeRollover = (childName: childName, time: time)
    }

    /// Handles rollover event from BLE: throttle check, then sends notification and presents full-screen alert.
    func handleRolloverFromBLE(
        childName: String,
        time: Date,
        alertsEnabled: Bool,
        notificationService: NotificationServiceProtocol
    ) {
        guard alertsEnabled else { return }

        let throttleInterval = TimeInterval(rolloverAlertThrottleMinutes * 60)
        let now = Date()
        if let last = lastRolloverAlertTime, now.timeIntervalSince(last) < throttleInterval {
            return
        }

        lastRolloverAlertTime = time
        notificationService.sendRolloverAlert(childName: childName, rolloverTime: time)
        presentRollover(childName: childName, time: time)
    }

    /// Dismisses the full-screen alert and resets throttle so the next rollover can trigger within 5 min (PRD: "unless dismissed").
    func dismiss() {
        activeRollover = nil
        lastRolloverAlertTime = nil
    }
}

/// Full-screen rollover alert. Calm but urgent — peach/coral accent, "Check on [Child]", "I've Checked".
struct RolloverAlertView: View {
    let childName: String
    let rolloverTime: Date
    let onDismiss: () -> Void

    private var timeString: String {
        let f = DateFormatter()
        f.timeStyle = .short
        return f.string(from: rolloverTime)
    }

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()

            VStack(spacing: Spacing.md) {
                Text("\(childName) may have\nrolled over")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)

                Text("Your baby, \(childName), rolled onto their tummy at \(timeString). Many babies begin rolling as they grow. If placed on their back to sleep, you may want to gently reposition them. 💗")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xl)
            }

            Button(action: onDismiss) {
                Text("I've Checked")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: CornerRadius.small)
                            .fill(Color.sageGreen)
                    )
            }
            .padding(.horizontal, Spacing.lg)

            Text(relativeTimeString)
                .font(.system(size: 18, weight: .regular))
                .foregroundColor(.textSecondary)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }

    private var relativeTimeString: String {
        let s = Int(-rolloverTime.timeIntervalSinceNow)
        if s < 60 { return "Rollover detected just now" }
        if s < 120 { return "Rollover detected 1 minute ago" }
        return "Rollover detected \(s / 60) minutes ago"
    }
}
