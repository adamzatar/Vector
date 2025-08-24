//
//  Logger.swift
//  Vector
//
//  Created by Adam Zaatar on 8/21/25.
//
// File: Services/Infra/Logger.swift

import Foundation
import OSLog

/// Logging facade. Conforms to `Sendable` so it can be safely passed in DI under Swift 6.
public protocol Logging: Sendable {
    func debug(_ message: String)
    func info(_ message: String)
    func warn(_ message: String)
    func error(_ message: String)
}

// MARK: - Default Logger

/// Thin wrapper around `os.Logger`.
public struct DefaultLogger: Logging {
    private let log = Logger(subsystem: "com.vector.app", category: "app")
    public init() {}

    public func debug(_ message: String) { log.debug("\(message)") }
    public func info(_ message: String)  { log.info("\(message)") }
    public func warn(_ message: String)  { log.warning("\(message)") }
    public func error(_ message: String) { log.error("\(message)") }
}

// MARK: - Redacting Logger

/// Redacts obvious secrets by keyword before logging.
/// Useful for debugging without risk of leaking sensitive material.
public struct RedactingLogger: Logging {
    private let log = Logger(subsystem: "com.vector.app", category: "app")
    public init() {}

    @inline(__always)
    private func scrub(_ s: String) -> String {
        let lowered = s.lowercased()
        let sensitive = ["secret", "key", "cipher", "token", "pass", "iv"]
        return sensitive.contains(where: lowered.contains) ? "[REDACTED]" : s
    }

    public func debug(_ message: String) { log.debug("\(scrub(message))") }
    public func info(_ message: String)  { log.info("\(scrub(message))") }
    public func warn(_ message: String)  { log.warning("\(scrub(message))") }
    public func error(_ message: String) { log.error("\(scrub(message))") }
}
