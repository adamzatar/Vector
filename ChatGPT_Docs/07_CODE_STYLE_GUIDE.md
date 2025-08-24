# chatgpt_docs/07_CODE_STYLE_GUIDE.md
# Vector — Code Style Guide (Swift + SwiftUI)

Consistent, modern Swift with first-class concurrency, testability, and privacy.

---

## 0) Scope & Targets
- Swift 5.9+ / iOS 16+ baseline; Swift 6-ready (strict concurrency).
- SwiftUI for UI; StoreKit 2; CryptoKit; Keychain Services.
- **No third-party SDKs**.

---

## 1) File Layout & Headers
- One top-level type per file when reasonable.
- Keep folders aligned with architecture (App / Features / Services / Models / UI).
- At file top include path header:

```swift
//
//  AddTokenViewModel.swift
//  Vector
//  File: Features/AddToken/AddTokenViewModel.swift
//

    •    Organize with // MARK: blocks by domain (State, Init, Actions, Private).

⸻

2) Naming & Structure
    •    Types: UpperCamelCase (AddTokenView, VaultStore).
    •    Methods/vars: lowerCamelCase (saveManual(), isPro).
    •    Abbreviations allowed only if Apple-standard (URL, ID, JSON).
    •    ViewModels are final class + @MainActor when mutating UI state.
    •    Pure utilities prefer struct or enum with static functions.

⸻

3) Access Control
    •    Default to internal; tighten to private/fileprivate where possible.
    •    Views and modifiers: internal unless used only in the file (private).
    •    Keep helpers private if not referenced elsewhere (prevents symbol bleed).

⸻

4) Optionals, Guards, and Early Returns
    •    Prefer guard for validation; keep indentation flat.

func saveManual() {
  guard canSave else { errorMessage = "…" ; return }
  // …
}

    •    Do not use ?? on non-optionals.
    •    Avoid force unwraps (!) outside of tests or truly impossible states.
    •    Use nil-aware helpers:

extension Array {
  subscript(safe i: Int) -> Element? { indices.contains(i) ? self[i] : nil }
}


⸻

5) Errors & Logging
    •    Throwing APIs use throws; surface user-facing strings via AppError.
    •    Wrap external errors once at boundary:

do { try await vault.add(token) }
catch { logger.error("Vault add failed: \(error.localizedDescription)")
        errorMessage = AppError.wrap(error).localizedDescription }

    •    No secrets in logs. Use logger.debug/info/warn/error consistently.

⸻

6) Concurrency Model
    •    UI state is @MainActor.
    •    Shared mutable, non-UI state uses actor.

@MainActor final class AddTokenViewModel: ObservableObject { … }

private actor ScanDebounce {
  private var last: CFTimeInterval = 0
  func shouldEmit(now: CFTimeInterval) -> Bool { … }
}

    •    Background work: capture queues or Task.detached only for pure work.
    •    Crossing isolation:

Task { @MainActor in self.isTorchOn = on }

    •    AVCaptureSession graph mutations off main (custom queue); UI flags back on main.

⸻

7) SwiftUI Rules
    •    Views are pure structs; no side effects in body.
    •    Complex Section content as functions not computed vars to prevent generic inference bugs:

@ViewBuilder private func sectionParameters() -> some View { … }

    •    Bindings must map optionals to concrete types:

let colorBinding = Binding<TokenColor>(get: { vm.color ?? .gray },
                                       set: { vm.color = $0 })

    •    Animations: ≤ 0.18s, gated by Reduce Motion.

withAnimation(UIAccessibility.isReduceMotionEnabled ? nil : .easeOut(duration: 0.12)) { … }

    •    Use design tokens (BrandColor, Typography, Spacing)—no ad-hoc values.

⸻

8) Dependency Injection
    •    Central DIContainer holds services: vault, logger, metrics, entitlements, flags.
    •    Views read via @Environment(\.di); ViewModels get container in init.

@Environment(\.di) private var di
init(container: DIContainer) { self.container = container }

    •    For previews: .environment(\.di, .makePreview()).

⸻

9) Metrics (Local-only)
    •    Log only event name + minimal context. Never PII.

di.metrics.log(.account_added)

    •    Events: account_added, sync_enabled, paywall_shown, pro_purchased, backup_exported.

⸻

10) Pro Gating
    •    Never block free core flow.
    •    Gate UI actions on await entitlements.isPro; if false → present paywall.

if await di.entitlements.isPro {
  // proceed
} else {
  di.metrics.log(.paywall_shown)
  router.showPaywall()
}


⸻

11) Testing
    •    Unit: RFC6238 vectors; Backup round-trip; Keychain CRUD; StoreKit pathway.
    •    UI: snapshot Paywall, AddToken, Vault row (dark/light, Dynamic Type).
    •    Avoid sleeps; use dependency injection and deterministic clocks.

⸻

12) Formatting & Lint
    •    Xcode default indent 2 spaces.
    •    Line length soft 120.
    •    Trailing commas allowed in multiline literals.
    •    Group import by standard → internal.
    •    Sort modifiers functionally (layout → style → accessibility).

⸻

13) Documentation
    •    Public types/functions get doc comments ///.
    •    Explain security rationale where applicable (Keychain flags, KDF params).
    •    Add #if DEBUG previews with realistic data.

⸻

14) Common Patterns

Copy Haptic + Toast

let gen = UINotificationFeedbackGenerator()
gen.notificationOccurred(.success)
// show toast for ≤ 1.2s

Safe File Importer

.fileImporter(isPresented: $showPicker,
              allowedContentTypes: allowedTypes,
              allowsMultipleSelection: false) { result in
  switch result {
  case .success(let url): pickedURL = url
  case .failure(let err): errorMessage = err.localizedDescription
  }
}

Privacy Guard

PrivacySensitiveView { VaultView() }


⸻

15) Git & PR Hygiene
    •    Commit messages: feat:, fix:, ui:, refactor:, docs:, test:.
    •    One shippable slice per PR; include screenshots for UI changes.
    •    Checklists: UI tokens used, a11y labels, reduce-motion path, previews pass.

⸻

16) Anti-Patterns (Avoid)
    •    Blocking the main actor with heavy crypto or parsing.
    •    Force unwrapping parsed values.
    •    New color/size literals inside views.
    •    Long body with business logic—move to VM.
    •    Paywall gating in multiple places—centralize in one helper if reused.

⸻

17) Small Examples

Good

@MainActor
final class QRScannerViewModel: NSObject, ObservableObject {
  @Published var isTorchAvailable = false
  private let sessionQueue = DispatchQueue(label: "camera.session", qos: .userInitiated)

  func start() {
    sessionQueue.async { [weak self] in
      guard let self else { return }
      // configure session…
      self.updateTorchAvailability()
    }
  }
  private func updateTorchAvailability() {
    let available = (self.videoDevice()?.hasTorch ?? false)
    Task { @MainActor in self.isTorchAvailable = available }
  }
}

Bad

// UI thread mutation from background, optional misuse, magic numbers
isTorchAvailable = device!.hasTorch // ❌


⸻

18) Versioning & Migration
    •    Bump CURRENT_PROJECT_VERSION via xcconfig.
    •    Migrations are idempotent, small, and logged (no PII).

⸻

Keep it tight, predictable, and boring—in the best sense. Clean code + clean UI = user trust.

