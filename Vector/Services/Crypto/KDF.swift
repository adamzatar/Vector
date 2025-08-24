//
//  KDF.swift
//  Vector
//
//  Created by Adam Zaatar on 8/21/25.
//  File: Services/Crypto/KDF.swift
//


import Foundation
import CryptoKit
import Security


/// Errors thrown by the KDF functions.
public enum KDFError: Error, Sendable {
    case invalidLength
}

/// Supported key‑derivation algorithms (expandable in Phase 2).
public enum KDFAlgorithm: String, Codable, Sendable {
    /// HKDF using HMAC‑SHA256 (portable, dependency‑free stand‑in for PBKDF2 in V1).
    /// Phase 2 can switch/add PBKDF2/scrypt/Argon2 without touching call sites.
    case hkdf_sha256
    case pbkdf2_sha256 // reserved for Phase 2 (CommonCrypto)
    case scrypt        // reserved for Phase 2
}

/// Parameters needed to derive a vault/master key.
/// This unified definition is used across Crypto and VaultMeta.
public struct KDFParams: Codable, Equatable, Sendable {
    public var algorithm: KDFAlgorithm
    /// Random salt (16–32 bytes recommended). Must be unique per vault.
    public var salt: Data
    /// Iteration count semantics are algorithm‑dependent.
    /// For HKDF this is ignored; kept for schema stability.
    public var iterations: Int
    /// Desired key length in bytes (e.g., 32 for 256‑bit).
    public var outputLength: Int
    /// Optional memory parameter for scrypt/Argon2 (MiB). Ignored for HKDF/PBKDF2.
    public var memoryMB: Int?
    /// Optional parallelism parameter for scrypt/Argon2. Ignored for HKDF/PBKDF2.
    public var parallelism: Int?

    public init(
        algorithm: KDFAlgorithm = .hkdf_sha256,
        salt: Data,
        iterations: Int = 150_000,
        outputLength: Int = 32,
        memoryMB: Int? = nil,
        parallelism: Int? = nil
    ) {
        self.algorithm = algorithm
        self.salt = salt
        self.iterations = iterations
        self.outputLength = outputLength
        self.memoryMB = memoryMB
        self.parallelism = parallelism
    }
}

/// Protocol façade for KDF so we can swap implementations without touching callers.
public protocol KDF: Sendable {
    /// Derives a key from a UTF‑8 passphrase and parameters.
    func deriveKey(passphrase: String, params: KDFParams) throws -> Data
}

/// Default implementation using CryptoKit HKDF‑SHA256.
/// - Note: Temporary stand‑in for PBKDF2/scrypt to avoid CommonCrypto bridging in V1.
public struct DefaultKDF: KDF {
    public init() {}

    public func deriveKey(passphrase: String, params: KDFParams) throws -> Data {
        guard params.outputLength > 0 else { throw KDFError.invalidLength }

        switch params.algorithm {
        case .hkdf_sha256:
            // Correct CryptoKit signature expects `salt` and `info` as Data (not SymmetricKey).
            let ikm = SymmetricKey(data: Data(passphrase.utf8))
            let derived = HKDF<SHA256>.deriveKey(
                inputKeyMaterial: ikm,
                salt: params.salt,
                info: Data("Vector.KDF".utf8), // domain separation; safe to change later
                outputByteCount: params.outputLength
            )
            return derived.withUnsafeBytes { Data($0) }

        case .pbkdf2_sha256, .scrypt:
            // Phase 2: implement PBKDF2 via CommonCrypto and scrypt via a safe binding.
            throw KDFError.invalidLength
        }
    }
}

// MARK: - Factories & Helpers

public extension KDFParams {
    /// Opinionated defaults (schema‑compatible with a future PBKDF2 switch).
    static func pbkdf2Default(
        saltLength: Int = 16,
        iterations: Int = 200_000,
        outputLength: Int = 32
    ) -> KDFParams {
        KDFParams(
            algorithm: .hkdf_sha256, // swap to .pbkdf2_sha256 in Phase 2
            salt: .randomSalt(saltLength),
            iterations: iterations,
            outputLength: outputLength
        )
    }
}

public extension Data {
    /// Generates cryptographically secure random bytes (salt).
    static func randomSalt(_ count: Int = 16) -> Data {
        var bytes = [UInt8](repeating: 0, count: count)
        let status = SecRandomCopyBytes(kSecRandomDefault, count, &bytes)
        precondition(status == errSecSuccess, "Failed to generate random bytes")
        return Data(bytes)
    }
}
