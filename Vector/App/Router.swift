//
//  Router.swift
//  Vector
//
//  Created by Adam Zaatar on 8/21/25.
//
// File: App/Router.swift

import Foundation
import Foundation
import SwiftUI

/// Top-level destinations for the app.
/// Keep cases human-readable and feature-oriented.
/// Add new cases sparingly to avoid route sprawl.
enum Route: Equatable {
    case splash
    case intro
    case vault
    case addToken
    case settings
}

/// Centralized, state-first router used by SwiftUI views via `@EnvironmentObject`.
/// - Note: `@MainActor` ensures UI updates publish on the main thread.
/// - Future: If we adopt NavigationStack paths or tabbed roots, we can
///   extend this router with a typed path while preserving the same API.
@MainActor
final class AppRouter: ObservableObject {
    // MARK: - Published State

    /// The current top-level destination.
    @Published private(set) var route: Route = .splash

    /// Optional sheet routing if/when we introduce modal flows.
    /// Keeping this internal until a sheet use-case arrives.
    @Published private(set) var sheet: SheetRoute?

    // MARK: - Navigation API (explicit intent)

    /// Navigate to a new top-level route.
    func go(_ newRoute: Route) {
        route = newRoute
    }

    /// Return to the primary screen (Vault). Prefer this over hard-coding `.vault`.
    func goHome() {
        route = .vault
    }

    func showIntro()      { route = .intro }
    func showVault()      { route = .vault }
    func showAddToken()   { route = .addToken }
    func showSettings()   { route = .settings }

    // MARK: - Sheet Routing (non-disruptive scaffold)

    /// Present a modal sheet.
    func present(_ sheet: SheetRoute) {
        self.sheet = sheet
    }

    /// Dismiss the currently presented sheet, if any.
    func dismissSheet() {
        self.sheet = nil
    }

    // MARK: - Future: Deep Link Handling
    // We can map incoming URLs or user activities to Route/SheetRoute here.
    // Keeping the signature private until we finalize a deep link format.
    // func handle(url: URL) { ... }
}

/// Modal destinations (scaffolded for future use).
/// Keep separate from `Route` to avoid mixing modal and primary navigation.
enum SheetRoute: Equatable {
    case none // placeholder to demonstrate pattern; prefer using `nil` instead
}
