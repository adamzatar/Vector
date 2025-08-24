# chatgpt_docs/11_SECURITY_THREAT_MODEL.md
# Vector — Security Threat Model (Authoritative)

Privacy-first by design. This model enumerates what we protect, who from, how, and the tests that
prove it. Keep this document and the code in lockstep.

---

## 1) Scope & Architecture

- **Data residency:** _On-device only_. No first/third-party servers.
- **Sync:** iCloud **Keychain** (via `kSecAttrSynchronizable=true`) — E2E by Apple.
- **Backups:** Optional user-initiated, **encrypted** (AES-GCM) with passphrase-derived key (PBKDF2-HMAC-SHA256).
- **UI surfaces:** App, Widgets, Watch. Widgets/Watch default to **tap-to-reveal**.

---

## 2) Assets (what we protect)

1. **OTP secrets** (TOTP/HOTP seeds)
2. **Derived codes** (30s disposable values)
3. **Metadata** (issuer, account, tags, color)
4. **Encrypted backups** (files user exports)
5. **Local settings** (clipboard timeout, Face ID lock, etc.)

Non-secret but sensitive: app usage patterns, paywall events (stored **locally** only).

---

## 3) Trust & Assumptions

- The user’s Apple ID and device secure enclave are uncompromised.
- iOS code integrity / sandbox enforced; device not jailbroken (we **degrade gracefully** if detected).
- iCloud Keychain provides E2E encryption for synchronizable Keychain items.
- We never log secrets or codes.

**If jailbroken / debugger attached:** we warn, reduce features (e.g., disallow backups), and require strong local auth.

---

## 4) Adversaries

1. **Casual shoulder-surfer** (glancing at screen)
2. **Opportunistic local attacker** (brief device access, unlocked)
3. **Malware/rogue app** (attempts to scrape screen/clipboard)
4. **Lost/stolen device** (locked)
5. **Cloud adversary** (access to iCloud storage but **not** user passphrase)
6. **Supply chain attacker** (tampered build or injected dependency)

Out of scope: nation-state targeting across OS trust boundaries.

---

## 5) Attack Surfaces & Controls

### A. At Rest (device storage)
- **Threat:** Extraction of secrets from disk.
- **Control:** iOS **Keychain** with `kSecAttrAccessibleWhenUnlocked` and `kSecAttrSynchronizable=true`.  
  Optional secondary gate with **LocalAuthentication** (Face/Touch ID) before reads.
- **Rationale:** Hardware-backed keys + class A protection when device locked.

### B. In Memory (runtime)
- **Threat:** Process memory scraping.
- **Control:** Keep secrets in Keychain; load transiently only to compute codes; avoid retaining in view state.  
  No debug prints; no crash logs with secrets. Use `.privacySensitive()` on sensitive views.

### C. Backups (export/import)
- **Threat:** Backup file leaks.
- **Control:** AES-GCM(256) with **random 16-byte salt**, **random 12-byte nonce**, PBKDF2-HMAC-SHA256 ≥ **150k** iters, min 10-char passphrase.  
  Store `{salt, nonce, ciphertext, tag}`; never store passphrase or derived key.
- **Rationale:** Offline resistance vs. brute force; GCM for integrity.

### D. Clipboard
- **Threat:** Other apps read copied code.
- **Control:** Copy with auto-clear (**≤ 20s** default), “Copied” toast, privacy explanation.  
  Never copy **secrets**, only short-lived **codes**.

### E. Screen exposure (recording / app switcher / screenshots)
- **Threat:** Codes visible in captures.
- **Control:** `.privacySensitive()` + **ScreenCaptureObserver** → blur overlay when recording detected.  
  Widgets/Watch **tap-to-reveal** by default.

### F. UI Phishing / QR injection
- **Threat:** Malicious `otpauth://` QR with oversized/invalid params.
- **Control:** Strict parser (size caps, allowlist params, Base32 validation), safe defaults, reject on overflow.  
  Debounce scanner events; no deep links that execute actions.

### G. Sync
- **Threat:** Interception in transit / Apple infra compromise.
- **Control:** iCloud **Keychain** only (E2E by Apple). We do not implement custom sync transports.

### H. Supply chain
- **Threat:** Tampered dependencies/builds.
- **Control:** Apple-native frameworks; SPM pinning; Xcode managed signing; CI notarization (when added).  
  Verify StoreKit via local config during development.

---

## 6) Security Requirements (non-negotiable)

- **Keychain class:** `kSecAttrAccessibleWhenUnlocked` for all secrets.  
- **Synchronizable:** `kSecAttrSynchronizable=true` for items that must sync.  
- **Local Auth gate:** require Face/Touch ID before revealing secrets or exporting backup.  
- **Backups:** AES-GCM(256), PBKDF2-SHA256 ≥150k iters, random salt/nonce per backup.  
- **No logs:** never print secrets/codes; DEBUG logs allowed for benign events only.  
- **Privacy UI:** `.privacySensitive()` everywhere codes appear; blur on capture.  
- **Widgets/Watch:** default tap-to-reveal; show warning if user opts-in to auto-reveal.  
- **Clipboard:** auto-clear ≤20s; never copy secrets.  
- **Parser:** validate/normalize `otpauth://`; reject suspicious payloads.  
- **Paywall:** ethical; Pro features never weaken core security.

---

## 7) Detection & Hardening

- **Jailbreak heuristics:** if detected → force local auth every open; disable backups; warn user.
- **Tamper hints:** sudden entitlement mismatch / bundle ID change → invalidate sensitive flows.
- **Rate limiting:** QR scans + import lines; cap lines/file size to prevent resource exhaustion.

---

## 8) Test Matrix (prove controls)

- **Keychain CRUD (sync):** write→read→delete; verify `kSecAttrSynchronizable`; confirm second device observe.
- **Local Auth:** LAContext flow denies on failed auth; bypass not possible.
- **Backup round-trip:** 500 tokens export→import equality; nonce unique; salt unique; wrong passphrase fails.
- **RFC6238:** SHA1/256/512 vectors; 6/8 digits; periods 15/30.
- **Clipboard:** clears within timeout; not retained across app relaunch.
- **Screen capture:** toggling recording overlays blur; widgets stay hidden until tap.
- **Parser fuzz:** oversized labels, invalid Base32, unknown params → rejected safely.

---

## 9) Incident Response (user guidance baked into Settings)

- **Lost device:** rely on device lock; remotely wipe with Find My; sign out of Apple ID.
- **Suspected compromise:** rotate 2FA with service providers; purge vault: `VaultStore.reset()`; clear synchronizable Keychain; delete backups.
- **Leaked backup:** treat as compromised; assume offline brute force; re-issue secrets.

In-app: “Emergency Reset” clears vault + Keychain + app data after Face ID + confirmation.

---

## 10) Residual Risks & Trade-offs

- **Clipboard exposure window** (≤20s) — user override reduces risk further.
- **Passphrase strength** for backups is user-dependent — we enforce length + meter, but cannot guarantee quality.
- **Jailbroken devices** weaken sandbox — we harden but cannot fully protect.

---

## 11) Future Work

- **Argon2id** derivation (when available natively) or CryptoKit-backed HKDF with strong pre-key.
- **Secure Enclave sealed backup key** (device-tied optional mode).
- **Automatic vault wipe** after N failed local-auth attempts (opt-in).
- **Attestation of build (RCT/AS)** when ecosystem support is practical.

---

## 12) Snippets (reference)

**Keychain write (sync + WhenUnlocked)**
```swift
let query: [String: Any] = [
  kSecClass as String: kSecClassGenericPassword,
  kSecAttrService as String: "app.vector.vault",
  kSecAttrAccount as String: key,
  kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked,
  kSecAttrSynchronizable as String: kCFBooleanTrue as Any,
  kSecValueData as String: data
]
SecItemDelete(query as CFDictionary)
let status = SecItemAdd(query as CFDictionary, nil)
precondition(status == errSecSuccess)
