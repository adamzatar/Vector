# chatgpt_docs/03_APP_FLOW.md
# Vector — App Flow & Screen Contracts

This doc defines **how the app moves** between screens, **what each screen does**, and **where gating/metrics** happen. Treat it as the source of truth for navigation + lifecycle.

---

## 0) Actors & Globals

- **AppRouter** (`@EnvironmentObject`): `route: AppRoute = .splash`
  - Cases: `.splash`, `.intro`, `.vault`, `.addToken`, `.settings`, `.paywall`
  - Methods: `showIntro()`, `showVault()`, `showAddToken()`, `showSettings()`, `goHome()`, `go(_:)`
- **DIContainer** (`@Environment(\.di)`):
  - `vault: VaultStore`, `entitlements: Entitlements`, `metrics: Metrics`, `featureFlags`, `logger`
- **Entitlements** (`ObservableObject`): `@Published isPro`, `@Published products`, `purchase`, `restore`
- **Key Persistence**: `@AppStorage("hasCompletedOnboarding")`
- **Design**: `BrandGradient/BrandColor/Typography/Spacing`
- **Header**: `AppHeaderBar(title: String, subtitle: String?, showBack: Bool)` used at top of every primary view

---

## 1) High-Level Route

App Launch
└─ AppRootView
├─ SplashView (≤650ms)
│   ├─ First run? → IntroScreen
│   └─ Else → VaultView
├─ IntroScreen → sets hasCompletedOnboarding = true → VaultView
├─ VaultView
│   ├─ “+” → AddTokenView
│   └─ “gear” → SettingsView
├─ AddTokenView → on save → VaultView
├─ SettingsView → may sheet PaywallView
└─ PaywallView (sheet) → purchase/restore → dismiss

---

## 2) Per-Screen Contracts

### 2.1 SplashView
**Purpose:** Brand moment + route decision.

- **Header:** `AppHeaderBar(title: "Vector", subtitle: "Private 2FA", showBack: false)` centered above content.
- **OnAppear:** delay ~0.65s (respect Reduce Motion), then:
  - if `hasCompletedOnboarding == false` → `router.showIntro()`
  - else → `router.showVault()`
- **Background:** `BrandGradient.primary().ignoresSafeArea()`
- **A11y:** Label static text; no blocking animations.

### 2.2 IntroScreen
**Purpose:** 3-card intro (Privacy, Backup, Add token).

- **Header:** `AppHeaderBar(title: "Welcome to Vector", subtitle: "Privacy-first 2FA")`
- **Primary CTA:** “Continue” → sets `hasCompletedOnboarding = true` → `router.showVault()`
- **Secondary CTA:** “Learn more” → Settings (optional) or docs
- **Metrics:** none
- **A11y:** Cards marked as headers; body text readable with Dynamic Type.

### 2.3 VaultView (Home)
**Purpose:** Show token list; copy codes; time ring; search.

- **Header:** `AppHeaderBar(title: "Vector", subtitle: "Your accounts")`
- **Body:**
  - `SearchBar` (optional)
  - `List` of `TokenRow(issuer, account, color, secondsRemaining, progress, onCopy)`
  - Copy triggers haptic + toast (“Copied” ≤1.2s)
- **Actions:**
  - NavBar trailing `+` → `router.showAddToken()`
  - NavBar leading `gear` → `router.showSettings()`
- **Lifecycle:**
  - Subscribe to a 1s tick (coalesce update to visible rows)
  - Observe vault changes (`@Published` stream)
- **Metrics:** on successful add via VM, log `account_added` (VM logs; view doesn’t)
- **Privacy:** Wrap main list in `PrivacySensitiveView { … }`

### 2.4 AddTokenView
**Purpose:** Manual entry + optional QR scan.

- **Header:** `AppHeaderBar(title: "Add Token", subtitle: "Manual or QR", showBack: true)`
- **Form Sections:**
  - **Account:** Issuer, Account, Secret (Base32)
  - **Security Parameters:** Algorithm (sha1/256/512), Digits (6/8), Period (15–120)
  - **Presentation:** Color tag, Tags input (`TagCloud`)
  - **Scan / Import:** “Scan QR” → `QRScannerView` sheet
- **Save:** `vm.saveManual()`:
  - Validate non-empty issuer/account, plausible Base32, parameters valid
  - Persist with `VaultStore.add`
  - On success: haptic success → `router.goHome()`
- **Scan Sheet:** `QRScannerView`:
  - If camera not authorized → permission overlay → open Settings
  - On result → parsed fields populate VM
- **Metrics:** VM logs `account_added` on save
- **Errors:** Inline message + alert (short, actionable)

### 2.5 SettingsView
**Purpose:** App preferences; Pro features entry points.

- **Header:** `AppHeaderBar(title: "Settings", subtitle: nil, showBack: true)`
- **Sections (examples):**
  - **Security:** Face ID lock (free)
  - **Sync (Pro):** iCloud Keychain Sync `Toggle`
    - On set `true` when `!entitlements.isPro` → present **PaywallView** sheet and log `paywall_shown`
  - **Backups (Pro):** Encrypted export/import → gate similarly
  - **Appearance:** Theme (optional)
  - **About:** Version, Privacy policy
- **Gating Rule:** Any Pro tap/option → if `!isPro` then show paywall
- **Metrics:** `sync_enabled` when enabling real sync; `backup_exported` on export

### 2.6 PaywallView (Sheet)
**Purpose:** Ethical upsell, StoreKit purchase/restore.

- **Header:** `AppHeaderBar(title: "Vector Pro", subtitle: "Power features that stay private", showBack: false)`
- **Content:** benefits list (iCloud Sync, Backups, Watch/Widgets, Icons/Bulk Import)
- **Plan Picker:** Monthly vs Lifetime
- **CTAs:** **Unlock Pro**, **Restore Purchases**, **Maybe later**
- **OnAppear:** `metrics.log(.paywall_shown)`
- **Purchase:** on success →
  - `entitlements.isPro = true` (via transaction updates) → dismiss sheet
  - `metrics.log(.pro_purchased)`

---

## 3) Gating Map (Where Paywall Appears)

- Settings → **iCloud Sync** toggle
- Backup → **Encrypted Export** / **Import**
- Watch App → “Install/Enable”
- Widgets → “Enable code display”
- Appearance → **Brand Icons**
- Import → **Bulk Import**

Soft upsell:
- `VaultView` → if `tokenCount >= 2` and user enters **Settings**, show paywall **once per install** (gentle, dismissible).

---

## 4) Metrics Matrix (Local-Only)

| Event              | When                                      | Properties       |
|--------------------|-------------------------------------------|------------------|
| `account_added`    | VM save success (manual/QR)                | `{source:"qr|manual"}` |
| `sync_enabled`     | iCloud Sync toggled on (and allowed)       | `{}`             |
| `paywall_shown`    | Any Pro entry shows paywall                | `{surface:"sync|backup|watch|widgets|icons|bulk"}` |
| `pro_purchased`    | StoreKit success                           | `{plan:"monthly|lifetime"}` |
| `backup_exported`  | Successful encrypted export                | `{count:"N"}`    |

---

## 5) Lifecycle & Backgrounding

- **App enters background:** if App Lock on → lock on next foreground
- **Screen capture/recording:** `PrivacySensitiveView` adds blur overlay with notice
- **Reduce Motion:** disable large transitions, time ring pulses, confetti
- **Clipboard:** optional auto-clear timer (Settings)

---

## 6) Error & Permission Flows

- **Camera denied:** overlay with “Enable Camera” → open Settings
- **Parser error (QR/CSV):** succinct alert; skip bad lines; continue others
- **Keychain failures:** show single-line error; log details only in DEBUG
- **StoreKit:** purchase cancelled/pending → silent; failure → small alert

---

## 7) Performance Budgets

- **Vault cells:** ≤ 4ms render on iPhone 12+
- **Widget provider:** ≤ 20ms load
- **Backup round-trip:** ≤ 1s for 500 tokens
- **Animations:** ≤ 0.18s, easeInOut; respect Reduce Motion

---

## 8) Future Surfaces (stubs)

- **Watch App:** reads minimal, precomputed model via App Group; “tap to reveal” by default
- **Widgets:** show issuer/account + time ring; codes hidden unless explicitly enabled

---

## 9) AppHeader Placement Rule

- Each primary view puts **`AppHeaderBar`** **inside** its own `NavigationStack`, **above** scrollable content:
  ```swift
  NavigationStack {
      VStack(spacing: Spacing.m) {
          AppHeaderBar(title: "...", subtitle: "...", showBack: true/false)
          // rest of the screen
      }
      .padding(.horizontal, Spacing.m)
  }

    •    Splash uses centered header (no back), intro/vault/settings/add/paywall use standard spacing.

⸻

10) Done Checklist per Screen
    •    Header present and aligned
    •    Gating respected (if applicable)
    •    Metrics fired (if applicable)
    •    A11y tested (VoiceOver, Dynamic Type, Reduce Motion)
    •    Previews with realistic data
    •    No layout jank on iPhone SE → Pro Max

If a requested flow conflicts with Business Policy, propose the closest compliant alternative and update this doc.

