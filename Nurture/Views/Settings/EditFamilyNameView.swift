//
//  EditFamilyNameView.swift
//  Nurture
//
//  Edit household family name. Tapped from Settings HOUSEHOLD section.
//

import SwiftUI

/// Form to edit the household family name.
struct EditFamilyNameView: View {
    @ObservedObject var householdService: HouseholdService
    @Environment(\.dismiss) private var dismiss

    @State private var familyName: String = ""

    var body: some View {
        ZStack {
            DesignTokens.cream.ignoresSafeArea()
            Form {
                Section {
                    TextField("Family name", text: $familyName)
                        .textInputAutocapitalization(.words)
                }
            }
        }
        .navigationTitle("Family Name")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    let trimmed = familyName.trimmingCharacters(in: .whitespacesAndNewlines)
                    householdService.updateHouseholdName(trimmed.isEmpty ? "My Family" : trimmed)
                    dismiss()
                }
                .font(.system(size: 17, weight: .semibold))
            }
        }
        .onAppear {
            familyName = householdService.currentHousehold?.name ?? "My Family"
        }
    }
}
