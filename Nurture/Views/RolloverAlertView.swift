//
//  RolloverAlertView.swift
//  Nurture
//
//  Full-screen position change alert. FDA-compliant informational tone: lavender/cream (NOT alarming).
//  PRD Section 4: "Check on [Child's Name]", dismissal on "Got it".
//

import SwiftUI

/// Holds the active rollover alert to show app-wide. Set when rollover is received (BLE or demo trigger); clear on dismiss.
final class RolloverAlertState: ObservableObject {
    @Published var activeRollover: (childName: String, time: Date)?

    func presentRollover(childName: String, time: Date) {
        activeRollover = (childName: childName, time: time)
    }

    func dismiss() {
        activeRollover = nil
    }
}

/// Full-screen position change alert. Calm informational design (lavender/cream) for FDA compliance.
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

            Image(systemName: "info.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(.lavender)
                .padding(.top, Spacing.xl)

            VStack(spacing: Spacing.xs) {
                Text("Position Update")
                    .font(.displayMedium)
                    .foregroundColor(.textPrimary)

                Text("\(childName) changed position at \(timeString)")
                    .font(.bodyMedium)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xl)
            }

            Button(action: onDismiss) {
                Text("Got it")
                    .font(.labelLarge)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: CornerRadius.small)
                            .fill(Color.lavender)
                    )
            }
            .padding(.horizontal, Spacing.lg)

            Text(relativeTimeString)
                .font(.bodySmall)
                .foregroundColor(.textSecondary)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.cream)
    }

    private var relativeTimeString: String {
        let s = Int(-rolloverTime.timeIntervalSinceNow)
        if s < 60 { return "Position change detected just now" }
        if s < 120 { return "Position change detected 1 minute ago" }
        return "Position change detected \(s / 60) minutes ago"
    }
}
