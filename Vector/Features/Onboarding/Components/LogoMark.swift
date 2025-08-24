//
//  LogoMark.swift
//  Vector
//
//  Created by Adam Zaatar on 8/22/25.
//  File: Features/Onboarding/Components/LogoMark.swift
//

import Foundation
import SwiftUI

/// Vector brand mark: circular badge with a lock and a subtle pulsing arrow.
/// Designed to be reusable in Splash and elsewhere (Settings header, marketing screens).
public struct LogoMark: View {
    public enum Size { case small, medium, large }

    private let size: Size
    @State private var appear = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(size: Size = .large) {
        self.size = size
    }

    public var body: some View {
        let dim = dimension
        ZStack {
            // Badge
            Circle()
                .fill(.black.opacity(0.25))
                .frame(width: dim, height: dim)
                .overlay(Circle().stroke(.white.opacity(0.15), lineWidth: 1))
                .shadow(color: .black.opacity(0.25), radius: dim * 0.12, x: 0, y: dim * 0.08)

            // Lock
            Image(systemName: "lock.circle.fill")
                .symbolRenderingMode(.hierarchical)
                .font(.system(size: dim * 0.48, weight: .semibold))
                .foregroundStyle(.white)
                .scaleEffect(appear ? 1.0 : 0.94)
                .animation(.spring(response: 0.6, dampingFraction: 0.9).delay(0.05), value: appear)

            // Arrow pulse overlay
            ArrowPulse()
                .offset(x: 0, y: dim * 0.42)
                .opacity(appear ? 1.0 : 0.0)
                .animation(.easeIn(duration: 0.25).delay(0.20), value: appear)
        }
        .onAppear { appear = true }
        .accessibilityHidden(true)
    }

    private var dimension: CGFloat {
        switch size {
        case .small: return 72
        case .medium: return 104
        case .large: return 132
        }
    }
}

#if DEBUG
struct LogoMark_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            BrandGradient.primary().ignoresSafeArea()
            LogoMark(size: .large)
        }
        .preferredColorScheme(.dark)
    }
}
#endif
