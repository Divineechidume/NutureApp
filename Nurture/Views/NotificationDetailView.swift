//
//  NotificationDetailView.swift
//  Nurture
//
//  Gentle in-app sheet shown when a notification is tapped. Shows title, relative time, body, and a Done button.
//

import SwiftUI

struct NotificationDetailView: View {
    let displayTitle: String
    let displayBody: String
    let timestamp: Date?
    let onDismiss: () -> Void

    var body: some View {
        NavigationView {
            VStack(alignment: .center, spacing: Spacing.md) {
                Text(displayTitle)
                    .font(.displayMedium)
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.top, Spacing.lg)

                Text(relativeTimeLabel(for: timestamp))
                    .font(.labelSmall)
                    .foregroundColor(.textSecondary)

                Text(displayBody)
                    .font(.bodyMedium)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.md)

                Spacer()

                Button(action: onDismiss) {
                    Text("Done")
                        .font(.labelLarge)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.sm)
                        .background(RoundedRectangle(cornerRadius: CornerRadius.small).fill(Color.sageGreen))
                        .padding(.horizontal, Spacing.md)
                }
                .buttonStyle(.plain)
                .padding(.bottom, Spacing.xl)
            }
            .background(Color.cream.ignoresSafeArea())
            .navigationTitle("Notification")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

/// Returns a human-readable relative time label for the given date.
private func relativeTimeLabel(for date: Date?) -> String {
    guard let date = date else { return "" }
    let delta = Int(Date().timeIntervalSince(date))
    if delta < 60 { return "Just now" }
    if delta < 3600 { return "\(delta / 60)m ago" }
    if delta < 86400 { return "\(delta / 3600)h ago" }
    let f = DateFormatter()
    f.dateStyle = .medium
    f.timeStyle = .none
    return f.string(from: date)
}

#if DEBUG
struct NotificationDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationDetailView(
            displayTitle: "Baby may have rolled over 🧸",
            displayBody: "Your baby rolled onto their tummy. You may want to gently reposition them. 💗",
            timestamp: Date(),
            onDismiss: {}
        )
    }
}
#endif
