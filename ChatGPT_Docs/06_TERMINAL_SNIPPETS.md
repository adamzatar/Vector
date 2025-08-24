# chatgpt_docs/06_UI_RULES.md
# Vector — UI Rules & Design System

Opinionated, production-grade UI guidance. Keep screens consistent, fast, and trustworthy.

---

## 0) Core Principles
- **Clarity over chrome.** Fewer elements, stronger hierarchy.
- **Semantic tokens only.** No raw hex/colors/sizes in screens.
- **Fast feel.** Animations ≤ 180 ms; respect Reduce Motion.
- **Accessible by default.** Dynamic Type, VoiceOver labels, 44×44 hit targets.
- **Privacy-forward.** Use `PrivacySensitiveView` for token surfaces.

---

## 1) Design Tokens (use these, never ad-hoc)
### Colors (`UI/Design/Colors.swift`)
- **Surfaces:** `BrandColor.surface`, `BrandColor.surfaceSecondary`
- **Text:** `BrandColor.primaryText`, `.secondary` (system)
- **Accents:** `BrandColor.accent`
- **Dividers:** `BrandColor.divider`
- **Gradients:** `BrandGradient.primary()`, `.secondary()`, `.neutral()`, `.wash()`

> Don’t invent new color names in views. Extend `BrandColor` if needed.

### Typography (`UI/Design/Typography.swift`)
- Titles: `Typography.titleS/M/L/XL`
- Body: `Typography.body`
- Caption: `Typography.caption`
- Mono: `Typography.monoS/M/L` (codes, timers)

### Spacing (`UI/Design/Spacing.swift`)
- `Spacing.xs/s/m/l/xl/xxl` for padding and gaps.

### View Helpers (`UI/Modifiers/View+If.swift`)
- Conditional styling: ```.if(condition) { $0.modifier(...) }```
- Minimum tap target: `.minTapTarget()`
- Branded titles for plain `Text`: `.brandTitle(.m)`

---

## 2) Global Framing

### Backgrounds
- **Full-screen:** `BrandGradient.primary().ignoresSafeArea()` for entry points (Splash/Intro/Paywall).
- **Content screens:** `BrandColor.surface` as list/form background.

### App Header (logo + light chrome)
- **Overlay on important screens** (Home/Vault, Add Token, Paywall, Settings).
- Use the shared components (already added):
  - `AppHeaderOverlay(alignment: .top, safeAreaPadding: true)`
  - `AppHeaderBar(title: String?, trailing: some View)`
- Header is **decorative**; it must not compete with navigation title.

_Example (top of a screen body):_
```swift
ZStack(alignment: .top) {
  BrandColor.surface.ignoresSafeArea()
  content
  AppHeaderOverlay(alignment: .top, safeAreaPadding: true)
}


⸻

3) Components (preferred)
    •    Card (UI/Components/Card.swift): elevated containers with consistent padding/border.
    •    PrimaryButton / SecondaryButton: use for primary/secondary actions; no raw Button styling.
    •    TokenRow: issuer, account, color dot, TimeRing, copy button.
    •    TimeRing: lightweight progress ring; no heavy rendering in body.
    •    SearchBar: compose into Vault list headers.

If you need something new, add it under UI/Components/ and wire tokens.

⸻

4) Lists & Forms
    •    Group content with Section (use @ViewBuilder func sectionX() -> some View).
    •    Single-line labels; secondary info in .secondary.
    •    Copy action gets a haptic (UIImpactFeedbackGenerator(style: .light) or UINotificationFeedbackGenerator for success).

⸻

5) Motion & Feedback
    •    Default animation: .easeInOut(duration: 0.18)
    •    Conditional wrapper:

withAnimation(UIAccessibility.isReduceMotionEnabled ? nil : .easeOut(duration: 0.12)) {
  // state change
}

    •    Haptics: light for copy; success for “added/imported”.

⸻

6) Accessibility
    •    Dynamic Type: never clamp text; layout adapts.
    •    VoiceOver:
    •    Token row label = issuer + account
    •    Value = “code 123 456, 12 seconds left”
    •    Hit areas ≥ 44×44; use .minTapTarget().
    •    Reduce Motion honored on all animations (ring pulse, transitions).

⸻

7) Privacy
    •    Wrap sensitive surfaces:

PrivacySensitiveView {
  VaultView()
}

    •    Show blur overlay when screen recording is active (already in PrivacySensitiveView).

⸻

8) Error & Empty States
    •    Empty Vault: friendly explainer + CTA “Add your first account”.
    •    Import errors: “Some entries could not be parsed. First error: …” (no crypto jargon).
    •    Backup: explain passphrase importance; require ≥ 10 chars, show strength hint.

⸻

9) Paywall (ethical)
    •    Single sheet: benefits, Monthly + Lifetime, Restore, “Maybe later”.
    •    Trigger only on Pro action (or soft upsell after ≥ 2 accounts).
    •    Don’t block onboarding or base 2FA.

⸻

10) Patterns by Screen

Splash / Intro
    •    Gradient background, subtle logo motion, fast route (≤ 700ms).
    •    2–3 intro cards max.

Vault (Home)
    •    Header overlay present.
    •    List of TokenRow.
    •    Pull-to-refresh not needed (codes auto-tick).
    •    Copy toast ≤ 1.2s.

Add Token
    •    Form with issuer/account/secret, validated as you type.
    •    QR scanner sheet is dark appearance.
    •    Tags using TagCloud with capsule badges.

Settings
    •    Grouped sections (Security, Clipboard, Appearance, Pro).
    •    Pro toggles gated by entitlements (show paywall if tapped when not Pro).

Paywall
    •    Gradient, logo header, benefits pills, two price buttons, restore, maybe later.

⸻

11) Do / Don’t

Do
    •    Keep hierarchy strong; one primary action per section.
    •    Use semantic colors/typography.
    •    Profile if a view recomputes often (use derived vars smartly).

Don’t
    •    Hardcode colors/sizes.
    •    Introduce long animations or parallax.
    •    Leak secrets into logs.

⸻

12) Snippets

Non-optional selection binding bridge

let colorBinding = Binding<TokenColor>(
  get: { vm.color ?? .gray },
  set: { vm.color = $0 }
)
Picker("Color Label", selection: colorBinding) { … }

Toast (Copy)

withAnimation(.easeOut(duration: 0.12)) { showToast = true }
DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
  withAnimation(.easeIn(duration: 0.12)) { showToast = false }
}

Section function (avoids generic inference errors)

@ViewBuilder
private func sectionParameters() -> some View { … }


⸻

13) Review Checklist (UI PR)
    •    Uses tokens (colors/typography/spacing).
    •    Header overlay included where applicable.
    •    VoiceOver labels/values set.
    •    Reduce Motion path present.
    •    Previews show realistic data (dark mode preferred).
    •    No raw constants that belong in the design system.

⸻

Keep it sharp and repeatable. If a new pattern appears more than twice, promote it into UI/Components and document it here.


