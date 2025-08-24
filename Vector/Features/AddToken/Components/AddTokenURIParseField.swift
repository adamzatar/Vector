//
//  AddTokenURIParseField.swift
//  Vector
//
//  Created by Adam Zaatar on 8/23/25.
//  File: Features/AddToken/Components/AddTokenURIParseField.swift
//

import SwiftUI
import Foundation

/// Polished, accessible input for pasting an `otpauth://` URI and parsing it.
/// - Validates prefix live and surfaces a small status chip.
/// - Uses brand surfaces/borders; respects Dynamic Type & Reduce Motion.
/// - Emits the current text via `onParse` when user taps the Parse button.
///
/// Usage:
/// ```swift
/// @State private var uri: String = ""
/// AddTokenURIParseField(text: $uri) { parse($0) }
/// ```
public struct AddTokenURIParseField: View {
    @Binding var text: String
    var onParse: (String) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize
    @FocusState private var focused: Bool
    @State private var appeared = false

    public init(text: Binding<String>, onParse: @escaping (String) -> Void) {
        self._text = text
        self.onParse = onParse
    }

    private var trimmed: String { text.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var isLikelyURI: Bool { trimmed.lowercased().hasPrefix("otpauth://") }
    private var canParse: Bool { !trimmed.isEmpty && isLikelyURI }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            HStack(spacing: Spacing.s) {
                Image(systemName: "link.badge.plus")
                    .imageScale(.medium)
                    .foregroundStyle(.secondary)
                Text("Paste otpauth:// URI") // Localize
                    .font(Typography.body)
                    .foregroundStyle(BrandColor.primaryText)
                Spacer(minLength: Spacing.s)
                statusChip
            }
            .accessibilityElement(children: .combine)

            HStack(alignment: .top, spacing: Spacing.s) {
                TextField("otpauth://totp/Issuer:account?secret=BASE32…", text: $text, axis: .vertical) // Localize
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)
                    .lineLimit(1...(typeSize.isAccessibilitySize ? 5 : 3))
                    .focused($focused)
                    .padding(.horizontal, Spacing.s)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: Layout.smallCorner, style: .continuous)
                            .fill(BrandColor.surfaceSecondary)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: Layout.smallCorner, style: .continuous)
                            .strokeBorder(BrandColor.divider.opacity(0.6), lineWidth: 1)
                    )
                    .accessibilityLabel(Text("OTP Auth URI field")) // Localize

                Button {
                    withAnimation(reduceMotion ? nil : .easeOut(duration: 0.12)) {
                        focused = false
                    }
                    onParse(trimmed)
                } label: {
                    Label("Parse", systemImage: "arrow.down.doc") // Localize
                        .labelStyle(.titleAndIcon)
                        .font(Typography.body)
                        .padding(.horizontal, Spacing.m)
                        .padding(.vertical, 10)
                        .background(
                            Capsule(style: .continuous)
                                .fill(canParse ? BrandColor.accent.opacity(0.18) : BrandColor.surfaceSecondary)
                        )
                        .overlay(
                            Capsule(style: .continuous)
                                .stroke(canParse ? Color.accentColor : BrandColor.divider.opacity(0.6), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .disabled(!canParse)
                .accessibilityHint(Text("Parses the pasted URI into fields")) // Localize
            }
        }
        .scaleEffect(reduceMotion ? 1.0 : (appeared ? 1.0 : 0.98))
        .opacity(appeared ? 1.0 : 0.0)
        .animation(reduceMotion ? nil : .spring(response: 0.28, dampingFraction: 0.9), value: appeared)
        .onAppear { appeared = true }
    }

    private var statusChip: some View {
        HStack(spacing: 6) {
            Image(systemName: isLikelyURI ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                .imageScale(.small)
                .foregroundStyle(isLikelyURI ? Color.green : Color.yellow)
                .accessibilityHidden(true)
            Text(isLikelyURI ? "Looks valid" : "Waiting for otpauth://") // Localize
                .font(Typography.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, Spacing.s)
        .padding(.vertical, 6)
        .background(
            Capsule(style: .continuous)
                .fill(BrandColor.surfaceSecondary)
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(BrandColor.divider.opacity(0.6), lineWidth: 1)
        )
        .accessibilityLabel(Text(isLikelyURI ? "URI appears valid" : "Paste an otpauth URI"))
    }
}

// MARK: - Preview

#if DEBUG
struct AddTokenURIParseField_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: Spacing.m) {
            AddTokenURIParseField(text: .constant("")) { _ in }
            AddTokenURIParseField(text: .constant("otpauth://totp/GitHub:me?secret=ABC&issuer=GitHub")) { _ in }
        }
        .padding()
        .background(BrandColor.surface)
        .preferredColorScheme(.dark)
    }
}
#endif
