//
//  RolloverAlertView.swift
//  Nurture
//
//  Full-screen rollover alert per PRD Section 4: "Check on [Child's Name]", "I've Checked" dismissal.
//  Peach/coral background, calm but urgent. Shown when activeRollover is non-nil.
//

import SwiftUI

/// Holds the active rollover alert to show app-wide. Set when rollover is received (BLE or demo trigger); clear on "I've Checked".
final class RolloverAlertState: ObservableObject {
    @Published var activeRollover: (childName: String, time: Date)?

    func presentRollover(childName: String, time: Date) {
        activeRollover = (childName: childName, time: time)
    }

    func dismiss() {
        activeRollover = nil
    }
}

/// Full-screen rollover alert. PRD Appendix: peach/coral background, "Check on Emma", "She rolled over at 9:47 PM", "I've Checked" button.
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
        ZStack {
            DesignTokens.peachCoral.ignoresSafeArea()
            VStack(spacing: DesignTokens.spacingXL) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.white)
                Text("Check on \(childName)")
                    .font(DesignTokens.headingFont(size: 26))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                Text("They rolled over at \(timeString)")
                    .font(DesignTokens.bodyFont(size: 18))
                    .foregroundColor(.white.opacity(0.95))
                Button("I've Checked") {
                    onDismiss()
                }
                .font(DesignTokens.bodyFont(size: 18))
                .foregroundColor(DesignTokens.peachCoral)
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignTokens.spacingMD)
                .background(Color.white)
                .cornerRadius(DesignTokens.buttonCornerRadius)
                .padding(.horizontal, DesignTokens.spacingXL)
                .padding(.top, DesignTokens.spacingLG)
                Text("Rollover detected \(relativeTimeString)")
                    .font(DesignTokens.captionFont())
                    .foregroundColor(.white.opacity(0.85))
            }
            .padding(DesignTokens.spacingXL)
        }
    }

    private var relativeTimeString: String {
        let s = Int(-rolloverTime.timeIntervalSinceNow)
        if s < 60 { return "just now" }
        if s < 120 { return "1 minute ago" }
        return "\(s / 60) minutes ago"
    }
}
