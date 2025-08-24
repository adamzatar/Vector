//
//  IntroHeader.swift
//  Vector
//
//  Created by Adam Zaatar on 8/22/25.
//  File: Features/Onboarding/Components/IntroHeader.swift
//

import Foundation
import SwiftUI

/// Consistent header used across onboarding screens.
/// Large title + supporting tagline; monochrome styling.
struct IntroHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(Typography.titleL)
                .foregroundStyle(.white)
                .accessibilityAddTraits(.isHeader)

            Text(subtitle)
                .font(Typography.bodyS)
                .foregroundStyle(.white.opacity(0.85))
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.l)
        }
    }
}

#if DEBUG
struct IntroHeader_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            BrandGradient.primary().ignoresSafeArea()
            IntroHeader(
                title: "Welcome to Vector",
                subtitle: "A zero‑knowledge authenticator that keeps your secrets on your devices."
            )
            .padding()
        }
        .preferredColorScheme(.dark)
    }
}
#endif
