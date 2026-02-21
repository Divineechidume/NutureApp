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

#if DEBUG
struct NotificationDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationDetailView(displayTitle: "Test", displayBody: "This is a test notification.", timestamp: Date(), onDismiss: {})
    }
}
#endif
