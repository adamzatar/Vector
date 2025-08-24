//
//  KeychainStore.swift
//  Vector
//
//  Created by Adam Zaatar on 8/21/25.
//  File: Services/Keychain/KeychainStore.swift
//

import Foundation
import Security

/// Async interface for secure key storage.
/// Backed by Keychain, wrapped in an actor to avoid race conditions.
public protocol KeychainStore: Sendable {
    func save(key: String, data: Data) async throws
    func load(key: String) async throws -> Data?
    func delete(key: String) async throws
}

// MARK: - Default Implementation

/// Default Keychain implementation.
/// - Security: uses `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`.
///   This means data is only available after the first unlock and never synced to iCloud.
public actor DefaultKeychainStore: KeychainStore {
    public init() {}

    public func save(key: String, data: Data) async throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        // Remove old if exists
        SecItemDelete(query as CFDictionary)

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.osStatus(status)
        }
    }

    public func load(key: String) async throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var out: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &out)

        if status == errSecItemNotFound {
            return nil
        }
        guard status == errSecSuccess, let data = out as? Data else {
            throw KeychainError.osStatus(status)
        }
        return data
    }

    public func delete(key: String) async throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.osStatus(status)
        }
    }

    // MARK: - Errors
    public enum KeychainError: Error {
        case osStatus(OSStatus)
    }
}
