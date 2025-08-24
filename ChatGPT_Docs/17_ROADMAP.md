# chatgpt_docs/17_ROADMAP.md
# Vector — Product & Engineering Roadmap

Single source of truth for near/medium/long-term goals. Dates are **relative sprints** (1 sprint = ~1 week). Each milestone lists: goals, scope, acceptance criteria (AC), dependencies, and risks.

---

## KPIs & Guardrails (apply to all sprints)

- **Crash-free sessions:** ≥ 99.7%
- **Cold launch:** ≤ 800 ms on iPhone 12+ (post-splash)
- **OTP list frame time:** ≤ 4 ms p90
- **Paywall ethics:** “Maybe later” always present; no dark patterns
- **Privacy:** No third-party tracking; local metrics only
- **Security:** No plaintext secrets outside memory; AES-GCM backups; `kSecAttrAccessibleWhenUnlocked` + `kSecAttrSynchronizable=true`
- **A11y:** Dynamic Type, VoiceOver labels, Reduce Motion respected

---

## Near-Term

### M1 — v1.1 Monetization (Sprint 1)
**Goal:** Ship ethical Pro paywall + gating with StoreKit 2.  
**Scope:**
- Add `Entitlements` (StoreKit 2) and `Metrics` (local JSON)
- Implement `PaywallView` (monthly + lifetime + restore + maybe later)
- Gate Pro surfaces: iCloud sync toggle, encrypted backup, Watch, Widgets, brand icons, bulk import
- Soft upsell after ≥2 accounts (settings visit)  
**AC:**
- Paywall products load within 1.5s on Wi-Fi
- Purchase, cancel, and restore paths tested via StoreKit config
- Metrics log: `paywall_shown`, `pro_purchased`, `sync_enabled`, `backup_exported`
**Deps:** App Store Connect products (`pro.monthly`, `pro.lifetime`, `tip.small`, `tip.large`)  
**Risks:** Receipt/entitlement mismatch on first install → mitigate with `Transaction.currentEntitlements` refresh on app start

---

### M2 — v1.2 Backups & Import Polish (Sprint 2)
**Goal:** Reliable, encrypted backups + robust import UX.  
**Scope:**
- Implement `BackupService` (PBKDF2 + AES-GCM) + passphrase policy (≥10 chars, strength meter)
- Import: `otpauth://` + CSV with detailed error surfacing
- “Explain backup” sheet + warnings for weak passwords
**AC:**
- 500 tokens: export < 1s / import < 1.5s (iPhone 12+)
- Round-trip unit tests pass; corrupted envelope errors are friendly
**Deps:** None (pure client)  
**Risks:** Very old devices PBKDF2 perf → fallback iterations (≥100k)

---

### M3 — v1.3 iCloud Keychain Sync (Sprints 3–4)
**Goal:** Seamless cross-device vault via synchronizable Keychain.  
**Scope:**
- Store OTP secrets with `kSecAttrSynchronizable=true`
- Conflict policy: last-writer wins; log merge events locally
- Read-through in-memory cache + change observation
- LAContext prompt on unlock (optional)
**AC:**
- Add token on Device A → appears on Device B within iCloud Keychain propagation window
- Toggle “Sync” requires Pro and logs `sync_enabled`  
**Deps:** iCloud Keychain enabled on test devices; consistent bundle ID & Keychain access groups  
**Risks:** Misconfigured entitlements → add preflight diagnostics

---

### M4 — v1.4 Apple Watch (Sprints 5–6)
**Goal:** Glanceable codes on watchOS with privacy defaults.  
**Scope:**
- watchOS target + minimal list UI (issuer, code, seconds)
- Sync via Keychain (if viable across targets) or App Group snapshot (precomputed code + expiry)
- “Tap to reveal” default; adjust for Reduce Motion  
**AC:**
- Timeline remains ≤20ms compute per refresh
- Codes match iPhone within 1s drift  
**Deps:** Watch target, shared Access Group/App Group  
**Risks:** Keychain sharing quirks → prefer App Group snapshot if needed

---

### M5 — v1.5 Widgets (Sprint 7)
**Goal:** Small/medium widgets with privacy by default.  
**Scope:**
- Provider precomputes `{code, expiry}`; no HMAC in timeline
- “Tap to reveal” toggle with explicit consent
**AC:**
- Timeline performance ≤20ms p90
- No unobscured codes unless user opted-in  
**Deps:** Widget extension, App Group  
**Risks:** Stale timelines → schedule refresh at expiry−1s

---

### M6 — v1.6 Visual Polish & Onboarding (Sprint 8)
**Goal:** Mature visual brand; trustworthy feel.  
**Scope:**
- `AppHeader` across major surfaces (Splash/Intro/Vault/Add/Settings/Paywall)
- Fine motion (≤120ms) guarded by Reduce Motion
- Empty states & helpful footers in forms  
**AC:**
- App-wide design tokens used (BrandColor/Typography/Spacing)
- No overlapping toolbars; previews cover dark/light, large text  
**Deps:** UI token audit  
**Risks:** Over-animation → adhere to budget

---

## Medium-Term

### M7 — v1.7 Localization (Sprint 9)
**Goal:** Ship at least 2 languages (e.g., EN + AR).  
**Scope:**
- Localize strings; right-to-left audit; fix truncation
**AC:** Screenshots verified for both locales in key sizes  
**Deps:** String tables  
**Risks:** Layout regressions → snapshot tests

---

### M8 — v1.8 Importers & Brand Icons (Sprint 10)
**Goal:** Smoother onboarding for switchers + visual clarity.  
**Scope:**
- Import helpers (Authy/Google/1Password export formats)
- Optional brand icons (Pro); graceful fallback to color dots  
**AC:** ≥90% of test files import without manual edits  
**Deps:** Public export formats  
**Risks:** Format drift → defensive parsing

---

### M9 — v1.9 Security Hardening (Sprint 11, ongoing)
**Goal:** Raise bar on local threats.  
**Scope:**
- Background blur + screenshot/recording detection (`PrivacySensitiveView`)
- Keychain access group minimization; audit LAContext flows
- Threat model doc update  
**AC:** Automated checks for privacy overlays in sensitive screens  
**Deps:** N/A  
**Risks:** False positives on capture → simple override UX

---

## Long-Term / Exploratory

### M10 — v2.0 Quality & Teams-Friendly Improvements (Sprints 12–14)
**Goal:** Reliability & scale polish; optional family use **without servers**.  
**Scope (candidate):**
- Diagnostics screen (sync state, clock drift, iCloud status)
- Import/export presets & auto-repair suggestions
- Family sharing guidance via iCloud (educational, not multi-user sync)
**AC:** Support volumes of 1k tokens with acceptable perf  
**Deps:** None  
**Risks:** Scope creep → keep serverless promise

---

## Cross-Cutting Engineering

- **Tests:** RFC6238 vectors; Keychain CRUD (sync); backup round-trip; StoreKit purchase/restore; snapshot tests (Add Token, Paywall)
- **Perf:** Instruments on vault list & widget provider; retain cycles scrub
- **CI (optional):** Fastlane lanes for build, unit tests, screenshots
- **Release:** TestFlight every sprint; phased App Store rollouts

---

## Backlog Ideas (triage later)

- Search & tag management enhancements (merge, rename)
- Per-token notes (encrypted)
- Secure pasteboard w/ auto-clear + “copy with timestamp”
- Import validator with live error preview
- Optional app lock on background immediately vs delayed

---

## Dependencies Matrix

| Feature                 | Needs                              |
|-------------------------|------------------------------------|
| Paywall (v1.1)          | App Store products, StoreKit cfg   |
| Backups (v1.2)          | CryptoKit, file access             |
| iCloud Sync (v1.3)      | iCloud Keychain, Keychain group    |
| Watch (v1.4)            | watchOS target, App Group/Keychain |
| Widgets (v1.5)          | WidgetKit, App Group               |
| Localization (v1.7)     | String tables, RTL audit           |

---

## Release Checklist (per version)

- [ ] All ACs satisfied; unit & snapshot tests pass
- [ ] StoreKit config tested: buy/cancel/restore
- [ ] Privacy review: no sensitive data in logs/files
- [ ] A11y audit: labels, Dynamic Type, Reduce Motion
- [ ] App Store metadata & screenshots up to date
- [ ] Create tag & GitHub release notes (see `15_RELEASE_NOTES_TEMPLATE.md`)
- [ ] Phase rollout configured

---

## Risks & Mitigations (quick)

- **iCloud Keychain propagation delays** → Educate users; optimistic UI; background refresh
- **PBKDF2 perf on old devices** → Adaptive iterations (≥100k), progress UI
- **Entitlement desync** → Refresh on foreground; explicit “Restore Purchases”
- **Widget staleness** → Schedule refresh at expiry−1s; user-initiated tap refresh

---

## Version Naming

- v1.1 “Pro, Ethically” — Paywall + Gating  
- v1.2 “Bring-Along” — Backups/Import  
- v1.3 “Cloud-Sure” — iCloud Keychain Sync  
- v1.4 “Wrist-Ready” — Watch  
- v1.5 “At-a-Glance” — Widgets  
- v1.6 “Polish Pass” — Visual & Onboarding  
- v1.7 “Speak More” — Localization  
- v1.8 “Open Door” — Importers & Icons  
- v1.9 “Hardened” — Security  
- v2.0 “Scale & Quality” — Reliability at volume
