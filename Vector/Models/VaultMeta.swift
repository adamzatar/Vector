//
//  VaultMeta.swift
//  Vector
//
//  Created by Adam Zaatar on 8/21/25.
//  File: Models/VaultMeta.swift
import Foundation

/// User‑tunable security and privacy settings kept alongside vault metadata.
/// These are **not secrets**, but avoid storing identifying info here.
public struct VaultSettings: Codable, Equatable, Sendable {
    /// Minutes of inactivity before auto‑lock engages (app will require biometrics/passcode).
    public var autoLockMinutes: Int
    /// Seconds before the copied OTP is cleared from the system pasteboard.
    public var clipboardTimeoutSec: Int

    public init(autoLockMinutes: Int = 5, clipboardTimeoutSec: Int = 20) {
        self.autoLockMinutes = autoLockMinutes
        self.clipboardTimeoutSec = clipboardTimeoutSec
    }
}

/// Metadata for a vault, including KDF configuration and the wrapped master key blob.
/// - Important: `keyWrapData` is the Secure Enclave–wrapped vault key (opaque bytes). It is **not** the key itself.
/// - Cloud: This struct can be serialized and stored in CloudKit as ciphertext (Phase 2).
public struct VaultMeta: Codable, Equatable, Sendable {
    /// Salt used for passphrase → master key derivation (KDF).
    public var kdfSalt: Data
    /// KDF parameters (iterations, memory/parallelism for scrypt/Argon2 if applicable).
    public var kdfParams: KDFParams
    /// Opaque blob returned by key wrapping (Secure Enclave or software fallback).
    /// Unwrapped with Face ID / device passcode at unlock.
    public var keyWrapData: Data
    /// Non‑secret user preferences related to security ergonomics (auto‑lock, clipboard).
    public var settings: VaultSettings

    public init(
        kdfSalt: Data,
        kdfParams: KDFParams,
        keyWrapData: Data,
        settings: VaultSettings = .init()
    ) {
        self.kdfSalt = kdfSalt
        self.kdfParams = kdfParams
        self.keyWrapData = keyWrapData
        self.settings = settings
    }
}

// MARK: - Convenience Factories (safe defaults)

public extension VaultMeta {
    /// Create a placeholder `VaultMeta` with random salts and empty wrap data.
    /// - Warning: Intended for scaffolding; real `keyWrapData` must be produced by Keychain/SE.
    static func placeholder() -> VaultMeta {
        let kdf = KDFParams.pbkdf2Default()
        return VaultMeta(kdfSalt: kdf.salt, kdfParams: kdf, keyWrapData: Data(), settings: .init())
    }
}
