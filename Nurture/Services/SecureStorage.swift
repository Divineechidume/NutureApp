//
//  SecureStorage.swift
//  Nurture
//
//  Secure storage for PII and sensitive data. Architectural plan - security-first.
//  Use Keychain instead of UserDefaults for child name, birthdate, BLE identifiers.
//

import Foundation

/// Protocol for secure storage of sensitive data.
/// Use Keychain implementation for production; mock for tests.
protocol SecureStorageProtocol {
    func save(_ data: Data, forKey key: String) throws
    func load(forKey key: String) throws -> Data?
    func delete(forKey key: String) throws
}

/// Keychain-backed secure storage.
final class KeychainSecureStorage: SecureStorageProtocol {
    private let service = Bundle.main.bundleIdentifier ?? "com.nurture.app"

    func save(_ data: Data, forKey key: String) throws {
        try delete(forKey: key)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw SecureStorageError.saveFailed(status)
        }
    }

    func load(forKey key: String) throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess else {
            throw SecureStorageError.loadFailed(status)
        }
        return result as? Data
    }

    func delete(forKey key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}

enum SecureStorageError: Error {
    case saveFailed(OSStatus)
    case loadFailed(OSStatus)
}
