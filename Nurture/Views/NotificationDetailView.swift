//
//  NotificationDetailView.swift
//  Nurture
//
//  Gentle in-app page shown when a notification is tapped. Minimal UI: title, body, dismiss.
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
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .navigationTitle("Notification")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Helpers

private func relativeTimeLabel(for date: Date?) -> String {
    guard let date = date else { return "" }
    let delta = Int(Date().timeIntervalSince(date))
    if delta < 60 { return "Just now" }
    if delta < 3600 { return "\(delta / 60)m ago" }
    if delta < 86400 { return "\(delta / 3600)h ago" }
    return date.formatted(as: .dateLabel)
}

#if DEBUG
struct NotificationDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationDetailView(displayTitle: "Test", displayBody: "This is a test notification.", timestamp: Date(), onDismiss: {})
    }
}
#endif
