//
//  IssuerAccountFields.swift
//  Vector
//
//  Created by Adam Zaatar on 8/23/25.
//  File: Features/AddToken/Components/IssuerAccountFields.swift
//

import SwiftUI
import Foundation

/// Polished issuer + account inputs used by AddTokenView.
/// - Consistent styling with BrandColor / Typography
/// - Smart keyboards (org name vs email/username)
/// - Live “is-filled” affordance with subtle validation hints
/// - Large tap targets, full accessibility, and Reduced Motion-aware
///
/// Usage:
/// ```swift
/// IssuerAccountFields(
///     issuer: $vm.issuer,
///     account: $vm.account,
///     onNext: { focusedField = .secret }
/// )
/// ```
public struct IssuerAccountFields: View {
    @Binding public var issuer: String
    @Binding public var account: String
    public var onNext: (() -> Void)?

    @FocusState private var focusIssuer: Bool
    @FocusState private var focusAccount: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(issuer: Binding<String>, account: Binding<String>, onNext: (() -> Void)? = nil) {
        _issuer = issuer
        _account = account
        self.onNext = onNext
    }

    // MARK: - Derived

    private var isIssuerValid: Bool { !issuer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    private var isAccountValid: Bool { !account.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    private func row(icon: String, title: String, placeholder: String, isValid: Bool, isFocused: Bool, field: () -> some View) -> some View {
        HStack(spacing: Spacing.m) {
            Image(systemName: icon)
                .imageScale(.medium)
                .frame(width: 24)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(Typography.caption)
                    .foregroundStyle(.secondary)

                field()
                    .font(Typography.body)
                    .foregroundStyle(BrandColor.primaryText)
            }

            Spacer(minLength: Spacing.s)

            if isValid {
                Image(systemName: "checkmark.circle.fill")
                    .imageScale(.large)
                    .foregroundStyle(.green)
                    .transition(.opacity.combined(with: .scale))
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
                .stroke(isFocused ? BrandColor.accent : BrandColor.divider.opacity(0.6),
                        lineWidth: isFocused ? 1.5 : 1)
                .animation(reduceMotion ? nil : .easeInOut(duration: 0.12), value: isFocused)
        )
        .accessibilityElement(children: .combine)
    }

    // MARK: - Body

    public var body: some View {
        VStack(spacing: Spacing.m) {
            // Issuer
            row(icon: "building.2.crop.circle",
                title: "Issuer",                 // Localize
                placeholder: "Issuer (e.g., GitHub)",  // Localize
                isValid: isIssuerValid,
                isFocused: focusIssuer
            ) {
                TextField("Issuer (e.g., GitHub)", text: $issuer) // Localize
                    .textContentType(.organizationName)
                    .submitLabel(.next)
                    .focused($focusIssuer)
                    .onSubmit { focusAccount = true }
            }

            // Account (email/username)
            row(icon: "person.crop.circle",
                title: "Account",                // Localize
                placeholder: "Email or username", // Localize
                isValid: isAccountValid,
                isFocused: focusAccount
            ) {
                TextField("Email or username", text: $account) // Localize
                    .textContentType(.username)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(account.contains("@") ? .emailAddress : .default)
                    .submitLabel(.next)
                    .focused($focusAccount)
                    .onSubmit { onNext?() }
            }

            // Helper
            Text("Issuer is the service name (e.g., GitHub). Account is your email or username.") // Localize
                .font(Typography.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Preview

#if DEBUG
struct IssuerAccountFields_Previews: PreviewProvider {
    struct Demo: View {
        @State var issuer = ""
        @State var account = ""
        var body: some View {
            VStack(spacing: Spacing.l) {
                IssuerAccountFields(issuer: $issuer, account: $account)
                IssuerAccountFields(issuer: .constant("GitHub"), account: .constant("dev@example.com"))
            }
            .padding()
            .background(BrandColor.surface)
        }
    }
    static var previews: some View { Demo().preferredColorScheme(.dark) }
}
#endif
