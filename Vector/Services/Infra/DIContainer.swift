//
//  DIContainer.swift
//  Vector
//
//  Created by Adam Zaatar on 8/21/25.
//
//  File: Services/Infra/DIContainer.swift
//

import Foundation
import SwiftUI

/// Dependency injection container passed through the SwiftUI environment.
/// Keep this lightweight and free of heavy state. Long-lived state should live
/// inside each service (actors/singletons) rather than in this struct.
public struct DIContainer: @unchecked Sendable {
    // Core services
    public let logger: any Logging
    public let featureFlags: FeatureFlags

    // Domain services
    public let vault: any VaultStore
    public let cloudSync: any CloudSync
    public let crypto: any CryptoService
    public let kdf: any KDF
    public let keychain: any KeychainStore
    public let timeSkew: any TimeSkewServicing

    // Monetization & telemetry
    public let entitlements: any EntitlementsService
    public let metrics: any Metrics

    // MARK: - Init

    public init(
        logger: any Logging,
        featureFlags: FeatureFlags,
        vault: any VaultStore,
        cloudSync: any CloudSync,
        crypto: any CryptoService,
        kdf: any KDF,
        keychain: any KeychainStore,
        timeSkew: any TimeSkewServicing,
        entitlements: any EntitlementsService,
        metrics: any Metrics
    ) {
        self.logger = logger
        self.featureFlags = featureFlags
        self.vault = vault
        self.cloudSync = cloudSync
        self.crypto = crypto
        self.kdf = kdf
        self.keychain = keychain
        self.timeSkew = timeSkew
        self.entitlements = entitlements
        self.metrics = metrics
    }
}

// MARK: - Factories

public extension DIContainer {
    /// Production/default wiring. Keep fast for cold launch.
    static func makeDefault() -> DIContainer {
        // Logger
        let logger: any Logging = RedactingLogger()

        // Feature flags (adjust per build config)
        let flags = FeatureFlags(
            allowScreenshotsInDebug: false,
            enableCloudKitSync: false,         // flip on when CloudKit is wired
            showExperimentalTags: false,
            enableLightweightMetrics: true
        )

        // Services
        let vault = InMemoryVaultStore()
        let kdf: any KDF = DefaultKDF()
        let crypto: any CryptoService = NoopCryptoService()              // Phase 2: real AES-GCM
        let keychain: any KeychainStore = DefaultKeychainStore()
        let timeSkew: any TimeSkewServicing = TimeSkewService()
        let cloud: any CloudSync = CloudSyncStub(logger: logger)

        // Monetization & telemetry
        let entitlements: any EntitlementsService = StoreKitEntitlements()
        let metrics: any Metrics = LocalMetrics()

        return DIContainer(
            logger: logger,
            featureFlags: flags,
            vault: vault,
            cloudSync: cloud,
            crypto: crypto,
            kdf: kdf,
            keychain: keychain,
            timeSkew: timeSkew,
            entitlements: entitlements,
            metrics: metrics
        )
    }

    /// Preview/dev wiring with friendlier defaults and seeded data.
    static func makePreview() -> DIContainer {
        let logger: any Logging = RedactingLogger()
        let flags = FeatureFlags(
            allowScreenshotsInDebug: true,
            enableCloudKitSync: false,
            showExperimentalTags: true,
            enableLightweightMetrics: false
        )

        let vault = InMemoryVaultStore()
        let kdf: any KDF = DefaultKDF()
        let crypto: any CryptoService = NoopCryptoService()
        let keychain: any KeychainStore = DefaultKeychainStore()
        let timeSkew: any TimeSkewServicing = TimeSkewService()
        let cloud: any CloudSync = CloudSyncStub(logger: logger)

        let entitlements: any EntitlementsService = StoreKitEntitlements()
        let metrics: any Metrics = LocalMetrics()

        // Seed a couple of tokens for previews
        Task { await vault.seedForPreview() }

        return DIContainer(
            logger: logger,
            featureFlags: flags,
            vault: vault,
            cloudSync: cloud,
            crypto: crypto,
            kdf: kdf,
            keychain: keychain,
            timeSkew: timeSkew,
            entitlements: entitlements,
            metrics: metrics
        )
    }
}

// MARK: - SwiftUI Environment

private struct DIContainerKey: EnvironmentKey {
    static let defaultValue: DIContainer = .makeDefault()
}

public extension EnvironmentValues {
    var di: DIContainer {
        get { self[DIContainerKey.self] }
        set { self[DIContainerKey.self] = newValue }
    }
}

public extension View {
    /// Convenience for previews/tests:
    /// `.environment(\.di, DIContainer.makePreview())`
    func di(_ container: DIContainer) -> some View {
        environment(\.di, container)
    }
}

// MARK: - Local placeholders (scoped to DI to avoid symbol clashes)

/// Lightweight CloudSync stub to satisfy DI in V1.
/// Matches `CloudSyncResult(pushed:pulled:)` shape from Services/Sync/CloudSync.swift.
private final class CloudSyncStub: CloudSync {
    private let logger: any Logging
    init(logger: any Logging) { self.logger = logger }

    func push() async -> CloudSyncResult {
        logger.debug("CloudSyncStub.push()")
        return CloudSyncResult(pushed: 0, pulled: 0)
    }

    func pull() async -> CloudSyncResult {
        logger.debug("CloudSyncStub.pull()")
        return CloudSyncResult(pushed: 0, pulled: 0)
    }
}
