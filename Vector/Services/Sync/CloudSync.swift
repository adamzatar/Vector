//
//  CloudSync.swift
//  Vector
//
//  Created by Adam Zaatar on 8/21/25.
// File: Services/Sync/CloudSync.swift
//

import Foundation

/// Result of a sync operation.
public struct CloudSyncResult: Equatable, Sendable {
    /// Number of records pushed to the cloud.
    public let pushed: Int
    /// Number of records pulled from the cloud.
    public let pulled: Int

    public init(pushed: Int, pulled: Int) {
        self.pushed = pushed
        self.pulled = pulled
    }
}

/// Protocol for end‑to‑end encrypted sync over CloudKit (Private DB).
/// V1 ships a no‑op implementation; Phase 2 will push/pull encrypted blobs.
public protocol CloudSync: Sendable {
    /// Push local changes to the cloud and return counts.
    func push() async throws -> CloudSyncResult
    /// Pull remote changes from the cloud and return counts.
    func pull() async throws -> CloudSyncResult
}

// MARK: - Default (No‑Op) Implementation

/// Default no‑op implementation used in early scaffolding.
/// Keeps API stable while we finalize schemas & encryption.
public struct DefaultCloudSync: CloudSync {
    private let logger: any Logging

    public init(logger: any Logging = RedactingLogger()) {
        self.logger = logger
    }

    public func push() async throws -> CloudSyncResult {
        logger.info("CloudSync.push (no‑op)")
        return CloudSyncResult(pushed: 0, pulled: 0)
    }

    public func pull() async throws -> CloudSyncResult {
        logger.info("CloudSync.pull (no‑op)")
        return CloudSyncResult(pushed: 0, pulled: 0)
    }
}

// MARK: - Mock (Previews/Tests)

/// Mock implementation for previews/tests. Configure counts to simulate activity.
public struct MockCloudSync: CloudSync {
    public var nextPush: CloudSyncResult
    public var nextPull: CloudSyncResult

    public init(nextPush: CloudSyncResult = .init(pushed: 0, pulled: 0),
                nextPull: CloudSyncResult = .init(pushed: 0, pulled: 0)) {
        self.nextPush = nextPush
        self.nextPull = nextPull
    }

    public func push() async throws -> CloudSyncResult { nextPush }
    public func pull() async throws -> CloudSyncResult { nextPull }
}
