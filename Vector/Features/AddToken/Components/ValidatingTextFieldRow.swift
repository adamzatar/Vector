//
//  ValidatingTextFieldRow.swift
//  Vector
//
//  Created by Adam Zaatar on 8/23/25.
//  File: Features/AddToken/Components/ValidatingTextFieldRow.swift
//

import Foundation
import SwiftUI
import UIKit

/// A polished, reusable form row with inline validation and (optional) secure reveal.
/// - Works for issuer/account/secret fields on AddTokenView.
/// - Shows a trailing status icon (success/warning/error) based on a validator closure.
/// - If `isSecure == true`, renders an eye button to reveal/hide the text.
/// - Respects Dynamic Type and Reduce Motion.
/// - Uses the Vector design system (Typography, Spacing, BrandColor).
struct ValidatingTextFieldRow: View {
    // MARK: - Types
    enum ValidationState: Equatable {
        case neutral
        case success(message: String? = nil)
        case warning(message: String? = nil)
        case error(message: String? = nil)

        var message: String? {
            switch self {
            case .neutral: return nil
            case .success(let m), .warning(let m), .error(let m): return m
            }
        }
    }

    // MARK: - Inputs
    let title: String?
    let placeholder: String
    @Binding var text: String

    var isSecure: Bool = false
    var keyboard: UIKeyboardType = .default
    var contentType: UITextContentType? = nil
    var autocap: TextInputAutocapitalization = .never
    var autocorrect: Bool = false
    var validator: ((String) -> ValidationState)? = nil

    // MARK: - State
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var revealSecure: Bool = false
    @State private var isFocused: Bool = false

    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let title {
                Text(title)
                    .font(Typography.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityAddTraits(.isHeader)
            }

            HStack(spacing: 10) {
                field
                    .font(Typography.body)
                    .textInputAutocapitalization(autocap)
                    .autocorrectionDisabled(!autocorrect)
                    .keyboardType(keyboard)
                    .textContentType(contentType)
                    .onTapGesture { withSmallAnim { isFocused = true } }

                if isSecure {
                    Button {
                        withSmallAnim { revealSecure.toggle() }
                    } label: {
                        Image(systemName: revealSecure ? "eye.slash.fill" : "eye.fill")
                            .imageScale(.medium)
                            .foregroundStyle(.secondary)
                            .padding(8)
                            .background(
                                Circle().fill(BrandColor.surfaceSecondary.opacity(0.6))
                            )
                    }
                    .buttonStyle(.plain)
                    .minTapTarget()
                    .accessibilityLabel(revealSecure ? "Hide secret" : "Show secret") // Localize
                }

                statusIcon
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(BrandColor.surfaceSecondary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(borderColor.opacity(0.7), lineWidth: 1)
            )

            if let msg = currentState.message, !msg.isEmpty {
                Text(msg)
                    .font(Typography.caption)
                    .foregroundStyle(captionColor)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                    .accessibilityHint(msg)
            }
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.12), value: currentStateHash)
        .accessibilityElement(children: .contain)
    }

    // MARK: - Subviews

    @ViewBuilder
    private var field: some View {
        if isSecure && !revealSecure {
            SecureField(placeholder, text: $text)
                .textContentType(contentType)
        } else {
            TextField(placeholder, text: $text)
                .textContentType(contentType)
        }
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch currentState {
        case .neutral:
            EmptyView()
        case .success:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .accessibilityLabel("Looks good") // Localize
        case .warning:
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(.yellow)
                .accessibilityLabel("Warning") // Localize
        case .error:
            Image(systemName: "xmark.octagon.fill")
                .foregroundStyle(.red)
                .accessibilityLabel("Error") // Localize
        }
    }

    // MARK: - Derived

    private var currentState: ValidationState {
        validator?(text) ?? .neutral
    }

    private var currentStateHash: Int {
        switch currentState {
        case .neutral: return 0
        case .success: return 1
        case .warning: return 2
        case .error:   return 3
        }
    }

    private var borderColor: Color {
        switch currentState {
        case .neutral: return BrandColor.divider
        case .success: return .green
        case .warning: return .yellow
        case .error:   return .red
        }
    }

    private var captionColor: Color {
        switch currentState {
        case .neutral, .success: return .secondary
        case .warning: return .yellow
        case .error:   return .red
        }
    }

    // MARK: - Helpers

    private func withSmallAnim(_ changes: () -> Void) {
        if reduceMotion { changes(); return }
        withAnimation(.easeInOut(duration: 0.12), changes)
    }
}

// MARK: - Sugar Validators (optional, handy for AddToken)

extension ValidatingTextFieldRow.ValidationState {
    static func nonEmpty(_ s: String, message: String = "") -> Self {
        s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .error(message: "Required") : .success(message: message)
    }

    static func base32(_ s: String) -> Self {
        let trimmed = s.replacingOccurrences(of: " ", with: "").uppercased()
        let allowed = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567=")
        if trimmed.isEmpty { return .neutral }
        if trimmed.unicodeScalars.contains(where: { !allowed.contains($0) }) { return .error(message: "Invalid Base32") }
        if trimmed.count < 16 { return .warning(message: "Short secret") }
        return .success(message: nil)
    }

    static func emailish(_ s: String) -> Self {
        if s.isEmpty { return .neutral }
        return (s.contains("@") && s.contains(".")) ? .success() : .warning(message: "Looks unusual")
    }
}

// MARK: - Previews

#if DEBUG
struct ValidatingTextFieldRow_Previews: PreviewProvider {
    struct Demo: View {
        @State var issuer = ""
        @State var account = "dev@example.com"
        @State var secret = ""
        var body: some View {
            VStack(spacing: 16) {
                ValidatingTextFieldRow(
                    title: "Issuer",
                    placeholder: "GitHub",
                    text: $issuer,
                    isSecure: false,
                    keyboard: .default,
                    contentType: .organizationName,
                    autocap: .words,
                    autocorrect: true,
                    validator: { .nonEmpty($0) }
                )
                ValidatingTextFieldRow(
                    title: "Account",
                    placeholder: "email or username",
                    text: $account,
                    keyboard: .emailAddress,
                    contentType: .username,
                    autocap: .never,
                    autocorrect: false,
                    validator: { .emailish($0) }
                )
                ValidatingTextFieldRow(
                    title: "Base32 Secret",
                    placeholder: "JBSWY3DPEHPK3PXP…",
                    text: $secret,
                    isSecure: true,
                    keyboard: .asciiCapable,
                    contentType: .oneTimeCode,
                    validator: { .base32($0) }
                )
            }
            .padding()
            .background(BrandGradient.primary().ignoresSafeArea())
            .preferredColorScheme(.dark)
        }
    }

    static var previews: some View {
        Demo()
            .previewLayout(.sizeThatFits)
    }
}
#endif
