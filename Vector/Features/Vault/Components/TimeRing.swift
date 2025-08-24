//
//  TimeRing.swift
//  Vector
//
//  Created by Adam Zaatar on 8/21/25.
//  File: Features/Vault/Components/TimeRing.swift
//

import Foundation
import SwiftUI

/// A lightweight, allocation-conscious progress ring used to visualize the TOTP window (0...1).
/// - Performance: Avoids per-frame allocations; uses a simple `Shape` + stroke trimming.
/// - Accessibility: Hidden by default (call sites should expose a label/value describing time left).
/// - Appearance: Monochrome gradient matching Vector's identity.
struct TimeRing: View {
    /// Normalized progress of the current TOTP window, clamped to [0, 1].
    let progress: Double

    /// Ring thickness in points.
    var lineWidth: CGFloat = 3

    /// Background track opacity.
    var trackOpacity: Double = 0.20

    /// Disable animation (e.g., when Reduce Motion is enabled).
    var animated: Bool = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Precomputed gradient to avoid re-allocating each frame.
    private static let ringGradient = AngularGradient(
        gradient: Gradient(colors: [
            BrandColor.white,
            BrandColor.silver,
            BrandColor.gray,
            BrandColor.charcoal
        ]),
        center: .center
    )

    var body: some View {
        ZStack {
            // Track
            Circle()
                .stroke(lineWidth: lineWidth)
                .fill(Color.secondary.opacity(trackOpacity))

            // Progress arc
            RingArc(progress: progress.clamped01)
                .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .fill(Self.ringGradient)
                .rotationEffect(.degrees(-90)) // start at top
                .animation(
                    (animated && !reduceMotion) ? .linear(duration: 0.18) : .none,
                    value: progress.clamped01
                )
        }
        .contentShape(Rectangle())
        .accessibilityHidden(true)
    }
}

// MARK: - Shape

/// A trim-friendly circular arc from 0 to `progress` (clamped to [0,1]).
/// Using a custom `Shape` avoids intermediate views and keeps updates cheap.
private struct RingArc: Shape {
    var progress: Double

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let inset: CGFloat = 0.5 // crisp edges
        let radius = min(rect.width, rect.height) / 2 - inset
        let center = CGPoint(x: rect.midX, y: rect.midY)

        // Ensure a visible dot at very small progress to indicate activity.
        let trimmed = max(0.02, min(1.0, progress))

        p.addArc(
            center: center,
            radius: radius,
            startAngle: .degrees(-90),
            endAngle: .degrees(-90 + (trimmed * 360.0)),
            clockwise: false
        )
        return p
    }

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }
}

// MARK: - Safety Clamp

private extension Double {
    var clamped01: Double { max(0.0, min(1.0, self)) }
}



// MARK: - Previews

#if DEBUG
struct TimeRing_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 24) {
            HStack(spacing: 24) {
                TimeRing(progress: 0.10)
                    .frame(width: 36, height: 36)
                TimeRing(progress: 0.45)
                    .frame(width: 36, height: 36)
                TimeRing(progress: 0.85)
                    .frame(width: 36, height: 36)
            }
            .padding()

            // Larger ring demo
            TimeRing(progress: 0.65, lineWidth: 5)
                .frame(width: 64, height: 64)
        }
        .padding()
        .background(BrandColor.surface)
        .previewLayout(.sizeThatFits)
        .preferredColorScheme(.dark)
    }
}
#endif
