//
//  IntroCard.swift
//  Vector
//
//  Created by Adam Zaatar on 8/22/25.
//  File: Features/Onboarding/Components/IntroCard.swift

import Foundation
import SwiftUI

/// A polished card for onboarding pages: hero icon, title, and body copy.
/// Monochrome-friendly; uses subtle translucent circle behind the icon for depth.
struct IntroCard: View {
    let systemImage: String
    let title: String
    let bodyOfIntro: String

    var body: some View {
        Card(useWashBackground: true) {
            VStack(spacing: Spacing.m) {
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.08))
                        .frame(width: 92, height: 92)
                    Image(systemName: systemImage)
                        .symbolRenderingMode(.hierarchical)
                        .font(.system(size: 48, weight: .regular))
                        .foregroundStyle(.white)
                }
                .accessibilityHidden(true)

                Text(title)
                    .font(Typography.titleM)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text(bodyOfIntro)
                    .font(Typography.body)
                    .foregroundStyle(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, Spacing.l)
            .frame(maxWidth: .infinity)
        }
        .background(BrandColor.surface.opacity(0.0001))
    }
}

#if DEBUG
struct IntroCard_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            BrandGradient.primary().ignoresSafeArea()
            IntroCard(
                systemImage: "lock.shield.fill",
                title: "End‑to‑end encrypted",
                bodyOfIntro: "Your 2FA secrets are encrypted before sync. Only your devices can decrypt them."
            )
            .padding()
        }
        .preferredColorScheme(.dark)
    }
}
#endif
