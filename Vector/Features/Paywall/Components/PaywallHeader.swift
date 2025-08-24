//
//  PaywallHeader.swift
//  Vector
//
//  Created by Adam Zaatar on 8/23/25.
//
// ===============================
// File: Features/Paywall/Components/PaywallHeader.swift
// ===============================

import SwiftUI
import Foundation


/// Hero header with animated glow + brand mark.
/// Use inside Paywall and other Pro surfaces.
public struct PaywallHeader: View {
    public init(title: String = "Vector Pro",
                subtitle: String = "Power features that stay private.") {
        self.title = title
        self.subtitle = subtitle
    }

    private let title: String
    private let subtitle: String

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var glow = false

    public var body: some View {
        VStack(spacing: Spacing.s) {
            ZStack {
                Circle()
                    .fill(BrandGradient.primary())
                    .frame(width: 160, height: 160)
                    .blur(radius: 24)
                    .opacity(reduceMotion ? 0.35 : (glow ? 0.55 : 0.35))
                    .scaleEffect(reduceMotion ? 1.0 : (glow ? 1.06 : 0.98))
                    .animation(reduceMotion ? nil :
                               .easeInOut(duration: 1.6).repeatForever(autoreverses: true),
                               value: glow)

                // Brand mark (prefer your asset name "LaunchLogo"; fallback to SF)
                if let uiImage = UIImage(named: "LaunchLogo") {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 84, height: 84)
                        .accessibilityHidden(true)
                } else {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 56, weight: .bold))
                        .accessibilityHidden(true)
                }
            }
            .padding(.top, Spacing.l)
            .onAppear { glow = true }

            Text(title) // Localize
                .font(Typography.titleL)
                .foregroundStyle(BrandColor.primaryText)
                .accessibilityAddTraits(.isHeader)

            Text(subtitle) // Localize
                .font(Typography.body)
                .foregroundStyle(.secondary)
        }
        .multilineTextAlignment(.center)
        .padding(.bottom, Spacing.m)
        .accessibilityElement(children: .contain)
    }
}

#if DEBUG
struct PaywallHeader_Previews: PreviewProvider {
    static var previews: some View {
        PaywallHeader()
            .padding()
            .background(BrandGradient.primary())
            .preferredColorScheme(.dark)
    }
}
#endif
