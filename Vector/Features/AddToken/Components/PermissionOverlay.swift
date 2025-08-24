//
//  PermissionOverlay.swift
//  Vector
//
//  Created by Adam Zaatar on 8/22/25.
//  File: Features/AddToken/Components/PermissionOverlay.swift
//

import Foundation
import SwiftUI

/// Full-screen overlay instructions shown when camera permission is denied.
struct PermissionOverlay: View {
    var body: some View {
        VStack(spacing: Spacing.m) {
            Image(systemName: "camera.fill")
                .font(.system(size: 44))
                .foregroundStyle(.white.opacity(0.9))
            Text("Camera access denied") // Localize
                .font(Typography.titleS)
                .foregroundStyle(.white)
            Text("Enable Camera in Settings to scan QR codes.") // Localize
                .font(Typography.bodyS)
                .foregroundStyle(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.l)
        }
        .padding(.bottom, 140)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .background(Color.black.opacity(0.3))
        .allowsHitTesting(false)
    }
}
