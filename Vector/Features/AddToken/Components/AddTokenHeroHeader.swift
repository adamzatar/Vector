//
//  AddTokenHeroHeader.swift
//  Vector
//
//  Created by Adam Zaatar on 8/23/25.
//  File: Features/AddToken/Components/AddTokenHeroHeader.swift
//
import Foundation
import SwiftUI

/// Brand-forward header for the Add Token screen.
/// - Shows the Vector mark with a soft “breathe” animation (respects Reduce Motion),
///   plus a concise title & subtitle using the design system.
/// - Drop this at the top of the form for immediate polish.
/// - Uses asset "LaunchLogo" to avoid cross-feature dependencies.
struct AddTokenHeroHeader: View {
    // MARK: - Inputs
    let title: String
    let subtitle: String
    var compact: Bool = false

    // MARK: - Motion
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var breathe = false

    // MARK: - Body
    var body: some View {
        VStack(spacing: compact ? 8 : 12) {
            // Logo mark
            Image("LaunchLogo")
                .resizable()
                .scaledToFit()
                .frame(width: compact ? 44 : 64, height: compact ? 44 : 64)
                .shadow(color: .black.opacity(0.18), radius: 10, x: 0, y: 6)
                .scaleEffect(reduceMotion ? 1.0 : (breathe ? 1.03 : 1.0))
                .animation(reduceMotion ? nil : .easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: breathe)
                .accessibilityHidden(true)

            // Copy
            Text(title)
                .font(compact ? Typography.titleM : Typography.titleL)
                .foregroundStyle(BrandColor.primaryText)
                .accessibilityAddTraits(.isHeader)

            Text(subtitle)
                .font(Typography.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 16)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, compact ? 6 : 10)
        .padding(.bottom, compact ? 6 : 10)
        .background(
            // Subtle wash to give the header separation without a heavy card
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .opacity(0.7)
                .blur(radius: 0.3)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(BrandColor.divider.opacity(0.5), lineWidth: 1)
                )
                .padding(.horizontal, 12)
        )
        .onAppear { breathe = true }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Convenience Initializers

extension AddTokenHeroHeader {
    init(compact: Bool = false) {
        self.init(
            title: "Add Token",                     // Localize
            subtitle: "Scan a QR or enter details", // Localize
            compact: compact
        )
    }
}

// MARK: - Previews

#if DEBUG
struct AddTokenHeroHeader_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 24) {
            AddTokenHeroHeader()
            AddTokenHeroHeader(
                title: "Add GitHub",
                subtitle: "Use your camera to scan the QR code from GitHub’s Security settings.",
                compact: true
            )
        }
        .padding()
        .background(BrandGradient.primary().ignoresSafeArea())
        .preferredColorScheme(.dark)
    }
}
#endif
