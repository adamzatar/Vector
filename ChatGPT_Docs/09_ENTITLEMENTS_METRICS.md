# chatgpt_docs/09_ENTITLEMENTS_METRICS.md
# Vector — Entitlements (StoreKit 2) & Local Metrics

Authoritative spec + drop-in code for **Pro entitlement** and **privacy-safe local metrics**. Keep this file aligned with `08_PAYWALL_POLICY.md`.

---

## Goals

- **Entitlements:** single source of truth for Pro (`pro.monthly` / `pro.lifetime`), live-updating via StoreKit 2.
- **Metrics:** local-only, zero-PII event logging for product decisions.

---

## 1) StoreKit 2 Entitlements (copy-paste)

```swift
// File: Services/Infra/Entitlements.swift
import Foundation
import StoreKit

@MainActor
public final class Entitlements: ObservableObject {
    public static let shared = Entitlements()

    @Published public private(set) var isPro: Bool = false
    @Published public private(set) var products: [Product] = []

    private let proIDs: Set<String>  = ["pro.monthly", "pro.lifetime"]
    private let allIDs: Set<String>  = ["pro.monthly", "pro.lifetime", "tip.small", "tip.large"]

    private var updatesTask: Task<Void, Never>?

    public init(startListener: Bool = true) {
        if startListener { updatesTask = listenForTransactions() }
    }

    deinit { updatesTask?.cancel() }

    // Load products once (e.g., when presenting paywall)
    public func loadProducts() async {
        do { products = try await Product.products(for: Array(allIDs)) }
        catch { products = [] }
        await refreshEntitlement()
    }

    public func product(id: String) -> Product? {
        products.first(where: { $0.id == id })
    }

    @discardableResult
    public func purchase(_ product: Product) async -> Bool {
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let tx) = verification {
                    await tx.finish()
                    await refreshEntitlement()
                    return true
                }
                return false
            case .userCancelled, .pending:
                return false
            @unknown default:
                return false
            }
        } catch {
            return false
        }
    }

    public func restore() async {
        do { try await AppStore.sync() } catch {}
        await refreshEntitlement()
    }

    public func refreshEntitlement() async {
        var pro = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let tx) = result, proIDs.contains(tx.productID) {
                pro = true
                break
            }
        }
        isPro = pro
    }

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await update in Transaction.updates {
                if case .verified(let tx) = update {
                    await tx.finish()
                    await self?.refreshEntitlement()
                }
            }
        }
    }
}
