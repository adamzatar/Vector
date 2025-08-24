//
//  Token.swift
//  Vector
//
//  Created by Adam Zaatar on 8/21/25.
//  File: Models/Token.swift
//

import Foundation

// MARK: - Ciphertext

/// Opaque encrypted payload container.
/// In V1 scaffolding this is just raw `Data`. In Phase 2 it will carry AES‑GCM ciphertext bytes
/// and (optionally) an authenticated metadata header.
/// - Important: Never convert this to `String` in production code. Avoid logging.
public struct Ciphertext: Equatable, Hashable, Sendable, Codable {
    public let data: Data

    public init(data: Data) { self.data = data }

    // Custom Codable to keep the door open for future headers/format versions.
    // For now we simply encode the raw bytes (base64 in JSON).
    public init(from decoder: any Decoder) throws {
        let c = try decoder.singleValueContainer()
        self.data = try c.decode(Data.self)
    }
    public func encode(to encoder: any Encoder) throws {
        var c = encoder.singleValueContainer()
        try c.encode(data)
    }
}

#if DEBUG
public extension Ciphertext {
    /// DEV‑ONLY helper to construct mock ciphertext from a debug string.
    /// - Warning: Do not call in production paths.
    static func debug_fromPlaintext(_ s: String) -> Ciphertext { .init(data: Data(s.utf8)) }

    /// DEV‑ONLY helper to peek plaintext from mock ciphertext.
    /// - Warning: Do not call in production paths.
    var debug_plaintextString: String { String(decoding: data, as: UTF8.self) }
}
#endif

// MARK: - Enums

/// Supported HMAC algorithms for TOTP generation (RFC 6238).
public enum OTPAlgorithm: String, CaseIterable, Codable, Sendable, Identifiable {
    case sha1 = "SHA1"
    case sha256 = "SHA256"
    case sha512 = "SHA512"
    public var id: String { rawValue }
}

/// Optional per‑token color label used for quick visual grouping in the list.
/// Stored as a lightweight, codable enum so it’s stable across platforms.
public enum TokenColor: String, CaseIterable, Codable, Sendable, Identifiable {
    case blue
    case orange
    case green
    case purple
    case gray

    public var id: String { rawValue }
}

// MARK: - Model

/// Primary data model for a TOTP credential.
/// - Note: `issuer`, `account`, and `secret` are encrypted (`Ciphertext`).
/// - Decision V1: `tags` are cleartext for simple local search/sort. We can add
///   an opt‑in "Private Tags" mode later by switching to `[Ciphertext]`.
public struct Token: Identifiable, Equatable, Codable, Sendable {
    // Identity
    public var id: UUID

    // Encrypted fields
    public var issuer: Ciphertext
    public var account: Ciphertext
    public var secret: Ciphertext

    // OTP parameters
    public var algo: OTPAlgorithm             // default .sha1
    public var digits: Int                    // default 6
    public var period: Int                    // default 30 (seconds)

    // Presentation
    public var color: TokenColor?             // optional label color
    public var tags: [String]                 // cleartext in V1

    // Audit
    public var createdAt: Date
    public var lastUsedAt: Date?

    // Init
    public init(
        id: UUID = UUID(),
        issuer: Ciphertext,
        account: Ciphertext,
        secret: Ciphertext,
        algo: OTPAlgorithm = .sha1,
        digits: Int = 6,
        period: Int = 30,
        color: TokenColor? = nil,
        tags: [String] = [],
        createdAt: Date = .init(),
        lastUsedAt: Date? = nil
    ) {
        self.id = id
        self.issuer = issuer
        self.account = account
        self.secret = secret
        self.algo = algo
        self.digits = digits
        self.period = period
        self.color = color
        self.tags = tags
        self.createdAt = createdAt
        self.lastUsedAt = lastUsedAt
    }
}

// MARK: - Convenience (Non‑Persisted Display Helpers)

public extension Token {
    /// Returns a stable, non‑secret fingerprint suitable for lightweight local diffing.
    /// - Important: This is **not** a cryptographic hash; do not use for security decisions.
    var localFingerprint: String {
        "\(id.uuidString.prefix(8))-\(algo.rawValue)-\(digits)-\(period)"
    }
}

#if canImport(SwiftUI)
import SwiftUI

public extension TokenColor {
    /// Maps `TokenColor` to a system color. Keep palette accessible (sufficient contrast).
    var color: Color {
        switch self {
        case .blue:   return .blue
        case .orange: return .orange
        case .green:  return .green
        case .purple: return .purple
        case .gray:   return .gray
        }
    }
}
#endif
