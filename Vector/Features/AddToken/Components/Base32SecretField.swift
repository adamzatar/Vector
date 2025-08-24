//
//  Base32SecretField.swift
//  Vector
//
//  Created by Adam Zaatar on 8/23/25.
//  File: Features/AddToken/Components/Base32SecretField.swift
//

import SwiftUI
import Foundation
import UIKit

/// A polished, reusable Base32 secret field with:
/// - Show/Hide toggle, paste-from-clipboard, and (optional) Scan action
/// - Live Base32 validation with subtle success/error affordances
/// - Monospaced font, large tap targets, and full accessibility support
///
/// Usage:
/// ```swift
/// Base32SecretField(text: $vm.secretBase32, onScanTapped: { scanning = true })
/// ```
///
/// Design notes:
/// - Uses BrandColor / Typography / Spacing
/// - Keeps motion minimal and respects Reduce Motion
public struct Base32SecretField: View {
    @Binding var text: String

    public init(
        text: Binding<String>,
        placeholder: String = "Base32 Secret",            // Localize
        onScanTapped: (() -> Void)? = nil,
        onValidityChange: ((Bool) -> Void)? = nil
    ) {
        self._text = text
        self.placeholder = placeholder
        self.onScanTapped = onScanTapped
        self.onValidityChange = onValidityChange
    }

    // MARK: - Configuration

    private let placeholder: String
    private let onScanTapped: (() -> Void)?
    private let onValidityChange: ((Bool) -> Void)?

    // MARK: - Local UI State

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @FocusState private var focused: Bool
    @State private var showPlain = false
    @State private var lastValidity: Bool = false

    // MARK: - Derived

    private var sanitized: String {
        text.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "-", with: "")
    }

    private var isValidBase32: Bool {
        guard !sanitized.isEmpty else { return false }
        // RFC 4648 alphabet (case-insensitive), ignore spaces/hyphens which we strip.
        let allowed = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567abcdefghijklmnopqrstuvwxyz")
        return sanitized.unicodeScalars.allSatisfy { allowed.contains($0) }
    }

    private var borderColor: Color {
        if text.isEmpty { return BrandColor.divider.opacity(0.6) }
        return isValidBase32 ? BrandColor.accent : .red.opacity(0.6)
    }

    // MARK: - Body

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: Spacing.s) {
                // Text / Secure field
                Group {
                    if showPlain {
                        TextField(placeholder, text: $text, axis: .vertical)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .keyboardType(.asciiCapable)
                            .focused($focused)
                            .lineLimit(1...3)
                            .font(Typography.monoM)
                            .accessibilityLabel(Text("Base32 Secret")) // Localize
                    } else {
                        SecureField(placeholder, text: $text)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .keyboardType(.asciiCapable)
                            .focused($focused)
                            .font(Typography.monoM)
                            .accessibilityLabel(Text("Base32 Secret (secure)")) // Localize
                    }
                }

                Spacer(minLength: Spacing.s)

                // Paste
                Button {
                    if let s = UIPasteboard.general.string {
                        text = s.trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                } label: {
                    Image(systemName: "doc.on.clipboard")
                        .imageScale(.medium)
                        .padding(8)
                        .background(Circle().fill(BrandColor.surfaceSecondary.opacity(0.5)))
                        .accessibilityLabel(Text("Paste")) // Localize
                }
                .buttonStyle(.plain)
                .minTapTarget()

                // Scan (optional)
                if let onScanTapped {
                    Button(action: onScanTapped) {
                        Image(systemName: "qrcode.viewfinder")
                            .imageScale(.medium)
                            .padding(8)
                            .background(Circle().fill(BrandColor.surfaceSecondary.opacity(0.5)))
                            .accessibilityLabel(Text("Scan QR")) // Localize
                    }
                    .buttonStyle(.plain)
                    .minTapTarget()
                }

                // Show/Hide toggle
                Button {
                    withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.12)) {
                        showPlain.toggle()
                    }
                } label: {
                    Image(systemName: showPlain ? "eye.slash" : "eye")
                        .imageScale(.medium)
                        .padding(8)
                        .background(Circle().fill(BrandColor.surfaceSecondary.opacity(0.5)))
                        .accessibilityLabel(Text(showPlain ? "Hide secret" : "Show secret")) // Localize
                }
                .buttonStyle(.plain)
                .minTapTarget()

                // Validity icon
                if !text.isEmpty {
                    Image(systemName: isValidBase32 ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .imageScale(.large)
                        .foregroundStyle(isValidBase32 ? .green : .red)
                        .transition(.opacity.combined(with: .scale))
                        .accessibilityLabel(Text(isValidBase32 ? "Valid Base32" : "Invalid Base32")) // Localize
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
                    .stroke(borderColor, lineWidth: focused ? 1.5 : 1)
                    .animation(reduceMotion ? nil : .easeInOut(duration: 0.12), value: focused)
            )

            // Helper text
            if !text.isEmpty {
                Text("Use letters A–Z and digits 2–7. Spaces and dashes are ignored.") // Localize
                    .font(Typography.caption)
                    .foregroundStyle(.secondary)
                    .transition(.opacity)
            }
        }
        .onChange(of: isValidBase32) { _, new in
            if new != lastValidity {
                lastValidity = new
                onValidityChange?(new)
            }
        }
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Preview

#if DEBUG
struct Base32SecretField_Previews: PreviewProvider {
    struct Demo: View {
        @State var secret = ""
        var body: some View {
            VStack(spacing: Spacing.m) {
                Base32SecretField(text: $secret, onScanTapped: {})
                Base32SecretField(text: .constant("JBSWY3DPEHPK3PXP"))
                Base32SecretField(text: .constant("invalid*secret"))
            }
            .padding()
            .background(BrandColor.surface)
        }
    }
    static var previews: some View { Demo().preferredColorScheme(.dark) }
}
#endif
