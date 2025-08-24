//
//  SecretValidationIndicator.swift
//  Vector
//
//  Created by Adam Zaatar on 8/23/25.
//  File: Features/AddToken/Components/SecretValidationIndicator.swift
//

import SwiftUI
import Foundation

/// Shows live validation feedback for the Base32 secret the user is typing.
/// - Validates allowed Base32 charset (RFC 4648) and attempts a decode.
/// - Estimates strength using decoded byte length (≈ entropy bits).
/// - Designed to sit directly under the “Base32 Secret” field.
///
/// Usage:
/// ```swift
/// SecureField("Base32 Secret", text: $vm.secretBase32)
/// SecretValidationIndicator(secret: vm.secretBase32)
/// ```
public struct SecretValidationIndicator: View {
    public init(secret: String) { self.secret = secret }

    private let secret: String
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var visible = false

    public var body: some View {
        Group {
            switch evaluate(secret) {
            case .none:
                EmptyView()

            case .invalid:
                pill(icon: "exclamationmark.triangle.fill",
                     text: "Invalid Base32 — use A-Z and 2-7",
                     tint: .orange)

            case .weak(let bits):
                pill(icon: "exclamationmark.circle.fill",
                     text: "Valid, but weak (\(bits)-bit). Use a longer secret.",
                     tint: .yellow)

            case .ok(let bits):
                pill(icon: "checkmark.seal.fill",
                     text: "Valid Base32 (\(bits)-bit)",
                     tint: .green)
            }
        }
        .onAppear { visible = true }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.18), value: visible)
    }

    // MARK: - UI

    @ViewBuilder
    private func pill(icon: String, text: String, tint: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .imageScale(.medium)
                .foregroundStyle(tint)
            Text(text)
                .font(Typography.caption)
                .foregroundStyle(BrandColor.primaryText)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, Spacing.m)
        .padding(.vertical, 8)
        .background(
            Capsule(style: .continuous)
                .fill(BrandColor.surfaceSecondary)
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(BrandColor.divider.opacity(0.6), lineWidth: 1)
        )
        .transition(.opacity.combined(with: .move(edge: .top)))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(text)) // Localize
    }

    // MARK: - Validation

    private enum Result {
        case none
        case invalid
        case weak(bits: Int)
        case ok(bits: Int)
    }

    private func evaluate(_ input: String) -> Result {
        let trimmed = input.replacingOccurrences(of: " ", with: "")
                           .replacingOccurrences(of: "-", with: "")
                           .replacingOccurrences(of: "_", with: "")
                           .uppercased()

        guard !trimmed.isEmpty else { return .none }
        guard isBase32Charset(trimmed) else { return .invalid }
        guard let bytes = Base32.decode(trimmed) else { return .invalid }

        let bits = bytes.count * 8
        // NIST-ish guidance: 80+ bits acceptable for shared secret.
        if bits < 64 { return .weak(bits: bits) }
        return .ok(bits: bits)
    }

    private func isBase32Charset(_ s: String) -> Bool {
        for ch in s where ch != "=" {
            let isAZ = (ch >= "A" && ch <= "Z")
            let is27 = (ch >= "2" && ch <= "7")
            if !(isAZ || is27) { return false }
        }
        return true
    }
}

// MARK: - Minimal Base32 decode (RFC 4648, no padding required)

fileprivate enum Base32 {
    private static let alphabet = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ234567")
    private static let map: [Character: UInt8] = {
        var m = [Character: UInt8]()
        for (i, c) in alphabet.enumerated() {
            m[c] = UInt8(i)
        }
        return m
    }()

    static func decode(_ s: String) -> Data? {
        var buffer: UInt32 = 0
        var bits = 0
        var out = [UInt8]()
        for ch in s where ch != "=" {
            guard let val = map[ch] else { return nil }
            buffer = (buffer << 5) | UInt32(val)
            bits += 5
            if bits >= 8 {
                bits -= 8
                out.append(UInt8((buffer >> UInt32(bits)) & 0xff))
            }
        }
        // If leftover bits are non-zero, ignore (common in no-padding input)
        return out.isEmpty ? nil : Data(out)
    }
}

// MARK: - Preview

#if DEBUG
struct SecretValidationIndicator_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: Spacing.m) {
            Group {
                Text("Empty → no pill")
                SecretValidationIndicator(secret: "")

                Text("Invalid")
                SecretValidationIndicator(secret: "OOPS-?!")

                Text("Weak (~40 bits)")
                SecretValidationIndicator(secret: "GEZDGNBV") // "1234567" ~ 5 bytes

                Text("OK (>=80 bits)")
                SecretValidationIndicator(secret: "GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ") // 20 bytes
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(BrandColor.surface)
        .preferredColorScheme(.dark)
    }
}
#endif
