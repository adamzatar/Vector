//
//  SplashBackground.swift
//  Vector
//
//  Created by Adam Zaatar on 8/22/25.
//  File: Features/Onboarding/Components/SplashBackground.swift
//

import Foundation
import SwiftUI

/// Monochrome animated background for Splash/Intro.
/// GPU‑friendly: uses gradient + two moving radial highlights driven by `TimelineView`.
public struct SplashBackground: View {
    public init() {}

    public var body: some View {
        TimelineView(.animation) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            ZStack {
                BrandGradient.primary().ignoresSafeArea()

                // Moving radial lights for subtle depth
                RadialHighlight(
                    center: movingPoint(phase: t * 0.12, radius: 0.28, angleOffset: .pi/4),
                    color: .white.opacity(0.10)
                )
                RadialHighlight(
                    center: movingPoint(phase: t * 0.10, radius: 0.35, angleOffset: .pi * 1.2),
                    color: .black.opacity(0.10)
                )
            }
            .compositingGroup()
        }
    }

    private func movingPoint(phase: Double, radius: CGFloat, angleOffset: Double) -> UnitPoint {
        let angle = angleOffset + sin(phase) * .pi
        let x = 0.5 + cos(angle) * radius
        let y = 0.5 + sin(angle) * radius
        return UnitPoint(x: x, y: y)
    }
}

/// A radial vignette rendered as a large blurred circle with a gradient falloff.
private struct RadialHighlight: View {
    let center: UnitPoint
    let color: Color

    var body: some View {
        GeometryReader { proxy in
            let maxDim = max(proxy.size.width, proxy.size.height)
            Circle()
                .fill(
                    RadialGradient(colors: [color, .clear],
                                   center: center,
                                   startRadius: maxDim * 0.05,
                                   endRadius: maxDim * 0.6)
                )
                .blur(radius: 30)
                .ignoresSafeArea()
        }
        .allowsHitTesting(false)
    }
}

#if DEBUG
struct SplashBackground_Previews: PreviewProvider {
    static var previews: some View {
        SplashBackground()
            .preferredColorScheme(.dark)
    }
}
#endif
