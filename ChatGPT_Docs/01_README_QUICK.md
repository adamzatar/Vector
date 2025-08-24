# chatgpt_docs/01_README_QUICK.md
# Vector — Privacy-First 2FA (Quick README)

Vector is a **SwiftUI authenticator** for time-based one-time passwords (TOTP).  
**Free forever:** unlimited tokens, QR/manual add, Face/Touch ID lock.  
**Pro (optional):** iCloud Keychain sync, encrypted backups, Apple Watch, Widgets, brand icons, bulk import.  
**Privacy:** no third-party analytics. Local metrics only.

---

## 🧭 App Flow

1. **Launch → Splash** → routes to **Intro** (first run) or **Vault**.  
2. **Vault (Home)** → token list (issuer, account, TimeRing, copy).  
3. **Add Token** → manual or QR scan; validates Base32, algo/digits/period.  
4. **Settings** → security, clipboard timeout, Face/Touch ID; Pro gates trigger paywall.  
5. **Backup** → (Pro) encrypted export/import (AES-GCM + PBKDF2).  
6. **Paywall** → shown only for Pro attempts or soft upsell (≥ 2 accounts).

---

## 🗂 Structure (essentials)

Vector/
App/
VectorApp.swift           # @main entry
AppRootView.swift         # Router → Splash/Intro/Vault/Add/Settings
Router.swift              # AppRouter for navigation
Assets.xcassets/          # Icons, mark, launch assets
LaunchScreen.storyboard   # Static launch

Config/
Info.plist                # Build setting must point here
Debug.xcconfig
Release.xcconfig

Features/
Onboarding/               # SplashView, IntroScreen (+ components)
Vault/                    # VaultView, TokenRow, TimeRing
AddToken/                 # AddTokenView, QRScannerView, ViewModels
Backup/                   # Import/Export views
Settings/                 # SettingsView (+ rows/toggles)
Paywall/                  # PaywallView (+ components)

Models/
Token.swift
VaultMeta.swift
DTOs/

Services/
Infra/                    # DIContainer, Entitlements, Metrics, FeatureFlags
Crypto/                   # CryptoService, KDF
Vault/                    # VaultStore
Sync/                     # CloudSync
Keychain/                 # KeychainStore
ImportExport/             # OTPAuthParser, BackupExporter
Time/                     # TimeSkewService
AppLock/                  # AppLockService

UI/
Components/               # Card, Buttons, CopyToast, etc.
Design/                   # Colors, Typography, Spacing
Modifiers/                # View+If, CaptureShield

> Full spec docs live in `chatgpt_docs/` (instructions, security, tests, UI catalog, release checklist).

---

## 🧰 Requirements

- **Xcode** 15+  
- **iOS** 16+ target (adjust as needed)  
- **Bundle ID** unique to your team  
- **Info.plist path**: Build Settings → *Packaging* → **Info.plist File** = `Vector/Config/Info.plist`

---

## ▶️ Build & Run

1. Open `Vector/Vector.xcodeproj`.  
2. Select **Vector** scheme → simulator or device.  
3. **Run (⌘R)**.

**Local StoreKit (optional):**  
Create a `.storekit` config with products:
- `pro.monthly` ($0.99/mo)
- `pro.lifetime` ($14.99)
- `tip.small` ($2.99)
- `tip.large` ($9.99)  
Scheme → Run → Options → StoreKit Configuration → select the file.

---

## 💳 Pro Gating

Trigger **Paywall** when user attempts:
- iCloud Sync, Encrypted Backup, Apple Watch / Widgets, Brand Icons, Bulk Import  
Soft upsell after **≥ 2 accounts** in Settings.

---

## 🔒 Security Defaults

- **Keychain:** `kSecAttrAccessibleWhenUnlocked`, `kSecAttrSynchronizable = true` (iCloud Keychain)  
- **Backups:** AES-GCM + PBKDF2-HMAC-SHA256 (≥150k iters), random 16-byte salt & 12-byte nonce  
- **Privacy:** `.privacySensitive()` on token UI; blur while screen recording  
- **Serverless:** iCloud Keychain/Drive only (no external servers)

---

## ♿ Accessibility & Motion

- Dynamic Type throughout (Typography ramp)  
- VoiceOver on token rows (e.g., “code 123 456, 12 seconds left”)  
- Respect **Reduce Motion** (disable pulses/scale; quick fades only)  
- Tap targets ≥ 44×44pt

---

## ✅ Tests to Run

- **TOTP:** RFC6238 vectors (SHA1/256/512), 6/8 digits  
- **Crypto:** backup export→import round-trip  
- **Keychain:** save/load/delete (synchronizable)  
- **StoreKit:** purchase/cancel/restore (local config)  
Run with **⌘U** or Test navigator.

---

## 🧽 Troubleshooting

- **Info.plist not found:** point to `Vector/Config/Info.plist`.  
- **SwiftUI Section generic errors:** use `private func sectionFoo() -> some View` (not computed vars).  
- **fileImporter type mismatch:** single selection returns `URL`, multiple returns `[URL]`.  
- **“Left side of ?? is non-optional”:** remove `??` when property is non-optional.  
- **Xcode freeze:** Force Quit →  
  `rm -rf ~/Library/Developer/Xcode/DerivedData/*` → relaunch.

---

## 📦 Release

- Update `MARKETING_VERSION` + `CURRENT_PROJECT_VERSION`  
- Confirm products live in App Store Connect  
- Full test pass + manual paywall/restore on 2 devices  
- Tag `v1.x.y` and ship TestFlight

---

## 🙋 Policy

- **Privacy:** no tracking; local metrics only.  
- **Support:** GitHub issues or app support link.  
- **License:** TBD (add LICENSE).
