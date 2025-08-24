//
//  ReticleOverlay.swift
//  Vector
//
//  Created by Adam Zaatar on 8/22/25.
//  File: Features/AddToken/Components/ReticleOverlay.swift
//

import Foundation
import SwiftUI

/// Darkens the screen with a rounded-rect cutout to guide scanning towards center.
struct ReticleOverlay: View {
    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let rectW = min(size.width * 0.78, 340)
            let rectH = rectW
            let rect = CGRect(
                x: (size.width - rectW) / 2,
                y: (size.height - rectH) / 2.5,
                width: rectW, height: rectH
            )

            ZStack {
                // Dim outside the reticle using destinationOut mask
                Color.black.opacity(0.45)
                    .mask(
                        Rectangle()
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .frame(width: rect.width, height: rect.height)
                                    .position(x: rect.midX, y: rect.midY)
                                    .blendMode(.destinationOut)
                            )
                    )
                    .compositingGroup()

                // Reticle stroke
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.85), lineWidth: 2)
                    .frame(width: rect.width, height: rect.height)
                    .position(x: rect.midX, y: rect.midY)
            }
            .ignoresSafeArea()
        }
    }
}
