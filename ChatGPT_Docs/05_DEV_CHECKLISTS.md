# chatgpt_docs/05_DEV_CHECKLISTS.md
# Vector — Developer Checklists

Short, ruthless checklists to keep the app reliable, fast, and on-brand.  
Tick through these before commits, PRs, and releases.

---

## 0) Daily Start
- [ ] Pull `main`, resolve conflicts locally.
- [ ] Clean build if Xcode is weird: `Shift+Cmd+K` (or nuke DerivedData if needed).
- [ ] Run app on a **physical device** at least once.

---

## 1) While Coding (Golden Rules)
- [ ] Use **BrandColor / Typography / Spacing** tokens (no raw `Color.gray`, etc.).
- [ ] `Section` content defined as **functions** (`@ViewBuilder private func sectionX() -> some View`) not computed vars.
- [ ] Bindings are **real** bindings: `@Published` in VM + `$vm.prop` in views.
- [ ] Optional enum selections use a **non-optional binding bridge**.
- [ ] Main-actor UI state changes inside `Task { @MainActor in … }`.
- [ ] No paywall on first-run; paywall only on Pro taps or gentle upsell.

---

## 2) Pre-Commit
- [ ] Builds **Debug** (iPhone target) with no warnings you introduced.
- [ ] SwiftUI previews compile for changed files.
- [ ] Unit tests (TOTP/Crypto/Keychain/StoreKit) pass locally.
- [ ] `.gitignore` excludes `Library/`, `.gitkraken/`, `DerivedData/`, `.DS_Store`.
- [ ] No secrets / local paths / usernames leaked into code or configs.
- [ ] Files have `// File: …` headers and sensible access control (avoid `private` if reused).

---

## 3) Pre-Push / Pre-PR
- [ ] Light device sanity pass: add token, copy code, scan QR, settings toggles.
- [ ] **Accessibility quick pass:** VoiceOver reads issuer/account/code; Reduce Motion respected.
- [ ] Performance spot check: vault list scrolls smoothly; no obvious layout thrash.
- [ ] Metrics events added where appropriate (`account_added`, `paywall_shown`, etc.).

---

## 4) PR Checklist
- [ ] Title/description explain **user value** + any business implication (Pro gating).
- [ ] Screenshots / short screen capture included for UI PRs.
- [ ] Edge cases described (e.g., no camera permission, empty imports).
- [ ] Migration notes if persistence changed (none expected in v1.x).
- [ ] Rollback plan (simple revert) if things go south.

---

## 5) Release / TestFlight
- [ ] Version bump in **Config/Debug.xcconfig** & **Release.xcconfig** (MARKETING_VERSION).
- [ ] **Info.plist** path correct: `Vector/Config/Info.plist`.
- [ ] App icons / launch assets present and referenced by target.
- [ ] Local StoreKit config updated with product IDs:
  - `pro.monthly`, `pro.lifetime`, `tip.small`, `tip.large`
- [ ] Manual paywall flow test: purchase, cancel, restore.
- [ ] Real device tests: camera scan, background/foreground lock, copy toast, recording blur.
- [ ] Privacy nutrition labels accurate (no third-party tracking).

---

## 6) UI & Design System
- [ ] No raw fonts/sizes: use `Typography.titleS/M/L/XL`, `Typography.body`, `Typography.caption`, `Typography.monoM`.
- [ ] Backgrounds are `BrandColor.surface` or gradient; text is `BrandColor.primaryText`.
- [ ] Dividers use `BrandColor.divider`; subtle shadows from layout tokens only.
- [ ] Buttons: `PrimaryButton` / `SecondaryButton` components where possible.
- [ ] Token rows use monospaced digits, large tap targets, haptic on copy.
- [ ] Animated logo header (`AppHeader`) present at top of major screens and **properly layered**.

---

## 7) Accessibility
- [ ] Dynamic Type: no hard caps; labels scale without clipping.
- [ ] VoiceOver labels & values (e.g., “code 123 456, 12 seconds left”).
- [ ] Reduce Motion honored: wrap animations with `UIAccessibility.isReduceMotionEnabled`.
- [ ] Hit targets ≥ 44×44; `minTapTarget()` applied to small icons.

---

## 8) Performance
- [ ] Vault list refresh ≤ 4ms/frame (no heavy work in `body`).
- [ ] TOTP recompute **once per second**; ring uses a cheap progress update.
- [ ] Widget provider ≤ 20ms; pass precomputed code/expiry via model.
- [ ] Avoid extra `@Published` churn (combine changes, debounce where needed).

---

## 9) Concurrency & MainActor
- [ ] UI state (`@Published`) mutated on main actor only.
- [ ] AVFoundation session graph mutations on `sessionQueue`.
- [ ] Snapshot values on main before using in background closures.
- [ ] No “main actor isolated in nonisolated context” errors in Swift 6.

---

## 10) Camera / AVFoundation
- [ ] Request camera permission early; handle denied with settings CTA.
- [ ] `AVCaptureSession` configured once; inputs/outputs added on `sessionQueue`.
- [ ] Torch: lock/unlock device for configuration; publish `isTorchOn` on main.
- [ ] Metadata output delegate on `sessionQueue`; debounce scans.

---

## 11) Import / Backup
- [ ] `fileImporter` result type matches selection mode (URL vs [URL]).
- [ ] Parser uses `OTPAuthParser.parse(_:)` (not `uri:` label).
- [ ] CSV: trims, tolerates missing columns, skips bad rows, shows first error.
- [ ] Backup export/import uses AES-GCM + PBKDF2 (random salt + nonce).

---

## 12) Keychain & Sync
- [ ] `kSecAttrAccessible = kSecAttrAccessibleWhenUnlocked`.
- [ ] Synchronizable for iCloud: `kSecAttrSynchronizable = true` on save; `kSecAttrSynchronizableAny` on read/delete.
- [ ] Access Group/App Group consistent across targets if/when needed.
- [ ] No plaintext secrets on disk; no logging of secrets.

---

## 13) StoreKit 2 / Pro Gating
- [ ] Trigger paywall **only** on Pro features (sync, backups, watch, widgets, brand icons, bulk import) or soft upsell after ≥ 2 accounts.
- [ ] `Entitlements.isPro` checked before enabling Pro surfaces.
- [ ] Products loaded with IDs above; `purchase` / `restore` flows tested.
- [ ] Log `paywall_shown`, `pro_purchased`.

---

## 14) Metrics (Local Only)
- [ ] Use local `Metrics` utility (no SDKs).
- [ ] Events logged where they matter; no PII stored.

---

## 15) Testing (minimum bar per PR)
- [ ] TOTP RFC6238 vectors for the touched algo/path.
- [ ] Backup round-trip test for any change to crypto or serialization.
- [ ] Keychain CRUD test runs (mock if needed).
- [ ] StoreKit local config runs: purchase cancel/restore logic still works.

---

## 16) Xcode Project Hygiene
- [ ] Target Membership correct for new files.
- [ ] Build phases not duplicating resources.
- [ ] `Info.plist` path consistent across configurations.
- [ ] No leftover placeholders routed in `AppRootView`.

---

## 17) Git Hygiene
- [ ] Commit limited to **Vector/** (and optionally **chatgpt_docs/**).
- [ ] No OneDrive/Library artifacts in history.
- [ ] Atomic commits with succinct messages: *verb + scope + value*.

---

## 18) Troubleshooting Quick Commands
```sh
# Kill DerivedData
rm -rf ~/Library/Developer/Xcode/DerivedData/*

# Reset git index noise (if junk was staged)
git rm -r --cached Library .gitkraken
echo -e "Library/\n.gitkraken/\nDerivedData/\n.DS_Store\nxcuserdata/\n" >> .gitignore

# Verify Info.plist path (should print Vector/Config/Info.plist)
xcodebuild -showBuildSettings | grep -i "INFOPLIST_FILE"

# Reinstall pods/SPM (if relevant)
# (Using SPM by default; open workspace again after)
