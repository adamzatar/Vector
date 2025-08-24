# chatgpt_docs/10_UI_UX_RULES.md
# Vector — UI / UX Rules (Authoritative)

Design language + interaction contracts for every screen. These rules align with our design tokens
(`BrandColor`, `BrandGradient`, `Typography`, `Spacing`, `Layout`) and components
(`VectorAppHeader`, `Card`, `PrimaryButton`, `SecondaryButton`, `TimeRing`, etc.).

---

## 1) Visual Language

### Color roles (always use semantic tokens)
- **Backgrounds**
  - `BrandColor.surface` → primary screen background
  - `BrandColor.surfaceSecondary` → cards / elevated blocks
  - `BrandColor.divider` → hairline borders (opacity ≤ 0.6)
- **Text**
  - `BrandColor.primaryText` for main copy
  - `.secondary` for supportive copy (via `.foregroundStyle(.secondary)`)
- **Accents**
  - `BrandColor.accent` for interactive emphasis (not for body text)
- **Hero backgrounds**
  - `BrandGradient.primary()` for splash/onboarding/paywall hero zones only

> **Do**: prefer neutral surfaces + crisp 1pt borders.  
> **Don’t**: hardcode system colors or raw hex values.

### Contrast
- Minimum 4.5:1 for body/labels. Use the tokens above; avoid opacity < 0.5 for text.

---

## 2) Typography & Density

- Use **Typography** scale exclusively:
  - Titles: `titleS`, `titleM`, `titleL`, (optional `titleXL`)
  - Body: `body`
  - Metadata: `caption`
  - Numbers: `monoM` (codes, seconds, counters)
- **Dynamic Type** must be respected. Never clamp below `.large`.
- Line limits:
  - Titles: `lineLimit(2)` max
  - Body/captions: let text wrap (avoid ellipsizing important content)
- Minimum tap area: **44×44** (`.minTapTarget()`)

---

## 3) Spacing & Layout

- Use `Spacing` for gaps; default vertical rhythm:
  - Small = `Spacing.s`, Medium = `Spacing.m`, Large = `Spacing.l`, XL = `Spacing.xl`
- Cards use `EdgeInsets.card` and `Layout.cardCorner`.
- Lists:
  - `.listStyle(.plain)`
  - `.listRowBackground(BrandColor.surface)`
  - Row insets: keep vertical padding generous; never compress to < 10pt.

---

## 4) App Header (Brand Presence)

- Every primary screen **should** render `VectorAppHeader` near the top.
- Placement:
  - Inside the scroll view (sticks to content), not as a navigation bar title.
  - Preferred alignment: **centered**, padded top with `Spacing.l`.
- Variant:
  - Default: gradient **off** for dense screens (Vault, Add Token, Settings).
  - Gradient **on** for hero pages (Splash, Intro, Paywall).

> If a view already has a large hero (e.g., Onboarding), use `VectorAppHeader` with reduced opacity or compact mode.

---

## 5) Components & Patterns

### Cards
- Use `Card` or `Card.titled("…")` for grouped content.
- Always show subtle border (`showsBorder: true`) and neutral elevation.
- Use `.useWashBackground: true` sparingly (marketing surfaces).

### Buttons
- Primary actions → `PrimaryButton` (single per section)
- Secondary/neutral → `SecondaryButton`
- Destructive → system `.tint(.red)` on `SecondaryButton` (confirm with alert)

### Token Row
- Issuer (body) + Account (caption)
- Color dot (12×12) on the left
- `TimeRing` on the right; code copy button uses circular subtle background
- Accessibility:
  - `accessibilityLabel`: “<Issuer>, <Account>, code 123 456, 12 seconds left”
  - `accessibilityValue`: remaining seconds only on the ring

### Forms
- Prefer `Form` for settings/entry; use `Section` headers/footers for guidance.
- Field order: Issuer → Account → Secret → Advanced (algo/digits/period) → Presentation (color/tags).
- Validation is inline (no blocking banners).

### Paywall
- One sheet. Columns: Title/Subtitle → Benefits (pills) → Plan cards → Primary CTA → Restore → Maybe later.
- Respect `08_PAYWALL_POLICY.md` for copy and ethics.

---

## 6) Motion & Haptics

- Animation defaults:
  - Micro transitions: `.easeInOut(duration: 0.18)`
  - Springs: `.spring(response: 0.35, dampingFraction: 0.9)`
- **Reduced Motion**:
  - Wrap non-essential animations with a guard:
    ```swift
    withAnimation(UIAccessibility.isReduceMotionEnabled ? nil : .easeOut(duration: 0.12)) { … }
    ```
- Haptics:
  - Copy success → `UINotificationFeedbackGenerator().notificationOccurred(.success)`
  - Selection changes → `UISelectionFeedbackGenerator().selectionChanged()`
  - Keep subtle; never stack multiple haptics on a single tap.

---

## 7) Accessibility

- Content is **navigable** and **understandable** via VoiceOver:
  - Provide `accessibilityLabel` + `accessibilityValue` for composite items.
  - Titles add `.accessibilityAddTraits(.isHeader)`.
- `privacySensitive()` on code surfaces; show a blur overlay when screen is recorded (see `PrivacySensitiveView`).
- Color alone must not convey meaning (e.g., ring urgency adds label or trait).

---

## 8) Empty, Loading, Error States

- **Empty Vault**: big mark, “Add your first account” CTA, brief explainer.
- **Loading**: lightweight progress indicators; avoid skeletons unless necessary.
- **Errors**:
  - Short, human: “Couldn’t import that file. Try a .txt or .csv.”
  - Avoid crypto jargon. Provide one recovery suggestion.
  - Use alerts sparingly; prefer inline footers on forms.

---

## 9) Iconography & Imagery

- **SF Symbols** only; weights `.regular` or `.semibold`.
- Brand mark (from `Vector/App/Assets.xcassets`) via `VectorAppHeader` or `LogoMark`.
- No decorative photography. Keep UI crisp and focused.

---

## 10) Privacy & Security Surface

- Any code display: `.privacySensitive()`
- Backups: explain passphrase importance; require 10+ characters.
- Widgets/Watch: default **tap to reveal**; never show codes by default.

---

## 11) Performance Budgets (targets, not hard limits)

- Token list render: ≤ **4 ms** per frame on iPhone 12+
- Time ring recompute: ≤ **1 ms** per tick
- Widget provider load: ≤ **20 ms**
- Import/export 500 tokens: ≤ **1 s**

> Use Instruments → Time Profiler & SwiftUI template. If breached, prefer simpler layouts over nested stacks.

---

## 12) Internationalization & Resilience

- No text baked into images.
- Avoid directional glyphs that break in RTL.
- Support long issuer/account strings: use `.lineLimit(1)` + `.truncationMode(.middle)` only where space is constrained.

---

## 13) Review Checklists

**Screen-level** (run before PR):
- [ ] `VectorAppHeader` placed correctly and not clashing with nav bars
- [ ] Semantics: tokens used (no hardcoded colors/fonts)
- [ ] Accessible labels/traits present
- [ ] Reduced Motion respected
- [ ] Tap targets ≥ 44pt
- [ ] Empty/error states defined
- [ ] No layout jump on first appearance

**Interaction-level:**
- [ ] Haptics: at most 1 per action, appropriate type
- [ ] Copy action shows toast (≤ 1.2s) and success haptic
- [ ] Paywall respects ethical rules; “Maybe later” always visible

---

## 14) Snippets (for quick adoption)

**Header inclusion**
```swift
VStack(spacing: Spacing.m) {
    VectorAppHeader(variant: .standard, usesGradient: false)
        .padding(.top, Spacing.l)
    // …rest of content
}
.background(BrandColor.surface.ignoresSafeArea())

Card block

Card.titled("Security") {
    VStack(alignment: .leading, spacing: Spacing.s) {
        Text("Face ID Lock").font(Typography.body)
        Text("Require Face ID to open the vault").font(Typography.caption).foregroundStyle(.secondary)
    }
}

Privacy-sensitive list

PrivacySensitiveView {
    List { /* Token rows */ }
        .listStyle(.plain)
        .background(BrandColor.surface)
}


⸻

15) Non-negotiables
    •    Never expose secrets or codes in logs.
    •    No dark patterns. Pro upsell is earned (user attempts Pro feature or soft nudge after 2+ accounts).
    •    Always ship previews for new components with realistic data.

⸻

This document is the UI/UX contract.
If a new request conflicts, propose a compliant alternative that preserves privacy, accessibility, and clarity.


