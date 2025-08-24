//
//  VaultViewModel.swift
//  Vector
//
//  Created by Adam Zaatar on 8/21/25.
//  File: Features/Vault/VaultViewModel.swift
//


import Foundation
import SwiftUI
import Combine
@preconcurrency import UIKit

/// ViewModel for the Vault list screen.
/// Owns only UI state; all I/O (store/sync) happens off‑main and publishes back to UI.
/// - Note: OTP generation lands in Phase 2. For now we handle listing, search, copy (placeholder),
///         and a 1s tick that drives the time ring UI.
@MainActor
final class VaultViewModel: ObservableObject {
    // MARK: - Published UI State
    @Published private(set) var tokens: [Token] = []
    @Published var query: String = ""
    @Published var selectedTag: String?
    @Published private(set) var now: Date = .init()
    @Published private(set) var isLoading: Bool = false
    @Published var errorMessage: String?

    // MARK: - Settings (persisted)
    @AppStorage("clipboardTimeoutSec") private var clipboardTimeoutSec: Int = 20

    // MARK: - Deps
    private let vault: any VaultStore
    private let sync: any CloudSync
    private let logger: any Logging

    // MARK: - Lifecycle
    private var tickTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init
    init(container: DIContainer) {
        self.vault = container.vault
        self.sync = container.cloudSync
        self.logger = container.logger

        // Observe a single stable change signal via Combine (no Obj‑C observer storage).
        NotificationCenter.default.publisher(for: .vaultDidChange)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                Task { [weak self] in
                    await self?.reload(reason: "vaultDidChange")
                }
            }
            .store(in: &cancellables)

        startTicking()
    }

    deinit {
        tickTask?.cancel()
        // No explicit cleanup needed for Combine — AnyCancellable dealloc cancels.
    }

    // MARK: - Public API

    func onAppear() {
        Task { await initialLoadIfNeeded() }
    }

    var filteredTokens: [Token] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let selectedTagLower = selectedTag?.lowercased()

        let byText: (Token) -> Bool = { [q] t in
            guard !q.isEmpty else { return true }
            let issuer = self.displayIssuer(t).lowercased()
            let account = self.displayAccount(t).lowercased()
            let tags = t.tags.map { $0.lowercased() }
            return issuer.contains(q) || account.contains(q) || tags.contains(where: { $0.contains(q) })
        }

        let byTag: (Token) -> Bool = { [selectedTagLower] t in
            guard let tag = selectedTagLower, !tag.isEmpty else { return true }
            return t.tags.map { $0.lowercased() }.contains(tag)
        }

        return tokens
            .filter { byText($0) && byTag($0) }
            .sorted { lhs, rhs in
                let li = self.displayIssuer(lhs)
                let ri = self.displayIssuer(rhs)
                if li != ri {
                    return li.localizedCaseInsensitiveCompare(ri) == .orderedAscending
                }
                let la = self.displayAccount(lhs)
                let ra = self.displayAccount(rhs)
                return la.localizedCaseInsensitiveCompare(ra) == .orderedAscending
            }
    }

    func secondsRemaining(for token: Token) -> Int {
        let period = max(1, token.period)
        let epoch = Int(now.timeIntervalSince1970)
        let sec = epoch % period
        return period - sec
    }

    func windowProgress(for token: Token) -> Double {
        let period = max(1, token.period)
        let elapsed = period - secondsRemaining(for: token)
        return Double(elapsed) / Double(period)
    }

    /// Copy the current OTP code to the clipboard (placeholder).
    func copyCode(for token: Token) {
        let placeholder = "••••••"
        UIPasteboard.general.string = placeholder

        let gen = UINotificationFeedbackGenerator()
        gen.notificationOccurred(.success)

        NotificationCenter.default.post(
            name: .clipboardShouldClear,
            object: nil,
            userInfo: [AppNotification.Key.timeoutSec: clipboardTimeoutSec]
        )

        Task.detached { [weak self] in
            guard let self else { return }
            do {
                var updated = token
                updated.lastUsedAt = Date()
                try await self.vault.update(updated) // throws
            } catch {
                self.logger.warn("Failed to update lastUsedAt for token \(token.id)")
            }
        }
    }

    /// Pull remote changes (handle throwing sync surfaces).
    func pullFromCloud() {
        Task { [weak self] in
            guard let self else { return }
            do {
                _ = try await self.sync.pull()          // may throw per your protocol; handle here
            } catch {
                self.logger.warn("Cloud pull failed: \(error)")
            }
            await self.reload(reason: "sync.pull")
        }
    }

    /// Push local changes (handle throwing sync surfaces).
    func pushToCloud() {
        Task { [weak self] in
            guard let self else { return }
            do {
                _ = try await self.sync.push()          // may throw; handle
            } catch {
                self.logger.warn("Cloud push failed: \(error)")
            }
            await self.reload(reason: "sync.push")
        }
    }

    func clearFilters() {
        query = ""
        selectedTag = nil
    }

    // MARK: - Display helpers

    func displayIssuer(_ token: Token) -> String {
        #if DEBUG
        token.issuer.debug_plaintextString
        #else
        "Encrypted" // Localize
        #endif
    }

    func displayAccount(_ token: Token) -> String {
        #if DEBUG
        token.account.debug_plaintextString
        #else
        "Hidden" // Localize
        #endif
    }

    // MARK: - Private

    private func initialLoadIfNeeded() async {
        if tokens.isEmpty {
            await reload(reason: "initial")
            #if DEBUG
            if tokens.isEmpty {
                await seedMocks()
                await reload(reason: "seed")
            }
            #endif
        }
    }

    private func reload(reason: String) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let list = try await vault.list() // throws
            self.tokens = list
        } catch {
            self.errorMessage = AppError.wrap(error).localizedDescription
            logger.error("Vault reload failed (\(reason)) — \(self.errorMessage ?? "n/a")")
        }
    }

    private func startTicking() {
        tickTask?.cancel()
        tickTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                self.now = Date()
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1s
            }
        }
    }

    #if DEBUG
    private func seedMocks() async {
        let now = Date()
        let mocks: [Token] = [
            Token(
                issuer: .debug_fromPlaintext("GitHub"),
                account: .debug_fromPlaintext("you@example.com"),
                secret: .debug_fromPlaintext("JBSWY3DPEHPK3PXP"),
                algo: .sha1, digits: 6, period: 30,
                color: .blue, tags: ["dev","work"],
                createdAt: now.addingTimeInterval(-3600)
            ),
            Token(
                issuer: .debug_fromPlaintext("Cloudflare"),
                account: .debug_fromPlaintext("ops@company.com"),
                secret: .debug_fromPlaintext("MFRGGZDFMZTWQ2LK"),
                algo: .sha1, digits: 6, period: 30,
                color: .orange, tags: ["infra"],
                createdAt: now.addingTimeInterval(-1800)
            )
        ]
        do {
            for m in mocks {
                try await vault.add(m) // throws
            }
        } catch {
            logger.warn("Mock seeding failed: \(error)")
        }
    }
    #endif
}
