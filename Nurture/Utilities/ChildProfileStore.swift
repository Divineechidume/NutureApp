//
//  ChildProfileStore.swift
//  Nurture
//
//  Persists Child profile to UserDefaults. PRD Section 1 (Device Pairing), Section 6 (Settings).
//  Saved when onboarding completes; read by SettingsController and HomeController.
//

import Foundation

/// Saves and loads Child profile from UserDefaults.
enum ChildProfileStore {
    private static let nameKey = "childProfileName"
    private static let birthdateKey = "childProfileBirthdate"

    static func save(_ child: Child) {
        UserDefaults.standard.set(child.name, forKey: nameKey)
        UserDefaults.standard.set(child.birthdate.timeIntervalSince1970, forKey: birthdateKey)
    }

    static func load() -> Child? {
        guard let name = UserDefaults.standard.string(forKey: nameKey),
              UserDefaults.standard.object(forKey: birthdateKey) != nil else { return nil }
        let timestamp = UserDefaults.standard.double(forKey: birthdateKey)
        let birthdate = Date(timeIntervalSince1970: timestamp)
        return Child(
            name: name,
            birthdate: birthdate,
            ageRange: AgeRange.from(birthdate: birthdate)
        )
    }
}
