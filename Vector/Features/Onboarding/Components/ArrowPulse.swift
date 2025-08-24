//
//  ArrowPulse.swift
//  Vector
//
//  Created by Adam Zaatar on 8/22/25.
//  File: Features/Onboarding/Components/ArrowPulse.swift
//

import Foundation
import SwiftUI

/// A small pulsing arrow used to hint “scroll / continue”.
/// Default tint uses our brand primary text (monochrome) so it works on both themes.
/// Place over dark/light surfaces; opacity/scale animate continuously.
struct ArrowPulse: View {
    enum Direction { case down, up, left, right }

    var direction: Direction = .down
    var size: CGFloat = 28
    var tint: Color = BrandColor.primaryText
    var opacityRange: ClosedRange<Double> = 0.35...1.0
    var scaleRange: ClosedRange<Double> = 0.92...1.08
    var period: TimeInterval = 1.2

    @State private var anim = false

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: size, weight: .semibold))
            .foregroundStyle(tint)
            .scaleEffect(anim ? scaleRange.upperBound : scaleRange.lowerBound)
            .opacity(anim ? opacityRange.upperBound : opacityRange.lowerBound)
            .rotationEffect(rotation)
            .animation(.easeInOut(duration: period).repeatForever(autoreverses: true), value: anim)
            .onAppear { anim = true }
            .accessibilityHidden(true)
    }

    // MARK: - Helpers

    private var systemName: String {
        switch direction {
        case .down:  return "chevron.down"
        case .up:    return "chevron.up"
        case .left:  return "chevron.left"
        case .right: return "chevron.right"
        }
    }

    private var rotation: Angle {
        // Keep symbol fixed; we already choose a proper symbol per direction.
        .degrees(0)
    }
}

#if DEBUG
struct ArrowPulse_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            BrandGradient.wash().ignoresSafeArea()
            VStack(spacing: Spacing.l) {
                ArrowPulse(direction: .down, size: 34, tint: .white)
                ArrowPulse(direction: .right, size: 28, tint: BrandColor.silver)
            }
        }
        .preferredColorScheme(.dark)
    }
}
#endif
