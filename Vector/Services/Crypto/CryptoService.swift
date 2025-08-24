//
//  CryptoService.swift
//  Vector
//
//  Created by Adam Zaatar on 8/21/25.
//  File: Services/Crypto/CryptoService.swift

import Foundation

/// Symmetric crypto service surface for Vector.
/// Phase 2 will provide real AES‑GCM; V1 ships a no‑op placeholder so the app builds/runs.
///
/// - Important: Never log plaintext, ciphertext, or keys. This API is intentionally minimal.
/// - Parameters:
///   - plaintext/ciphertext: raw bytes
///   - key: derived vault key bytes
///   - aad: additional authenticated data (optional domain/context tag)
public protocol CryptoService: Sendable {
    func encrypt(_ plaintext: Data, key: Data, aad: Data?) throws -> Data
    func decrypt(_ ciphertext: Data, key: Data, aad: Data?) throws -> Data
}

/// Temporary no‑op crypto so the app compiles in V1 scaffolding.
/// DO NOT SHIP to production; replace with AES‑GCM in Phase 2.
public struct NoopCryptoService: CryptoService {
    public init() {}

    public func encrypt(_ plaintext: Data, key: Data, aad: Data?) throws -> Data {
        // DEV ONLY: identity transform
        plaintext
    }

    public func decrypt(_ ciphertext: Data, key: Data, aad: Data?) throws -> Data {
        // DEV ONLY: identity transform
        ciphertext
    }
}
