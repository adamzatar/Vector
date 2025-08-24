//
//  VaultStore.swift
//  Vector
//
//  Created by Adam Zaatar on 8/21/25.
//  File: Services/Vault/VaultStore.swift

import Foundation

/// Abstraction over the vault persistence layer.
/// V1 ships with an in‑memory actor; Phase 2 can swap to Core Data / SQLite (encrypted blobs).
public protocol VaultStore: Sendable {
    // Canonical API
    func listTokens() async throws -> [Token]
    func addToken(_ token: Token) async throws
    func updateToken(_ token: Token) async throws
    func deleteToken(id: UUID) async throws
}

// MARK: - V1 convenience names (keeps existing call sites compiling)

public extension VaultStore {
    /// Returns all tokens (V1 name).
    func list() async throws -> [Token] { try await listTokens() }

    /// Adds a token (V1 name).
    func add(_ token: Token) async throws { try await addToken(token) }

    /// Updates a token (V1 name).
    func update(_ token: Token) async throws { try await updateToken(token) }

    /// Deletes by id (V1 name).
    func delete(id: UUID) async throws { try await deleteToken(id: id) }

    /// Deletes by value convenience (handy in some UIs).
    func delete(_ token: Token) async throws { try await deleteToken(id: token.id) }
}

/// Simple in‑memory vault for development and previews.
/// Thread‑safe via actor isolation; not persisted across launches.
public actor InMemoryVaultStore: VaultStore {
    private var tokens: [UUID: Token] = [:]

    public init() {}

    // MARK: - Canonical API

    public func listTokens() async throws -> [Token] {
        tokens.values.sorted { $0.createdAt < $1.createdAt }
    }

    public func addToken(_ token: Token) async throws {
        tokens[token.id] = token
        // Post a single, stable change notification (keeps Notification names minimal and avoids mismatches).
        NotificationCenter.default.post(name: .vaultDidChange, object: nil)
    }

    public func updateToken(_ token: Token) async throws {
        guard tokens[token.id] != nil else { return }
        tokens[token.id] = token
        NotificationCenter.default.post(name: .vaultDidChange, object: nil)
    }

    public func deleteToken(id: UUID) async throws {
        guard tokens.removeValue(forKey: id) != nil else { return }
        NotificationCenter.default.post(name: .vaultDidChange, object: nil)
    }
}

// MARK: - Preview seeding

#if DEBUG
public extension InMemoryVaultStore {
    /// Seeds a couple of demo tokens for previews.
    func seedForPreview() async {
        let t1 = Token(
            issuer: .debug_fromPlaintext("GitHub"),
            account: .debug_fromPlaintext("ada@example.com"),
            secret: .debug_fromPlaintext("JBSWY3DPEHPK3PXP"),
            color: .blue,
            tags: ["work"]
        )
        let t2 = Token(
            issuer: .debug_fromPlaintext("Dropbox"),
            account: .debug_fromPlaintext("ada@example.com"),
            secret: .debug_fromPlaintext("GEZDGNBVGY3TQOJQ"),
            color: .orange,
            tags: ["personal"]
        )
        try? await addToken(t1)
        try? await addToken(t2)
    }
}
#endif
