# chatgpt_docs/00_MASTER_INSTRUCTIONS.md
# The Vector Project — Master Instructions (Concise)

You are Vector’s **Senior iOS Engineer + Product Strategist**. All deliverables must follow these rules.

## Business Policy
- **Free forever:** unlimited TOTP, QR/manual add, Face/Touch ID lock. Never cripple free.
- **Pro tier:** iCloud Keychain sync, encrypted backups, Apple Watch, Widgets, brand icons, bulk import.
- **Paywall timing:** show only when user attempts Pro OR soft-upsell after ≥2 accounts.
- **Pricing IDs:** `pro.monthly` ($0.99/mo), `pro.lifetime` ($14.99), tips: `tip.small` ($2.99), `tip.large` ($9.99).
- **Paywall UX:** one clean SwiftUI sheet; benefits list; Monthly + Lifetime; Restore; “Maybe later.”
- **Metrics (local-only):** `account_added`, `sync_enabled`, `paywall_shown`, `pro_purchased`, `backup_exported`.
- **Security:** Keychain (`kSecAttrAccessibleWhenUnlocked`, `kSecAttrSynchronizable=true`), backups via CryptoKit AES-GCM + passphrase KDF.
- **Accessibility:** Dynamic Type, VoiceOver, Reduce Motion. Widgets default “tap to reveal”.

## Operating Principles
- Prefer Apple-native (SwiftUI, CryptoKit, StoreKit 2, WidgetKit, WatchKit, Keychain).
- Serverless: iCloud Keychain/Drive only.
- Ship small, testable slices. Pro surfaces must check `Entitlements.isPro`.
- Provide unit tests: RFC6238, Keychain R/W, crypto round-trip, StoreKit2.

## Code & Style
- Semantic design system: BrandColor/BrandGradient/Typography/Spacing.
- File headers `// File: …`. Provide realistic `#if DEBUG` previews.
- If a request conflicts with policy, propose a compliant alternative.

## Bug Lessons (don’t repeat)
1) Don’t use `??` on non-optional types.  
2) `.fileImporter`: single vs multiple URL return types.  
3) Use `$vm.prop` for bindings; ensure `@Published` in VM.  
4) Convert complex `Section` vars into `private func section…() -> some View`.  
5) Don’t `private` types used cross-file (e.g., `TagCloud`).  
6) Update **Build Settings → Info.plist File** to `Vector/Config/Info.plist`.  
7) Replace placeholders with real screens in `AppRootView`.  
8) Add `.gitignore` for OneDrive/Library noise.  
9) If Xcode freezes: Force Quit; clear DerivedData.

## Next Steps Checklist
- Add Entitlements + Metrics services and DI wiring.
- Add PaywallView; gate Pro features; log events.
- Configure StoreKit products & local StoreKit config file.
- Add tests: RFC6238, backup round-trip, Keychain, StoreKit.
- Ship v1.1 (“Pro monetization + paywall”).

---

# chatgpt_docs/01_PAYWALL_SPEC.md
# Paywall / Monetization Spec

## Triggers
- Tapping Pro controls: iCloud Sync toggle, Encrypted Backup, Watch install, Widgets enable, Brand icons, Bulk import.
- Soft upsell: on Settings open when user has ≥2 accounts (no hard block).

## UX (single sheet)
- **Header:** Logo mark + title “Vector Pro”, subtitle “Power features that stay private.”
- **Benefits:** iCloud sync, Encrypted backups, Watch & Widgets, Brand icons & Bulk import.
- **Plans:** Monthly + Lifetime (buttons/cards); show localized `displayPrice`.
- **CTAs:** Primary “Unlock Pro”, Secondary “Restore Purchases”, Tertiary “Maybe later”.
- **Copy:** “No ads. No tracking. Cancel anytime.”
- Respect Reduce Motion; announce via VoiceOver.

## StoreKit
- Product IDs: `pro.monthly`, `pro.lifetime`, `tip.small`, `tip.large`.
- Load products on appear; cache in `Entitlements`.
- Purchase → verify → finish → refresh entitlement → dismiss paywall.
- Restore → `AppStore.sync()` + iterate `Transaction.currentEntitlements`.

## Routing
- `router.route == .paywall` as sheet from current view.
- Log `paywall_shown` on present; `pro_purchased` on success.

---

# chatgpt_docs/02_ENTITLEMENTS_METRICS.md
# Entitlements & Metrics

## Entitlements
- Singleton `Entitlements` (`ObservableObject`) with:
  - `@Published var isPro: Bool`
  - `@Published var products: [Product]`
  - `func loadProducts()`, `func purchase(_:)`, `func restore()`, `func refreshEntitlement()`
- Listen to `Transaction.updates`; verify + finish; refresh state.

## Metrics (local only)
- JSON file in Documents, append events:
  - `account_added`, `sync_enabled`, `paywall_shown`, `pro_purchased`, `backup_exported`
- Structure: `{ ts: ISO8601, event: String, props: {…} }`
- No device/user IDs, no network.

---

# chatgpt_docs/03_SECURITY_BACKUP_KDF.md
# Encrypted Backups — KDF & Envelope

## Goals
- Export/import vault as encrypted JSON with **passphrase**; no server.

## Algorithm
- **KDF:** PBKDF2-HMAC-SHA256, ≥150k iterations, 32-byte key, 16-byte random salt.
- **AEAD:** AES-GCM with 12-byte random nonce.
- **Envelope (JSON):**
```json
{
  "salt":"base64", "nonce":"base64",
  "ciphertext":"base64", "tag":"base64"
}

    •    Never reuse nonce; unique per export.

UX
    •    Require passphrase (≥10 chars). Show strength hints. Warn about loss risk.

Tests
    •    Round-trip 500 tokens in <1s on modern hardware.
    •    Wrong passphrase fails cleanly.

⸻

chatgpt_docs/04_TOTP_ENGINE.md

TOTP (RFC 6238) Design

Inputs
    •    secret (raw bytes), digits (6/8), period (e.g., 30), algo (SHA1/256/512).

Behavior
    •    code(at:) returns zero-padded digits; remainingSeconds(at:) for the ring.
    •    Base32 decode (RFC 4648, case-insensitive, ignore whitespace, = optional).

Tests
    •    RFC vector times: 59, 1111111109, 1111111111, 1234567890, 2000000000, 20000000000 across algos/digits.
    •    Compare against known values.

⸻

chatgpt_docs/05_KEYCHAIN_VAULT.md

Keychain Vault (Synchronizable)

Policy
    •    kSecClassGenericPassword, Service = app.vector.vault
    •    kSecAttrAccessible = kSecAttrAccessibleWhenUnlocked
    •    Sync: kSecAttrSynchronizable = true (iCloud Keychain).

API
    •    save(key:data:) → delete-then-add.
    •    load(key:) → kSecReturnData=true, kSecAttrSynchronizableAny.
    •    delete(key:).

Notes
    •    App Group not required for sync; use Access Group to share between app/extensions on device.
    •    Use LAContext gate for unlock if needed.

⸻

chatgpt_docs/06_PRIVACY_MODIFIERS.md

Privacy Modifiers

Rules
    •    Mark token UI privacySensitive().
    •    Blur when screen recording is active (UIScreen.capturedDidChangeNotification).
    •    Widgets default to “tap to reveal”.

Component
    •    PrivacySensitiveView { content } overlays blur + message while captured.

⸻

chatgpt_docs/07_METRICS_LOCAL.md

Local Metrics

Storage
    •    Append-only JSON in Documents (metrics.json), pretty-printed.

API
    •    Metrics.log(_ event: MetricEvent, context: [String:String])

Hygiene
    •    Rotate file if >1MB.
    •    Optionally show “Export diagnostics” screen for the user.

⸻

chatgpt_docs/08_ROUTER_NAVIGATION.md

Router / Navigation

Route Enum
    •    .splash, .intro, .vault, .addToken, .settings, .paywall

Patterns
    •    Each feature in its own NavigationStack.
    •    Present paywall as .sheet above current feature.
    •    On first launch: Splash → Intro → Vault; else Splash → Vault.

Deep Links (later)
    •    otpauth:// open → route to AddToken prefilled.

⸻

chatgpt_docs/09_DEBUGGING_PLAYBOOK.md

Debugging Playbook
    •    Sendable/actor warnings: mark ObjectiveC imports with @preconcurrency when needed; isolate UI to @MainActor.
    •    Nonisolated deinit: avoid touching non-sendable state; move cleanup to main or make storage Sendable.
    •    Section generic errors: use private func sectionFoo() -> some View (not computed vars).
    •    Optional misuse: ensure ?? only on optionals.
    •    fileImporter: single URL vs array of URLs matches allowsMultipleSelection.
    •    Private symbols: don’t make cross-file views private.
    •    Info.plist path: set to Vector/Config/Info.plist.
    •    Xcode freezes: Force Quit, clear DerivedData, reboot if metal shader cache is corrupt.

⸻

chatgpt_docs/10_SECURITY_CRYPTO.md

Security & Crypto Overview

Threat Model
    •    Local device attacker (post-unlock), shoulder-surfer, cloud adversary without passphrase.

Controls
    •    Keychain WhenUnlocked + biometrics.
    •    Backups: AES-GCM + PBKDF2 key, random salt/nonce.
    •    No servers; iCloud only.
    •    Privacy screens + .privacySensitive().

Reviews
    •    Code review for constant-time comparisons where relevant.
    •    Disallow debug logs for secrets.

⸻

chatgpt_docs/11_KEYCHAIN_SYNC.md

iCloud Keychain Sync Notes
    •    kSecAttrSynchronizable=true for add/query/delete.
    •    Propagation is best-effort; do not assume immediate cross-device availability.
    •    Conflict strategy: last-writer wins; prefer idempotent merges.
    •    Use Access Groups to share between app/watch/widget on same device (and entitlements must match).

⸻

chatgpt_docs/12_TOTP_TEST_VECTORS.md

TOTP Test Vectors (RFC 6238)

Use seed “12345678901234567890” (ASCII) unless noted; period 30s.

Time (Unix)    Algo    Digits    OTP (expected)
59    SHA1    8    94287082
59    SHA256    8    46119246
59    SHA512    8    90693936
1111111109    SHA1    8    07081804
1111111111    SHA1    8    14050471
1234567890    SHA1    8    89005924
2000000000    SHA1    8    69279037
20000000000    SHA1    8    65353130

Tests: verify across 6 and 8 digits by modulo; verify remaining seconds in [0, period).

⸻

chatgpt_docs/13_UI_COMPONENTS_CATALOG.md

UI Components Catalog
    •    AppHeader: centered logo mark + subtle brand gradient hairline; respects safe area; optional progress/notice line.
    •    Card: padded surface with divider border; header slot + accessory; used in Settings/Import/Paywall.
    •    PrimaryButton/SecondaryButton: pill style; large tap target; haptics on success.
    •    TokenRow: issuer, account, color dot, TimeRing, copy button; accessibilityLabel announces code & seconds remaining.
    •    TimeRing: 1s tick; gradient sweep; pulse ≤5s remaining; respects Reduce Motion.
    •    Paywall components: BenefitRow, PlanPicker, SelectCard.

⸻

chatgpt_docs/14_ACCESSIBILITY_GUIDE.md

Accessibility Guide
    •    Dynamic Type: test from XS–XXXL; line breaks safe.
    •    VoiceOver: Token row → “GitHub, you@example.com, code 123 456, 12 seconds left.”
    •    Reduce Motion: disable scale/pulse; keep opacity fades ≤150ms.
    •    Contrast: ≥ 4.5:1 for body; avoid low-alpha text.
    •    Hit targets: ≥44×44pt; .contentShape(Rectangle()).

⸻

chatgpt_docs/15_RELEASE_CHECKLIST.md

Release Checklist
    •    Bump MARKETING_VERSION + CURRENT_PROJECT_VERSION.
    •    Info.plist path = Vector/Config/Info.plist.
    •    StoreKit products configured; local StoreKit config used for tests.
    •    Unit tests pass (TOTP, backup, keychain, StoreKit).
    •    App Privacy nutrition labels accurate; no tracking.
    •    Screenshots & promo text updated.
    •    TestFlight build verified on ≥2 devices; restore purchases works.
    •    Verify screen-recording blur + privacySensitive.
    •    .git tags pushed (v1.1.0).

⸻

chatgpt_docs/16_ASO_MARKETING.md

ASO / Marketing Notes

Subtitle: Private 2FA that just works.
Keywords: 2FA, Authenticator, TOTP, iCloud, Backup, Watch, Widgets, Privacy.
Promo Text: Free core 2FA. Pro adds iCloud sync, encrypted backups, Apple Watch, and widgets—no ads, no tracking.
Screenshots: Splash, Vault with tokens, Add via QR, Paywall, Settings security, Backup flow.

⸻

chatgpt_docs/17_GIT_HYGIENE.md

Git Hygiene
    •    .gitignore include: Library/, *.xcuserstate, DerivedData/, *.xcworkspace/xcuserdata/, .DS_Store, OneDrive tombstones, .gitkraken/.
    •    Avoid committing nested repos; remove with git rm --cached path/to/embedded/.git.
    •    Feature branches: feat/paywall, fix/import-fileImporter, etc.
    •    Conventional commits: feat: paywall sheet, fix: optional misuse in ImportView.

⸻

chatgpt_docs/18_FAQ_SUPPORT.md

FAQ / Support

Q: Is Vector free?
A: Yes—core 2FA is free forever. Pro adds convenience features only.

Q: Where are my secrets stored?
A: On-device Keychain (WhenUnlocked). Optional iCloud Keychain sync.

Q: How do backups work?
A: Encrypted with your passphrase (AES-GCM + PBKDF2). Keep passphrase safe.

Q: Do you track me?
A: No third-party analytics. Optional local metrics only.

Support: Add in-app link to email or GitHub Issues. Provide “Export diagnostics” for local metrics if the user consents.

