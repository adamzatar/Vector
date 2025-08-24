//
//  SecretField.swift
//  Vector
//
//  Created by Adam Zaatar on 8/23/25.
//  File: Features/AddToken/Components/SecretField.swift
//

import SwiftUI
import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// Polished Base32 secret entry used by AddTokenView.
/// - Monospaced, optional reveal, paste helper, and (optionally) a scan button.
/// - Live validation for RFC4648 Base32 charset (A–Z, 2–7, '=') ignoring spaces.
/// - Highlights focus/valid state and shows concise helper text.
///
/// Usage:
/// ```swift
/// SecretField(
///     secret: $vm.secretBase32,
///     onScan: { scanning = true }
/// )
/// ```
public struct SecretField: View {
    @Binding public var secret: String
    public var onScan: (() -> Void)?
    public var title: String
    public var placeholder: String

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @FocusState private var isFocused: Bool
    @State private var reveal: Bool = false
    @State private var justPasted: Bool = false

    public init(secret: Binding<String>,
                title: String = "Base32 Secret",
                placeholder: String = "JBSWY3DPEHPK3PXP",
                onScan: (() -> Void)? = nil) {
        _secret = secret
        self.title = title
        self.placeholder = placeholder
        self.onScan = onScan
    }

    // MARK: - Derived

    private var normalized: String {
        secret.replacingOccurrences(of: " ", with: "")
    }

    private var isValidBase32: Bool {
        guard !normalized.isEmpty else { return false }
        for ch in normalized {
            if !(ch.isBase32Char || ch == "=") { return false }
        }
        return true
    }

    private var borderColor: Color {
        if isFocused { return BrandColor.accent }
        if normalized.isEmpty { return BrandColor.divider.opacity(0.6) }
        return isValidBase32 ? .green : .red
    }

    // MARK: - Body

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Label
            Text(title) // Localize
                .font(Typography.caption)
                .foregroundStyle(.secondary)

            // Field row
            HStack(spacing: Spacing.s) {
                Image(systemName: "lock.square")
                    .imageScale(.medium)
                    .frame(width: 22)
                    .accessibilityHidden(true)

                if reveal {
                    TextField(placeholder, text: $secret, axis: .vertical)
                        .textContentType(.oneTimeCode)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.asciiCapable)
                        .font(Typography.monoM)
                        .lineLimit(1...3)
                        .focused($isFocused)
                        .onChange(of: secret) { _, new in
                            secret = new.uppercased()
                        }
                } else {
                    SecureField(placeholder, text: $secret)
                        .textContentType(.oneTimeCode)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.asciiCapable)
                        .font(Typography.monoM)
                        .focused($isFocused)
                        .onChange(of: secret) { _, new in
                            secret = new.uppercased()
                        }
                }

                // Trailing actions
                HStack(spacing: 6) {
                    Button {
                        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.12)) {
                            reveal.toggle()
                        }
                    } label: {
                        Image(systemName: reveal ? "eye.slash" : "eye")
                            .imageScale(.medium)
                            .padding(8)
                            .background(BrandColor.surfaceSecondary, in: Circle())
                            .accessibilityLabel(reveal ? "Hide secret" : "Show secret") // Localize
                    }
                    .buttonStyle(.plain)
                    .minTapTarget()

                    Button {
                        pasteFromClipboard()
                    } label: {
                        Image(systemName: "doc.on.clipboard")
                            .imageScale(.medium)
                            .padding(8)
                            .background(BrandColor.surfaceSecondary, in: Circle())
                            .accessibilityLabel("Paste from clipboard") // Localize
                    }
                    .buttonStyle(.plain)
                    .minTapTarget()

                    if let onScan {
                        Button(action: onScan) {
                            Image(systemName: "qrcode.viewfinder")
                                .imageScale(.medium)
                                .padding(8)
                                .background(BrandColor.surfaceSecondary, in: Circle())
                                .accessibilityLabel("Scan QR code") // Localize
                        }
                        .buttonStyle(.plain)
                        .minTapTarget()
                    }
                }
            }
            .padding(.horizontal, Spacing.m)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: Layout.smallCorner, style: .continuous)
                    .fill(BrandColor.surfaceSecondary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Layout.smallCorner, style: .continuous)
                    .stroke(borderColor, lineWidth: isFocused ? 1.5 : 1)
                    .animation(reduceMotion ? nil : .easeInOut(duration: 0.12), value: borderColor)
            )

            // Helper line
            HStack(spacing: 6) {
                Image(systemName: helperIcon)
                    .imageScale(.small)
                Text(helperText) // Localize
                    .font(Typography.caption)
                if justPasted {
                    Text("Pasted").font(Typography.caption).foregroundStyle(.secondary)
                        .transition(.opacity)
                }
                Spacer()
            }
            .foregroundStyle(helperColor)
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.18), value: justPasted)
            .accessibilityElement(children: .combine)
        }
        .accessibilityElement(children: .contain)
    }

    // MARK: - Helpers

    private var helperText: String {
        if normalized.isEmpty { return "We never send your secret anywhere." }
        return isValidBase32 ? "Looks like a valid Base32 secret." : "Use A–Z and 2–7 only (spaces OK)."
    }

    private var helperIcon: String {
        if normalized.isEmpty { return "info.circle" }
        return isValidBase32 ? "checkmark.seal" : "exclamationmark.triangle"
    }

    private var helperColor: Color {
        if normalized.isEmpty { return .secondary }
        return isValidBase32 ? .green : .yellow
    }

    private func pasteFromClipboard() {
        #if canImport(UIKit)
        if let s = UIPasteboard.general.string {
            let cleaned = s.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: " ", with: "").uppercased()
            secret = cleaned
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.18)) {
                justPasted = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                withAnimation(reduceMotion ? nil : .easeOut(duration: 0.18)) {
                    justPasted = false
                }
            }
        }
        #endif
    }
}

// MARK: - Base32 Charset Helper

private extension Character {
    var isBase32Char: Bool {
        guard let ascii = self.asciiValue else { return false }
        // 'A'..'Z'
        if ascii >= 65 && ascii <= 90 { return true }
        // '2'..'7'
        if ascii >= 50 && ascii <= 55 { return true }
        return false
    }
}

// MARK: - Preview

#if DEBUG
struct SecretField_Previews: PreviewProvider {
    struct Demo: View {
        @State var secret = ""
        var body: some View {
            VStack(spacing: Spacing.l) {
                SecretField(secret: $secret)
                SecretField(secret: .constant("JBSWY3DPEHPK3PXP"), onScan: {})
            }
            .padding()
            .background(BrandColor.surface)
        }
    }
    static var previews: some View {
        Demo().preferredColorScheme(.dark)
    }
}
#endif
