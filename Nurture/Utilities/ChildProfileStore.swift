//
//  ChildProfileStore.swift
//  Nurture
//
//  Persists Child profile. PRD Section 1 (Device Pairing), Section 6 (Settings).
//  PII (name, birthdate) stored in Keychain via SecureStorage.
//

import Foundation

/// Saves and loads Child profile. PII stored in Keychain.
enum ChildProfileStore {
    private static let nameKey = "childProfileName"
    private static let birthdateKey = "childProfileBirthdate"
    private static let secureStorage: SecureStorageProtocol = KeychainSecureStorage()

    static func save(_ child: Child) {
        do {
            try secureStorage.save(Data(child.name.utf8), forKey: nameKey)
            var timestamp = child.birthdate.timeIntervalSince1970
            try secureStorage.save(withUnsafeBytes(of: &timestamp) { Data($0) }, forKey: birthdateKey)
        } catch {
            // Fallback to UserDefaults if Keychain fails (e.g. Simulator)
            UserDefaults.standard.set(child.name, forKey: nameKey)
            UserDefaults.standard.set(child.birthdate.timeIntervalSince1970, forKey: birthdateKey)
        }
    }

    static func load() -> Child? {
        do {
            guard let nameData = try secureStorage.load(forKey: nameKey),
                  let name = String(data: nameData, encoding: .utf8),
                  let birthdateData = try secureStorage.load(forKey: birthdateKey),
                  birthdateData.count == MemoryLayout<Double>.size else {
                return loadFromUserDefaultsFallback()
            }
            let timestamp = birthdateData.withUnsafeBytes { $0.load(as: Double.self) }
            let birthdate = Date(timeIntervalSince1970: timestamp)
            return Child(
                name: name,
                birthdate: birthdate,
                ageRange: AgeRange.from(birthdate: birthdate)
            )
        } catch {
            return loadFromUserDefaultsFallback()
        }
    }

    private static func loadFromUserDefaultsFallback() -> Child? {
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
