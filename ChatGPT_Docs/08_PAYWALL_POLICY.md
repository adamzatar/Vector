# chatgpt_docs/08_PAYWALL_POLICY.md
# Vector — Paywall & Monetization Policy (Authoritative Spec)

This document defines **what** is monetized, **when** the paywall appears, **how** it looks, and **how** purchases are handled. It is binding for UX, code, and tests.

---

## 1) Products (App Store Connect)

| ID            | Type                | Price (launch) |
|---------------|---------------------|----------------|
| `pro.monthly` | Auto-renew sub      | $0.99 / mo     |
| `pro.lifetime`| Non-consumable      | $14.99         |
| `tip.small`   | Consumable          | $2.99          |
| `tip.large`   | Consumable          | $9.99          |

> **Rule:** Only **`pro.monthly`** and **`pro.lifetime`** grant **Pro entitlement**. Tip jars **never** unlock features.

---

## 2) Pro Gated Features

- iCloud sync (Keychain synchronizable)
- Encrypted backups (export/import)
- Apple Watch app
- Home/Lock Screen widgets (code display toggles)
- Brand icons
- Bulk import

> **Free forever:** unlimited TOTP, QR/manual add, Face/Touch ID lock. **Never** cripple free.

---

## 3) When to Show the Paywall

### A. Hard Triggers (immediate)
Show paywall when the user **attempts**:
- Enabling iCloud sync
- Exporting/importing encrypted backups
- Enabling Watch app integration
- Enabling widget code visibility
- Using brand icons or bulk import

### B. Soft Upsell (polite)
- When user has **≥ 2 accounts** and opens **Settings** → show **non-blocking** banner (“Try Vector Pro”) that opens paywall if tapped.
- Never block onboarding or first successful add.

---

## 4) UX / Copy (Single Ethical Screen)

**Title:** Vector Pro  
**Subtitle:** Power features that stay private.  

**Benefits (bullets):**
- iCloud Sync — your codes on all devices, end-to-end
- Encrypted Backups — bring your codes anywhere
- Apple Watch & Widgets — faster 2FA at a glance
- Brand Icons & Bulk Import — organize in seconds

**Plans Row:** `$0.99 / month · $14.99 lifetime` (local currency shown via StoreKit `displayPrice`)  
**Primary:** Unlock Pro  
**Secondary (bordered):** Restore Purchases  
**Tertiary (tiny):** Maybe later  
**Trust footer:** No ads. No tracking. Cancel anytime.

**Accessibility**
- Title `.accessibilityAddTraits(.isHeader)`
- VoiceOver labels for each benefit row
- Respect Reduce Motion (no confetti; ≤ 180ms easeInOut transitions)
- Dynamic Type friendly (no clipped text)

**Visual**
- Clean gradient header + app mark
- Feature “pills” with SF Symbols, high contrast (AA+)

---

## 5) StoreKit 2 Policy

- **Entitlement source of truth:** `Entitlements.shared` (`@MainActor`, publishes `isPro` & `products`).
- **Preload products** on first paywall show; cache in memory.
- **Listen for** `Transaction.updates` to refresh entitlement live.
- **Restore** via `AppStore.sync()`; never gate behind login.
- **Unverified / pending / cancelled** → do not unlock; show gentle error only for explicit failures.

**Minimal Flow:**
```swift
@EnvironmentObject var ent: Entitlements

func gatePro(orPresentPaywall router: AppRouter, proceed: @escaping () -> Void) {
  Task { @MainActor in
    if ent.isPro { proceed(); return }
    di.metrics.log(.paywall_shown)
    router.showPaywall()
  }
}
