//
//  CopyToast.swift
//  Vector
//
//  Created by Adam Zaatar on 8/21/25.
//  File: UI/Components/CopyToast.swift
//

import SwiftUI

/// A lightweight, reusable toast that appears after copying an OTP code,
/// showing a countdown until the clipboard is auto-cleared.
///
/// Behavior:
/// • Listens for `.clipboardShouldClear` notifications with `timeoutSec` in `userInfo`.
/// • Displays a small floating banner with a seconds countdown.
/// • Auto-dismisses at 0s or when tapped.
///
/// Styling: Monochrome-friendly (white/black/charcoal), rounded, subtle shadow.
/// Accessibility: Announces copy success and remaining seconds.
public struct CopyToast: View {
    let initialSeconds: Int
    let onDismiss: () -> Void

    @State private var secondsLeft: Int
    @State private var timerTask: Task<Void, Never>?

    public init(seconds: Int, onDismiss: @escaping () -> Void) {
        self.initialSeconds = max(1, seconds)
        self.onDismiss = onDismiss
        _secondsLeft = State(initialValue: max(1, seconds))
    }

    public var body: some View {
        HStack(spacing: Spacing.m) {
            Image(systemName: "doc.on.doc.fill")
                .imageScale(.large)
                .foregroundStyle(iconForeground)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text("Code copied") // Localize
                    .font(Typography.body)
                    .foregroundStyle(textForeground)
                Text("Clearing in \(secondsLeft)s") // Localize
                    .font(Typography.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel(Text("Clearing in \(secondsLeft) seconds")) // Localize
            }

            Spacer(minLength: Spacing.m)

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .padding(6)
                    .background(Circle().fill(buttonBackground))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Dismiss") // Localize
        }
        .padding(.horizontal, Spacing.m)
        .padding(.vertical, Spacing.s)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(containerBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(BrandColor.divider.opacity(0.6), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.18), radius: 10, x: 0, y: 8)
        .onAppear(perform: startCountdown)
        .onDisappear { timerTask?.cancel(); timerTask = nil }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isStaticText)
        .accessibilityHint(Text("Clipboard will be cleared automatically.")) // Localize
    }

    @Environment(\.colorScheme) private var scheme

    private var containerBackground: Color { scheme == .dark ? BrandColor.charcoal.opacity(0.95) : BrandColor.white }
    private var textForeground: Color { scheme == .dark ? BrandColor.white : BrandColor.black }
    private var iconForeground: Color { scheme == .dark ? BrandColor.white : BrandColor.black }
    private var buttonBackground: Color { scheme == .dark ? Color.white.opacity(0.10) : Color.black.opacity(0.06) }

    private func startCountdown() {
        timerTask?.cancel()
        timerTask = Task { @MainActor in
            while !Task.isCancelled && secondsLeft > 0 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                secondsLeft -= 1
            }
            if !Task.isCancelled { dismiss() }
        }
    }

    private func dismiss() {
        timerTask?.cancel()
        timerTask = nil
        onDismiss()
    }
}

// MARK: - Host Modifier

/// A view modifier that listens for `.clipboardShouldClear` events and presents a `CopyToast`
/// anchored at the top of the safe area. Add once at a high level (e.g., VaultView root).
public struct CopyToastHost: ViewModifier {
    @State private var isShowing: Bool = false
    @State private var seconds: Int = 20

    public init() {}

    public func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            content
            if isShowing {
                CopyToast(seconds: seconds) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                        isShowing = false
                    }
                }
                .padding(.top, Spacing.m)
                .padding(.horizontal, Spacing.m)
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(1)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .clipboardShouldClear)) { note in
            let timeout = (note.userInfo?[AppNotification.Key.timeoutSec] as? Int) ?? 20
            seconds = max(1, timeout)
            withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) { isShowing = true }
            UIAccessibility.post(notification: .announcement, argument: "Code copied. Clearing in \(seconds) seconds.") // Localize
        }
    }
}

public extension View {
    /// Attach once to show a copy toast on clipboard events.
    func copyToastHost() -> some View { modifier(CopyToastHost()) }
}

// MARK: - Previews

#if DEBUG
struct CopyToast_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            BrandGradient.wash().ignoresSafeArea()
            VStack { Spacer(); Text("Demo").font(Typography.titleM).foregroundStyle(.white); Spacer() }
        }
        .overlay(VStack { CopyToast(seconds: 7) {}; Spacer() }.padding())
        .preferredColorScheme(.dark)
        .previewDisplayName("Dark")

        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            VStack { Spacer(); Text("Demo").font(Typography.titleM); Spacer() }
        }
        .overlay(VStack { CopyToast(seconds: 7) {}; Spacer() }.padding())
        .preferredColorScheme(.light)
        .previewDisplayName("Light")
    }
}
#endif
