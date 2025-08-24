//
//  PagerDots.swift
//  Vector
//
//  Created by Adam Zaatar on 8/22/25.
//  File: Features/Onboarding/Components/PagerDots.swift
//

import Foundation
import SwiftUI

/// Minimal, animated page indicator with accessible labels.
/// Uses scale + opacity to highlight the active page.
struct PagerDots: View {
    let count: Int
    let index: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<count, id: \.self) { i in
                Circle()
                    .fill(i == index ? Color.white : Color.white.opacity(0.35))
                    .frame(width: i == index ? 8 : 6, height: i == index ? 8 : 6)
                    .scaleEffect(i == index ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.15), value: index)
                    .accessibilityLabel(Text("Page \(i+1) of \(count)")) // Localize
                    .accessibilityAddTraits(i == index ? [.isSelected] : [])
            }
        }
        .accessibilityElement(children: .contain)
    }
}

#if DEBUG
struct PagerDots_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            BrandGradient.primary().ignoresSafeArea()
            PagerDots(count: 3, index: 1)
        }
        .preferredColorScheme(.dark)
    }
}
#endif
