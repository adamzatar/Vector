# chatgpt_docs/13_STOREKIT_PLAYBOOK.md
# Vector — StoreKit 2 Playbook (Authoritative)

This is the **end-to-end guide** for implementing, testing, and shipping Vector Pro with **StoreKit 2**.
It aligns with our Business Policy: **ethical paywall, privacy-safe, Apple-native**.

---

## 0) Product Catalog (single source of truth)

**Product IDs (App Store Connect → In-App Purchases):**
- `pro.monthly` — Auto-renewable subscription (1 month).
- `pro.lifetime` — Non-consumable “lifetime unlock”.
- `tip.small` — Consumable (one-time tip).
- `tip.large` — Consumable (one-time tip).

**Rules**
- Free tier stays fully functional for core 2FA.
- Pro features **check entitlement** at point-of-use.
- Present **one clean paywall** when needed; allow “Maybe later”.

---

## 1) App Wiring (Boot, DI, and Listener)

**Goal:** Entitlements load at launch, update reactively when purchases/restore occur.

```swift
// File: Vector/App/VectorApp.swift (snippet)
import SwiftUI

@main
struct VectorApp: App {
    @StateObject private var entitlements = Entitlements.shared  // from Services/Infra

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environmentObject(entitlements) // make isPro/products available
                .task {
                    // Warm up the product list and entitlement state.
                    await entitlements.loadProducts()
                }
        }
    }
}

Why: Entitlements.shared internally listens to Transaction.updates, calls finish(), and flips isPro.

⸻

2) Gating a Pro Feature (Pattern)

Do not hide Pro UI. Do allow taps and then gate ethically.

// In any View (e.g., Settings → Sync)
@EnvironmentObject private var ent: Entitlements
@Environment(\.di) private var di
@EnvironmentObject private var router: AppRouter

Toggle(isOn: Binding(
    get: { /* current value */ false },
    set: { newValue in
        Task { @MainActor in
            if !ent.isPro {
                di.metrics.log(.paywall_shown)
                router.showPaywall()        // present PaywallView
                return
            }
            if newValue {
                di.metrics.log(.sync_enabled)
                // enable iCloud Keychain sync…
            } else {
                // disable sync…
            }
        }
    }
)) {
    Label("iCloud Sync", systemImage: "icloud")
}


⸻

3) Paywall Presentation (Sheet)

// Router → add a route or a sheet Boolean
.sheet(isPresented: $router.isShowingPaywall) {
    PaywallView()                         // already uses Entitlements env object
        .preferredColorScheme(.dark)
}

When to trigger: On tapping Pro toggles (Sync, Backup Export, Watch install, Widgets unlock) or soft-upsell after ≥ 2 accounts when opening Settings.

⸻

4) Purchase & Restore Flow (StoreKit 2)

A. Purchase (monthly or lifetime)
    •    Use Product.purchase().
    •    On success .verified, call finish() and await refreshEntitlement().

// inside PaywallView
if let monthly {
    Button("Continue – \(monthly.displayPrice)/mo") {
        Task { _ = await ent.purchase(monthly) }
    }
    .buttonStyle(.borderedProminent)
}

B. Restore

Button("Restore Purchases") {
    Task { await ent.restore() }
}

C. Tips (consumables)
    •    Tips do not change entitlement. Just purchase and thank the user.

if let small = ent.products.first(where: { $0.id == "tip.small" }) {
    Button("Leave a Tip – \(small.displayPrice)") {
        Task { _ = await ent.purchase(small) } // ignore isPro; just show a toast on success
    }
}

D. Manage Subscription

import StoreKit
Button("Manage Subscription") {
    Task { _ = try? await AppStore.showManageSubscriptions() }
}


⸻

5) StoreKit Configuration for Local Testing

Create a .storekit config file:
    1.    Xcode → File → New → StoreKit Configuration File → Vector.storekit.
    2.    Add products with matching IDs:
    •    pro.monthly: price $0.99, subscription group “Pro”, monthly duration.
    •    pro.lifetime: non-consumable, $14.99, Family Sharing enabled (optional).
    •    tip.small: consumable $2.99.
    •    tip.large: consumable $9.99.
    3.    Scheme → Run → Options → StoreKit Configuration: select Vector.storekit.

Simulate:
    •    Purchases/restores without App Store.
    •    Subscription renewal speed (fast/slow).
    •    Billing issues, refunds, grace periods.

⸻

6) QA Matrix (Purchasing Scenarios)
    •    Happy path (monthly/lifetime): purchase completes, entitlement flips to true, paywall dismisses.
    •    User canceled: no entitlement, paywall stays.
    •    Restore: fresh install → tap Restore → entitlement returns.
    •    Refund / revocation: simulate in .storekit → entitlement flips to false.
    •    Network loss: purchase pending; UI remains consistent; no crashes.
    •    Different storefront: price localization appears via displayPrice.

Automated Tests (StoreKitTest)
    •    Use StoreKitTest with .storekit file.
    •    Assert: Entitlements.isPro becomes true after purchase; false after revoke.
    •    Assert: Transaction.updates triggers finish + refresh.
    •    Snapshot tests of Paywall with mock products (localized price strings).

⸻

7) Error Handling & UX

We never block core 2FA. On errors:
    •    Show succinct alert (title “Purchase Failed”, message = error.localizedDescription).
    •    Offer Restore and Maybe later.
    •    Log locally: metrics.log(.paywall_shown) before presenting, metrics.log(.pro_purchased) after success.

Common statuses
    •    .userCancelled → simply dismiss spinner.
    •    .pending → show “Pending approval” toast if applicable.
    •    .success(.unverified) → treat as failure; suggest retry.

⸻

8) Entitlement Truth & Caching
    •    Source of truth: Transaction.currentEntitlements stream.
    •    We also persist a light flag if desired (not required) to speed up UI, but never trust it alone.
    •    On app start: call await refreshEntitlement().

Revocation / Refund
    •    Handled via Transaction.updates. If a Pro entitlement disappears, isPro flips to false automatically.

⸻

9) App Store Connect Checklist
    •    Create products with IDs listed above.
    •    Localize Display Names and Descriptions.
    •    Group subscriptions (if more tiers later).
    •    Enable Family Sharing for pro.lifetime if you want family availability.
    •    Upload Review Notes:
    •    Explain free vs Pro.
    •    “Privacy-first; no accounts/servers; StoreKit 2 only.”
    •    Provide TestFlight instructions for reviewers (how to reach Paywall).

⸻

10) Security & Privacy Notes
    •    No receipt uploads / no server: we solely rely on StoreKit 2 verification.
    •    No tracking / no 3P SDKs. Only local metrics.
    •    Purchase state does not touch Keychain; it lives in StoreKit and our Entitlements object.

⸻

11) Implementation Snippets (Reference)

A. Entitlements (recap)

// Services/Infra/Entitlements.swift (already in repo)
@MainActor
public final class Entitlements: ObservableObject {
    public static let shared = Entitlements()
    @Published public private(set) var isPro: Bool = false
    @Published public private(set) var products: [Product] = []
    private let productIDs = ["pro.monthly", "pro.lifetime", "tip.small", "tip.large"]

    public func loadProducts() async { /* Product.products(for:) then refreshEntitlement() */ }
    public func purchase(_ product: Product) async -> Bool { /* Product.purchase() */ }
    public func restore() async { try? await AppStore.sync(); await refreshEntitlement() }
    public func refreshEntitlement() async { /* iterate Transaction.currentEntitlements */ }
}

B. Paywall View (recap)
    •    One screen, clear benefits, Monthly+Lifetime, Restore, Maybe later.
    •    Respect Reduce Motion for any celebratory effects you might add (off by default).

⸻

12) Observability (Local Only)
    •    Log key events:
    •    paywall_shown, pro_purchased.
    •    (Optional) Append purchase attempts and statuses to the local metrics file for debugging:
    •    { ts, event, productID, status }.

⸻

13) Troubleshooting
    •    “No products returned”: App Store Connect products must be in Ready to Submit / Approved state; bundle ID & signer must match; try .storekit locally.
    •    “Purchase completes but UI not updating”:
    •    Ensure Transaction.updates listener is alive for app lifetime.
    •    Confirm you call await transaction.finish().
    •    Call await ent.refreshEntitlement() after purchase/restore.
    •    “Restore does nothing”:
    •    Use await AppStore.sync() (iOS 15+).
    •    Test with a Sandbox tester signed in on device.
    •    “Lifetime not shared with family”:
    •    Enable Family Sharing in ASC for the non-consumable.
    •    “Subscription price wrong”:
    •    Always use product.displayPrice (localized), not hard-coded strings.

⸻

14) Ship List (pre-release)
    •    .storekit config checked in and attached to Debug scheme.
    •    App shows one ethical paywall; “Maybe later” visible.
    •    Pro features gated only at point-of-use; free core intact.
    •    Purchase/Restore tested on device with Sandbox Apple ID.
    •    Entitlements.isPro flips correctly on purchase/restore/revoke.
    •    Local metrics log events (no PII).
    •    App Review notes prepared (access steps to paywall, no account needed).

⸻

TL;DR
    •    IDs: pro.monthly, pro.lifetime, tip.small, tip.large.
    •    Singleton: Entitlements.shared publishes isPro + products.
    •    Gate at tap → show PaywallView (ethical, simple).
    •    Test with .storekit + Sandbox; listen to Transaction.updates; call finish().
    •    No servers, no tracking—just StoreKit 2 done right.


