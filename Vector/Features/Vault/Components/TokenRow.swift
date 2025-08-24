//
//  TokenRow.swift
//  Vector
//
//  Created by Adam Zaatar on 8/21/25.
//  File: Features/Vault/Components/TokenRow.swift
//


import SwiftUI
import Foundation

/// A compact, performant row presenting a single OTP token entry.
/// - Shows issuer, account, a small color dot, a ticking time ring, and a copy action.
/// - Color handling uses our `TokenColor` enum (blue, orange, green, purple, gray).
/// - Accessible labels/hints; large tap targets; zero layout jank.
struct TokenRow: View {
    let issuer: String
    let account: String
    let color: TokenColor?
    let secondsRemaining: Int
    /// Normalized [0,1] progress of the current TOTP window.
    let progress: Double
    let onCopy: () -> Void

    var body: some View {
        HStack(spacing: Spacing.m) {
            // Leading emblem (color tag)
            Circle()
                .fill(dotColor)
                .frame(width: 12, height: 12)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(issuer)
                    .font(Typography.body)
                    .foregroundStyle(BrandColor.primaryText)
                    .lineLimit(1)

                Text(account)
                    .font(Typography.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: Spacing.m)

            // Countdown ring + seconds remaining (decorative ring, value via AX)
            TimeRing(progress: progress)
                .frame(width: 28, height: 28)
                .accessibilityLabel(Text("Time remaining")) // Localize
                .accessibilityValue(Text("\(secondsRemaining) seconds")) // Localize

            Button(action: onCopy) {
                Image(systemName: "doc.on.doc")
                    .imageScale(.medium)
                    .padding(8)
                    .background(Circle().fill(BrandColor.surfaceSecondary.opacity(0.5)))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Copy code") // Localize
            .minTapTarget()
        }
        .contentShape(Rectangle())
        // List row configuration is kept here for convenience; safe to remove if styling list externally.
        .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
        .listRowBackground(BrandColor.surface)
    }

    private var dotColor: Color {
        // Map optional TokenColor to a SwiftUI Color. Fallback = brand accent.
        color?.color ?? BrandColor.accent
    }
}

// MARK: - Preview

#if DEBUG
struct TokenRow_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: Spacing.l) {
            TokenRow(
                issuer: "GitHub",
                account: "dev@example.com",
                color: .blue,
                secondsRemaining: 18,
                progress: 0.4,
                onCopy: {}
            )
            TokenRow(
                issuer: "AWS",
                account: "admin@example.com",
                color: .orange,
                secondsRemaining: 3,
                progress: 0.9,
                onCopy: {}
            )
            TokenRow(
                issuer: "Cloudflare",
                account: "ops@example.com",
                color: nil, // fallback accent
                secondsRemaining: 27,
                progress: 0.1,
                onCopy: {}
            )
        }
        .padding()
        .background(BrandColor.surface)
        .previewLayout(.sizeThatFits)
        .preferredColorScheme(.dark)
    }
}
#endif
