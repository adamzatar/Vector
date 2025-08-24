LEGAL_RESTRICTIONS.md

Scope: Hard rules and red-lines for the Vector authenticator project.
Audience: All contributors (engineering, product, marketing).
Status: Enforced. Non-compliance blocks release.
Disclaimer: This is compliance guidance, not formal legal advice.

⸻

0) Severity legend
	•	Severity: HIGH, MEDIUM, LOW (Likelihood × Impact)
	•	Any item marked [BLOCKER] must be resolved before testflight/release.

⸻

1) Immigration & Monetization (F-1 status) — [BLOCKER]

Applies to: Project owner is an F-1 student (OPT/CPT unused).
	•	MUST NOT accept revenue, equity-for-work, compensation, or provide services that create commercial value in the U.S. before CPT/OPT is authorized. Severity: HIGH
	•	MUST operate as passive owner only until authorization. No operational work “for free” at your own for-profit. Severity: HIGH
	•	MUST keep all monetization features disabled (IAP SKUs defined but feature-flagged OFF) until OPT/CPT is in place and documented in the repo (/compliance/immigration/authorization.pdf). Severity: HIGH
	•	MUST add a CI check that blocks merges if MONETIZATION_ENABLED=true while immigration/authorization.pdf is missing. Severity: HIGH

Allowed now: personal learning build; internal testing with no revenue and no paid customers.

⸻

2) App Store Compliance — [BLOCKER]
	•	Payments: All paid digital features (e.g., iCloud sync, backups, watch app) MUST use StoreKit IAP.
	•	MUST NOT link to external purchase flows or mention external pricing inside the app. Severity: HIGH
	•	Push: Push must be optional; TOTP fallback fully usable with push disabled. Severity: HIGH
	•	MUST NOT send marketing pushes without explicit in-app consent and easy opt-out. Severity: HIGH
	•	Account Deletion: If any server account exists, MUST provide in-app delete account & data flow (immediate request, device auth, server wipe). Severity: HIGH
	•	Privacy Label & Manifest: App Privacy “nutrition label” and Privacy Manifest MUST accurately declare:
	•	Identifiers: APNs token, Apple userIdentifier (if used)
	•	Diagnostics: crash reports (if any)
	•	Usage Data: audit timestamps (if retained)
	•	Required Reason APIs: declare reasons where Apple requires. Severity: HIGH
	•	Background behavior: MUST NOT use background tasks or push for anything outside authentication/security use cases. Severity: MEDIUM

⸻

3) Security & Secrets — [BLOCKER]
	•	TOTP secrets (RFC 4226/6238) MUST never leave the device unencrypted. Severity: HIGH
	•	Store in Keychain with kSecAttrAccessibleWhenUnlocked and (where available) Secure Enclave–backed keys.
	•	MUST NOT log secrets, OTPs, QR payloads, or seed URIs. Redact crash/analytics.
	•	Backups/Exports: If offering encrypted backup/export, MUST use AES-GCM with a strong KDF (e.g., Argon2id/scrypt; high work factor) and per-file random salt/nonce. No password hints. Severity: HIGH
	•	Transport: MUST use TLS 1.2+; pin leaf or intermediate if feasible; enable CT logging checks. Severity: MEDIUM
	•	Replay/Abuse: Rate-limit approvals; nonce + expiry on approval tokens; server stores no TOTP seeds. Severity: MEDIUM
	•	Key Handling: Server may hold public device keys only. MUST NOT derive or reconstruct secrets server-side. Severity: HIGH

⸻

4) Data Protection (GDPR/CCPA) — [BLOCKER] if serving real users

Data you said you collect: internal UUID, Apple userIdentifier, device public key, APNs token, trust score, audit timestamps, coarse IP hash.
	•	Lawful Basis: Document legitimate interests for security, with a balancing test in /compliance/gdpr/LIA.md. Severity: HIGH
	•	Rights: Implement Access (export JSON) and Deletion (full wipe) endpoints; surface both in-app and on a privacy page. Severity: HIGH
	•	Transparency: Publish a concise privacy notice describing data elements, purposes, retention, and user rights. Severity: HIGH
	•	Minimization:
	•	Hash+salt IPs; never store raw IP.
	•	Default retention for audit logs ≤ 90 days, configurable; rotate salts/keys. Severity: MEDIUM
	•	EU→US Transfers: If EU users are allowed and hosting is in the U.S., sign SCCs with VPS/any processors and complete a transfer risk assessment. Place docs in /compliance/gdpr/transfers/. Severity: HIGH
	•	Children: Not directed to children; MUST block under-16 sign-ups where required. Severity: MEDIUM

⸻

5) Marketing & Claims — [BLOCKER] for release copy

Banned phrases (deceptive/absolute): “unhackable,” “military-grade” (without standard cited), bare “zero-knowledge,” “biometric-guarded keys” (vague).

Approved equivalents:
	•	“We never see your TOTP secrets. They’re generated and stored on your device and protected by Apple’s Keychain (Secure Enclave where available).”
	•	“No SMS costs: Vector uses standard time-based one-time passwords (RFC 6238) and optional push approvals.”
	•	“No plaintext storage of TOTP secrets or one-time codes.”
	•	“Open, standards-based 2FA (TOTP); on-device by default.”

Process: All public copy requires a claim-substantiation note in /compliance/marketing/claims.md linking to code references or docs. Severity: HIGH

⸻

6) Export Controls (U.S. EAR)
	•	The app uses cryptography; treat as ENC software.
	•	MUST maintain an ENC self-classification note (ECCN, rationale, date) in /compliance/export/enc.md. Severity: MEDIUM
	•	MUST NOT ship to embargoed destinations or prohibited parties. Add a geo-block list at distribution layer if needed. Severity: MEDIUM

⸻

7) Third-Party/AI-Generated Code & IP
	•	MUST own rights to all code/assets. If any external contributor exists, require a Contributor License Agreement (CLA) and assignment. Severity: MEDIUM
	•	MUST maintain an SBOM (/compliance/sbom.json) and pin licenses; no copyleft code in app target without legal review. Severity: MEDIUM
	•	MUST perform security review (static analysis + dependency audit) before each release; file results in /security/release-review.md. Severity: MEDIUM

⸻

8) Regulated Workloads (Scope Guard)
	•	MUST NOT market or position Vector as compliant with HIPAA/GLBA/PSD2/SCA unless those programs are implemented and contracts (e.g., BAA) are signed. Severity: HIGH
	•	Add a visible note: “Not intended for storage or transmission of PHI or regulated financial data.” Severity: MEDIUM

⸻

9) Trademarks & Naming
	•	“Vector” may be conflicted.
	•	MUST complete a knockout search in USPTO (classes 9 & 42) and document result in /compliance/ip/trademark-clearance.md before investing in branding. Severity: MEDIUM
	•	Keep a backup name (e.g., “Vector2FA,” “VectraAuth”). Severity: LOW

⸻

10) Telemetry, Logging & Retention
	•	Default retention: 30–90 days for server audit logs; document exact values. Severity: MEDIUM
	•	MUST NOT log secrets, OTPs, QR content, or full IPs. Severity: HIGH
	•	Provide a LOGGING.md specifying fields, redaction, and rotation schedule. Severity: MEDIUM

⸻

11) Incident Response & Breach
	•	Create /security/ir-plan.md with contacts, 24-hour triage, and decision tree. Severity: MEDIUM
	•	If personal data is implicated, follow statutory timelines (e.g., GDPR 72-hour authority notice). Severity: MEDIUM
	•	Maintain evidence handling and post-mortem template.

⸻

12) Vendor & Hosting
	•	MUST sign a DPA (data processing addendum) with VPS/any processor. Severity: HIGH
	•	MUST document data locations, encryption at rest, and access controls. Severity: MEDIUM

⸻

13) Change-Control & Gates

A pull request that toggles any of the following fails CI unless the linked checklist is green:
	•	MONETIZATION_ENABLED → requires /compliance/immigration/authorization.pdf ✅
	•	New data field in telemetry → requires PRIVACY_LABEL.md update ✅
	•	Push scope change → requires consent UX reviewed ✅
	•	New claim in marketing → requires claims.md entry ✅

⸻

14) “DO NOT” (Red-Line Summary)
	•	DO NOT monetize or accept revenue in the U.S. before OPT/CPT.
	•	DO NOT store or log TOTP secrets/OTPs in plaintext (anywhere).
	•	DO NOT require push to use the app; TOTP must work fully offline.
	•	DO NOT use external payment links; use IAP only.
	•	DO NOT ship without in-app account deletion if any server account exists.
	•	DO NOT mislabel the App Privacy details or omit Privacy Manifest reasons.
	•	DO NOT claim “unhackable,” bare “zero-knowledge,” or imply HIPAA/GLBA/PSD2 compliance.
	•	DO NOT ship crypto features without ENC self-classification notes.
	•	DO NOT expand data collection beyond what’s listed without updating notices and labels.
	•	DO NOT launch under a conflicted trademark.

⸻

15) Pre-Release Checklist (paste into PR)
	•	Immigration: OPT/CPT authorization on file (or monetization flag OFF)
	•	StoreKit IAP for all paid digital features; no external payment links
	•	In-app account deletion implemented and tested (server wipe)
	•	Privacy Label & Manifest updated; data map current
	•	GDPR rights: export & delete endpoints live; privacy notice published
	•	SCCs/DPA signed if EU users + U.S. hosting
	•	Secrets: device-only storage; no secret egress/logging; backup crypto verified
	•	Push optional; marketing push behind explicit opt-in with easy opt-out
	•	Marketing claims reviewed; approved wording only; claims.md updated
	•	ENC self-classification note added/updated
	•	Trademark clearance note added
	•	SBOM generated; dependency & static analysis clean; release review filed
	•	IR plan exists; contacts verified

⸻

16) References (for counsel verification)
	•	USCIS F-1 employment rules (CPT/OPT)
	•	Apple App Store Review Guidelines (payments §3.1.1; account deletion; push)
	•	Apple Privacy Manifest & App Privacy Details
	•	GDPR (personal data; rights; transfers; 72-hour breach notice)
	•	CCPA/CPRA (consumer rights, disclosures)
	•	FTC Act §5 (deceptive claims)
	•	RFC 4226 / RFC 6238 (HOTP/TOTP)
	•	U.S. EAR §740.17 (ENC)

⸻x

Owner: Compliance & Risk (Vector GPT)
Last updated: (fill on commit)
Change policy: Modifications require approval from Compliance & Risk and must pass CI gates.
