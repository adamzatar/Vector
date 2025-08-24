//
//  AppError.swift
//  Vector
//
//  Created by Adam Zaatar on 8/21/25.
// File: Models/AppError.swift
import Foundation

/// Central application error type.
/// Use domain-specific cases rather than stringly-typed errors.
/// Conforms to `LocalizedError` for user-facing descriptions and `Sendable` for concurrency safety.
public enum AppError: Error, LocalizedError, Equatable, Sendable {
    // MARK: - Categories

    /// Validation or precondition failures (e.g., invalid Base32, missing fields).
    case validation(message: String)

    /// Authorization/biometric failures (Face ID canceled, not enrolled, etc.).
    case unauthorized(message: String = "Not authorized")

    /// Cryptographic operation failed (KDF, AES-GCM, key unwrap).
    case crypto(message: String)

    /// I/O failures (file read/write, persistence, keychain).
    case io(message: String)

    /// Network/sync failures (CloudKit, connectivity).
    case network(message: String)

    /// Item not found (by ID or query).
    case notFound

    /// A defensive “should never happen” guard triggered.
    case invariantViolation(message: String)

    /// Unknown or wrapped error from lower layers.
    case unknown(underlying: String? = nil)
}

// MARK: - LocalizedError

public extension AppError {
    var errorDescription: String? {
        switch self {
        case .validation(let message):
            return message // Localize

        case .unauthorized(let message):
            return message // Localize

        case .crypto(let message):
            return "Encryption error: \(message)" // Localize

        case .io(let message):
            return "Storage error: \(message)" // Localize

        case .network(let message):
            return "Network error: \(message)" // Localize

        case .notFound:
            return "Item not found." // Localize

        case .invariantViolation(let message):
            return "Internal invariant violated: \(message)" // Localize

        case .unknown(let underlying):
            if let u = underlying, !u.isEmpty {
                return "Unknown error: \(u)" // Localize
            } else {
                return "Unknown error." // Localize
            }
        }
    }
}

// MARK: - Helpers

public extension AppError {
    /// Wrap an arbitrary `Error` into `AppError`, preserving a concise description.
    static func wrap(_ error: any Error, fallback: AppError = .unknown()) -> AppError {
        if let app = error as? AppError { return app }
        // Avoid leaking sensitive info; truncate long descriptions.
        let descr = String(describing: error)
        let trimmed = descr.count > 200 ? String(descr.prefix(200)) + "…" : descr
        switch fallback {
        case .unknown:
            return .unknown(underlying: trimmed)
        default:
            return fallback
        }
    }

    /// Convenience guard that throws `.validation` when a condition fails.
    @inlinable
    static func require(_ condition: @autoclosure () -> Bool, _ message: String) throws {
        if !condition() { throw AppError.validation(message: message) }
    }
}
