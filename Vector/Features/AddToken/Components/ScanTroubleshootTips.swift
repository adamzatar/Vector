//
//  ScanTroubleshootTips.swift
//  Vector
//
//  Created by Adam Zaatar on 8/23/25.
//  File: Features/AddToken/Components/ScanTroubleshootTips.swift
//

import Foundation
import SwiftUI

struct ScanTroubleshootTips: View {
    var body: some View {
        VStack(spacing: 10) {
            Text("Point your camera at a QR code") // Localize
                .font(Typography.body)
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.45), in: Capsule())

            HStack(spacing: 10) {
                tip("Brighten screen")
                tip("Avoid glare")
                tip("Fill the frame")
            }
            .padding(.horizontal, 12)
        }
        .accessibilityElement(children: .contain)
    }

    private func tip(_ text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark.circle.fill").imageScale(.small)
            Text(text).font(Typography.caption)
        }
        .foregroundStyle(.white.opacity(0.9))
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial, in: Capsule())
    }
}

#if DEBUG
struct ScanTroubleshootTips_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ScanTroubleshootTips()
        }
        .preferredColorScheme(.dark)
    }
}
#endif
