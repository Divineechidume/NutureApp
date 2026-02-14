//
//  Child.swift
//  Nurture
//
//  Child profile model. PRD Section 1 (Device Pairing & Setup), Section 6 (Settings).
//  Created during onboarding; stored locally; used for nap prediction and alert copy.
//

import Foundation

/// Represents a child's profile in the app.
/// Created during onboarding and stored locally. Used for nap prediction age bracket and alert copy ("Check on [name]").
struct Child: Identifiable {
    /// Unique identifier. Generated at creation.
    var id: UUID
    /// Child's name from onboarding. User input.
    var name: String
    /// Birthdate for age calculations. User input.
    var birthdate: Date
    /// Current age bracket (0-6mo, 6-12mo, 1-2yr, 2-3yr). User selection; used by MLPredictionService.
    var ageRange: AgeRange
    /// Optional profile photo. User input; stored locally.
    var photoURL: URL?
    /// Which NurtureBand is assigned to this child. Nil until paired.
    var bandID: UUID?

    init(id: UUID = UUID(), name: String, birthdate: Date, ageRange: AgeRange, photoURL: URL? = nil, bandID: UUID? = nil) {
        self.id = id
        self.name = name
        self.birthdate = birthdate
        self.ageRange = ageRange
        self.photoURL = photoURL
        self.bandID = bandID
    }
}
