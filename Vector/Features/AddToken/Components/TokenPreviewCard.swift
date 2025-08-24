//
//  TokenPreviewCard.swift
//  Vector
//
//  Created by Adam Zaatar on 8/23/25.
//  File: Features/AddToken/Components/TokenPreviewCard.swift
//


import Foundation
import SwiftUI
import Combine

/// Live “what this will look like” preview for Add Token.
/// Shows issuer/account, color dot, a ticking time ring, and a masked code placeholder.
/// Reuses the same visual language as `TokenRow` without needing a real secret/code.
public struct TokenPreviewCard: View {
    public init(issuer: String,
                account: String,
                color: TokenColor? = nil,
                digits: Int = 6,
                period: Int = 30) {
        self.issuer = issuer
        self.account = account
        self.color = color
        self.digits = max(6, min(8, digits))
        self.period = max(10, min(120, period))
    }

    private let issuer: String
    private let account: String
    private let color: TokenColor?
    private let digits: Int
    private let period: Int

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var now: Date = .init()

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Text("Preview") // Localize
                .font(Typography.titleS)
                .foregroundStyle(BrandColor.primaryText)
                .accessibilityAddTraits(.isHeader)

            HStack(spacing: Spacing.m) {
                // Leading color tag
                Circle()
                    .fill((color?.color ?? BrandColor.accent))
                    .frame(width: 12, height: 12)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text(issuer.isEmpty ? "Issuer" : issuer) // Localize placeholder
                        .font(Typography.body)
                        .foregroundStyle(BrandColor.primaryText)
                        .lineLimit(1)

                    Text(account.isEmpty ? "account@example.com" : account)
                        .font(Typography.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: Spacing.m)

                // Masked code + ring (decorative)
                VStack(spacing: 2) {
                    Text(maskedCode(digits: digits))
                        .font(Typography.monoM)
                        .foregroundStyle(BrandColor.primaryText)

                    // Removed unsupported `strokeWidth:` parameter
                    TimeRing(progress: ringProgress)
                        .frame(width: 26, height: 26)
                        .accessibilityLabel(Text("Time remaining")) // Localize
                        .accessibilityValue(Text("\(secondsRemaining) seconds")) // Localize
                }
            }
            .padding(.vertical, 4)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(Text("\(issuer.isEmpty ? "Issuer" : issuer), \(account.isEmpty ? "account at example dot com" : account). \(secondsRemaining) seconds left.")) // Localize
        }
        .padding(Spacing.m)
        .background(
            RoundedRectangle(cornerRadius: Layout.cardCorner, style: .continuous)
                .fill(BrandColor.surfaceSecondary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Layout.cardCorner, style: .continuous)
                .stroke(BrandColor.divider.opacity(0.6), lineWidth: 1)
        )
        .onReceive(timer) { now = $0 }
    }

    // MARK: - Timer

    private var timer: Publishers.Autoconnect<Timer.TimerPublisher> {
        Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    }

    // MARK: - Ring / code helpers

    private var ringProgress: Double {
        let t = Int(now.timeIntervalSince1970)
        let mod = t % period
        // Progress goes 0 -> 1 over the period
        return Double(mod) / Double(period)
    }

    private var secondsRemaining: Int {
        let t = Int(now.timeIntervalSince1970)
        let mod = t % period
        return max(0, period - mod)
    }

    private func maskedCode(digits: Int) -> String {
        // Group into 3-3 for 6 or 4-4 for 8 to match common display
        if digits == 6 {
            return "••• •••"
        } else {
            return "•••• ••••"
        }
    }
}

// MARK: - Preview

#if DEBUG
struct TokenPreviewCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: Spacing.m) {
            TokenPreviewCard(issuer: "GitHub", account: "you@example.com", color: .blue, digits: 6, period: 30)
            TokenPreviewCard(issuer: "AWS", account: "admin@company.com", color: .orange, digits: 8, period: 30)
            TokenPreviewCard(issuer: "", account: "", color: nil, digits: 6, period: 30) // placeholders
        }
        .padding()
        .background(BrandColor.surface)
        .preferredColorScheme(.dark)
    }
}
#endif
