# chatgpt_docs/15_RELEASE_NOTES_TEMPLATE.md
# Vector — Release Notes Template

> Use this file as your source of truth for each release. Copy the relevant sections into:
> - **App Store “What’s New”**
> - **TestFlight Beta Notes**
> - **GitHub Releases**

---

## 0) Release Header

- **App Version (Marketing):** `X.Y.Z`
- **Build Number:** `NNNN`
- **Codename (optional):** `<codename>`
- **Date:** `YYYY-MM-DD`
- **Targets:** iOS (min iOS `xx`), Widgets, Watch (if applicable)
- **Highlights (1-line):** _A crisp sentence users will see first._

---

## 1) App Store — “What’s New” (short & friendly)

> Keep to **2–5 bullets**, plain English, benefit-oriented. No technical jargon.  
> Suggested character target: **~300–600** (App Store shows a short preview).

- New: …
- Improvements: …
- Fixes: …

**One-liner (very short fallback, ~140–170 chars):**  
`…`

---

## 2) Extended Release Notes (GitHub / Website)

### ✨ New
- **[Free/Pro] Feature:** What it does, where to find it, and why it helps.
- **[Pro] Feature:** Note that it’s gated ethically (tap to try → paywall).

### 🔧 Improvements
- UI polish, micro-interactions, accessibility tweaks, copy updates, etc.

### 🐞 Fixes
- Issue #123: …
- Crash on … resolved by …
- Edge case handling for …

### ⚡ Performance & 🔎 Accessibility
- Token list frame time down to … ms on iPhone …
- VoiceOver labels added/updated for …
- Respects Reduce Motion in …

### 🔐 Security & Privacy
- Keychain access tuned (`kSecAttrAccessibleWhenUnlocked`, synchronizable).
- Backup AES-GCM params: random 12-byte nonce, PBKDF2-HMAC-SHA256 (≥150k iters).
- Privacy screens: app switcher snapshot shield; screen-recording blur.

### 💳 Payments (StoreKit 2)
- Products: `pro.monthly`, `pro.lifetime`, `tip.small`, `tip.large`.
- Paywall copy refresh / purchase flow fixes …

### 🧩 Known Issues (transparent)
- Rare … under conditions … Workaround: …

---

## 3) Migration Notes (developers)

- **Schema/Model changes:**  
  - Token model: … (non-breaking / breaking)
- **Keychain:**  
  - Keys added/renamed: `vault.tokens`, …
- **Backup format:**  
  - Envelope vN → vN+1 changes: salt length, metadata fields, etc.
- **Widget/Watch:**  
  - Timeline payload changed: …
- **Action Required:**  
  - If previous version < X.Y: perform one-time migration step …

---

## 4) QA Checklist (tick before shipping)

- [ ] Cold launch (airplane mode / poor network).
- [ ] Onboarding (intro → vault) success.
- [ ] Add Token (manual + QR) happy/invalid paths.
- [ ] Vault list performance on device (≤ 4 ms/frame typical).
- [ ] Copy OTP → clipboard expires (≤ 20s), localOnly.
- [ ] Privacy: screen record → content blurred; app switcher shows “Locked”.
- [ ] Pro gating: toggling iCloud sync / backup / widgets shows paywall if not Pro.
- [ ] Purchase, cancel, restore; entitlement reflected live.
- [ ] Backup export/import round-trip (500 tokens).
- [ ] Accessibility: VoiceOver announces issuer/account; reduced motion respected.
- [ ] No secrets in logs/metrics. Local metrics events recorded.
- [ ] App Store screenshots match UI; Launch Screen OK.

---

## 5) Store Metadata (for App Store Connect)

**Subtitle (≤30 chars):**  
`Private 2FA, Pro tools`

**Promotional Text (≤170 chars):**  
`Vector keeps 2FA private—unlimited codes free. Pro adds iCloud sync, encrypted backups, Watch & widgets. No ads. No tracking.`

**Keywords:**  
`2FA, authenticator, TOTP, privacy, security, iCloud, backup, OTP`

**Support URL:** `https://…`  
**Marketing URL:** `https://…`  
**Privacy Policy URL:** `https://…`

**Export Compliance:**  
- Uses only Apple Crypto (CryptoKit); **Non-exempt encryption** = `false`.

---

## 6) Localizations (delta)

- Updated strings: `Intro`, `Paywall`, `Settings → Sync`, …
- New locales added: …
- Reviewer note (if any UI is gated or geo-specific): …

---

## 7) Developer Commands

```bash
# Bump versions in Xcode (Marketing + Build), then:
git add -A
git commit -m "release: Vector vX.Y.Z (build NNNN)"
git tag -a vX.Y.Z -m "Vector vX.Y.Z"
git push origin main --tags

Archive & Upload:
    •    Xcode → Product → Archive → Distribute → App Store Connect.
    •    Attach this “What’s New”; choose Phased Release (recommended).
    •    Submit for review.

⸻

8) Template Examples

Example “What’s New” (concise)
    •    Encrypted backups (Pro): safely move codes across devices
    •    Slicker token list & faster QR scanner
    •    Stronger privacy during screen recording
    •    Many fixes & performance improvements

Short one-liner:
Encrypted backups (Pro), a faster vault, and stronger privacy. Many fixes.

⸻

9) Rollback Plan
    •    Keep previous build live until new build status is Ready for Sale.
    •    If critical issue emerges:
    1.    Pull from sale or submit hotfix vX.Y.(Z+1).
    2.    Post note in GitHub Release.
    3.    Update “Known Issues” in the next TestFlight notes.

⸻

10) Sign-off
    •    Engineering: @name — date
    •    Design: @name — date
    •    QA: @name — date
    •    Owner: @name — date


