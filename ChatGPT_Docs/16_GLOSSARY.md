# chatgpt_docs/16_GLOSSARY.md
# Vector — Glossary

Short, practical definitions of concepts, APIs, and project-specific terms used in Vector.

---

## OTP & Crypto

- **TOTP (RFC 6238)** — Time-based One-Time Password; HMAC(counter) where counter = ⌊epoch/period⌋. Default: 6 digits / 30s / SHA-1.
- **HOTP (RFC 4226)** — Counter-based OTP; rarely used by modern consumer apps; included for completeness.
- **Base32 (RFC 4648)** — Alphabet `A–Z2–7` (optional `=` padding). Used to encode TOTP secrets. Often **uppercase**.
- **`otpauth://` URI** — Standard QR schema for OTP import. Example:  
  `otpauth://totp/Issuer:Account?secret=BASE32&issuer=Issuer&digits=6&period=30&algorithm=SHA1`
- **OTP Algorithm** — Hash function for HMAC (`SHA1`, `SHA256`, `SHA512`). Must match issuer’s settings.
- **Digits** — Number of displayed OTP digits (6 or 8 for Vector). Affects modulo operation and UI layout.
- **Period** — Window length in seconds (commonly 30). Drives countdown ring and refresh cadence.
- **Time Skew** — Device clock drift affecting TOTP validity. Vector uses a `TimeSkewService` to compensate.
- **HMAC** — Hash-based Message Authentication Code. Core primitive behind OTP generation.
- **AES-GCM** — Authenticated encryption used for backups (confidentiality + integrity). Requires unique nonce.
- **Nonce (IV)** — 12-byte random value for GCM. **Never reuse** with the same key.
- **Tag (GCM)** — Authentication tag output (~16 bytes) validating ciphertext integrity.
- **PBKDF2-HMAC-SHA256** — Password-based key derivation; ≥150k iterations recommended on modern devices.
- **KDF Salt** — Random bytes used to defeat rainbow tables. Stored alongside backup.
- **Zero-Knowledge** — No servers and no plaintext leaves device; iCloud Keychain is end-to-end encrypted by Apple.
- **Ciphertext Envelope** — Struct containing `{salt, nonce, ciphertext, tag}` for backup export/import.

---

## iOS Security & Storage

- **Keychain** — Secure storage for small secrets. Vector uses `kSecClassGenericPassword`.
- **`kSecAttrAccessibleWhenUnlocked`** — Items accessible only when device is unlocked; preferred for OTP secrets.
- **`kSecAttrSynchronizable`** — When `true`, item participates in **iCloud Keychain** sync.
- **Keychain Access Group** — Identifier to share Keychain items between the app and extensions on the same device.
- **App Group (container)** — Shared filesystem container for app + extensions (e.g., widgets/watch). Not the same as Keychain access group.
- **LocalAuthentication (LAContext)** — Face ID/Touch ID prompts to unlock protected flows (e.g., viewing codes).
- **`privacySensitive()` (SwiftUI)** — Marks views as sensitive; hides in App Switcher and some share/screen contexts.
- **Screen Capture Detection** — Observe `UIScreen.capturedDidChangeNotification`; blur sensitive UI while recording.

---

## StoreKit 2 & Monetization

- **Product** — StoreKit object representing an in-app purchase (`pro.monthly`, `pro.lifetime`, `tip.small`, `tip.large`).
- **Transaction** — Purchase record; verify (`.verified`) and then `finish()` it.
- **`Transaction.currentEntitlements`** — Async stream of active entitlements.
- **`AppStore.sync()`** — Triggers restore flow / receipt refresh.
- **Entitlement** — App-level notion of feature access; here, “Pro” if monthly or lifetime product is owned.
- **Ethical Paywall** — One clean screen; no dark patterns; “Maybe later” always visible.
- **Soft Upsell** — Show paywall only after user taps a Pro feature or after 2+ accounts.

---

## SwiftUI & App Architecture

- **`@State` / `@Binding`** — Local state vs bound state for inputs (forms, toggles).
- **`@StateObject` / `@ObservedObject`** — Create vs observe a reference-type view model with `@Published` properties.
- **`@EnvironmentObject`** — Dependency injected via environment (e.g., `AppRouter`, `Entitlements`).
- **`NavigationStack`** — SwiftUI navigation container; prefer a single stack per feature surface.
- **`Section{}`** — Grouping inside `List`/`Form`. For compiler sanity, prefer **helper functions** over large computed vars.
- **Type Erasure** — Use helper funcs / `AnyView` sparingly to tame “generic parameter could not be inferred” errors.
- **Design Tokens** — `BrandColor`, `BrandGradient`, `Typography`, `Spacing`, `Layout` control visual consistency.
- **Components** — `Card`, `PrimaryButton`, `SecondaryButton`, `SettingRow`, `TokenRow`, `TimeRing`, `SearchBar`, `TagCloud`.
- **`minTapTarget(_:)`** — Custom modifier ensuring ≥44pt hit area.
- **Launch Screen** — Static storyboard; Logo + background from asset catalog; no dynamic logic.
- **`AppRootView`** — Top-level switchboard between `.splash` → `.intro` → `.vault` etc. via `AppRouter`.

---

## Concurrency & AVFoundation

- **`@MainActor`** — Constrains functions/properties to run on main thread (UI). In Swift 6, cross-actor calls must be `await`.
- **`nonisolated`** — Method not isolated to actor (or `@MainActor` class); enables safe calling from other threads.
- **`Sendable`** — Marker for types safe to cross concurrency domains. Watch for closures capturing non-Sendable state.
- **`Task {}`** — Structured concurrency unit; use `await Task.sleep(...)` for lightweight delays.
- **Capture Session Queue** — Dedicated `DispatchQueue` for `AVCaptureSession` mutations (start/stop, torch).
- **Torch Control** — Lock device for configuration, set `torchMode`, and unlock; update UI on main actor.

---

## Metrics, Logging & Debugging

- **Local Metrics** — JSON file of events: `account_added`, `sync_enabled`, `paywall_shown`, `pro_purchased`, `backup_exported`.
- **Debug Ciphertext** — In `#if DEBUG`, wrapper storing human-readable strings to speed UI dev; never ship in release.
- **.gitignore Hygiene** — Exclude `Library/`, `DerivedData/`, `.gitkraken/`, OneDrive tombstones; commit only source tree.
- **FileImporter** — Returns `URL` (single) or `[URL]` (multiple) based on `allowsMultipleSelection`.
- **Common SwiftUI Pitfall** — Large computed `var section...: some View` causing inference errors; prefer `private func section...() -> some View`.

---

## Accessibility & Motion

- **Dynamic Type** — Use system fonts / scalable tokens; OTP digits use `monospacedDigit()` for legibility.
- **VoiceOver** — Concise labels: “GitHub, code 123 456, 12 seconds left.”
- **Reduce Motion** — Disable nonessential animations if `UIAccessibility.isReduceMotionEnabled == true`.
- **High Contrast** — Maintain ≥4.5:1 contrast; `BrandColor` tokens tuned for light/dark.

---

## Widgets & Watch

- **WidgetKit** — Timeline entries should carry **precomputed** code + expiry; avoid heavy crypto at refresh time.
- **Privacy in Widgets** — Default to “tap to reveal” codes; allow explicit opt-in to show unobscured values.
- **Watch App** — Lightweight list of issuers + current code; sync via Keychain or App Group snapshot.

---

## Backups

- **Export** — Encode token list JSON → derive key (PBKDF2) → AES-GCM seal with random nonce → envelope `{salt, nonce, ciphertext, tag}`.
- **Import** — Re-derive key from passphrase + salt → open GCM box → decode JSON → validate model.
- **Passphrase Policy** — Minimum length (≥10), encourage manager-generated passphrases; show strength meter.

---

## Routing & Feature Flags

- **`AppRouter`** — Enum routes (`.splash`, `.intro`, `.vault`, `.addToken`, `.settings`, `.paywall`); drives screen transitions.
- **Feature Flags** — Development toggles (e.g., show experimental fields) wired via `DIContainer.featureFlags`.

---

## Testing & Release

- **RFC Vectors** — Canonical test times for TOTP verification across hash algorithms and digits.
- **Round-Trip Tests** — Export→Import invariants for backups (deep compare of tokens).
- **Keychain Tests** — CRUD with `kSecAttrSynchronizable=true`; propagation check across devices (manual).
- **StoreKit Tests** — Xcode StoreKit config: purchase, cancel, restore flows.
- **Phased Release** — Gradual rollout in App Store to mitigate risk.
- **TestFlight** — Beta distribution; include privacy & paywall test scenarios.

---

## Copy & Messaging

- **Value Prop** — “Privacy-first 2FA. Free forever for core; Pro adds convenience.”
- **Paywall Copy** — “Vector Pro — Power features that stay private.” Clear feature bullets; prices; “Maybe later.”

---

## Project-Specific Types

- **`Token`** — Model for a single OTP entry (issuer, account, secret, algo, digits, period, color, tags).
- **`VaultStore`** — Persistence/service API for storing tokens (Keychain + in-memory cache).
- **`OTPAuthParser`** — Parser for `otpauth://` URIs; validates required fields and normalizes names.
- **`DIContainer`** — Dependency graph (vault, logger, feature flags, entitlements, metrics, time services).
- **`Entitlements`** — StoreKit 2 singleton publishing `isPro` and product catalog.
- **`Metrics`** — Lightweight local event logger; **no third-party SDKs**.

---

## Visual Identity

- **`BrandColor`** — Semantic colors: `surface`, `surfaceSecondary`, `divider`, `primaryText`, `accent`.
- **`BrandGradient`** — `primary()` background; `wash()` subtle surface gradient.
- **`Typography`** — Scales: `titleS/M/L`, `body`, `caption`, `monoM` for OTP digits.
- **`Spacing` / `Layout`** — Consistent paddings, corner radii, and shadow sizes.
- **`AppHeader`** — Animated logo/header component pinned top-center for brand trust and navigation clarity.

---

## Terminology (Quick)

- **Aha! Moment** — Point where user perceives core value (after adding tokens). Show paywall **after** this moment.
- **Soft Lock** — UI control visible but gated (tapping shows paywall rather than hiding the feature).
- **Privacy Screen** — Overlay/blur during capture or backgrounding.
- **Snapshot** — The image iOS shows in App Switcher; hide sensitive content with `privacySensitive()`.

---

## Do/Don’t (At a Glance)

- **Do**: Use Apple frameworks; encrypt backups; gate Pro ethically; respect accessibility; test with RFC vectors.
- **Don’t**: Reuse AES-GCM nonces; store secrets in UserDefaults; add third-party analytics; hard-block free flows.

---
