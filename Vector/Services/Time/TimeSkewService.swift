//
//  TimeSkewService.swift
//  Vector
//
//  Created by Adam Zaatar on 8/21/25.
//  File: Services/Time/TimeSkewService.swift
//

import Foundation

/// Service for handling time skew between device clock and trusted time sources.
/// Used to keep TOTP windows consistent even if device is slightly off.
/// V1: local only. Phase 2 may add NTP/Cloud sync sources.
public protocol TimeSkewServicing: Sendable {
    /// Returns the current corrected date (system date + skew offset).
    func now() async -> Date
    /// Updates the local skew offset (e.g., from NTP or Cloud sync).
    func updateSkew(offset: TimeInterval) async
    /// Returns the current skew value in seconds (positive = device is ahead).
    func currentSkew() async -> TimeInterval
}

/// Default implementation that applies a simple additive offset.
/// Actor keeps mutable state safe across threads.
public actor TimeSkewService: TimeSkewServicing {
    private var skewSeconds: TimeInterval = 0

    public init() {}

    public func now() async -> Date {
        Date().addingTimeInterval(skewSeconds)
    }

    public func updateSkew(offset: TimeInterval) async {
        skewSeconds = offset
    }

    public func currentSkew() async -> TimeInterval {
        skewSeconds
    }
}

// MARK: - Preview / Mock

#if DEBUG
/// Mock implementation for testing and previews.
public actor MockTimeSkewService: TimeSkewServicing {
    private var skewSeconds: TimeInterval = 0
    private let fixedNow: Date

    public init(fixedNow: Date = Date(timeIntervalSince1970: 1_700_000_000)) {
        self.fixedNow = fixedNow
    }

    public func now() async -> Date { fixedNow.addingTimeInterval(skewSeconds) }
    public func updateSkew(offset: TimeInterval) async { skewSeconds = offset }
    public func currentSkew() async -> TimeInterval { skewSeconds }
}
#endif
