//
//  ChildProfileStore.swift
//  Nurture
//
//  Persists Child profiles (supports multiple children). PII stored in Keychain via SecureStorage.
//

import Foundation

private enum StorageKey {
    static let childrenJSON = "childProfiles"
    static let selectedChildID = "selectedChildID"
    static let legacyNameKey = "childProfileName"
    static let legacyBirthdateKey = "childProfileBirthdate"
}

/// Saves and loads Child profiles. Supports multiple children. PII stored in Keychain.
enum ChildProfileStore {
    private static let secureStorage: SecureStorageProtocol = KeychainSecureStorage()

    // MARK: - Multi-Child API

    static func loadAll() -> [Child] {
        guard let data = try? secureStorage.load(forKey: StorageKey.childrenJSON),
              let decoded = try? JSONDecoder().decode([Child].self, from: data) else {
            return migrateFromLegacySingleChild()
        }
        return decoded
    }

    static func saveAll(_ children: [Child]) {
        guard let data = try? JSONEncoder().encode(children) else { return }
        try? secureStorage.save(data, forKey: StorageKey.childrenJSON)
        clearLegacyKeys()
    }

    static func add(_ child: Child) {
        var children = loadAll()
        if !children.contains(where: { $0.id == child.id }) {
            children.append(child)
            saveAll(children)
        }
    }

    static func update(_ child: Child) {
        var children = loadAll()
        if let idx = children.firstIndex(where: { $0.id == child.id }) {
            children[idx] = child
            saveAll(children)
        }
    }

    static func remove(childID: UUID) {
        let children = loadAll().filter { $0.id != childID }
        saveAll(children)
        if loadSelectedID() == childID {
            saveSelectedID(children.first?.id)
        }
    }

    // MARK: - Selected Child

    static func loadSelectedID() -> UUID? {
        guard let data = UserDefaults.standard.data(forKey: StorageKey.selectedChildID),
              data.count == MemoryLayout<uuid_t>.size else { return nil }
        return data.withUnsafeBytes { $0.load(as: UUID.self) }
    }

    static func saveSelectedID(_ id: UUID?) {
        guard let id = id else {
            UserDefaults.standard.removeObject(forKey: StorageKey.selectedChildID)
            return
        }
        withUnsafeBytes(of: id) { UserDefaults.standard.set(Data($0), forKey: StorageKey.selectedChildID) }
    }

    // MARK: - Legacy Single-Child (Migration & Backward Compatibility)

    /// Load single child for callers that expect the old API. Returns first child.
    static func load() -> Child? {
        loadAll().first
    }

    /// Save single child. Adds or updates; used during onboarding.
    static func save(_ child: Child) {
        var children = loadAll()
        if let idx = children.firstIndex(where: { $0.id == child.id }) {
            children[idx] = child
        } else {
            children.append(child)
        }
        saveAll(children)
        if loadSelectedID() == nil {
            saveSelectedID(child.id)
        }
    }

    // MARK: - Migration

    private static func migrateFromLegacySingleChild() -> [Child] {
        guard let legacy = loadLegacySingleChild() else { return [] }
        let children = [legacy]
        saveAll(children)
        saveSelectedID(legacy.id)
        clearLegacyKeys()
        return children
    }

    private static func loadLegacySingleChild() -> Child? {
        do {
            guard let nameData = try secureStorage.load(forKey: StorageKey.legacyNameKey),
                  let name = String(data: nameData, encoding: .utf8),
                  let birthdateData = try secureStorage.load(forKey: StorageKey.legacyBirthdateKey),
                  birthdateData.count == MemoryLayout<Double>.size else {
                return loadLegacyFromUserDefaults()
            }
            let timestamp = birthdateData.withUnsafeBytes { $0.load(as: Double.self) }
            let birthdate = Date(timeIntervalSince1970: timestamp)
            return Child(name: name, birthdate: birthdate, ageRange: AgeRange.from(birthdate: birthdate))
        } catch {
            return loadLegacyFromUserDefaults()
        }
    }

    private static func loadLegacyFromUserDefaults() -> Child? {
        guard let name = UserDefaults.standard.string(forKey: StorageKey.legacyNameKey),
              UserDefaults.standard.object(forKey: StorageKey.legacyBirthdateKey) != nil else {
            return nil
        }
        let timestamp = UserDefaults.standard.double(forKey: StorageKey.legacyBirthdateKey)
        let birthdate = Date(timeIntervalSince1970: timestamp)
        return Child(name: name, birthdate: birthdate, ageRange: AgeRange.from(birthdate: birthdate))
    }

    private static func clearLegacyKeys() {
        try? secureStorage.delete(forKey: StorageKey.legacyNameKey)
        try? secureStorage.delete(forKey: StorageKey.legacyBirthdateKey)
        UserDefaults.standard.removeObject(forKey: StorageKey.legacyNameKey)
        UserDefaults.standard.removeObject(forKey: StorageKey.legacyBirthdateKey)
    }

    static func clear() {
        try? secureStorage.delete(forKey: StorageKey.childrenJSON)
        UserDefaults.standard.removeObject(forKey: StorageKey.selectedChildID)
        clearLegacyKeys()
    }
}
