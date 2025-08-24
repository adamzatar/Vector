//
//  Entitlements.swift
//  Vector
//
//  Created by Vector Build System on 8/23/25.
//  File: Services/Infra/Entitlements.swift
//

import Foundation
import StoreKit

public protocol EntitlementsService: Sendable {
    var isPro: Bool { get async }
    func loadProducts() async throws -> (monthly: Product?, lifetime: Product?)
    func purchase(_ product: Product) async throws -> Bool
    func restore() async throws -> Bool
}

public actor StoreKitEntitlements: EntitlementsService {
    private let ids: Set<String> = ["pro.monthly", "pro.lifetime"]
    private var purchased: Set<String> = []
    private var cache: [String: Product] = [:]

    public init() {
        Task { await refreshFromCurrentEntitlements() }
        Task { await listenForTransactionUpdates() }
    }

    public var isPro: Bool { !purchased.isEmpty }

    public func loadProducts() async throws -> (monthly: Product?, lifetime: Product?) {
        if cache.isEmpty {
            let products = try await Product.products(for: Array(ids))
            for p in products { cache[p.id] = p }
        }
        return (cache["pro.monthly"], cache["pro.lifetime"])
    }

    public func purchase(_ product: Product) async throws -> Bool {
        let result = try await product.purchase()
        switch result {
        case .success(let v):
            if case .verified(let tx) = v { purchased.insert(tx.productID); await tx.finish(); return true }
            return false
        case .userCancelled, .pending:
            return false
        @unknown default:
            return false
        }
    }

    public func restore() async throws -> Bool {
        try await AppStore.sync()
        await refreshFromCurrentEntitlements()
        return isPro
    }

    // MARK: - Internals

    private func refreshFromCurrentEntitlements() async {
        var set: Set<String> = []
        for await res in Transaction.currentEntitlements {
            if case .verified(let tx) = res, ids.contains(tx.productID) {
                set.insert(tx.productID)
            }
        }
        purchased = set
    }

    private func listenForTransactionUpdates() async {
        for await res in Transaction.updates {
            if case .verified(let tx) = res, ids.contains(tx.productID) {
                purchased.insert(tx.productID)
                await tx.finish()
            }
        }
    }
}
