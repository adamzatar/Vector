//
//  ValidationHintRow.swift
//  Vector
//
//  Created by Adam Zaatar on 8/23/25.
//  File: Features/AddToken/Components/ValidationHintRow.swift
//

import Foundation
import SwiftUI

/// Lightweight, reusable validation hint row for form fields.
/// - Shows a leading status icon (pending/valid/invalid) and concise guidance.
/// - VoiceOver-friendly with combined label/value.
/// - Drop into footers or below inputs for issuer/account/secret guidance.
public enum FieldValidity: Equatable {
    case pending                 // default / untouched
    case valid                   // passes validation
    case invalid(message: String) // fails with reason
}

public struct ValidationHintRow: View {
    public init(title: String,
                validity: FieldValidity,
                help: String? = nil) {
        self.title = title
        self.validity = validity
        self.help = help
    }

    private let title: String
    private let validity: FieldValidity
    private let help: String?

    public var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.s) {
            statusIcon
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Typography.caption)
                    .foregroundStyle(labelColor)

                if let message = errorMessage {
                    Text(message)
                        .font(Typography.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                } else if let help {
                    Text(help)
                        .font(Typography.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: Spacing.s)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Accessible.label(for: title, validity: validity, help: help))
    }

    // MARK: - Pieces

    private var errorMessage: String? {
        if case let .invalid(message) = validity { return message }
        return nil
    }

    private var labelColor: Color {
        switch validity {
        case .pending: return BrandColor.secondaryText
        case .valid:   return BrandColor.primaryText
        case .invalid: return .red
        }
    }

    private var statusIcon: some View {
        Group {
            switch validity {
            case .pending:
                Image(systemName: "questionmark.circle")
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(BrandColor.secondaryText)
            case .valid:
                Image(systemName: "checkmark.circle.fill")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, .green)
            case .invalid:
                Image(systemName: "xmark.octagon.fill")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, .red)
            }
        }
        .imageScale(.medium)
    }
}

// MARK: - Accessible strings

private enum Accessible {
    static func label(for title: String, validity: FieldValidity, help: String?) -> Text {
        switch validity {
        case .pending:
            return Text("\(title). Status pending. \(help ?? "")")
        case .valid:
            return Text("\(title). Looks good.")
        case .invalid(let message):
            return Text("\(title). Invalid. \(message)")
        }
    }
}

// MARK: - Convenience container

/// Use this to show a stacked set of validation hints with consistent spacing & styling.
public struct ValidationHintGroup<Content: View>: View {
    public init(@ViewBuilder content: () -> Content) { self.content = content() }
    private let content: Content

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            content
        }
        .padding(.vertical, 4)
    }
}

#if DEBUG
struct ValidationHintRow_Previews: PreviewProvider {
    static var previews: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            ValidationHintGroup {
                ValidationHintRow(
                    title: "Issuer",
                    validity: .valid,
                    help: "Organization or service name."
                )
                ValidationHintRow(
                    title: "Account",
                    validity: .pending,
                    help: "Email or username associated with the service."
                )
                ValidationHintRow(
                    title: "Secret",
                    validity: .invalid(message: "Base32 must be letters A-Z and digits 2-7.")
                )
            }
        }
        .padding()
        .background(BrandColor.surface)
        .preferredColorScheme(.dark)
    }
}
#endif
