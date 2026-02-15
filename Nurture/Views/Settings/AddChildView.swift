//
//  AddChildView.swift
//  Nurture
//
//  Form to add a new child profile.
//

import SwiftUI

struct AddChildView: View {
    @ObservedObject var childrenStore: ChildrenStore
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var birthdate = Calendar.current.date(byAdding: .month, value: -8, to: Date()) ?? Date()

    var body: some View {
        NavigationView {
            ZStack {
                DesignTokens.cream.ignoresSafeArea()
                Form {
                    Section {
                        TextField("Child's name", text: $name)
                        DatePicker("Birthdate", selection: $birthdate, displayedComponents: .date)
                        Text("Age range: \(AgeRange.from(birthdate: birthdate).displayName)")
                            .font(.bodySmall)
                            .foregroundColor(.textSecondary)
                    }
                }
            }
            .navigationTitle("Add Child")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let child = Child(
                            name: name.isEmpty ? "Child" : name,
                            birthdate: birthdate,
                            ageRange: AgeRange.from(birthdate: birthdate)
                        )
                        childrenStore.addChild(child)
                        dismiss()
                    }
                    .font(.system(size: 17, weight: .semibold))
                }
            }
        }
    }
}
