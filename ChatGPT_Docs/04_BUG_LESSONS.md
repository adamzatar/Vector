# chatgpt_docs/04_BUG_LESSONS.md
# Vector — Bug Lessons & Debugging Playbook

A living, **pragmatic** list of pitfalls we hit (and will avoid again), with **symptoms → diagnosis → fix** recipes.

---

## 1) Swift / SwiftUI Type Gotchas

### 1.1 Nil-coalescing on non-optionals
- **Symptom:** “Left side of `??` has non-optional type ‘String’…”
- **Why:** Property was already non-optional (`secretBase32`, etc.).
- **Fix:** Remove `?? "fallback"`. Only coalesce optionals you *know* are optional.

### 1.2 `Section` generic inference explosions
- **Symptom:** “Generic parameter ‘V’ could not be inferred” / “Return type of property ‘section…’ requires…”
- **Why:** Complex `Section {}` inside **computed vars** triggers type inference hell.
- **Fix:** Use **functions** instead of properties:
  ```swift
  @ViewBuilder private func sectionFoo() -> some View { Section { … } }

Optionally wrap content in VStack inside the Section to give the compiler concrete types.

1.3 @ObservedObject dynamic member / bindings
    •    Symptom: “Value has no dynamic member ‘algo’…”, binding type errors.
    •    Why: Using vm.algo where a Binding is required, or property not @Published.
    •    Fix: Ensure VM property is @Published, and use $vm.property where a binding is needed.
For optional selections, convert to non-optional binding:

let colorBinding: Binding<TokenColor> = .init(
  get: { vm.color ?? .gray }, set: { vm.color = $0 }
)



1.4 Stepper range misuse
    •    Symptom: Won’t compile with in: [6,8].
    •    Fix: Use a range + step:

Stepper(value: $vm.digits, in: 6...8, step: 2) { … }



1.5 Private types reused elsewhere
    •    Symptom: “‘TagCloud’ initializer is inaccessible due to ‘private’…”
    •    Fix: Make the type internal (default) or fileprivate if needed in the same file.

⸻

2) Concurrency & MainActor (Swift 6)

2.1 Main actor isolation violations
    •    Symptoms:
    •    “Call to main actor-isolated method in nonisolated context…”
    •    “Main actor-isolated property ‘isTorchOn’ cannot be referenced from a Sendable closure…”
    •    Context: QRScannerViewModel mutates AVCaptureSession on a background sessionQueue, while UI state is @MainActor.
    •    Fix pattern:
    •    Keep all UI state mutations inside Task { @MainActor in … }.
    •    Never read/write @Published (MainActor) properties from sessionQueue.
    •    Query devices off-main, then hop to main to publish:

private func updateTorchAvailabilityOffMain() {
  let available = videoDevice()?.hasTorch ?? false
  Task { @MainActor in self.isTorchAvailable = available }
}


    •    When you need isTorchOn to compute a toggle off the main thread, pass it in:

func toggleTorch() {
  let newValue = !isTorchOn   // read on main
  sessionQueue.async { [weak self] in self?.setTorchLocked(on: newValue) }
  Task { @MainActor in self.isTorchOn = newValue } // publish on main
}



2.2 Sendable closures capturing MainActor state
    •    Symptom: Accessing self.isTorchOn inside sessionQueue.async.
    •    Fix: Snapshot values on main first, or re-enter main actor for reads/writes.

⸻

3) AVFoundation Rules (Camera / Torch)
    •    Lock the device to mutate torch:

try device.lockForConfiguration()
device.torchMode = on ? .on : .off
device.unlockForConfiguration()


    •    Only publish flags (isTorchOn, isTorchAvailable) on the main actor.
    •    Keep all AVCaptureSession graph mutations on a dedicated sessionQueue.

⸻

4) Design System Mismatches

4.1 Missing color tokens
    •    Symptom: BrandColor.background / .foreground not found.
    •    Fix: Use existing tokens:
    •    Text: BrandColor.primaryText
    •    Backgrounds: BrandColor.surface, BrandColor.surfaceSecondary
    •    Dividers: BrandColor.divider
    •    If a gradient referred to BrandColor.background, replace with BrandColor.surface.

4.2 Typography symbol mismatch
    •    Symptom: “Ambiguous use of ‘xl’”.
    •    Fix: Use the names we actually ship: Typography.titleS/M/L/XL, Typography.body, Typography.caption, Typography.monoM.

⸻

5) Parser & Import

5.1 Wrong label
    •    Symptom: “Extraneous argument label ‘uri:’…”
    •    Fix: API is OTPAuthParser.parse(_:), not parse(uri:).

5.2 fileImporter result type
    •    Symptom: “Cannot assign [URL] to URL” (or vice-versa).
    •    Fix: With allowsMultipleSelection: false the closure yields URL. With true, it yields [URL]. Match your state type accordingly.

5.3 CSV parsing leniency
    •    Trim whitespace, allow missing optional columns, and skip bad lines; show 1st error only.

⸻

6) App Root & Launch

6.1 Placeholders visible
    •    Symptom: “Looks like placeholders”.
    •    Fix: Ensure AppRootView routes to real SplashView / IntroScreen / VaultView / SettingsView / AddTokenView.

6.2 Launch screen assets not showing
    •    Checks:
    •    UILaunchStoryboardName = LaunchScreen in Info.plist.
    •    Target Membership on LaunchScreen.storyboard and images.
    •    No runtime code in launch screen; static layout only.

6.3 Info.plist not found
    •    Symptom: “Build input file cannot be found: …/Vector/Info.plist”
    •    Fix: Build Settings → Packaging → Info.plist File = Vector/Config/Info.plist

⸻

7) Git / OneDrive

7.1 Massive / permission errors on git add -A
    •    Symptoms: OneDrive/Library noise, “permission denied”, embedded repo warnings.
    •    Fix:
    •    Add a .gitignore:

.DS_Store
xcuserdata/
DerivedData/
Library/
.gitkraken/
**/.DS_Store


    •    Remove bad paths from index:

git rm -r --cached Library
git rm -r --cached .gitkraken


    •    Commit only the Vector/ source tree (and your chatgpt_docs/ if desired).

⸻

8) Xcode Stability
    •    Freeze: ⌥⌘⎋ → Force Quit.
    •    Nuke DerivedData:

rm -rf ~/Library/Developer/Xcode/DerivedData/*


    •    Clean Build Folder: ⇧⌘K, then rebuild.

⸻

9) Metrics & Paywall Ethics
    •    Never show paywall on first-run critical path.
    •    Trigger paywall only on Pro feature taps (or gentle upsell after ≥2 accounts).
    •    Log locally (no 3P SDKs): paywall_shown, pro_purchased, account_added, sync_enabled, backup_exported.

⸻

10) Privacy & A11y
    •    Wrap sensitive screens in PrivacySensitiveView { … }.
    •    Respect:
    •    Dynamic Type: don’t hard-cap text sizes.
    •    VoiceOver: meaningful accessibilityLabel / Value (e.g., “code 123 456, 12 seconds left”).
    •    Reduce Motion: short, subtle animations; offer nil animation when reduced.

⸻

11) Performance Budgets
    •    Vault row render ≤ 4ms (iPhone 12+).
    •    Widget provider ≤ 20ms.
    •    Backup (500 tokens) round-trip ≤ 1s.
    •    Avoid recomputing TOTP HMAC per frame—tick once per second and update progress only.

⸻

12) Testing Patterns
    •    TOTP: RFC6238 vectors across SHA1/256/512, digits 6/8, times (59, 1111111109, …).
    •    Keychain: CRUD with kSecAttrSynchronizable = true (and delete) + multi-device propagation sanity.
    •    Crypto: KDF + AES-GCM export/import round-trip with random salt/nonce.
    •    StoreKit 2: Purchase, cancel, restore using local StoreKit config file.

⸻

13) Golden Snippets

Hop to main for UI state

Task { @MainActor in self.isTorchOn = on }

Safer binding for optional enum

let selected: Binding<TokenColor> = .init(
  get: { vm.color ?? .gray }, set: { vm.color = $0 }
)

Section as function

@ViewBuilder private func sectionParameters() -> some View {
  Section {
    // …
  } header: { Text("Security Parameters") }
}

fileImporter (single)

.fileImporter(isPresented: $show, allowedContentTypes: types, allowsMultipleSelection: false) { result in
  switch result {
    case .success(let url): pickedURL = url
    case .failure(let err): errorMessage = err.localizedDescription
  }
}


⸻

14) “Before You Commit” Checklist
    •    ✅ No placeholders in live routes
    •    ✅ Info.plist path correct (Vector/Config/Info.plist)
    •    ✅ No main-actor violations in background queues
    •    ✅ UI uses BrandColor / Typography tokens
    •    ✅ A11y labels / Reduce Motion respected
    •    ✅ .gitignore excludes Library/, .gitkraken/, DerivedData/
    •    ✅ Previews compile with realistic data
    •    ✅ Unit tests pass locally

Keep this doc short, fierce, and current. Add the exact error string and the minimal fix whenever we hit a new issue.


