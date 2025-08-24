//
//  Notifications.swift
//  Vector
//
//  Created by Adam Zaatar on 8/21/25.
//
// File: App/Notifications.swift

import Foundation

/// Centralized notification names and tiny helpers.
/// Keep all `Notification.Name` definitions here to avoid duplication across the app.
/// Usage:
/// ```swift
/// NotificationCenter.default.post(name: AppNotification.appDidLock, object: nil)
/// NotificationCenter.default.post(name: AppNotification.clipboardShouldClear, object: nil, userInfo: [AppNotification.Key.timeoutSec: 20])
/// ```
/// Observing:
/// ```swift
/// NotificationCenter.default.addObserver(forName: AppNotification.clipboardShouldClear, object: nil, queue: .main) { note in
///     let timeout = note.userInfo?[AppNotification.Key.timeoutSec] as? Int ?? 20
///     // handle…
/// }
/// ```
enum AppNotification {
    /// Well-known notification names used across features and services.
    enum Name {
        /// Post when the app should lock (e.g., backgrounded or inactivity timeout).
        static let appDidLock = Notification.Name("vector.appDidLock")

        /// Post to request clipboard clearing after a given timeout (seconds).
        /// Include `Key.timeoutSec` in userInfo for clarity.
        static let clipboardShouldClear = Notification.Name("vector.clipboardShouldClear")

        /// Post when the vault contents changed (add/update/delete), prompting UIs to refresh.
        /// Optionally include `Key.changedTokenID: UUID`.
        static let vaultDidChange = Notification.Name("vector.vaultDidChange")

        /// Post to indicate sync state updates (started/completed/failed).
        /// Include `Key.syncEvent: SyncEvent`.
        static let syncStateDidChange = Notification.Name("vector.syncStateDidChange")
    }

    /// Strongly-typed userInfo keys to avoid stringly-typed mistakes.
    enum Key {
        /// Int seconds for clipboard auto-clear.
        static let timeoutSec = "timeoutSec"

        /// Affected token ID (UUID).
        static let changedTokenID = "changedTokenID"

        /// Sync event payload.
        static let syncEvent = "syncEvent"
    }

    /// Lightweight sync state payload published with `syncStateDidChange`.
    enum SyncEvent: Equatable {
        case started
        case completed
        case failed(errorDescription: String)
    }
}

// MARK: - Convenience Aliases

extension Notification.Name {
    /// Convenience aliases so call-sites can write `.appDidLock` without long prefixes.
    static let appDidLock = AppNotification.Name.appDidLock
    static let clipboardShouldClear = AppNotification.Name.clipboardShouldClear
    static let vaultDidChange = AppNotification.Name.vaultDidChange
    static let syncStateDidChange = AppNotification.Name.syncStateDidChange
}
