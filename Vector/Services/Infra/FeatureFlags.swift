//
//  FeatureFlags.swift
//  Vector
//
//  Created by Adam Zaatar on 8/21/25.
// File: Services/Infra/FeatureFlags.swift
//

import Foundation

/// Feature flags centralize opt-in behaviors for debug/experiments.
/// Keep flags additive, *not* removing code paths at compile time.
/// Use to gate optional or risky features, never for secrets/keys.
public struct FeatureFlags: Sendable, Equatable {
    // MARK: - Flags

    /// Allow screenshots / screen recording overlays (dev convenience).
    public var allowScreenshotsInDebug: Bool

    /// Enable CloudKit sync flows (can be toggled off in early development).
    public var enableCloudKitSync: Bool

    /// Show experimental UI (e.g., tag editing, color labels).
    public var showExperimentalTags: Bool

    /// Emit lightweight signposts/metrics.
    public var enableLightweightMetrics: Bool

    // MARK: - Factories

    public static func debugDefaults() -> FeatureFlags {
        FeatureFlags(
            allowScreenshotsInDebug: true,
            enableCloudKitSync: true,
            showExperimentalTags: true,
            enableLightweightMetrics: true
        )
    }

    public static func releaseDefaults() -> FeatureFlags {
        FeatureFlags(
            allowScreenshotsInDebug: false,
            enableCloudKitSync: true,
            showExperimentalTags: false,
            enableLightweightMetrics: false
        )
    }

    public static func previewDefaults() -> FeatureFlags {
        FeatureFlags(
            allowScreenshotsInDebug: true,
            enableCloudKitSync: false,
            showExperimentalTags: true,
            enableLightweightMetrics: false
        )
    }
}
