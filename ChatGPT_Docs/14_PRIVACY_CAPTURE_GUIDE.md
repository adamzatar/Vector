# chatgpt_docs/14_PRIVACY_CAPTURE_GUIDE.md
# Vector — Privacy, Capture & Clipboard Hygiene Guide

**Goal:** Minimize accidental secrets exposure during **app switching, screen recording/airplay, screenshots, widgets, watch, and clipboard**—while keeping UX smooth.

This doc is *authoritative* for privacy behavior across the app.

---

## 1) Threat Model & Targets

**We defend against:**
- App switcher snapshots exposing codes.
- Screen recording / AirPlay mirroring leaks.
- Accidental screenshots capturing secrets.
- Widgets/Watch showing secrets on lock/home.
- Clipboard lingering or syncing to other devices.
- Logs/metrics containing sensitive values.

**We do _not_ attempt to:**
- “Block” screenshots. iOS does not allow it. We *detect* and *mask* when possible.

---

## 2) System APIs & What They Do

- `View.privacySensitive()`  
  Hints to the system: hide content in switcher, screen share, etc. (iOS 15+).

- `UIScreen.main.isCaptured` + `UIScreen.capturedDidChangeNotification`  
  Detects active **screen recording / AirPlay**. Not fired for single screenshots.

- `UIApplication.userDidTakeScreenshotNotification`  
  Fires after a **screenshot**. Use to notify user + optionally mask UI briefly.

- **Widgets**: `.privacySensitive()` in widget views + **redaction** for lock screen.

- **Clipboard**: `UIPasteboard.OptionsKey.expirationDate`, `.localOnly` to expire quickly and avoid Universal Clipboard sync.

---

## 3) App-Level Patterns (Use Everywhere)

### 3.1 Wrap sensitive surfaces

- Vault lists, token rows, code detail, backup keys → wrap in **PrivacySensitiveView** *(below)* and mark subviews with `.privacySensitive()`.

```swift
// File: UI/Modifiers/PrivacySensitiveView.swift
import SwiftUI
import Combine

final class ScreenCaptureObserver: ObservableObject {
    @Published var isCaptured = UIScreen.main.isCaptured
    private var bag = Set<AnyCancellable>()
    init() {
        NotificationCenter.default.publisher(for: UIScreen.capturedDidChangeNotification)
            .map { _ in UIScreen.main.isCaptured }
            .assign(to: \.isCaptured, on: self)
            .store(in: &bag)
    }
}

public struct PrivacySensitiveView<Content: View>: View {
    @StateObject private var capture = ScreenCaptureObserver()
    let content: () -> Content
    public init(@ViewBuilder content: @escaping () -> Content) { self.content = content }
    public var body: some View {
        content()
            .privacySensitive()
            .overlay {
                if capture.isCaptured {
                    VisualEffectBlur()
                        .transition(.opacity)
                        .overlay(
                            Label("Hidden while recording", systemImage: "eye.slash")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        )
                        .accessibilityLabel("Hidden while recording")
                }
            }
    }
}

struct VisualEffectBlur: UIViewRepresentable {
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

Usage:

// VaultView.swift
var body: some View {
    PrivacySensitiveView {
        VaultList() // token rows, time ring, copy buttons, etc.
    }
}

3.2 Mask while app is backgrounded (app switcher snapshot)

Add a lightweight shield that shows when the app resigns active, hiding live UI in the switcher. SwiftUI-only approach:

// File: App/PrivacyShield.swift
import SwiftUI

public struct PrivacyShield: ViewModifier {
    @Environment(\.scenePhase) private var phase
    public func body(content: Content) -> some View {
        ZStack {
            content
                .privacySensitive() // hint for system snapshot
            if phase != .active {
                Color(.systemBackground)
                    .overlay(
                        VStack(spacing: 8) {
                            Image(systemName: "lock.fill").imageScale(.large)
                            Text("Locked").font(.headline)
                        }.foregroundStyle(.secondary)
                    )
                    .transition(.opacity)
                    .accessibilityHidden(true)
            }
        }
    }
}
public extension View {
    func appPrivacyShield() -> some View { modifier(PrivacyShield()) }
}

Apply once at root:

// AppRootView.swift (body)
ZStack {
  BrandGradient.primary().ignoresSafeArea()
  // …
}
.appPrivacyShield()

3.3 Notify on screenshot (best-effort)

You cannot prevent screenshots. You can inform the user and briefly mask.

// File: Services/Infra/ScreenshotObserver.swift
import UIKit
import Combine

final class ScreenshotObserver: ObservableObject {
    @Published var didScreenshot = false
    private var bag = Set<AnyCancellable>()
    init() {
        NotificationCenter.default.publisher(for: UIApplication.userDidTakeScreenshotNotification)
            .sink { [weak self] _ in
                self?.didScreenshot = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { self?.didScreenshot = false }
            }
            .store(in: &bag)
    }
}

Attach in a high-level view (e.g., Vault):

@StateObject private var shot = ScreenshotObserver()

.overlay(alignment: .top) {
    if shot.didScreenshot {
        Text("Screenshot captured — codes hidden")
            .font(.callout).padding(8)
            .background(.thinMaterial, in: Capsule())
            .padding(.top, 12)
            .transition(.move(edge: .top).combined(with: .opacity))
    }
}


⸻

4) Clipboard Hygiene (OTP Copy)

Requirements
    •    Expire within ≤ 20s (configurable).
    •    Prefer localOnly = true to avoid Universal Clipboard.
    •    Never log the code. Haptic feedback on copy.

// File: Services/Infra/Clipboard.swift
import UIKit

public enum Clipboard {
    public static func copyOTP(_ code: String, ttl: TimeInterval = 20) {
        let pb = UIPasteboard.general
        let item: [String: Any] = [UTType.utf8PlainText.identifier: code]
        let exp = Date().addingTimeInterval(ttl)
        pb.setItems([item], options: [
            .localOnly: true,
            .expirationDate: exp
        ])
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}

Usage:

Button {
    Clipboard.copyOTP(currentCode, ttl: Double(di.settings.clipboardTimeoutSec))
    di.metrics.log(.account_added) // example event; never log code
} label: { Image(systemName: "doc.on.doc") }


⸻

5) Widgets & Watch

Widgets (WidgetKit):
    •    Use .privacySensitive() on the entry view.
    •    Default to redacted or “Tap to reveal in app”.
    •    Do not compute HMAC in timeline—use a precomputed model via App Group if needed.

Apple Watch:
    •    Complications should not display the code by default.
    •    Show issuer/time ring/status; tap to open the watch app for reveal.

⸻

6) Backups, Logs, Metrics
    •    Backups: Use AES-GCM with PBKDF2 (see BackupService.swift), never plain text.
    •    Logs/Metrics: Local-only; never include secrets, URIs, or key material.
    •    Crash reports: If enabled in future, sanitize breadcrumbs.

⸻

7) QA Checklist (Privacy)
    •    Vault, Token Detail, Add Token wrapped in PrivacySensitiveView.
    •    Root uses .appPrivacyShield(); switcher snapshot shows “Locked”.
    •    Screen recording enables blur overlay immediately.
    •    Screenshot shows in-app notice; UI remains privacy-safe.
    •    Clipboard expires in ≤ 20s; localOnly true.
    •    Widgets/Watch do not reveal codes by default.
    •    No secrets in logs/metrics/backups without encryption.
    •    VoiceOver still announces issuer/account (not code) when masked.

⸻

8) Notes & Pitfalls
    •    .privacySensitive() is a hint; still add your own blur/shield for certainty.
    •    UIScreen.isCaptured won’t fire for single screenshots—use the screenshot notification.
    •    Universal Clipboard is avoided with .localOnly, but users can still manually share; minimize TTL.
    •    When masking, keep accessibility: announce the state (“Hidden while recording”) to VoiceOver.

⸻

9) Minimal Integration Map
    •    Root: AppRootView → .appPrivacyShield().
    •    Vault/Token: Wrap bodies in PrivacySensitiveView { … }.
    •    Copy: Use Clipboard.copyOTP(_:ttl:).
    •    Widgets: mark entry view .privacySensitive(); show redacted.
    •    Watch: no codes on complications; reveal on app open.
    •    Backup: always through BackupService.

Result: Strong privacy posture with minimal friction, aligned with our “privacy-first” brand.


